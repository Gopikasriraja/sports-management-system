import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_roles.dart';
import '../../../models/training_session_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/training_session_provider.dart';
import '../../admin/widgets/components/training_session_dialog.dart';

class TrainingScheduleView extends StatelessWidget {
  final bool readOnly;

  const TrainingScheduleView({super.key, this.readOnly = true});

  Future<void> _editSession(
    BuildContext context, {
    TrainingSession? session,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => TrainingSessionDialog(session: session),
    );
  }

  Future<void> _deleteSession(
    BuildContext context,
    TrainingSession session,
    String role,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete training session?'),
        content: Text('“${session.sport}” will be removed from the schedule.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final provider = context.read<TrainingSessionProvider>();
    final deleted = await provider.deleteSession(
      session.sessionId,
      actorRole: role,
    );
    if (!context.mounted) return;
    if (!deleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Could not delete the training session.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<TrainingSessionProvider>();
    final role = context.watch<AuthProvider>().currentUser?.role;
    final canManage = !readOnly && AppRoles.canManageTrainingSessions(role);
    final sessions = provider.sessions;
    final upcomingCount = sessions
        .where(
          (session) =>
              session.status == 'Scheduled' &&
              !session.startsAt.isBefore(DateTime.now()),
        )
        .length;
    final sessionCards = sessions
        .map(
          (session) => _TrainingSessionCard(
            session: session,
            canManage: canManage,
            onEdit: () => _editSession(context, session: session),
            onDelete: role == null
                ? null
                : () => _deleteSession(context, session, role),
          ),
        )
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                readOnly ? 'Training schedule' : 'Manage training schedule',
                style: theme.textTheme.titleLarge,
              ),
            ),
            if (canManage)
              FilledButton.icon(
                onPressed: () => _editSession(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Schedule training'),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'View upcoming and past training sessions.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _ScheduleCount(label: 'Sessions', count: sessions.length),
            _ScheduleCount(label: 'Upcoming', count: upcomingCount),
          ],
        ),
        const SizedBox(height: 16),
        if (provider.isLoading && sessions.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: CircularProgressIndicator(),
            ),
          )
        else if (provider.errorMessage != null && sessions.isEmpty)
          _ScheduleMessage(
            icon: Icons.cloud_off_outlined,
            message: 'The training schedule could not be loaded.',
            action: TextButton.icon(
              onPressed: provider.refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          )
        else if (sessions.isEmpty)
          const _ScheduleMessage(
            icon: Icons.event_busy_outlined,
            message: 'No training sessions have been scheduled.',
          )
        else if (provider.errorMessage != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ScheduleMessage(
                icon: Icons.cloud_off_outlined,
                message: 'The schedule may be out of date.',
                action: TextButton.icon(
                  onPressed: provider.refresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ),
              ...sessionCards,
            ],
          )
        else
          ...sessionCards,
      ],
    );
  }
}

class _ScheduleCount extends StatelessWidget {
  final String label;
  final int count;

  const _ScheduleCount({required this.label, required this.count});

  @override
  Widget build(BuildContext context) => Chip(
    avatar: const Icon(Icons.fitness_center_rounded, size: 18),
    label: Text('$label: $count'),
  );
}

class _TrainingSessionCard extends StatelessWidget {
  final TrainingSession session;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _TrainingSessionCard({
    required this.session,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateFormat('EEE, d MMM yyyy').format(session.startsAt);
    final start = DateFormat.jm().format(session.startsAt);
    final end = DateFormat.jm().format(session.endsAt);
    final details = [
      if (session.team.isNotEmpty) session.team,
      'Coach: ${session.coach}',
      session.venue,
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.fitness_center_rounded,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(session.sport),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$date · $start–$end'),
              Text('Status: ${session.status}'),
              if (details.isNotEmpty) Text(details),
              if (session.notes.isNotEmpty) Text(session.notes),
            ],
          ),
        ),
        trailing: canManage
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete?.call();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              )
            : Text(
                session.status,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: session.status == 'Cancelled'
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
              ),
      ),
    );
  }
}

class _ScheduleMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;

  const _ScheduleMessage({
    required this.icon,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
          if (action != null) action!,
        ],
      ),
    ),
  );
}
