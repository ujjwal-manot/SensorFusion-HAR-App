import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sensor_sample.dart';
import '../services/sensor_service.dart';

final sensorServiceProvider = Provider<SensorService>((ref) {
  final service = SensorService();
  ref.onDispose(() => service.dispose());
  return service;
});

final sensorActiveProvider = StateProvider<bool>((ref) => false);

final sensorWindowProvider = StreamProvider<List<List<double>>>((ref) {
  final service = ref.watch(sensorServiceProvider);
  return service.windowStream;
});

final latestSampleProvider = StreamProvider<SensorSample>((ref) {
  final service = ref.watch(sensorServiceProvider);
  return service.sampleStream;
});
