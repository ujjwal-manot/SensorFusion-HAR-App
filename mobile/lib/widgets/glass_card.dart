import 'dart:ui';
import 'package:flutter/material.dart';
import '../config/theme.dart';

/// A premium glassmorphism card with backdrop blur, semi-transparent background,
/// subtle white border, and optional gradient glow.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final List<Color>? glowColors;
  final double glowOpacity;
  final double glowBlur;
  final double opacity;
  final bool enableBlur;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24,
    this.glowColors,
    this.glowOpacity = 0.15,
    this.glowBlur = 24,
    this.opacity = 0.6,
    this.enableBlur = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasGlow = glowColors != null && glowColors!.isNotEmpty;

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: enableBlur
            ? ImageFilter.blur(sigmaX: 24, sigmaY: 24)
            : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: AppTheme.cardColor.withOpacity(opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: hasGlow
                  ? glowColors!.first.withOpacity(0.15)
                  : AppTheme.borderColor,
              width: hasGlow ? 1.2 : 1,
            ),
            boxShadow: hasGlow
                ? [
                    BoxShadow(
                      color: glowColors!.first.withOpacity(glowOpacity),
                      blurRadius: glowBlur,
                      spreadRadius: -4,
                    ),
                  ]
                : null,
          ),
          padding: padding,
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      card = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }

    return card;
  }
}

/// A smaller glass card variant for inline stats, pills, etc.
class MiniGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const MiniGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: child,
    );
  }
}
