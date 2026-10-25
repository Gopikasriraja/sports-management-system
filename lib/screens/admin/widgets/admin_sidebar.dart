import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_roles.dart';
import '../../../core/widgets/mrcas_brand_mark.dart';
import '../../../providers/auth_provider.dart';

class AdminSidebar extends StatefulWidget {
  final bool collapsed;
  final String activeItem;
  final Function(String) onItemSelect;

  const AdminSidebar({
    super.key,
    required this.collapsed,
    required this.activeItem,
    required this.onItemSelect,
  });

  @override
  State<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final Color secondaryColor = isDark ? AppColors.secondaryDark : AppColors.secondaryLight;
    final Color onBackgroundColor = isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight;

    final Color sidebarBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final Color dividerColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);

    final auth = Provider.of<AuthProvider>(context);
    final role = auth.currentUser?.role;
    final bool isAdmin = AppRoles.canManageUsers(role);
    final bool canManageStudents = AppRoles.canManageStudents(role);
    final bool canViewReports = AppRoles.canViewReports(role);
    final bool canManageAnnouncements =
        AppRoles.canManageAnnouncements(role);
    final bool canManageSystemSettings =
        AppRoles.canManageSystemSettings(role);
    final portalTitle = switch (role) {
      AppRoles.admin => 'Sports Admin',
      AppRoles.manager => 'Sports Manager Portal',
      _ => 'Sports Staff Portal',
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: widget.collapsed ? 80 : 260,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(
          right: BorderSide(color: dividerColor, width: 1.5),
        ),
      ),
      child: Column(
        children: [
          // 1. Sidebar Header (College Emblem & Portal Details)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Row(
              mainAxisAlignment: widget.collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: widget.collapsed ? 40 : 44,
                  height: widget.collapsed ? 40 : 44,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: secondaryColor.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Center(
                    child: MrcasBrandMark(size: widget.collapsed ? 30 : 36),
                  ),
                ),
                if (!widget.collapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MRCAS',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: primaryColor,
                          ),
                        ),
                        Text(
                          portalTitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: onBackgroundColor.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Divider(color: dividerColor, height: 1, thickness: 1),

          // 2. Navigation List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              children: [
                _buildMenuItem(context, 'Dashboard', Icons.dashboard_rounded),
                if (AppRoles.canManageTeams(role))
                  _buildMenuItem(context, 'Teams', Icons.groups_rounded),
                if (canManageStudents)
                  _buildMenuItem(
                    context,
                    'Student Management',
                    Icons.people_alt_rounded,
                  ),
                _buildMenuItem(context, 'Attendance Management', Icons.calendar_today_rounded),
                _buildMenuItem(context, 'Sports Equipment', Icons.sports_soccer_rounded),
                _buildMenuItem(context, 'Achievements', Icons.emoji_events_rounded),
                _buildMenuItem(context, 'Sports Calendar', Icons.event_note_rounded),
                if (AppRoles.canManageTrainingSessions(role))
                  _buildMenuItem(
                    context,
                    'Training Schedule',
                    Icons.fitness_center_rounded,
                  ),
                _buildMenuItem(context, 'Gallery', Icons.photo_library_rounded),
                if (canViewReports)
                  _buildMenuItem(context, 'Reports', Icons.analytics_rounded),
                if (canManageAnnouncements)
                  _buildMenuItem(
                    context,
                    'Notifications',
                    Icons.notifications_active_rounded,
                  ),
                if (isAdmin) _buildMenuItem(context, 'User Management', Icons.manage_accounts_rounded),
                if (canManageSystemSettings)
                  _buildMenuItem(context, 'Settings', Icons.settings_rounded),
              ],
            ),
          ),

          Divider(color: dividerColor, height: 1, thickness: 1),

          // 3. Logout Item
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: _buildLogoutItem(context, primaryColor, secondaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, IconData icon) {
    return _HoverableMenuItem(
      title: title,
      icon: icon,
      isActive: widget.activeItem == title,
      isCollapsed: widget.collapsed,
      onTap: () => widget.onItemSelect(title),
    );
  }

  Widget _buildLogoutItem(BuildContext context, Color primaryColor, Color secondaryColor) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return InkWell(
      onTap: () async {
        await authProvider.logout();
        if (context.mounted) {
          context.go('/auth');
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          vertical: 12,
          horizontal: widget.collapsed ? 0 : 16,
        ),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(
          mainAxisAlignment: widget.collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            const Icon(
              Icons.logout_rounded,
              color: Colors.redAccent,
              size: 22,
            ),
            if (!widget.collapsed) ...[
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HoverableMenuItem extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isActive;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _HoverableMenuItem({
    required this.title,
    required this.icon,
    required this.isActive,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  State<_HoverableMenuItem> createState() => _HoverableMenuItemState();
}

class _HoverableMenuItemState extends State<_HoverableMenuItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final Color secondaryColor = isDark ? AppColors.secondaryDark : AppColors.secondaryLight;
    final Color onBackgroundColor = isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              vertical: 14,
              horizontal: widget.isCollapsed ? 0 : 16,
            ),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? primaryColor.withValues(alpha: 0.12)
                  : (_isHovering ? onBackgroundColor.withValues(alpha: 0.05) : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
              border: widget.isActive
                  ? Border.all(color: primaryColor.withValues(alpha: 0.2), width: 1.5)
                  : Border.all(color: Colors.transparent, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: widget.isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  widget.icon,
                  color: widget.isActive
                      ? primaryColor
                      : (_isHovering ? secondaryColor : onBackgroundColor.withValues(alpha: 0.65)),
                  size: 24,
                ),
                if (!widget.isCollapsed) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: widget.isActive ? FontWeight.bold : FontWeight.w600,
                        color: widget.isActive
                            ? primaryColor
                            : (_isHovering ? secondaryColor : onBackgroundColor.withValues(alpha: 0.8)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
