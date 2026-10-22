import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_roles.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/user_model.dart';
import '../../../providers/user_provider.dart';
import '../home/widgets/glass_card.dart';

class UserManagementView extends StatefulWidget {
  const UserManagementView({super.key});

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  final TextEditingController _searchController = TextEditingController();

  String _filterRole = 'All';
  String _filterDept = 'All';
  String _filterStatus = 'All';
  String _sortBy = 'Name';
  bool _sortAscending = true;
  int _currentPage = 1;

  static const int _pageSize = 8;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<UserProvider>().fetchAllUsers();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showAddEditUserDialog(UserModel? user) async {
    final isEdit = user != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user?.name ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');
    final passwordController = TextEditingController();
    var role = user?.role ?? AppRoles.sportsStaff;
    var department = user?.department ?? 'Physical Education';
    var status = user?.status.toLowerCase() == 'inactive'
        ? 'Inactive'
        : 'Active';
    XFile? pickedProfileImage;
    final actor = context.read<AuthProvider>().currentUser;
    if (actor == null || !AppRoles.canManageUsers(actor.role)) return;
    if (user?.uid == actor.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot modify your own account here.')),
      );
      return;
    }

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final primaryColor = isDark
                ? AppColors.primaryDark
                : AppColors.primaryLight;

            return AlertDialog(
              title: Text(isEdit ? 'Modify User Profile' : 'Register New User'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 38,
                          backgroundColor: primaryColor.withValues(alpha: 0.1),
                          foregroundImage:
                              pickedProfileImage == null &&
                                  user?.profileImage.isNotEmpty == true
                              ? NetworkImage(user!.profileImage)
                              : null,
                          child: pickedProfileImage != null
                              ? FutureBuilder<Uint8List>(
                                  future: pickedProfileImage!.readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return ClipOval(
                                        child: Image.memory(
                                          snapshot.data!,
                                          width: 76,
                                          height: 76,
                                          fit: BoxFit.cover,
                                        ),
                                      );
                                    }
                                    if (snapshot.hasError) {
                                      return const Icon(
                                        Icons.broken_image_outlined,
                                      );
                                    }
                                    return const CircularProgressIndicator();
                                  },
                                )
                              : user?.profileImage.isNotEmpty == true
                              ? null
                              : Icon(Icons.person_rounded, color: primaryColor),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final image = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 70,
                            );
                            if (image != null) {
                              setDialogState(() => pickedProfileImage = image);
                            }
                          },
                          icon: const Icon(Icons.photo_camera_rounded),
                          label: Text(
                            pickedProfileImage == null
                                ? 'Select Photo'
                                : 'Photo Selected',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Full Name *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Enter full name'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: emailController,
                          enabled: !isEdit,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Address *',
                            helperText: isEdit
                                ? 'Email address cannot be updated'
                                : null,
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter email address';
                            }
                            if (!RegExp(
                              r'^[\w.-]+@([\w-]+\.)+[\w-]{2,}$',
                            ).hasMatch(value.trim())) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        if (!isEdit) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Initial Password *',
                              helperText: 'At least 6 characters',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                value == null || value.trim().length < 6
                                ? 'Password must be at least 6 characters'
                                : null,
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Mobile Number *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Enter mobile number'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: role,
                          decoration: const InputDecoration(
                            labelText: 'User Role *',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              (user?.role == AppRoles.admin
                                      ? const [
                                          AppRoles.admin,
                                          AppRoles.manager,
                                          AppRoles.sportsStaff,
                                          AppRoles.student,
                                        ]
                                      : const [
                                          AppRoles.manager,
                                          AppRoles.sportsStaff,
                                          AppRoles.student,
                                        ])
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(item),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => role = value);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: department,
                          decoration: const InputDecoration(
                            labelText: 'Department *',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              const [
                                    'Physical Education',
                                    'Administration',
                                    'Sports Department',
                                    'Student',
                                  ]
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(item),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => department = value);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: status,
                          decoration: const InputDecoration(
                            labelText: 'Account Status *',
                            border: OutlineInputBorder(),
                          ),
                          items: const ['Active', 'Inactive']
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => status = value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!(formKey.currentState?.validate() ?? false)) return;

                    final navigator = Navigator.of(dialogContext);
                    final userProvider = context.read<UserProvider>();
                    final success = isEdit
                        ? await userProvider.updateUser(
                            existingUser: user,
                            name: nameController.text.trim(),
                            department: department,
                            role: role,
                            phone: phoneController.text.trim(),
                            status: status,
                            profileImageFile: pickedProfileImage,
                            actorUid: actor.uid,
                            actorRole: actor.role,
                          )
                        : await userProvider.createUser(
                            name: nameController.text.trim(),
                            email: emailController.text.trim(),
                            phone: phoneController.text.trim(),
                            department: department,
                            role: role,
                            status: status,
                            password: passwordController.text,
                            profileImageFile: pickedProfileImage,
                            actorUid: actor.uid,
                            actorRole: actor.role,
                          );

                    if (!mounted) return;
                    if (success) navigator.pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? isEdit
                                    ? 'User updated successfully.'
                                    : 'User account and profile created.'
                              : userProvider.errorMessage ??
                                    'The user operation failed.',
                        ),
                        backgroundColor: success
                            ? Colors.green
                            : Colors.redAccent,
                      ),
                    );
                  },
                  child: Text(isEdit ? 'Save Changes' : 'Create User'),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      nameController.dispose();
      emailController.dispose();
      phoneController.dispose();
      passwordController.dispose();
    }
  }

  Future<void> _confirmDeleteUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Deactivate User'),
        content: Text(
          'Deactivate ${user.name}\'s profile? This prevents app access after '
          'the next authentication check and preserves the account record.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final actor = context.read<AuthProvider>().currentUser;
    if (actor == null) return;
    final userProvider = context.read<UserProvider>();
    final success = await userProvider.deleteUser(
      uid: user.uid,
      actorUid: actor.uid,
      actorRole: actor.role,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'User account deactivated.'
              : userProvider.errorMessage ?? 'Failed to deactivate the account.',
        ),
        backgroundColor: success ? Colors.green : Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final actor = context.watch<AuthProvider>().currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark
        ? AppColors.primaryDark
        : AppColors.primaryLight;
    final secondaryColor = isDark
        ? AppColors.secondaryDark
        : AppColors.secondaryLight;
    final query = _searchController.text.trim().toLowerCase();

    final roles = userProvider.users.map((user) => user.role).toSet().toList()
      ..sort();
    final departments =
        userProvider.users.map((user) => user.department).toSet().toList()
          ..sort();

    var filteredUsers = userProvider.users.where((user) {
      final matchesQuery =
          query.isEmpty ||
          user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.phone.toLowerCase().contains(query) ||
          user.department.toLowerCase().contains(query) ||
          user.role.toLowerCase().contains(query) ||
          user.registerNumber.toLowerCase().contains(query);
      final matchesRole = _filterRole == 'All' || user.role == _filterRole;
      final matchesDepartment =
          _filterDept == 'All' || user.department == _filterDept;
      final matchesStatus =
          _filterStatus == 'All' ||
          user.status.toLowerCase() == _filterStatus.toLowerCase();
      return matchesQuery && matchesRole && matchesDepartment && matchesStatus;
    }).toList();

    filteredUsers.sort((first, second) {
      final comparison = switch (_sortBy) {
        'Email' => first.email.compareTo(second.email),
        'Role' => first.role.compareTo(second.role),
        'Department' => first.department.compareTo(second.department),
        _ => first.name.compareTo(second.name),
      };
      return _sortAscending ? comparison : -comparison;
    });

    final totalPages = filteredUsers.isEmpty
        ? 1
        : (filteredUsers.length / _pageSize).ceil();
    final currentPage = _currentPage > totalPages ? totalPages : _currentPage;
    final startIndex = (currentPage - 1) * _pageSize;
    final paginatedUsers = filteredUsers
        .skip(startIndex)
        .take(_pageSize)
        .toList();

    return SingleChildScrollView(
      child: Column(
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
                    'User Management',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create, update, and manage user profiles.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              if (actor != null && AppRoles.canManageUsers(actor.role))
                FilledButton.icon(
                  onPressed: () => _showAddEditUserDialog(null),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Add User'),
                  style: FilledButton.styleFrom(
                    backgroundColor: secondaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          GlassCard(
            backgroundOpacity: isDark ? 0.15 : 0.65,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search users by name, email, or phone',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _currentPage = 1);
                            },
                            icon: const Icon(Icons.clear_rounded),
                          ),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() => _currentPage = 1),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildFilterDropdown(
                      label: 'Role',
                      value: _filterRole,
                      items: ['All', ...roles],
                      onChanged: (value) => setState(() {
                        _filterRole = value;
                        _currentPage = 1;
                      }),
                    ),
                    _buildFilterDropdown(
                      label: 'Department',
                      value: _filterDept,
                      items: ['All', ...departments],
                      onChanged: (value) => setState(() {
                        _filterDept = value;
                        _currentPage = 1;
                      }),
                    ),
                    _buildFilterDropdown(
                      label: 'Status',
                      value: _filterStatus,
                      items: const ['All', 'Active', 'Inactive'],
                      onChanged: (value) => setState(() {
                        _filterStatus = value;
                        _currentPage = 1;
                      }),
                    ),
                    _buildFilterDropdown(
                      label: 'Sort by',
                      value: _sortBy,
                      items: const ['Name', 'Email', 'Role', 'Department'],
                      onChanged: (value) => setState(() => _sortBy = value),
                    ),
                    IconButton(
                      tooltip: _sortAscending
                          ? 'Sort descending'
                          : 'Sort ascending',
                      onPressed: () =>
                          setState(() => _sortAscending = !_sortAscending),
                      icon: Icon(
                        _sortAscending
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (userProvider.isLoading && userProvider.users.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (userProvider.errorMessage != null &&
              userProvider.users.isEmpty)
            Center(
              child: Column(
                children: [
                  Text(
                    userProvider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: userProvider.fetchAllUsers,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (paginatedUsers.isEmpty)
            Center(
              child: GlassCard(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 56,
                      color: primaryColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No users found.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text('Try changing your search or filters.'),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: paginatedUsers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final user = paginatedUsers[index];
                return GlassCard(
                  backgroundOpacity: isDark ? 0.15 : 0.65,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: primaryColor.withValues(alpha: 0.12),
                      foregroundImage: user.profileImage.isNotEmpty
                          ? NetworkImage(user.profileImage)
                          : null,
                      child: user.profileImage.isEmpty
                          ? Text(
                              user.name.isEmpty
                                  ? '?'
                                  : user.name[0].toUpperCase(),
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      user.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${user.email}  •  ${user.role}  •  '
                      '${user.department}  •  ${user.status}',
                    ),
                    trailing: actor?.uid == user.uid
                        ? const Chip(label: Text('Your account'))
                        : Wrap(
                            spacing: 4,
                            children: [
                        IconButton(
                          tooltip: 'Edit user',
                          onPressed: () => _showAddEditUserDialog(user),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: 'Deactivate account',
                          onPressed: () => _confirmDeleteUser(user),
                          icon: const Icon(Icons.person_off_outlined),
                        ),
                      ],
                          ),
                  ),
                );
              },
            ),
          if (filteredUsers.length > _pageSize) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Previous page',
                  onPressed: currentPage > 1
                      ? () => setState(() => _currentPage = currentPage - 1)
                      : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Text('Page $currentPage of $totalPages'),
                IconButton(
                  tooltip: 'Next page',
                  onPressed: currentPage < totalPages
                      ? () => setState(() => _currentPage = currentPage + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<String>(
        initialValue: items.contains(value) ? value : 'All',
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        items: items
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (selected) {
          if (selected != null) onChanged(selected);
        },
      ),
    );
  }
}
