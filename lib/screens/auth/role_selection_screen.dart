import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../home/widgets/glass_card.dart';
import '../home/widgets/hover_card.dart';
import 'login_screen.dart'; // import painter

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final Color secondaryColor = isDark ? AppColors.secondaryDark : AppColors.secondaryLight;
    final Color onBackgroundColor = isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight;

    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 600;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF0F172A), const Color(0xFF1E1B4B)]
                      : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                ),
              ),
            ),
          ),

          // 2. Painted Lines Overlay
          Positioned.fill(
            child: CustomPaint(
              painter: AuthBackgroundPainter(
                lineColor: (isDark ? Colors.blue : Colors.blue.shade900).withValues(alpha: 0.08),
              ),
            ),
          ),

          // 3. Main Centered Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Text(
                      'Select Your Role',
                      style: TextStyle(
                        fontSize: isMobile ? 26 : 36,
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose the correct portal type to continue your authentication.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: onBackgroundColor.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Cards Layout (Row on Desktop, Column on Mobile)
                    if (isMobile) ...[
                      _buildRoleCard(
                        context,
                        title: 'Admin Portal',
                        desc: 'Access sports administrative configurations, manage inventories, schedules, and certified coaches.',
                        icon: Icons.admin_panel_settings_rounded,
                        onTap: () => context.go('/auth/admin'),
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),
                      _buildRoleCard(
                        context,
                        title: 'User / Student Portal',
                        desc: 'View schedules, register for sports meets, track achievements, and update your sports profile.',
                        icon: Icons.sports_handball_rounded,
                        onTap: () => context.go('/auth/user'),
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor,
                        isDark: isDark,
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildRoleCard(
                              context,
                              title: 'Admin Portal',
                              desc: 'Access sports administrative configurations, manage inventories, schedules, and certified coaches.',
                              icon: Icons.admin_panel_settings_rounded,
                              onTap: () => context.go('/auth/admin'),
                              primaryColor: primaryColor,
                              secondaryColor: secondaryColor,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildRoleCard(
                              context,
                              title: 'User / Student Portal',
                              desc: 'View schedules, register for sports meets, track achievements, and update your sports profile.',
                              icon: Icons.sports_handball_rounded,
                              onTap: () => context.go('/auth/user'),
                              primaryColor: primaryColor,
                              secondaryColor: secondaryColor,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 48),

                    // Back Button
                    TextButton.icon(
                      onPressed: () => context.go('/auth'),
                      icon: Icon(Icons.arrow_back_rounded, color: primaryColor),
                      label: Text(
                        'Back to Login Splash',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String desc,
    required IconData icon,
    required VoidCallback onTap,
    required Color primaryColor,
    required Color secondaryColor,
    required bool isDark,
  }) {
    return HoverCard(
      scaleFactor: 1.03,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: GlassCard(
          backgroundOpacity: isDark ? 0.15 : 0.6,
          borderOpacity: 0.25,
          borderRadius: 20,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: secondaryColor.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Icon(icon, color: secondaryColor, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                desc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
