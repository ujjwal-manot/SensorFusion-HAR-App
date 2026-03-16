import 'dart:math';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../config/app_config.dart';
import '../config/activity_labels.dart';
import '../models/activity_result.dart';

class InferenceService {
  Interpreter? _interpreter;
  bool _isLoaded = false;
  String? _loadError;

  bool get isLoaded => _isLoaded;
  String? get loadError => _loadError;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(AppConfig.modelPath);
      _isLoaded = true;
      _loadError = null;
    } catch (e) {
      _isLoaded = false;
      _loadError = 'Failed to load TFLite model: $e';
    }
  }

  ActivityResult? predict(List<List<double>> window) {
    if (!_isLoaded || _interpreter == null) return null;

    final stopwatch = Stopwatch()..start();

    try {
      // window is (128, 9), transpose to (1, 9, 128) for the model
      final input = List.generate(
        1,
        (_) => List.generate(
          AppConfig.numChannels,
          (ch) => List.generate(
            AppConfig.windowSize,
            (t) => window[t][ch],
          ),
        ),
      );

      // Output shape: (1, 4)
      final output = List.generate(1, (_) => List.filled(4, 0.0));

      _interpreter!.run(input, output);

      stopwatch.stop();

      // Softmax normalization
      final logits = output[0];
      final maxLogit = logits.reduce((a, b) => a > b ? a : b);
      final exps = logits.map((x) => exp(x - maxLogit)).toList();
      final sumExps = exps.reduce((a, b) => a + b);
      final probs = exps.map((x) => x / sumExps).toList();

      final maxIdx = probs.indexOf(probs.reduce((a, b) => a > b ? a : b));
      final confidence = probs[maxIdx];
      final macroLabel = ActivityLabels.macro[maxIdx] ?? 'Unknown';

      return ActivityResult(
        activity: macroLabel,
        macroCategory: macroLabel.toLowerCase(),
        confidence: confidence,
        latencyMs: stopwatch.elapsedMicroseconds / 1000.0,
        timestamp: DateTime.now(),
        sensorSnapshot: window.isNotEmpty ? List.of(window.last) : null,
      );
    } catch (e) {
      stopwatch.stop();
      return null;
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
  }
}
