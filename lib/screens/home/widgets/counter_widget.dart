import 'package:flutter/material.dart';

class CounterWidget extends StatelessWidget {
  final int targetValue;
  final Duration duration;
  final TextStyle style;
  final String suffix;

  const CounterWidget({
    super.key,
    required this.targetValue,
    this.duration = const Duration(milliseconds: 2000),
    required this.style,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: targetValue.toDouble()),
      duration: duration,
      curve: Curves.easeOutExpo,
      builder: (context, value, child) {
        return Text(
          '${value.toInt()}$suffix',
          style: style,
        );
      },
    );
  }
}
