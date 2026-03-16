class AppConfig {
  static String serverUrl = 'http://192.168.1.100:8000';
  static String get wsUrl => serverUrl.replaceFirst('http', 'ws');
  static const String modelPath = 'assets/models/cascade_har_macro.tflite';
  static const String labelsPath = 'assets/config/activity_labels.json';
  static const int samplingRateHz = 50;
  static const int windowSize = 128;
  static const int strideSize = 16;
  static const int numChannels = 9;
  static const int bufferSize = 256;
  static const double confidenceThreshold = 0.6;
  static const int syncIntervalSeconds = 30;
  static const int syncBatchSize = 50;
}
