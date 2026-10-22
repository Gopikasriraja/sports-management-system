import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double borderOpacity;
  final double backgroundOpacity;
  final Color? color;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.blur = 12.0,
    this.borderOpacity = 0.15,
    this.backgroundOpacity = 0.1,
    this.color,
    this.borderColor,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    final Color defaultColor = color ?? (isDark ? Colors.black : Colors.white);
    final Color defaultBorderColor = borderColor ?? (isDark ? Colors.white : Colors.black);

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: defaultColor.withValues(alpha: backgroundOpacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: defaultBorderColor.withValues(alpha: borderOpacity),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.05),
                  blurRadius: 24,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
