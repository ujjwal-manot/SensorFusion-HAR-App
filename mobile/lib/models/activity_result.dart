class ActivityResult {
  final String activity;
  final String macroCategory;
  final double confidence;
  final double latencyMs;
  final DateTime timestamp;
  final List<double>? sensorSnapshot;

  const ActivityResult({
    required this.activity,
    required this.macroCategory,
    required this.confidence,
    required this.latencyMs,
    required this.timestamp,
    this.sensorSnapshot,
  });

  Map<String, dynamic> toJson() => {
        'activity': activity,
        'macro_category': macroCategory,
        'confidence': confidence,
        'sensor_data': sensorSnapshot,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ActivityResult.fromJson(Map<String, dynamic> json) => ActivityResult(
        activity: json['activity'] as String,
        macroCategory: json['macro_category'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        latencyMs: (json['latency_ms'] as num?)?.toDouble() ?? 0.0,
        timestamp: DateTime.parse(json['timestamp'] as String),
        sensorSnapshot: (json['sensor_data'] as List<dynamic>?)
            ?.map((e) => (e as num).toDouble())
            .toList(),
      );
}
