import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_roles.dart';
import '../../core/validation/team_validator.dart';
import '../../models/student_model.dart';
import '../../models/team_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/team_provider.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  List<TeamModel> _myTeams = [];
  bool _loadingMyTeams = false;
  String? _myTeamsError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user == null) return;
      if (user.role == AppRoles.student) {
        _loadMyTeams(user.uid);
      } else if (AppRoles.canManageTeams(user.role)) {
        context.read<StudentProvider>().fetchStudents();
      }
    });
  }

  Future<void> _loadMyTeams(String studentId) async {
    setState(() {
      _loadingMyTeams = true;
      _myTeamsError = null;
    });
    try {
      final actor = context.read<AuthProvider>().currentUser;
      if (actor == null || actor.uid != studentId) {
        throw StateError('The signed-in student account is unavailable.');
      }
      final teams = await context.read<TeamProvider>().getTeamsForStudent(
        studentId: studentId,
        actorUid: actor.uid,
        actorRole: actor.role,
      );
      if (mounted) setState(() => _myTeams = teams);
    } catch (error) {
      if (mounted) setState(() => _myTeamsError = error.toString());
    } finally {
      if (mounted) setState(() => _loadingMyTeams = false);
    }
  }

  Future<void> _openTeamForm(TeamModel? team) async {
    final actor = context.read<AuthProvider>().currentUser;
    if (actor == null || !AppRoles.canManageTeams(actor.role)) return;

    final students = context.read<StudentProvider>();
    final provider = context.read<TeamProvider>();
    if (students.students.isEmpty && !students.isLoading) {
      await students.fetchStudents();
    }
    var selectedStudentIds = <String>{};
    if (team != null) {
      try {
        await provider.loadMembers(
          teamId: team.teamId,
          actorUid: actor.uid,
          actorRole: actor.role,
        );
        selectedStudentIds = provider
            .membersFor(team.teamId)
            .map((student) => student.studentId)
            .toSet();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                provider.errorMessage ?? 'Could not load the team roster.',
              ),
            ),
          );
        }
        return;
      }
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: team?.name ?? '');
    final sportController = TextEditingController(text: team?.sport ?? '');
    final coachController = TextEditingController(text: team?.coachName ?? '');
    final captainController = TextEditingController(
      text: team?.captainName ?? '',
    );
    var formError = '';

    if (!mounted) return;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: Text(team == null ? 'Create team' : 'Edit team'),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Team name *',
                        ),
                        validator: TeamValidator.validateName,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: sportController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Sport *',
                          hintText: 'e.g. Football',
                        ),
                        validator: TeamValidator.validateSport,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: coachController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Coach (optional)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: captainController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Captain (optional)',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Roster',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (students.isLoading && students.students.isEmpty)
                        const Center(child: CircularProgressIndicator())
                      else if (students.errorMessage != null &&
                          students.students.isEmpty)
                        Text(
                          'Student records could not be loaded: '
                          '${students.errorMessage}',
                        )
                      else if (students.students
                          .where(_isActiveStudent)
                          .isEmpty)
                        const Text('No active student records are available.')
                      else
                        ...students.students
                            .where(_isActiveStudent)
                            .map(
                              (student) => CheckboxListTile(
                                value: selectedStudentIds.contains(
                                  student.studentId,
                                ),
                                contentPadding: EdgeInsets.zero,
                                title: Text(student.name),
                                subtitle: Text(
                                  '${student.registerNumber} • ${student.sports.join(', ')}',
                                ),
                                onChanged: (selected) {
                                  setDialogState(() {
                                    if (selected == true) {
                                      selectedStudentIds.add(student.studentId);
                                    } else {
                                      selectedStudentIds.remove(
                                        student.studentId,
                                      );
                                    }
                                  });
                                },
                              ),
                            ),
                      if (formError.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          formError,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: provider.isLoading
                    ? null
                    : () async {
                        if (!(formKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        final now = DateTime.now();
                        final saveId = await provider.saveTeam(
                          TeamModel(
                            teamId: team?.teamId ?? '',
                            name: nameController.text,
                            sport: sportController.text,
                            coachName: coachController.text,
                            captainName: captainController.text,
                            status: team?.status ?? 'active',
                            createdAt: team?.createdAt ?? now,
                            updatedAt: now,
                          ),
                          actorUid: actor.uid,
                          actorRole: actor.role,
                        );
                        if (saveId == null) {
                          setDialogState(
                            () => formError =
                                provider.errorMessage ?? 'Could not save team.',
                          );
                          return;
                        }

                        final existingIds = team == null
                            ? <String>{}
                            : provider
                                  .membersFor(team.teamId)
                                  .map((student) => student.studentId)
                                  .toSet();
                        final addedIds = selectedStudentIds.difference(
                          existingIds,
                        );
                        final removedIds = existingIds.difference(
                          selectedStudentIds,
                        );
                        for (final studentId in addedIds) {
                          final saved = await provider.setMembership(
                            teamId: saveId,
                            studentId: studentId,
                            isMember: true,
                            actorUid: actor.uid,
                            actorRole: actor.role,
                          );
                          if (!saved) break;
                        }
                        if (provider.errorMessage == null) {
                          for (final studentId in removedIds) {
                            final saved = await provider.setMembership(
                              teamId: saveId,
                              studentId: studentId,
                              isMember: false,
                              actorUid: actor.uid,
                              actorRole: actor.role,
                            );
                            if (!saved) break;
                          }
                        }
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                provider.errorMessage == null
                                    ? 'Team saved.'
                                    : 'Team saved, but roster changes were '
                                          'incomplete: ${provider.errorMessage}',
                              ),
                            ),
                          );
                        }
                      },
                child: const Text('Save team'),
              ),
            ],
          ),
        ),
      );
    } finally {
      nameController.dispose();
      sportController.dispose();
      coachController.dispose();
      captainController.dispose();
    }
  }

  Future<void> _confirmDeactivate(TeamModel team) async {
    final actor = context.read<AuthProvider>().currentUser;
    if (actor == null || !AppRoles.canManageTeams(actor.role)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Deactivate team?'),
        content: Text(
          'Deactivate ${team.name}? Membership records will be retained.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final provider = context.read<TeamProvider>();
    final success = await provider.deactivateTeam(
      team.teamId,
      actorUid: actor.uid,
      actorRole: actor.role,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Team deactivated.' : provider.errorMessage ?? 'Failed.',
          ),
        ),
      );
    }
  }

  bool _isActiveStudent(StudentModel student) =>
      student.status.toLowerCase() == 'active';

  @override
  Widget build(BuildContext context) {
    final actor = context.watch<AuthProvider>().currentUser;
    final teamProvider = context.watch<TeamProvider>();
    if (actor == null || !AppRoles.canViewTeams(actor.role)) {
      return const Center(child: Text('You are not authorized to view teams.'));
    }

    final isManager = AppRoles.canManageTeams(actor.role);
    final teams = actor.role == AppRoles.student
        ? teamProvider.teams.where(
            (team) => team.status.toLowerCase() == 'active',
          )
        : teamProvider.teams;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 12,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sports Teams',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  isManager
                      ? 'Manage teams, coaches, captains, and active student rosters.'
                      : 'Browse active teams and see your own memberships.',
                ),
              ],
            ),
            if (isManager)
              FilledButton.icon(
                onPressed: () => _openTeamForm(null),
                icon: const Icon(Icons.add),
                label: const Text('Create team'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (teamProvider.isLoading && teamProvider.teams.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(36),
              child: CircularProgressIndicator(),
            ),
          )
        else if (teamProvider.errorMessage != null &&
            teamProvider.teams.isEmpty)
          Center(
            child: Column(
              children: [
                Text(
                  'Teams could not be loaded: ${teamProvider.errorMessage}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: teamProvider.refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          )
        else if (teams.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.groups_outlined, size: 44),
                    const SizedBox(height: 8),
                    Text(
                      actor.role == AppRoles.student
                          ? 'No active teams are listed yet.'
                          : 'No teams have been created yet.',
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...teams.map((team) {
            final isMyTeam = _myTeams.any(
              (myTeam) => myTeam.teamId == team.teamId,
            );
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                onExpansionChanged: (expanded) async {
                  if (expanded && isManager) {
                    try {
                      await teamProvider.loadMembers(
                        teamId: team.teamId,
                        actorUid: actor.uid,
                        actorRole: actor.role,
                      );
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Roster unavailable: $error')),
                        );
                      }
                    }
                  }
                },
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.sports,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(team.name),
                subtitle: Text(
                  '${team.sport}'
                  '${team.coachName.isEmpty ? '' : ' • Coach ${team.coachName}'}'
                  '${team.captainName.isEmpty ? '' : ' • Captain ${team.captainName}'}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isMyTeam)
                      const Chip(
                        label: Text('Your team'),
                        visualDensity: VisualDensity.compact,
                      ),
                    if (isManager)
                      PopupMenuButton<String>(
                        onSelected: (action) {
                          if (action == 'edit') _openTeamForm(team);
                          if (action == 'deactivate') {
                            _confirmDeactivate(team);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(
                            value: 'deactivate',
                            child: Text('Deactivate'),
                          ),
                        ],
                      ),
                  ],
                ),
                children: [
                  if (isManager)
                    if (teamProvider.isLoading)
                      const Padding(
                        padding: EdgeInsets.all(18),
                        child: CircularProgressIndicator(),
                      )
                    else if (teamProvider.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(teamProvider.errorMessage!),
                      )
                    else if (teamProvider.membersFor(team.teamId).isEmpty)
                      const ListTile(title: Text('No members on this roster.'))
                    else
                      ...teamProvider
                          .membersFor(team.teamId)
                          .map(
                            (student) => ListTile(
                              leading: const Icon(Icons.person_outline),
                              title: Text(student.name),
                              subtitle: Text(student.registerNumber),
                            ),
                          )
                  else
                    ListTile(
                      leading: const Icon(Icons.lock_outline),
                      title: Text(
                        isMyTeam
                            ? 'You are a member of this team.'
                            : 'Roster details are only available to authorized staff.',
                      ),
                    ),
                ],
              ),
            );
          }),
        if (actor.role == AppRoles.student) ...[
          const SizedBox(height: 12),
          if (_loadingMyTeams)
            const LinearProgressIndicator()
          else if (_myTeamsError != null)
            Text('Your memberships could not be loaded: $_myTeamsError')
          else if (_myTeams.isEmpty)
            const Text('No team memberships are recorded for your account.'),
        ],
      ],
    );
  }
}
