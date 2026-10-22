import 'package:flutter/material.dart';

class HoverCard extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double scaleFactor;
  final bool enableGlow;
  final Color? glowColor;

  const HoverCard({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
    this.scaleFactor = 1.03,
    this.enableGlow = true,
    this.glowColor,
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glow = widget.glowColor ?? theme.colorScheme.secondary.withValues(alpha: 0.3);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: widget.duration,
        curve: Curves.easeInOut,
        transform: Matrix4.diagonal3Values(
          _isHovered ? widget.scaleFactor : 1.0,
          _isHovered ? widget.scaleFactor : 1.0,
          1.0,
        ),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isHovered && widget.enableGlow
              ? [
                  BoxShadow(
                    color: glow,
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: widget.child,
      ),
    );
  }
}
