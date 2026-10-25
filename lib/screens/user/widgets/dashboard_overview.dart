import 'package:flutter/material.dart';

class DashboardOverview extends StatelessWidget {
  final ValueChanged<String> onNavigate;

  const DashboardOverview({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final columns = width < 600 ? 1 : (width < 1000 ? 2 : 3);

    const destinations = [
      _DashboardDestination(
        title: 'My Profile',
        description: 'View your student and sports profile.',
        icon: Icons.person_outline_rounded,
        tab: 'My Profile',
      ),
      _DashboardDestination(
        title: 'Attendance',
        description: 'Open your sports attendance history.',
        icon: Icons.fact_check_outlined,
        tab: 'Attendance',
      ),
      _DashboardDestination(
        title: 'Sports Calendar',
        description: 'Browse the sports event calendar.',
        icon: Icons.event_available_outlined,
        tab: 'Sports Calendar',
      ),
      _DashboardDestination(
        title: 'Training Schedule',
        description: 'View upcoming team training sessions.',
        icon: Icons.fitness_center_outlined,
        tab: 'Training Schedule',
      ),
      _DashboardDestination(
        title: 'Sports Teams',
        description: 'Browse teams and view your memberships.',
        icon: Icons.groups_outlined,
        tab: 'Sports Teams',
      ),
      _DashboardDestination(
        title: 'Achievements',
        description: 'View your recorded sports achievements.',
        icon: Icons.emoji_events_outlined,
        tab: 'Achievements',
      ),
      _DashboardDestination(
        title: 'Equipment Availability',
        description: 'Check the equipment information available in the app.',
        icon: Icons.inventory_2_outlined,
        tab: 'Equipment Availability',
      ),
      _DashboardDestination(
        title: 'News & Announcements',
        description: 'Open department announcements.',
        icon: Icons.campaign_outlined,
        tab: 'News & Announcements',
      ),
      _DashboardDestination(
        title: 'Contact Sports Department',
        description: 'Find sports department contact information.',
        icon: Icons.contact_support_outlined,
        tab: 'Contact Sports Department',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick access', style: theme.textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Open a section to view the information available to your account.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: destinations.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: width < 600 ? 3.0 : 1.75,
          ),
          itemBuilder: (context, index) {
            final destination = destinations[index];
            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onNavigate(destination.tab),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            destination.icon,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              destination.title,
                              style: theme.textTheme.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              destination.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
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

class _DashboardDestination {
  final String title;
  final String description;
  final IconData icon;
  final String tab;

  const _DashboardDestination({
    required this.title,
    required this.description,
    required this.icon,
    required this.tab,
  });
}
