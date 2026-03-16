import 'dart:math';
import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Premium circular confidence gauge with gradient stroke, glow effect,
/// animated sweep, and large percentage display.
class ConfidenceGauge extends StatelessWidget {
  final double confidence;
  final double size;
  final List<Color>? gradientColors;

  const ConfidenceGauge({
    super.key,
    required this.confidence,
    this.size = 80,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ?? AppTheme.accentGradient;
    final percentage = (confidence * 100).toStringAsFixed(0);

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: confidence),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutBack,
        builder: (context, value, _) {
          return CustomPaint(
            painter: _GaugeGlowPainter(
              progress: value,
              gradientColors: colors,
              bgColor: AppTheme.cardColor.withOpacity(0.4),
              strokeWidth: 8,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: size * 0.28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: size * 0.02),
                  Text(
                    'CONFIDENCE',
                    style: TextStyle(
                      fontSize: size * 0.08,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textTertiary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GaugeGlowPainter extends CustomPainter {
  final double progress;
  final List<Color> gradientColors;
  final Color bgColor;
  final double strokeWidth;

  _GaugeGlowPainter({
    required this.progress,
    required this.gradientColors,
    required this.bgColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - strokeWidth;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background track
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -pi / 2, 2 * pi, false, bgPaint);

    if (progress <= 0) return;

    final sweepAngle = 2 * pi * progress;

    // Glow layer (wider, more transparent)
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: -pi / 2 + sweepAngle,
        colors: gradientColors,
        transform: const GradientRotation(-pi / 2),
      ).createShader(rect);

    canvas.drawArc(rect, -pi / 2, sweepAngle, false, glowPaint);

    // Main gradient arc
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: -pi / 2 + sweepAngle,
        colors: gradientColors,
        transform: const GradientRotation(-pi / 2),
      ).createShader(rect);

    canvas.drawArc(rect, -pi / 2, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugeGlowPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
