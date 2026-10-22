import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';

class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return IconButton(
      tooltip: brightness == Brightness.dark
          ? 'Switch to light theme'
          : 'Switch to dark theme',
      icon: Icon(
        brightness == Brightness.dark
            ? Icons.light_mode_outlined
            : Icons.dark_mode_outlined,
      ),
      onPressed: () async {
        try {
          await context.read<ThemeProvider>().setThemeMode(
            brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
          );
        } catch (error) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Theme preference could not be saved: $error')),
            );
          }
        }
      },
    );
  }
}
