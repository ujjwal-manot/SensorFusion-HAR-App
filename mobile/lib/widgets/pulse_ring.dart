import 'package:flutter/material.dart';

/// Concentric pulsing rings that radiate outward and fade.
/// Three rings with staggered timing for a smooth, infinite animation.
class PulseRing extends StatefulWidget {
  final Color color;
  final double size;
  final Widget child;
  final bool active;

  const PulseRing({
    super.key,
    required this.color,
    this.size = 140,
    required this.child,
    this.active = true,
  });

  @override
  State<PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<PulseRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.active) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(PulseRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(child: widget.child),
      );
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _PulseRingPainter(
              progress: _controller.value,
              color: widget.color,
            ),
            child: Center(child: widget.child),
          );
        },
      ),
    );
  }
}

class _PulseRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  static const int _ringCount = 3;

  _PulseRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    final baseRadius = maxRadius * 0.42; // inner ring start radius

    for (int i = 0; i < _ringCount; i++) {
      // Stagger each ring by 1/3 of the cycle
      final ringProgress = (progress + i / _ringCount) % 1.0;

      // Each ring expands from baseRadius to maxRadius and fades out
      final radius = baseRadius + (maxRadius - baseRadius) * ringProgress;
      final opacity = (1.0 - ringProgress) * 0.35;

      if (opacity <= 0) continue;

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * (1.0 - ringProgress * 0.5);

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PulseRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
