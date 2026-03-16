import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/activity_result.dart';
import 'activity_icon.dart';
import 'confidence_gauge.dart';
import 'glass_card.dart';

/// Hero activity card displaying the current recognized activity with
/// icon, name, category badge, and a row of stat pills.
class ActivityCard extends StatelessWidget {
  final ActivityResult? activity;

  const ActivityCard({super.key, this.activity});

  @override
  Widget build(BuildContext context) {
    if (activity == null) {
      return _buildEmptyState(context);
    }

    final activityName = activity!.activity;
    final category = activity!.macroCategory;
    final gradient = AppTheme.gradientForCategory(activityName);

    return GlassCard(
      glowColors: gradient,
      glowOpacity: 0.12,
      glowBlur: 32,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        children: [
          // Activity icon with pulse ring
          ActivityIcon(
            activity: activityName,
            isActive: true,
            size: 80,
          ),
          const SizedBox(height: 20),

          // Activity name
          Text(
            activityName,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Category badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(colors: gradient),
            ),
            child: Text(
              category.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Stats row
          Row(
            children: [
              // Confidence gauge
              Expanded(
                child: MiniGlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: ConfidenceGauge(
                    confidence: activity!.confidence,
                    size: 72,
                    gradientColors: gradient,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Latency pill
              Expanded(
                child: MiniGlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        color: gradient.first,
                        size: 22,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${activity!.latencyMs.toStringAsFixed(1)}ms',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'LATENCY',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textTertiary,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Duration pill (estimated from timestamp)
              Expanded(
                child: MiniGlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: gradient.first,
                        size: 22,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatDuration(activity!.timestamp),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'DURATION',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textTertiary,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom gradient accent line
          const SizedBox(height: 20),
          Container(
            height: 2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              gradient: LinearGradient(
                colors: [
                  gradient.first.withOpacity(0),
                  gradient.first.withOpacity(0.5),
                  gradient.last.withOpacity(0.5),
                  gradient.last.withOpacity(0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.9, end: 1.1),
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            // Restart the animation by using a repeating approach
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surface,
                border: Border.all(
                  color: AppTheme.borderColor,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.sensors_off_rounded,
                size: 36,
                color: AppTheme.textTertiary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Activity Detected',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap Start to begin recognition',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(DateTime since) {
    final diff = DateTime.now().difference(since);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      final s = diff.inSeconds % 60;
      return '${m}m ${s.toString().padLeft(2, '0')}s';
    }
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    return '${h}h ${m}m';
  }
}
