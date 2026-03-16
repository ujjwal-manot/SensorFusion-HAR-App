import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/sensor_provider.dart';
import '../providers/activity_provider.dart';
import '../widgets/activity_card.dart';
import '../widgets/animated_bg.dart';
import '../widgets/glass_card.dart';
import '../widgets/sensor_chart.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

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
  int _currentTab = 0;

  @override
  void dispose() {
    _windowSub?.cancel();
    _wsSub?.cancel();
    _stopSensing();
    super.dispose();
  }

  // ── Sensing Logic (preserved from original) ─────────────────────────

  Future<void> _startSensing() async {
    setState(() {
      _isInitializing = true;
      _initError = null;
    });

    try {
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

      final authState = ref.read(authProvider);
      if (authState.token != null) {
        final wsService = ref.read(webSocketServiceProvider);
        await wsService.connect(authState.token!);

        _wsSub?.cancel();
        _wsSub = wsService.connectionStatus.listen((connected) {
          ref.read(wsConnectedProvider.notifier).state = connected;
        });

        final syncService = ref.read(syncServiceProvider);
        await syncService.initialize(authState.token!);
      }

      final sensorService = ref.read(sensorServiceProvider);
      sensorService.start();
      ref.read(sensorActiveProvider.notifier).state = true;

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

      final history = ref.read(activityHistoryProvider);
      final updated = [result, ...history];
      ref.read(activityHistoryProvider.notifier).state =
          updated.length > 50 ? updated.sublist(0, 50) : updated;

      final wsService = ref.read(webSocketServiceProvider);
      wsService.sendActivity(result);

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

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTab,
        children: [
          _DashboardTab(
            isRunning: _isRunning,
            isInitializing: _isInitializing,
            initError: _initError,
            onStart: _startSensing,
            onStop: _stopSensing,
          ),
          const HistoryTab(),
          const SettingsTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 72 + MediaQuery.of(context).padding.bottom,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: AppTheme.cardColor.withOpacity(0.8),
            border: const Border(
              top: BorderSide(color: AppTheme.borderColor),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.dashboard_rounded, 'Home'),
              _navItem(1, Icons.history_rounded, 'History'),
              _navItem(2, Icons.settings_rounded, 'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isActive = _currentTab == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTab = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: Icon(
                icon,
                size: 26,
                color: isActive ? AppTheme.accent : AppTheme.textTertiary,
              ),
            ),
            const SizedBox(height: 4),
            // Active dot indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isActive ? 4 : 0,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppTheme.accent.withOpacity(0.5),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// DASHBOARD TAB
// ═══════════════════════════════════════════════════════════════════════

class _DashboardTab extends ConsumerWidget {
  final bool isRunning;
  final bool isInitializing;
  final String? initError;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const _DashboardTab({
    required this.isRunning,
    required this.isInitializing,
    required this.initError,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentActivity = ref.watch(currentActivityProvider);
    final wsConnected = ref.watch(wsConnectedProvider);
    final sensorActive = ref.watch(sensorActiveProvider);
    final history = ref.watch(activityHistoryProvider);
    final activityName = currentActivity?.activity ?? 'stationary';
    final gradient = AppTheme.gradientForCategory(activityName);

    return Stack(
      children: [
        // Animated background keyed to current activity
        Positioned.fill(
          child: AnimatedBackground(
            key: ValueKey(activityName),
            colors: gradient,
            intensity: sensorActive ? 0.08 : 0.04,
          ),
        ),

        // Scrollable content
        SafeArea(
          child: Column(
            children: [
              // Status header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  children: [
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        children: [
                          TextSpan(
                            text: 'Sensor',
                            style: TextStyle(color: AppTheme.textPrimary),
                          ),
                          TextSpan(
                            text: 'Fusion',
                            style: TextStyle(color: AppTheme.accent),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    _StatusDot(
                      active: sensorActive,
                      color: AppTheme.success,
                      tooltip: 'Sensors',
                    ),
                    const SizedBox(width: 6),
                    _StatusDot(
                      active: wsConnected,
                      color: const Color(0xFF3B82F6),
                      tooltip: 'WebSocket',
                    ),
                    const SizedBox(width: 6),
                    _StatusDot(
                      active: wsConnected,
                      color: const Color(0xFFF59E0B),
                      tooltip: 'Server',
                    ),
                  ],
                ),
              ),

              // Main content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),

                      // Hero activity card
                      ActivityCard(activity: currentActivity),
                      const SizedBox(height: 20),

                      // Error display
                      if (initError != null) ...[
                        GlassCard(
                          padding: const EdgeInsets.all(14),
                          glowColors: const [AppTheme.error],
                          glowOpacity: 0.1,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppTheme.error,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  initError!,
                                  style: const TextStyle(
                                    color: AppTheme.error,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Sensor chart
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Live Sensors',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (sensorActive)
                                  _PulsingDot(color: gradient.first),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 180,
                              child: sensorActive
                                  ? const SensorChart()
                                  : Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.show_chart_rounded,
                                            size: 32,
                                            color: AppTheme.textTertiary
                                                .withOpacity(0.4),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Start sensing to view chart',
                                            style: TextStyle(
                                              color: AppTheme.textTertiary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Recent activity timeline
                      if (history.isNotEmpty) ...[
                        GlassCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Recent',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                height: 40,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: history.take(8).length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (context, index) {
                                    final item = history[index];
                                    final g = AppTheme.gradientForCategory(
                                        item.activity);
                                    final ago = _timeAgo(item.timestamp);
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        color: g.first.withOpacity(0.1),
                                        border: Border.all(
                                          color: g.first.withOpacity(0.2),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: g.first,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            item.activity,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: g.first,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            ago,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: AppTheme.textTertiary
                                                  .withOpacity(0.8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Bottom spacer for action bar
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom action bar
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _ActionBar(
            isRunning: isRunning,
            isInitializing: isInitializing,
            onStart: onStart,
            onStop: onStop,
          ),
        ),
      ],
    );
  }

  String _timeAgo(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    return '${diff.inHours}h';
  }
}

// ── Status Dot ────────────────────────────────────────────────────────

class _StatusDot extends StatelessWidget {
  final bool active;
  final Color color;
  final String tooltip;

  const _StatusDot({
    required this.active,
    required this.color,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? color : AppTheme.textTertiary.withOpacity(0.3),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

// ── Pulsing Dot ───────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  final Color color;

  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(0.5 + _controller.value * 0.5),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3 + _controller.value * 0.3),
                blurRadius: 4 + _controller.value * 4,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Action Bar ────────────────────────────────────────────────────────

class _ActionBar extends StatefulWidget {
  final bool isRunning;
  final bool isInitializing;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const _ActionBar({
    required this.isRunning,
    required this.isInitializing,
    required this.onStart,
    required this.onStop,
  });

  @override
  State<_ActionBar> createState() => _ActionBarState();
}

class _ActionBarState extends State<_ActionBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isRunning) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_ActionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRunning && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isRunning && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: 16 + bottomPadding,
          ),
          decoration: BoxDecoration(
            color: AppTheme.cardColor.withOpacity(0.85),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: const Border(
              top: BorderSide(color: AppTheme.borderColor),
            ),
          ),
          child: GestureDetector(
            onTap: widget.isInitializing
                ? null
                : (widget.isRunning ? widget.onStop : widget.onStart),
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final isRunning = widget.isRunning;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: isRunning
                        ? LinearGradient(
                            colors: [
                              AppTheme.error,
                              AppTheme.error.withOpacity(0.8),
                            ],
                          )
                        : const LinearGradient(
                            colors: AppTheme.accentGradient,
                          ),
                    border: isRunning
                        ? Border.all(
                            color: AppTheme.error.withOpacity(
                              0.3 + _pulseController.value * 0.4,
                            ),
                            width: 2,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: (isRunning ? AppTheme.error : AppTheme.accent)
                            .withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.isInitializing)
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      else
                        Icon(
                          isRunning
                              ? Icons.stop_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      const SizedBox(width: 10),
                      Text(
                        widget.isInitializing
                            ? 'Starting...'
                            : (isRunning ? 'Stop' : 'Start Sensing'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
