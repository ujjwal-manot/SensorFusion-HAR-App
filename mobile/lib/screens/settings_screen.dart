import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../providers/activity_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _serverUrlController = TextEditingController();
  bool _urlSaved = false;

  @override
  void initState() {
    super.initState();
    _serverUrlController.text = AppConfig.serverUrl;
    _loadSettings();
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('server_url');
    if (savedUrl != null) {
      setState(() {
        _serverUrlController.text = savedUrl;
        AppConfig.serverUrl = savedUrl;
      });
    }
  }

  Future<void> _saveServerUrl() async {
    final url = _serverUrlController.text.trim();
    if (url.isEmpty) return;

    AppConfig.serverUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', url);

    setState(() {
      _urlSaved = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _urlSaved = false;
        });
      }
    });
  }

  Future<void> _logout() async {
    // Stop services
    final wsService = ref.read(webSocketServiceProvider);
    wsService.disconnect();

    final syncService = ref.read(syncServiceProvider);
    syncService.stop();

    // Clear auth
    await ref.read(authProvider.notifier).logout();

    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final inferenceService = ref.watch(inferenceServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Info
          if (authState.user != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.green.withOpacity(0.2),
                      radius: 24,
                      child: Text(
                        authState.user!.displayName.isNotEmpty
                            ? authState.user!.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authState.user!.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            authState.user!.email,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Server URL
          Text(
            'Server Configuration',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _serverUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Server URL',
                      hintText: 'http://192.168.1.100:8000',
                      prefixIcon: Icon(Icons.dns_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _saveServerUrl,
                    icon: Icon(_urlSaved ? Icons.check : Icons.save),
                    label: Text(_urlSaved ? 'Saved' : 'Save URL'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Model Info
          Text(
            'Model Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Model', 'CascadeHAR Macro'),
                  const SizedBox(height: 8),
                  _buildInfoRow('Classes', '4 (Stationary, Locomotion, Vehicle, Gesture)'),
                  const SizedBox(height: 8),
                  _buildInfoRow('Input Shape', '(1, 9, 128)'),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Status',
                    inferenceService.isLoaded ? 'Loaded' : 'Not loaded',
                  ),
                  if (inferenceService.loadError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      inferenceService.loadError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Sync Settings
          Text(
            'Sync Settings',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    'Sync Interval',
                    '${AppConfig.syncIntervalSeconds}s',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Batch Size',
                    '${AppConfig.syncBatchSize}',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Sampling Rate',
                    '${AppConfig.samplingRateHz} Hz',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Window Size',
                    '${AppConfig.windowSize} samples',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Stride Size',
                    '${AppConfig.strideSize} samples',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // About
          Text(
            'About',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('App', 'SensorFusion HAR'),
                  const SizedBox(height: 8),
                  _buildInfoRow('Version', '1.0.0'),
                  const SizedBox(height: 8),
                  _buildInfoRow('Architecture', 'CascadeHAR - Macro + Fine'),
                  const SizedBox(height: 8),
                  const Text(
                    'Real-time human activity recognition using on-device '
                    'TFLite inference with phone accelerometer, gyroscope, '
                    'and magnetometer data.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Logout
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
