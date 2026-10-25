import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/mrcas_brand_mark.dart';
import '../../../providers/auth_provider.dart';

class UserSidebar extends StatelessWidget {
  final bool collapsed;
  final String activeItem;
  final Function(String) onItemSelect;

  const UserSidebar({
    super.key,
    required this.collapsed,
    required this.activeItem,
    required this.onItemSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final Color secondaryColor = isDark ? AppColors.secondaryDark : AppColors.secondaryLight;
    final Color onBackgroundColor = isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight;

    final Color sidebarBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final Color dividerColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);

    return Container(
      width: collapsed ? 72 : 260,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(
          right: BorderSide(color: dividerColor, width: 1.5),
        ),
      ),
      child: Column(
        children: [
          // 1. Sidebar Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Row(
              mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Container(
                  width: collapsed ? 36 : 40,
                  height: collapsed ? 36 : 40,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: secondaryColor.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Center(
                    child: MrcasBrandMark(size: collapsed ? 28 : 34),
                  ),
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MRCAS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: primaryColor,
                          ),
                        ),
                        Text(
                          'Student Portal',
                          style: TextStyle(
                            fontSize: 11,
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

          // 2. Navigation Items List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
              children: [
                _buildMenuItem(context, 'Dashboard', Icons.dashboard_rounded),
                _buildMenuItem(context, 'My Profile', Icons.person_rounded),
                _buildMenuItem(context, 'Sports Calendar', Icons.calendar_month_rounded),
                _buildMenuItem(
                  context,
                  'Training Schedule',
                  Icons.fitness_center_rounded,
                ),
                _buildMenuItem(context, 'Sports Teams', Icons.groups_rounded),
                _buildMenuItem(context, 'Achievements', Icons.emoji_events_rounded),
                _buildMenuItem(context, 'Equipment Availability', Icons.inventory_2_rounded),
                _buildMenuItem(context, 'Attendance', Icons.assignment_ind_rounded),
                _buildMenuItem(context, 'Gallery', Icons.photo_library_rounded),
                _buildMenuItem(context, 'News & Announcements', Icons.campaign_rounded),
                _buildMenuItem(context, 'Contact Sports Department', Icons.contact_support_rounded),
              ],
            ),
          ),

          Divider(color: dividerColor, height: 1, thickness: 1),

          // 3. Logout Section
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: _buildLogoutItem(context, primaryColor, secondaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isActive = activeItem == title;

    final Color primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final Color secondaryColor = isDark ? AppColors.secondaryDark : AppColors.secondaryLight;
    final Color onBackgroundColor = isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () => onItemSelect(title),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: 12,
            horizontal: collapsed ? 0 : 16,
          ),
          decoration: BoxDecoration(
            color: isActive ? primaryColor.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isActive
                ? Border.all(color: primaryColor.withValues(alpha: 0.12), width: 1)
                : null,
          ),
          child: Row(
            mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: isActive ? secondaryColor : onBackgroundColor.withValues(alpha: 0.65),
                size: 22,
              ),
              if (!collapsed) ...[
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                      color: isActive ? primaryColor : onBackgroundColor.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
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
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: 12,
          horizontal: collapsed ? 0 : 16,
        ),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.15), width: 1),
        ),
        child: Row(
          mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            const Icon(
              Icons.logout_rounded,
              color: Colors.redAccent,
              size: 22,
            ),
            if (!collapsed) ...[
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 13.5,
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
