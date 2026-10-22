import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../providers/event_provider.dart';

class RecentEvents extends StatelessWidget {
  final VoidCallback? onOpenCalendar;

  const RecentEvents({super.key, this.onOpenCalendar});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<EventProvider>();
    final now = DateTime.now();
    final upcomingEvents =
        provider.events
            .where(
              (event) =>
                  event.startDate.isAfter(now) &&
                  event.status.toLowerCase() != 'completed',
            )
            .toList()
          ..sort(
            (first, second) => first.startDate.compareTo(second.startDate),
          );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final retryButton = provider.errorMessage == null
                    ? null
                    : IconButton(
                        tooltip: 'Retry loading events',
                        onPressed: provider.fetchEvents,
                        icon: const Icon(Icons.refresh_rounded),
                      );
                final calendarButton = onOpenCalendar == null
                    ? null
                    : TextButton.icon(
                        onPressed: onOpenCalendar,
                        icon: const Icon(
                          Icons.calendar_month_rounded,
                          size: 18,
                        ),
                        label: const Text('View calendar'),
                      );
                final narrowCalendarButton = calendarButton == null
                    ? null
                    : Align(
                        alignment: Alignment.centerRight,
                        child: calendarButton,
                      );
                final title = Text(
                  'Upcoming Events',
                  style: theme.textTheme.titleMedium,
                );

                if (constraints.maxWidth < 380) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(child: title),
                          ?retryButton,
                        ],
                      ),
                      ?narrowCalendarButton,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: title),
                    ?retryButton,
                    ?calendarButton,
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            if (provider.isLoading && provider.events.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (provider.errorMessage != null && provider.events.isEmpty)
              _StatusMessage(
                icon: Icons.cloud_off_outlined,
                message: 'Events could not be loaded.',
              )
            else if (upcomingEvents.isEmpty)
              _StatusMessage(
                icon: Icons.event_busy_outlined,
                message: 'There are no upcoming events in the calendar.',
              )
            else
              ...upcomingEvents
                  .take(4)
                  .map(
                    (event) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          Icons.sports_score_rounded,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(
                        event.title.isEmpty ? 'Untitled event' : event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        [
                          DateFormat('d MMM yyyy').format(event.startDate),
                          if (event.startTime.isNotEmpty) event.startTime,
                          if (event.venue.isNotEmpty) event.venue,
                        ].join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: onOpenCalendar,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const _StatusMessage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Icon(icon, color: colors.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
