import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity_result.dart';
import '../services/inference_service.dart';
import '../services/websocket_service.dart';
import '../services/sync_service.dart';

final inferenceServiceProvider = Provider<InferenceService>((ref) {
  final service = InferenceService();
  ref.onDispose(() => service.dispose());
  return service;
});

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(() => service.dispose());
  return service;
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService();
  ref.onDispose(() => service.dispose());
  return service;
});

final currentActivityProvider = StateProvider<ActivityResult?>((ref) => null);

final activityHistoryProvider =
    StateProvider<List<ActivityResult>>((ref) => []);

final wsConnectedProvider = StateProvider<bool>((ref) => false);
