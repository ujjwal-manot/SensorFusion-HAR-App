import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/activity_result.dart';

class SyncService {
  final Dio _dio;
  final List<ActivityResult> _queue = [];
  Timer? _syncTimer;
  bool _isSyncing = false;
  String? _token;
  static const String _queueKey = 'sync_queue';
  static const int _maxQueueSize = 100;

  SyncService() : _dio = Dio();

  String get _baseUrl => AppConfig.serverUrl;
  int get queueLength => _queue.length;

  Future<void> initialize(String token) async {
    _token = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
    await _restoreQueue();
    _startPeriodicSync();
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      Duration(seconds: AppConfig.syncIntervalSeconds),
      (_) => _syncNow(),
    );
  }

  void enqueue(ActivityResult result) {
    _queue.add(result);

    // Trim queue if it exceeds max size (drop oldest)
    while (_queue.length > _maxQueueSize) {
      _queue.removeAt(0);
    }

    // Trigger sync if batch size reached
    if (_queue.length >= AppConfig.syncBatchSize) {
      _syncNow();
    }

    // Persist queue for crash recovery
    _persistQueue();
  }

  Future<void> _syncNow() async {
    if (_isSyncing || _queue.isEmpty || _token == null) return;
    _isSyncing = true;

    try {
      final batchSize = _queue.length < AppConfig.syncBatchSize
          ? _queue.length
          : AppConfig.syncBatchSize;
      final batch = _queue.sublist(0, batchSize);

      final payload = batch.map((r) => r.toJson()).toList();

      await _dio.post(
        '$_baseUrl/activities/sync',
        data: {'activities': payload},
      );

      // Remove synced items from queue
      _queue.removeRange(0, batchSize);
      await _persistQueue();
    } on DioException catch (_) {
      // Keep items in queue for retry on next sync cycle
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _persistQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _queue.map((r) => jsonEncode(r.toJson())).toList();
      await prefs.setStringList(_queueKey, jsonList);
    } catch (_) {
      // Silent fail on persistence - queue still in memory
    }
  }

  Future<void> _restoreQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_queueKey);
      if (jsonList != null) {
        for (final jsonStr in jsonList) {
          try {
            final map = jsonDecode(jsonStr) as Map<String, dynamic>;
            _queue.add(ActivityResult.fromJson(map));
          } catch (_) {
            // Skip corrupted entries
          }
        }
      }
    } catch (_) {
      // Silent fail on restore
    }
  }

  Future<void> flush() async {
    while (_queue.isNotEmpty) {
      await _syncNow();
      if (_queue.isNotEmpty) {
        // If sync failed, stop trying
        break;
      }
    }
  }

  void stop() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  void dispose() {
    stop();
    _persistQueue();
  }
}
