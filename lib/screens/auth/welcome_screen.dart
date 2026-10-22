import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

/// MRCAS Sports Management System - Welcome/Auth Landing Screen
/// This is the first screen shown when no authenticated session exists.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    final Color primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final Color secondary = isDark ? AppColors.secondaryDark : AppColors.secondaryLight;
    final Color onBg = isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight;

    final bool isWide = size.width >= 900;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background gradient ──────────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF0F172A),
                          const Color(0xFF1E1B4B),
                          const Color(0xFF0F172A),
                        ]
                      : [
                          const Color(0xFFEFF6FF),
                          const Color(0xFFF8FAFC),
                          const Color(0xFFEDE9FE),
                        ],
                ),
              ),
            ),
          ),

          // ── Decorative overlay blobs ─────────────────────────────────────
          Positioned(
            top: -60,
            right: -80,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    secondary.withValues(alpha: isDark ? 0.12 : 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primary.withValues(alpha: isDark ? 0.10 : 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Main Content ─────────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: isWide
                    ? _buildWideLayout(context, primary, secondary, onBg, isDark)
                    : _buildNarrowLayout(context, primary, secondary, onBg, isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Wide layout (tablet/desktop) ─────────────────────────────────────────
  Widget _buildWideLayout(BuildContext context, Color primary, Color secondary,
      Color onBg, bool isDark) {
    return Row(
      children: [
        // Left panel: branding
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBranding(primary, secondary, onBg, isDark, compact: false),
              ],
            ),
          ),
        ),
        // Right panel: auth buttons
        Expanded(
          flex: 4,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: _buildAuthCard(context, primary, secondary, onBg, isDark),
            ),
          ),
        ),
      ],
    );
  }

  // ── Narrow layout (mobile) ───────────────────────────────────────────────
  Widget _buildNarrowLayout(BuildContext context, Color primary, Color secondary,
      Color onBg, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildBranding(primary, secondary, onBg, isDark, compact: true),
          const SizedBox(height: 40),
          _buildAuthCard(context, primary, secondary, onBg, isDark),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Branding section ─────────────────────────────────────────────────────
  Widget _buildBranding(Color primary, Color secondary, Color onBg, bool isDark,
      {required bool compact}) {
    return Column(
      crossAxisAlignment:
          compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        // Logo
        Container(
          width: compact ? 80 : 100,
          height: compact ? 80 : 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary.withValues(alpha: 0.08),
            border: Border.all(color: primary.withValues(alpha: 0.2), width: 2),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.12),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/mrcas_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(
                Icons.shield_rounded,
                color: primary,
                size: compact ? 44 : 54,
              ),
            ),
          ),
        ),
        SizedBox(height: compact ? 20 : 28),

        // College name
        Text(
          'MRCAS',
          textAlign: compact ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontSize: compact ? 30 : 42,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manikam Ramaswami College of Arts & Science',
          textAlign: compact ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontSize: compact ? 12 : 15,
            fontWeight: FontWeight.w600,
            color: onBg.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: secondary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Department of Physical Education & Sports',
          textAlign: compact ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontSize: compact ? 11 : 14,
            fontWeight: FontWeight.w500,
            color: onBg.withValues(alpha: 0.55),
            letterSpacing: 0.3,
          ),
        ),

        if (!compact) ...[
          const SizedBox(height: 40),
          // Feature bullets (desktop only)
          ..._buildFeatureList(primary, secondary, onBg),
        ],
      ],
    );
  }

  List<Widget> _buildFeatureList(Color primary, Color secondary, Color onBg) {
    final features = [
      (Icons.people_alt_rounded, 'Student Athlete Management'),
      (Icons.calendar_today_rounded, 'Attendance & Scheduling'),
      (Icons.sports_soccer_rounded, 'Equipment Inventory'),
      (Icons.emoji_events_rounded, 'Achievements & Records'),
      (Icons.analytics_rounded, 'Performance Analytics'),
    ];
    return features
        .map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary.withValues(alpha: 0.08),
                    ),
                    child: Icon(f.$1, size: 16, color: primary),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    f.$2,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: onBg.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ))
        .toList();
  }

  // ── Auth action card ─────────────────────────────────────────────────────
  Widget _buildAuthCard(BuildContext context, Color primary, Color secondary,
      Color onBg, bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.all(36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card title
          Text(
            'Welcome Back',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Access the MRCAS Sports Management portal',
            style: TextStyle(
              fontSize: 13,
              color: onBg.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 32),

          // Login Button
          _buildPrimaryButton(
            id: 'btn_login_welcome',
            label: 'Login to Portal',
            icon: Icons.login_rounded,
            color: primary,
            onPressed: () => context.go('/auth/role'),
          ),
          const SizedBox(height: 14),

          // Sign Up Button
          _buildSecondaryButton(
            id: 'btn_signup_welcome',
            label: 'Create New Account',
            icon: Icons.person_add_alt_1_rounded,
            color: secondary,
            onPressed: () => context.go('/auth/signup'),
            isDark: isDark,
          ),

          const SizedBox(height: 28),
          Divider(color: onBg.withValues(alpha: 0.1)),
          const SizedBox(height: 16),

          // Browse button
          TextButton.icon(
            onPressed: () => context.go('/home'),
            icon: Icon(Icons.explore_rounded, size: 18, color: onBg.withValues(alpha: 0.5)),
            label: Text(
              'Browse Public Portal',
              style: TextStyle(
                fontSize: 13,
                color: onBg.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Footer note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primary.withValues(alpha: 0.1)),
            ),
            child: Text(
              '🏛 This is a secure, production portal for MRCAS staff and students. Unauthorized access is strictly prohibited.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                color: onBg.withValues(alpha: 0.55),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String id,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        key: Key(id),
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String id,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return SizedBox(
      height: 54,
      child: OutlinedButton.icon(
        key: Key(id),
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: color),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.6), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
