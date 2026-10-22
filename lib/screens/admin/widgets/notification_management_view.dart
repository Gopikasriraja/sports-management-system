import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/notification_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notification_provider.dart';

class NotificationManagementView extends StatefulWidget {
  const NotificationManagementView({super.key});

  @override
  State<NotificationManagementView> createState() =>
      _NotificationManagementViewState();
}

class _NotificationManagementViewState
    extends State<NotificationManagementView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createAnnouncement() async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    final announcement = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New announcement'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  autofocus: true,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a title';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: messageController,
                  maxLines: 4,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a message';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'This announcement will be saved for the sports community.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, (
                  titleController.text.trim(),
                  messageController.text.trim(),
                ));
              }
            },
            child: const Text('Publish'),
          ),
        ],
      ),
    );

    titleController.dispose();
    messageController.dispose();
    if (!mounted || announcement == null) return;

    final user = context.read<AuthProvider>().currentUser;
    final notification = NotificationModel(
      notificationId: DateTime.now().microsecondsSinceEpoch.toString(),
      title: announcement.$1,
      message: announcement.$2,
      createdAt: DateTime.now(),
      createdBy: user?.name.trim().isNotEmpty == true
          ? user!.name.trim()
          : user?.email ?? 'Unknown',
    );

    final provider = context.read<NotificationProvider>();
    final saved = await provider.saveNotification(notification);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Announcement published.'
              : 'Could not publish announcement: '
                    '${provider.errorMessage ?? 'Unknown error'}',
        ),
        backgroundColor: saved ? Colors.green : Colors.redAccent,
      ),
    );
  }

  Future<void> _deleteAnnouncement(NotificationModel notification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete announcement?'),
        content: Text('“${notification.title}” will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final provider = context.read<NotificationProvider>();
    final deleted = await provider.deleteNotification(
      notification.notificationId,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted
              ? 'Announcement deleted.'
              : 'Could not delete announcement: '
                    '${provider.errorMessage ?? 'Unknown error'}',
        ),
        backgroundColor: deleted ? Colors.green : Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? AppColors.primaryDark
        : AppColors.primaryLight;

    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final query = _searchController.text.trim().toLowerCase();
        final notifications = provider.notifications.where((notification) {
          return query.isEmpty ||
              notification.title.toLowerCase().contains(query) ||
              notification.message.toLowerCase().contains(query) ||
              notification.createdBy.toLowerCase().contains(query);
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifications & Announcements',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Publish updates and manage announcement history.',
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: provider.isLoading ? null : _createAnnouncement,
                  icon: const Icon(Icons.campaign_outlined),
                  label: const Text('New announcement'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: 'Search announcements',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Refresh announcements',
                  onPressed: provider.isLoading
                      ? null
                      : provider.fetchNotifications,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (provider.errorMessage != null)
              MaterialBanner(
                content: Text(
                  'Could not load announcements: ${provider.errorMessage}',
                ),
                leading: const Icon(Icons.error_outline_rounded),
                actions: [
                  TextButton(
                    onPressed: provider.fetchNotifications,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            if (provider.isLoading && provider.notifications.isEmpty)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (notifications.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No announcements found. Publish one to get started.',
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: notifications.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: primaryColor.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.campaign_rounded,
                            color: primaryColor,
                          ),
                        ),
                        title: Text(
                          notification.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.message,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${notification.createdBy} · '
                                '${DateFormat.yMMMd().add_jm().format(notification.createdAt)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        trailing: IconButton(
                          tooltip: 'Delete announcement',
                          onPressed: provider.isLoading
                              ? null
                              : () => _deleteAnnouncement(notification),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
