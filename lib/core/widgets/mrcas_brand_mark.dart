import 'package:flutter/material.dart';

class MrcasBrandMark extends StatelessWidget {
  final double size;

  const MrcasBrandMark({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox.square(
      dimension: size,
      child: Image.asset(
        'assets/images/mrcas_logo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.shield_outlined,
          size: size * 0.72,
          color: color,
          semanticLabel: 'MRCAS logo unavailable',
        ),
      ),
    );
  }
}
