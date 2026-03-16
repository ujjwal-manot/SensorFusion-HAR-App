"""
Export CascadeHAR macro classifier to TFLite INT8.

This script:
1. Attempts to load a CascadeHAR checkpoint from EdgeHAR-1
2. Extracts the macro classifier (stage 1, 4 classes)
3. Exports to ONNX, then converts to TFLite INT8
4. Falls back to creating a dummy TFLite model if no checkpoint exists

Input shape:  (1, 9, 128)  - batch, channels (accel+gyro+mag xyz), timesteps
Output shape: (1, 4)       - 4 macro classes (stationary, locomotion, vehicle, gesture)
"""

import os
import sys
import shutil
import pathlib
import json
import numpy as np

# ── Paths ────────────────────────────────────────────────────────────────────

SCRIPT_DIR = pathlib.Path(__file__).resolve().parent
CHECKPOINT_DIR = pathlib.Path(r"C:\Users\Ujjwal\EdgeHAR-1\checkpoints")
OUTPUT_TFLITE = SCRIPT_DIR / "cascade_har_macro.tflite"
FLUTTER_ASSETS_DIR = pathlib.Path(
    r"C:\Users\Ujjwal\SensorFusion-HAR-App\mobile\assets\models"
)
FLUTTER_TFLITE = FLUTTER_ASSETS_DIR / "cascade_har_macro.tflite"

INPUT_CHANNELS = 9
INPUT_TIMESTEPS = 128
NUM_MACRO_CLASSES = 4


# ── Utility ──────────────────────────────────────────────────────────────────


def _copy_to_flutter(src: pathlib.Path) -> None:
    """Copy the exported TFLite model to the Flutter assets directory."""
    FLUTTER_ASSETS_DIR.mkdir(parents=True, exist_ok=True)
    shutil.copy2(str(src), str(FLUTTER_TFLITE))
    print(f"[OK] Copied model to {FLUTTER_TFLITE}")


def _representative_dataset():
    """Yield representative data for INT8 quantization calibration."""
    rng = np.random.default_rng(42)
    for _ in range(200):
        sample = rng.standard_normal((1, INPUT_CHANNELS, INPUT_TIMESTEPS)).astype(
            np.float32
        )
        yield [sample]


# ── Checkpoint export path ───────────────────────────────────────────────────


def _find_checkpoint() -> pathlib.Path | None:
    """Return the latest .pt / .pth checkpoint in EdgeHAR-1, or None."""
    if not CHECKPOINT_DIR.is_dir():
        return None
    candidates = sorted(
        list(CHECKPOINT_DIR.glob("*.pt")) + list(CHECKPOINT_DIR.glob("*.pth")),
        key=lambda p: p.stat().st_mtime,
        reverse=True,
    )
    return candidates[0] if candidates else None


def _export_from_checkpoint(ckpt_path: pathlib.Path) -> bool:
    """
    Load CascadeHAR checkpoint, extract macro classifier, export to TFLite INT8.

    Returns True on success, False on failure.
    """
    try:
        import torch
    except ImportError:
        print("[WARN] PyTorch not installed. Run: pip install torch")
        return False

    try:
        import onnx  # noqa: F401
        from onnxruntime.quantization import quantize_dynamic  # noqa: F401
    except ImportError:
        print("[WARN] ONNX / onnxruntime not installed.")
        print("       Run: pip install onnx onnxruntime")

    try:
        import tensorflow as tf
    except ImportError:
        print("[WARN] TensorFlow not installed. Run: pip install tensorflow")
        return False

    print(f"[INFO] Loading checkpoint: {ckpt_path}")
    checkpoint = torch.load(str(ckpt_path), map_location="cpu", weights_only=False)

    # Handle different checkpoint formats
    if isinstance(checkpoint, dict):
        state_dict = checkpoint.get(
            "model_state_dict", checkpoint.get("state_dict", checkpoint)
        )
    else:
        # Assume it is the model object itself
        state_dict = checkpoint.state_dict() if hasattr(checkpoint, "state_dict") else None

    if state_dict is None:
        print("[WARN] Could not extract state_dict from checkpoint.")
        return False

    # ── Extract macro-classifier weights ─────────────────────────────────
    # Convention: macro classifier keys start with "macro_classifier." or "stage1."
    macro_keys = [
        k
        for k in state_dict.keys()
        if k.startswith(("macro_classifier.", "stage1.", "macro."))
    ]

    if not macro_keys:
        print("[WARN] No macro-classifier weights found in checkpoint.")
        print("       Available keys (first 20):")
        for k in list(state_dict.keys())[:20]:
            print(f"         {k}")
        return False

    print(f"[INFO] Found {len(macro_keys)} macro-classifier parameters.")

    # ── Build a lightweight PyTorch model matching the macro head ─────────
    class MacroClassifier(torch.nn.Module):
        def __init__(self) -> None:
            super().__init__()
            self.conv1 = torch.nn.Conv1d(INPUT_CHANNELS, 16, kernel_size=3, padding=1)
            self.relu1 = torch.nn.ReLU()
            self.conv2 = torch.nn.Conv1d(16, 24, kernel_size=3, padding=1)
            self.relu2 = torch.nn.ReLU()
            self.pool = torch.nn.AdaptiveAvgPool1d(1)
            self.fc = torch.nn.Linear(24, NUM_MACRO_CLASSES)

        def forward(self, x: torch.Tensor) -> torch.Tensor:
            x = self.relu1(self.conv1(x))
            x = self.relu2(self.conv2(x))
            x = self.pool(x).squeeze(-1)
            return self.fc(x)

    model = MacroClassifier()

    # Try to load matching weights
    own_state = model.state_dict()
    loaded = 0
    for mk in macro_keys:
        # Strip prefix to get the bare parameter name
        for prefix in ("macro_classifier.", "stage1.", "macro."):
            if mk.startswith(prefix):
                short = mk[len(prefix) :]
                break
        else:
            short = mk

        if short in own_state and own_state[short].shape == state_dict[mk].shape:
            own_state[short] = state_dict[mk]
            loaded += 1

    model.load_state_dict(own_state)
    model.eval()
    print(f"[INFO] Loaded {loaded}/{len(macro_keys)} parameters into MacroClassifier.")

    # ── Export to ONNX ───────────────────────────────────────────────────
    onnx_path = SCRIPT_DIR / "cascade_har_macro.onnx"
    dummy_input = torch.randn(1, INPUT_CHANNELS, INPUT_TIMESTEPS)

    torch.onnx.export(
        model,
        dummy_input,
        str(onnx_path),
        input_names=["input"],
        output_names=["output"],
        dynamic_axes={"input": {0: "batch"}, "output": {0: "batch"}},
        opset_version=13,
    )
    print(f"[OK] Exported ONNX model to {onnx_path}")

    # ── Convert ONNX → TFLite INT8 ──────────────────────────────────────
    try:
        import onnx as _onnx
        import onnx_tf.backend as onnx_tf_backend

        onnx_model = _onnx.load(str(onnx_path))
        tf_rep = onnx_tf_backend.prepare(onnx_model)
        saved_model_dir = str(SCRIPT_DIR / "_saved_model_tmp")
        tf_rep.export_graph(saved_model_dir)

        converter = tf.lite.TFLiteConverter.from_saved_model(saved_model_dir)
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        converter.representative_dataset = _representative_dataset
        converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
        converter.inference_input_type = tf.int8
        converter.inference_output_type = tf.int8

        tflite_model = converter.convert()
        OUTPUT_TFLITE.write_bytes(tflite_model)
        print(f"[OK] Saved INT8 TFLite model to {OUTPUT_TFLITE}")

        # Clean up temp saved model
        shutil.rmtree(saved_model_dir, ignore_errors=True)
        _copy_to_flutter(OUTPUT_TFLITE)
        return True

    except Exception as exc:
        print(f"[WARN] ONNX→TFLite conversion failed: {exc}")
        print("[INFO] Falling back to dummy model generation.")
        return False


# ── Dummy model fallback ─────────────────────────────────────────────────────


def _create_dummy_tflite() -> bool:
    """
    Build a small Keras model matching the macro classifier interface,
    quantize to INT8, and save.  Used when no real checkpoint is available.
    """
    try:
        import tensorflow as tf
    except ImportError:
        print("[ERROR] TensorFlow is required to create the dummy model.")
        print("        Run: pip install tensorflow")
        return False

    print("[INFO] Creating dummy TFLite macro classifier …")

    # Build model: input (batch, 9, 128)
    inp = tf.keras.Input(shape=(INPUT_CHANNELS, INPUT_TIMESTEPS), dtype=tf.float32)

    # Transpose to (batch, 128, 9) for Conv1D which expects (batch, steps, features)
    x = tf.keras.layers.Permute((2, 1))(inp)
    x = tf.keras.layers.Conv1D(16, 3, padding="same", activation="relu")(x)
    x = tf.keras.layers.Conv1D(24, 3, padding="same", activation="relu")(x)
    x = tf.keras.layers.GlobalAveragePooling1D()(x)
    out = tf.keras.layers.Dense(NUM_MACRO_CLASSES, activation="softmax")(x)

    model = tf.keras.Model(inputs=inp, outputs=out)
    model.summary()

    # ── INT8 quantization ────────────────────────────────────────────────
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.representative_dataset = _representative_dataset
    converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
    converter.inference_input_type = tf.int8
    converter.inference_output_type = tf.int8

    tflite_int8 = converter.convert()
    OUTPUT_TFLITE.write_bytes(tflite_int8)
    print(f"[OK] Saved INT8 TFLite dummy model to {OUTPUT_TFLITE}")
    print(f"     Size: {len(tflite_int8):,} bytes")

    _copy_to_flutter(OUTPUT_TFLITE)
    return True


# ── Main ─────────────────────────────────────────────────────────────────────


def main() -> int:
    print("=" * 60)
    print("  CascadeHAR Macro Classifier → TFLite INT8 Exporter")
    print("=" * 60)

    # Load label map for reference
    labels_path = SCRIPT_DIR / "activity_labels.json"
    if labels_path.exists():
        with open(labels_path, "r", encoding="utf-8") as f:
            labels = json.load(f)
        macro_labels = labels.get("macro", {})
        print(f"\n[INFO] Macro classes: {json.dumps(macro_labels, indent=2)}")

    print(f"\n[INFO] Looking for checkpoints in {CHECKPOINT_DIR}")

    ckpt = _find_checkpoint()
    if ckpt is not None:
        print(f"[INFO] Found checkpoint: {ckpt.name}")
        success = _export_from_checkpoint(ckpt)
        if success:
            print("\n[DONE] Export from real checkpoint succeeded.")
            return 0
        print("\n[INFO] Real export failed; falling back to dummy model.")

    else:
        print("[INFO] No checkpoint found. Creating dummy model for development.")

    success = _create_dummy_tflite()
    if success:
        print("\n[DONE] Dummy model created successfully.")
        return 0

    print("\n[FAIL] Could not create any TFLite model.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
