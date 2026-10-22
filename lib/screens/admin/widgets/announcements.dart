import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../providers/notification_provider.dart';

class AnnouncementsWidget extends StatelessWidget {
  const AnnouncementsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<NotificationProvider>();
    final announcements = [...provider.notifications]
      ..sort((first, second) => second.createdAt.compareTo(first.createdAt));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.campaign_rounded,
                  color: theme.colorScheme.primary,
                  size: 21,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Announcements',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (provider.errorMessage != null)
                  IconButton(
                    tooltip: 'Retry loading announcements',
                    onPressed: provider.fetchNotifications,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (provider.isLoading && announcements.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (provider.errorMessage != null && announcements.isEmpty)
              const _AnnouncementStatus(
                icon: Icons.cloud_off_outlined,
                message: 'Announcements could not be loaded.',
              )
            else if (announcements.isEmpty)
              const _AnnouncementStatus(
                icon: Icons.mark_email_read_outlined,
                message: 'There are no announcements yet.',
              )
            else
              ...announcements.take(3).map(
                (announcement) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              announcement.title,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('d MMM').format(announcement.createdAt),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      if (announcement.message.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          announcement.message,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (announcement != announcements.take(3).last)
                        const Divider(height: 18),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementStatus extends StatelessWidget {
  final IconData icon;
  final String message;

  const _AnnouncementStatus({required this.icon, required this.message});

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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
