import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'pulse_ring.dart';

/// A large circular activity icon with gradient background, glow, and
/// optional animated [PulseRing] when sensing is active.
class ActivityIcon extends StatelessWidget {
  final String activity;
  final bool isActive;
  final double size;

  const ActivityIcon({
    super.key,
    required this.activity,
    this.isActive = false,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = AppTheme.gradientForCategory(activity);
    final icon = AppTheme.iconForActivity(activity);
    final primaryColor = gradient.first;

    final iconCircle = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(isActive ? 0.4 : 0.15),
              blurRadius: isActive ? 32 : 16,
              spreadRadius: isActive ? 2 : -2,
            ),
          ],
        ),
        child: Icon(
          icon,
          size: size * 0.48,
          color: Colors.white,
        ),
      ),
    );

    if (isActive) {
      return PulseRing(
        color: primaryColor,
        size: size * 1.5,
        active: true,
        child: iconCircle,
      );
    }

    return SizedBox(
      width: size * 1.5,
      height: size * 1.5,
      child: Center(child: iconCircle),
    );
  }
}

/// A smaller version of the activity icon for lists and cards.
class ActivityIconSmall extends StatelessWidget {
  final String activity;
  final double size;

  const ActivityIconSmall({
    super.key,
    required this.activity,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = AppTheme.gradientForCategory(activity);
    final icon = AppTheme.iconForActivity(activity);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color: Colors.white,
      ),
    );
  }
}
