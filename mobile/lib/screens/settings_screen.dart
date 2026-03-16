import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/activity_provider.dart';
import '../widgets/glass_card.dart';

/// Settings screen redesigned as a tab within the main home shell.
class SettingsTab extends ConsumerStatefulWidget {
  const SettingsTab({super.key});

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab> {
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
    final wsService = ref.read(webSocketServiceProvider);
    wsService.disconnect();

    final syncService = ref.read(syncServiceProvider);
    syncService.stop();

    await ref.read(authProvider.notifier).logout();

    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final inferenceService = ref.watch(inferenceServiceProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          // Header
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),

          // User profile card
          if (authState.user != null) ...[
            GlassCard(
              glowColors: AppTheme.accentGradient,
              glowOpacity: 0.06,
              glowBlur: 20,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: AppTheme.accentGradient,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        authState.user!.displayName.isNotEmpty
                            ? authState.user!.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
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
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          authState.user!.email,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Role badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppTheme.accent.withOpacity(0.1),
                      border: Border.all(
                        color: AppTheme.accent.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      authState.user!.role.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accent,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],

          // ── Connection Section ──────────────────────────────────────
          _SectionHeader(title: 'CONNECTION'),
          const SizedBox(height: 10),
          GlassCard(
            enableBlur: false,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _serverUrlController,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'http://192.168.1.100:8000',
                    prefixIcon: const Icon(Icons.dns_outlined, size: 20),
                    suffixIcon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _urlSaved
                          ? const Icon(
                              Icons.check_circle_rounded,
                              key: ValueKey('check'),
                              color: AppTheme.success,
                              size: 20,
                            )
                          : const SizedBox.shrink(key: ValueKey('empty')),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _saveServerUrl,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppTheme.accent.withOpacity(0.12),
                      border: Border.all(
                        color: AppTheme.accent.withOpacity(0.25),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _urlSaved ? 'Saved' : 'Save URL',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accent,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Model Section ───────────────────────────────────────────
          _SectionHeader(title: 'MODEL'),
          const SizedBox(height: 10),
          GlassCard(
            enableBlur: false,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _InfoRow(label: 'Model', value: 'CascadeHAR Macro'),
                const SizedBox(height: 12),
                _InfoRow(label: 'Input Shape', value: '(1, 9, 128)'),
                const SizedBox(height: 12),
                _InfoRow(
                  label: 'Status',
                  value: inferenceService.isLoaded ? 'Loaded' : 'Not loaded',
                  valueColor: inferenceService.isLoaded
                      ? AppTheme.success
                      : AppTheme.error,
                  showDot: true,
                ),
                if (inferenceService.loadError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    inferenceService.loadError!,
                    style: const TextStyle(
                      color: AppTheme.error,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Streaming Section ───────────────────────────────────────
          _SectionHeader(title: 'STREAMING'),
          const SizedBox(height: 10),
          GlassCard(
            enableBlur: false,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _InfoRow(
                  label: 'Sampling Rate',
                  value: '${AppConfig.samplingRateHz} Hz',
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  label: 'Window Size',
                  value: '${AppConfig.windowSize} samples',
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  label: 'Stride Size',
                  value: '${AppConfig.strideSize} samples',
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  label: 'Sync Interval',
                  value: '${AppConfig.syncIntervalSeconds}s',
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── About Section ───────────────────────────────────────────
          _SectionHeader(title: 'ABOUT'),
          const SizedBox(height: 10),
          GlassCard(
            enableBlur: false,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _InfoRow(label: 'App', value: 'SensorFusion HAR'),
                const SizedBox(height: 12),
                const _InfoRow(label: 'Version', value: '1.0.0'),
                const SizedBox(height: 12),
                const _InfoRow(
                    label: 'Architecture', value: 'CascadeHAR'),
                const SizedBox(height: 14),
                Text(
                  'Real-time human activity recognition using on-device '
                  'TFLite inference with phone accelerometer, gyroscope, '
                  'and magnetometer data.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textTertiary.withOpacity(0.8),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Logout Button ───────────────────────────────────────────
          GestureDetector(
            onTap: _logout,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppTheme.error.withOpacity(0.08),
                border: Border.all(
                  color: AppTheme.error.withOpacity(0.2),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, color: AppTheme.error, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Logout',
                    style: TextStyle(
                      color: AppTheme.error,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.textTertiary,
        letterSpacing: 2,
      ),
    );
  }
}

// ── Info Row ──────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool showDot;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textTertiary,
            ),
          ),
        ),
        if (showDot) ...[
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: valueColor ?? AppTheme.textPrimary,
              boxShadow: [
                BoxShadow(
                  color: (valueColor ?? AppTheme.textPrimary).withOpacity(0.4),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor ?? AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Legacy SettingsScreen wrapper (kept for backward compatibility if needed).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SettingsTab());
  }
}
