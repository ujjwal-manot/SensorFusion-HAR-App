"""
Generate a dummy TFLite model for SensorFusion-HAR-App development testing.

This standalone script creates a small Keras model that matches the
CascadeHAR macro classifier interface:

    Input:  (1, 9, 128)  float32  — 9 sensor channels x 128 timesteps
    Output: (1, 4)       float32  — 4 macro activity classes

Architecture:
    Permute → Conv1D(16, 3) → ReLU → Conv1D(24, 3) → ReLU → GlobalAvgPool → Dense(4, softmax)

Outputs:
    model/cascade_har_macro.tflite          — INT8 quantized
    model/cascade_har_macro_float32.tflite   — Full-precision float32

Usage:
    python model/generate_dummy_model.py
"""

import pathlib
import sys
import numpy as np

# ── Constants ────────────────────────────────────────────────────────────────

INPUT_CHANNELS = 9      # accel_xyz + gyro_xyz + mag_xyz
INPUT_TIMESTEPS = 128   # sliding window length
NUM_MACRO_CLASSES = 4   # stationary, locomotion, vehicle, gesture

SCRIPT_DIR = pathlib.Path(__file__).resolve().parent
OUTPUT_INT8 = SCRIPT_DIR / "cascade_har_macro.tflite"
OUTPUT_FLOAT32 = SCRIPT_DIR / "cascade_har_macro_float32.tflite"


# ── Representative dataset for INT8 calibration ─────────────────────────────


def _representative_dataset():
    """Yield 200 random samples for post-training INT8 quantization."""
    rng = np.random.default_rng(42)
    for _ in range(200):
        sample = rng.standard_normal((1, INPUT_CHANNELS, INPUT_TIMESTEPS)).astype(
            np.float32
        )
        yield [sample]


# ── Model builder ────────────────────────────────────────────────────────────


def build_macro_classifier(tf):
    """
    Build a lightweight Keras model matching the macro classifier spec.

    Parameters
    ----------
    tf : module
        TensorFlow module (passed explicitly so import errors are caught
        at the top level).

    Returns
    -------
    tf.keras.Model
    """
    inp = tf.keras.Input(
        shape=(INPUT_CHANNELS, INPUT_TIMESTEPS),
        dtype=tf.float32,
        name="sensor_input",
    )

    # Conv1D expects (batch, steps, features) → permute channels and timesteps
    x = tf.keras.layers.Permute((2, 1), name="permute_to_time_major")(inp)

    x = tf.keras.layers.Conv1D(
        filters=16, kernel_size=3, padding="same", activation="relu", name="conv1"
    )(x)

    x = tf.keras.layers.Conv1D(
        filters=24, kernel_size=3, padding="same", activation="relu", name="conv2"
    )(x)

    x = tf.keras.layers.GlobalAveragePooling1D(name="global_avg_pool")(x)

    out = tf.keras.layers.Dense(
        NUM_MACRO_CLASSES, activation="softmax", name="macro_output"
    )(x)

    model = tf.keras.Model(inputs=inp, outputs=out, name="CascadeHAR_MacroClassifier")
    return model


# ── Export helpers ────────────────────────────────────────────────────────────


def export_float32(model, tf) -> int:
    """Export the model as a float32 TFLite file. Returns file size."""
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_bytes = converter.convert()
    OUTPUT_FLOAT32.write_bytes(tflite_bytes)
    return len(tflite_bytes)


def export_int8(model, tf) -> int:
    """Export the model as an INT8 quantized TFLite file. Returns file size."""
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.representative_dataset = _representative_dataset
    converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
    converter.inference_input_type = tf.int8
    converter.inference_output_type = tf.int8

    tflite_bytes = converter.convert()
    OUTPUT_INT8.write_bytes(tflite_bytes)
    return len(tflite_bytes)


# ── Verification ─────────────────────────────────────────────────────────────


def verify_tflite(path: pathlib.Path, tf) -> bool:
    """Load a TFLite model and run a single inference to verify it works."""
    interpreter = tf.lite.Interpreter(model_path=str(path))
    interpreter.allocate_tensors()

    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    inp_shape = tuple(input_details[0]["shape"])
    out_shape = tuple(output_details[0]["shape"])
    inp_dtype = input_details[0]["dtype"]
    out_dtype = output_details[0]["dtype"]

    print(f"  Input:  shape={inp_shape}, dtype={inp_dtype.__name__}")
    print(f"  Output: shape={out_shape}, dtype={out_dtype.__name__}")

    # Create test input matching the expected dtype
    rng = np.random.default_rng(99)
    if np.issubdtype(inp_dtype, np.integer):
        test_input = rng.integers(-128, 127, size=inp_shape, dtype=inp_dtype)
    else:
        test_input = rng.standard_normal(inp_shape).astype(inp_dtype)

    interpreter.set_tensor(input_details[0]["index"], test_input)
    interpreter.invoke()
    output = interpreter.get_tensor(output_details[0]["index"])

    print(f"  Sample output: {output.flatten()}")

    expected_batch = 1
    expected_classes = NUM_MACRO_CLASSES
    if out_shape != (expected_batch, expected_classes):
        print(f"  [WARN] Unexpected output shape: {out_shape}")
        return False

    print("  [OK] Verification passed.")
    return True


# ── Main ─────────────────────────────────────────────────────────────────────


def main() -> int:
    # ── Check TensorFlow availability ────────────────────────────────────
    try:
        import tensorflow as tf
    except ImportError:
        print("=" * 60)
        print("  TensorFlow is required but not installed.")
        print()
        print("  Install with:")
        print("    pip install tensorflow")
        print()
        print("  Or for GPU support:")
        print("    pip install tensorflow[and-cuda]")
        print()
        print("  Minimum version: 2.13")
        print("=" * 60)
        return 1

    print("=" * 60)
    print("  Dummy CascadeHAR Macro Classifier Generator")
    print(f"  TensorFlow version: {tf.__version__}")
    print("=" * 60)

    # ── Build model ──────────────────────────────────────────────────────
    print("\n[1/4] Building Keras model …")
    model = build_macro_classifier(tf)
    model.summary()

    # ── Export float32 ───────────────────────────────────────────────────
    print("\n[2/4] Exporting float32 TFLite …")
    f32_size = export_float32(model, tf)
    print(f"  Saved to: {OUTPUT_FLOAT32}")
    print(f"  Size:     {f32_size:,} bytes")

    # ── Export INT8 ──────────────────────────────────────────────────────
    print("\n[3/4] Exporting INT8 quantized TFLite …")
    int8_size = export_int8(model, tf)
    print(f"  Saved to: {OUTPUT_INT8}")
    print(f"  Size:     {int8_size:,} bytes")
    print(f"  Compression ratio: {f32_size / int8_size:.1f}x")

    # ── Verify both models ───────────────────────────────────────────────
    print("\n[4/4] Verifying exported models …")

    print(f"\n  Float32 model ({OUTPUT_FLOAT32.name}):")
    ok_f32 = verify_tflite(OUTPUT_FLOAT32, tf)

    print(f"\n  INT8 model ({OUTPUT_INT8.name}):")
    ok_int8 = verify_tflite(OUTPUT_INT8, tf)

    # ── Summary ──────────────────────────────────────────────────────────
    print("\n" + "=" * 60)
    if ok_f32 and ok_int8:
        print("  All models generated and verified successfully.")
        print()
        print(f"  INT8 model:    {OUTPUT_INT8}")
        print(f"  Float32 model: {OUTPUT_FLOAT32}")
        print()
        print("  Next steps:")
        print("    1. Copy INT8 model to Flutter assets:")
        print(r"       mobile\assets\models\cascade_har_macro.tflite")
        print("    2. Or run export_tflite.py which copies automatically.")
    else:
        print("  [WARN] Some verifications failed. Check output above.")
    print("=" * 60)

    return 0 if (ok_f32 and ok_int8) else 1


if __name__ == "__main__":
    sys.exit(main())
