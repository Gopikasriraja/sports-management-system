import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/achievement_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/equipment_provider.dart';
import '../../../providers/event_provider.dart';
import '../../../providers/student_provider.dart';
import '../../home/widgets/hover_card.dart';

class DashboardCards extends StatelessWidget {
  final ValueChanged<String>? onNavigate;

  const DashboardCards({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final students = context.watch<StudentProvider>();
    final attendance = context.watch<AttendanceProvider>();
    final equipment = context.watch<EquipmentProvider>();
    final events = context.watch<EventProvider>();
    final achievements = context.watch<AchievementProvider>();

    final double width = MediaQuery.of(context).size.width;
    final int crossAxisCount = width < 600 ? 1 : (width < 960 ? 2 : (width < 1400 ? 3 : 4));

    final now = DateTime.now();
    final upcomingEvents = events.events
        .where(
          (event) =>
              event.startDate.isAfter(now) &&
              event.status.toLowerCase() != 'completed',
        )
        .length;

    final cardsData = [
      _CardItem(
        title: 'Student records',
        value: _displayValue(
          students.isLoading,
          students.errorMessage,
          students.students.length,
        ),
        icon: Icons.groups_rounded,
        color: colorScheme.secondary,
        description: _displayDescription(
          students.isLoading,
          students.errorMessage,
          'Records in the student directory',
        ),
        destination: 'Student Management',
      ),
      _CardItem(
        title: 'Attendance',
        value: attendance.errorMessage != null
            ? 'Unavailable'
            : attendance.isLoading
            ? 'Loading'
            : 'Open',
        icon: Icons.fact_check_rounded,
        color: Colors.green,
        description: attendance.errorMessage != null
            ? 'Attendance session data could not be loaded'
            : 'Open session management for live attendance summaries',
        destination: 'Attendance Management',
      ),
      _CardItem(
        title: 'Upcoming Events',
        value: _displayValue(
          events.isLoading,
          events.errorMessage,
          upcomingEvents,
        ),
        icon: Icons.upcoming_rounded,
        color: colorScheme.tertiary,
        description: _displayDescription(
          events.isLoading,
          events.errorMessage,
          'Future events from the event calendar',
        ),
        destination: 'Sports Calendar',
      ),
      _CardItem(
        title: 'Equipment units',
        value: _displayValue(
          equipment.isLoading,
          equipment.errorMessage,
          equipment.totalEquipmentUnits,
        ),
        icon: Icons.inventory_2_rounded,
        color: Colors.teal,
        description: _displayDescription(
          equipment.isLoading,
          equipment.errorMessage,
          'Total stock recorded in inventory',
        ),
        destination: 'Sports Equipment',
      ),
      _CardItem(
        title: 'Available Equipment',
        value: _displayValue(
          equipment.isLoading,
          equipment.errorMessage,
          equipment.availableEquipmentUnits,
        ),
        icon: Icons.check_circle_outline_rounded,
        color: Colors.green,
        description: _displayDescription(
          equipment.isLoading,
          equipment.errorMessage,
          'Units currently available to issue',
        ),
        destination: 'Sports Equipment',
      ),
      _CardItem(
        title: 'Achievements',
        value: _displayValue(
          achievements.isLoading,
          achievements.errorMessage,
          achievements.achievements.length,
        ),
        icon: Icons.military_tech_rounded,
        color: Colors.amber,
        description: _displayDescription(
          achievements.isLoading,
          achievements.errorMessage,
          'Achievement records',
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cardsData.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: width < 600 ? 2.5 : 2.0,
      ),
      itemBuilder: (context, index) {
        final card = cardsData[index];
        return HoverCard(
          scaleFactor: 1.03,
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Tooltip(
              message: card.destination == null
                  ? card.title
                  : 'Open ${card.destination}',
              child: InkWell(
                onTap: card.destination == null || onNavigate == null
                    ? null
                    : () => onNavigate!(card.destination!),
                child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            card.title,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            card.value,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            card.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: card.color.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(card.icon, color: card.color, size: 25),
                      ),
                    ),
                  ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _displayValue(bool isLoading, String? error, int value) {
    if (error != null) return 'Unavailable';
    if (isLoading && value == 0) return 'Loading';
    return value.toString();
  }

  String _displayDescription(bool isLoading, String? error, String value) {
    if (error != null) return 'Could not load this information';
    if (isLoading) return 'Updating from records';
    return value;
  }
}

class _CardItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String description;
  final String? destination;

  _CardItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.description,
    this.destination,
  });
}
