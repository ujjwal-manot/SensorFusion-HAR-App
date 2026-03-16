import 'dart:math';
import 'package:flutter/material.dart';
import '../config/theme.dart';

/// A subtle animated gradient mesh background that slowly drifts and morphs.
/// Uses [CustomPainter] wrapped in a [RepaintBoundary] for performance.
class AnimatedBackground extends StatefulWidget {
  final List<Color>? colors;
  final double intensity;

  const AnimatedBackground({
    super.key,
    this.colors,
    this.intensity = 0.08,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors ?? [AppTheme.accent, AppTheme.stationaryGlow];

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _MeshPainter(
              progress: _controller.value,
              colors: colors,
              intensity: widget.intensity,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _MeshPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;
  final double intensity;

  _MeshPainter({
    required this.progress,
    required this.colors,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final t = progress * 2 * pi;

    // Three orbiting gradient blobs
    final blobs = <_Blob>[
      _Blob(
        center: Offset(
          size.width * (0.3 + 0.15 * sin(t)),
          size.height * (0.25 + 0.1 * cos(t * 0.7)),
        ),
        radius: size.width * 0.45,
        color: colors.first.withOpacity(intensity),
      ),
      _Blob(
        center: Offset(
          size.width * (0.7 + 0.12 * cos(t * 0.9)),
          size.height * (0.6 + 0.15 * sin(t * 1.1)),
        ),
        radius: size.width * 0.5,
        color: (colors.length > 1 ? colors[1] : colors.first)
            .withOpacity(intensity * 0.7),
      ),
      _Blob(
        center: Offset(
          size.width * (0.5 + 0.2 * sin(t * 0.6)),
          size.height * (0.8 + 0.1 * cos(t * 0.8)),
        ),
        radius: size.width * 0.35,
        color: colors.first.withOpacity(intensity * 0.4),
      ),
    ];

    for (final blob in blobs) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [blob.color, blob.color.withOpacity(0)],
          stops: const [0.0, 1.0],
        ).createShader(
          Rect.fromCircle(center: blob.center, radius: blob.radius),
        );
      canvas.drawCircle(blob.center, blob.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MeshPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _Blob {
  final Offset center;
  final double radius;
  final Color color;

  const _Blob({
    required this.center,
    required this.radius,
    required this.color,
  });
}
