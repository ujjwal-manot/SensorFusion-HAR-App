import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../providers/sensor_provider.dart';
import '../providers/activity_provider.dart';
import '../widgets/activity_card.dart';
import '../widgets/sensor_chart.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isRunning = false;
  bool _isInitializing = false;
  String? _initError;
  StreamSubscription? _windowSub;
  StreamSubscription? _wsSub;

  @override
  void dispose() {
    _windowSub?.cancel();
    _wsSub?.cancel();
    _stopSensing();
    super.dispose();
  }

  Future<void> _startSensing() async {
    setState(() {
      _isInitializing = true;
      _initError = null;
    });

    try {
      // Load TFLite model
      final inferenceService = ref.read(inferenceServiceProvider);
      if (!inferenceService.isLoaded) {
        await inferenceService.loadModel();
        if (inferenceService.loadError != null) {
          setState(() {
            _initError = inferenceService.loadError;
            _isInitializing = false;
          });
          return;
        }
      }

      // Connect websocket
      final authState = ref.read(authProvider);
      if (authState.token != null) {
        final wsService = ref.read(webSocketServiceProvider);
        await wsService.connect(authState.token!);

        // Listen for ws connection status
        _wsSub?.cancel();
        _wsSub = wsService.connectionStatus.listen((connected) {
          ref.read(wsConnectedProvider.notifier).state = connected;
        });

        // Initialize sync service
        final syncService = ref.read(syncServiceProvider);
        await syncService.initialize(authState.token!);
      }

      // Start sensors
      final sensorService = ref.read(sensorServiceProvider);
      sensorService.start();
      ref.read(sensorActiveProvider.notifier).state = true;

      // Listen for inference windows
      _windowSub?.cancel();
      _windowSub = sensorService.windowStream.listen((window) {
        _onWindowReady(window);
      });

      setState(() {
        _isRunning = true;
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _initError = 'Failed to start: $e';
        _isInitializing = false;
      });
    }
  }

  void _onWindowReady(List<List<double>> window) {
    final inferenceService = ref.read(inferenceServiceProvider);
    final result = inferenceService.predict(window);

    if (result != null && result.confidence >= AppConfig.confidenceThreshold) {
      ref.read(currentActivityProvider.notifier).state = result;

      // Update history (keep last 50)
      final history = ref.read(activityHistoryProvider);
      final updated = [result, ...history];
      ref.read(activityHistoryProvider.notifier).state =
          updated.length > 50 ? updated.sublist(0, 50) : updated;

      // Send via websocket
      final wsService = ref.read(webSocketServiceProvider);
      wsService.sendActivity(result);

      // Queue for sync
      final syncService = ref.read(syncServiceProvider);
      syncService.enqueue(result);
    }
  }

  void _stopSensing() {
    final sensorService = ref.read(sensorServiceProvider);
    sensorService.stop();
    ref.read(sensorActiveProvider.notifier).state = false;

    final wsService = ref.read(webSocketServiceProvider);
    wsService.disconnect();
    ref.read(wsConnectedProvider.notifier).state = false;

    final syncService = ref.read(syncServiceProvider);
    syncService.stop();

    _windowSub?.cancel();
    _windowSub = null;
    _wsSub?.cancel();
    _wsSub = null;

    setState(() {
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentActivity = ref.watch(currentActivityProvider);
    final wsConnected = ref.watch(wsConnectedProvider);
    final sensorActive = ref.watch(sensorActiveProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SensorFusion HAR',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/history'),
            tooltip: 'History',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection status bar
            _buildStatusBar(
              sensorActive: sensorActive,
              wsConnected: wsConnected,
            ),
            const SizedBox(height: 16),

            // Activity Card
            ActivityCard(activity: currentActivity),
            const SizedBox(height: 16),

            // Sensor Chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Accelerometer',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: sensorActive
                          ? const SensorChart()
                          : Center(
                              child: Text(
                                'Start sensing to view chart',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Error display
            if (_initError != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _initError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            // Recent activity list
            if (ref.watch(activityHistoryProvider).isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ...ref
                  .watch(activityHistoryProvider)
                  .take(5)
                  .map((r) => _buildActivityTile(r)),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isInitializing
            ? null
            : (_isRunning ? _stopSensing : _startSensing),
        icon: _isInitializing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(_isRunning ? Icons.stop : Icons.play_arrow),
        label: Text(_isInitializing
            ? 'Starting...'
            : (_isRunning ? 'Stop' : 'Start')),
        backgroundColor: _isRunning ? Colors.red : Colors.green,
      ),
    );
  }

  Widget _buildStatusBar({
    required bool sensorActive,
    required bool wsConnected,
  }) {
    return Row(
      children: [
        _buildStatusChip(
          label: 'Sensors',
          isActive: sensorActive,
          activeColor: Colors.green,
        ),
        const SizedBox(width: 8),
        _buildStatusChip(
          label: 'WebSocket',
          isActive: wsConnected,
          activeColor: Colors.blue,
        ),
        const SizedBox(width: 8),
        _buildStatusChip(
          label: 'Server',
          isActive: wsConnected,
          activeColor: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatusChip({
    required String label,
    required bool isActive,
    required Color activeColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? activeColor.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? activeColor.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? activeColor : Colors.grey,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? activeColor : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile(dynamic result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        leading: Icon(
          Icons.circle,
          size: 12,
          color: Colors.green.withOpacity(result.confidence),
        ),
        title: Text(result.activity),
        subtitle: Text(
          '${(result.confidence * 100).toStringAsFixed(0)}% confidence',
        ),
        trailing: Text(
          '${result.latencyMs.toStringAsFixed(1)}ms',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ),
    );
  }
}
