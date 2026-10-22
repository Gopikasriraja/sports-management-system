import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../providers/event_provider.dart';

class SportsCalendar extends StatefulWidget {
  const SportsCalendar({super.key});

  @override
  State<SportsCalendar> createState() => _SportsCalendarState();
}

class _SportsCalendarState extends State<SportsCalendar> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<EventProvider>();
    final categories =
        provider.events
            .map((event) => event.category.trim())
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final visibleCategories = ['All', ...categories];
    final events =
        provider.events
            .where(
              (event) =>
                  _selectedCategory == 'All' ||
                  event.category.trim() == _selectedCategory,
            )
            .toList()
          ..sort(
            (first, second) => first.startDate.compareTo(second.startDate),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sports Calendar', style: theme.textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Events listed here are loaded from the sports event records.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        if (categories.isNotEmpty)
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: visibleCategories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = visibleCategories[index];
                return ChoiceChip(
                  label: Text(category),
                  selected: _selectedCategory == category,
                  onSelected: (_) {
                    setState(() => _selectedCategory = category);
                  },
                );
              },
            ),
          ),
        if (categories.isNotEmpty) const SizedBox(height: 16),
        if (provider.isLoading && provider.events.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: CircularProgressIndicator(),
            ),
          )
        else if (provider.errorMessage != null && provider.events.isEmpty)
          _CalendarStatus(
            icon: Icons.cloud_off_outlined,
            message: 'The event calendar could not be loaded.',
            action: TextButton.icon(
              onPressed: provider.fetchEvents,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          )
        else if (events.isEmpty)
          const _CalendarStatus(
            icon: Icons.event_busy_outlined,
            message: 'No events are available in this category.',
          )
        else
          ...events.map(
            (event) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.sports_score_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(
                  event.title.isEmpty ? 'Untitled event' : event.title,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    [
                      DateFormat('d MMM yyyy').format(event.startDate),
                      if (event.startTime.isNotEmpty) event.startTime,
                      if (event.venue.isNotEmpty) event.venue,
                      if (event.category.isNotEmpty) event.category,
                    ].join(' · '),
                  ),
                ),
                trailing: event.status.isEmpty
                    ? null
                    : Text(
                        event.status,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CalendarStatus extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;

  const _CalendarStatus({
    required this.icon,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Icon(icon, color: colors.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
            ?action,
          ],
        ),
      ),
    );
  }
}
