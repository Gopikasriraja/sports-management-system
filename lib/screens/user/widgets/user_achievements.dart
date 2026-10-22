import 'package:flutter/material.dart';

class UserAchievements extends StatelessWidget {
  const UserAchievements({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My achievements', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    'A verified, student-scoped achievement view is not yet '
                    'connected to this screen. Sample achievements have been '
                    'removed so no unverified records are presented as yours.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
