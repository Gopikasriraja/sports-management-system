import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_roles.dart';
import '../../../providers/auth_provider.dart';

class QuickActions extends StatelessWidget {
  final ValueChanged<String> onNavigate;

  const QuickActions({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final role = context.watch<AuthProvider>().currentUser?.role;

    final actions =
        [
              _ActionItem(
                label: 'Students',
                icon: Icons.groups_rounded,
                destination: 'Student Management',
                color: colorScheme.primary,
                tooltip: 'Open student records',
              ),
              _ActionItem(
                label: 'Attendance',
                icon: Icons.checklist_rtl_rounded,
                destination: 'Attendance Management',
                color: colorScheme.tertiary,
                tooltip: 'Open attendance management',
              ),
              _ActionItem(
                label: 'Equipment',
                icon: Icons.add_shopping_cart_rounded,
                destination: 'Sports Equipment',
                color: colorScheme.secondary,
                tooltip: 'Open equipment and inventory',
              ),
              _ActionItem(
                label: 'Events',
                icon: Icons.add_location_alt_rounded,
                destination: 'Sports Calendar',
                color: colorScheme.secondary,
                tooltip: 'Open event management',
              ),
              _ActionItem(
                label: 'Gallery',
                icon: Icons.photo_library_rounded,
                destination: 'Gallery',
                color: colorScheme.tertiary,
                tooltip: 'Open the sports gallery',
              ),
              _ActionItem(
                label: 'Reports',
                icon: Icons.analytics_rounded,
                destination: 'Reports',
                color: Colors.purple,
                tooltip: 'Open reports',
              ),
            ]
            .where(
              (action) =>
                  AppRoles.canOpenOperationsTab(role, action.destination),
            )
            .toList();

    final double width = MediaQuery.of(context).size.width;
    // Dynamic cross axis split for 6 items
    final int crossAxisCount = width < 600
        ? 2
        : (width < 1200 ? 3 : actions.length.clamp(1, 6).toInt());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick access', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Open a management area to continue.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: width < 600 ? 2.1 : (width < 960 ? 1.8 : 1.5),
          ),
          itemBuilder: (context, index) {
            final action = actions[index];
            return Card(
              clipBehavior: Clip.antiAlias,
              child: Tooltip(
                message: action.tooltip,
                child: InkWell(
                  onTap: () => onNavigate(action.destination),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: action.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(action.icon, color: action.color),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            action.label,
                            style: theme.textTheme.labelLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  final String destination;
  final Color color;
  final String tooltip;

  _ActionItem({
    required this.label,
    required this.icon,
    required this.destination,
    required this.color,
    required this.tooltip,
  });
}
