import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

/// MRCAS Sports Management System - Email Verification Screen
/// Shown after sign-up. User must verify their email before accessing the portal.
class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String password;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _pulse;

  Timer? _checkTimer;
  bool _isChecking = false;
  bool _isResending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulse = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);

    // Auto-check every 5 seconds
    _checkTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkVerification();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _checkTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerification() async {
    if (_isChecking || !mounted) return;
    setState(() => _isChecking = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    // Temporarily sign in to check verification status
    // The AuthProvider.checkEmailVerification() handles this
    final verified = await auth.checkEmailVerification();

    if (!mounted) return;
    setState(() => _isChecking = false);

    if (verified) {
      _checkTimer?.cancel();
      // Navigate to role selection (user verified — let them log in)
      if (mounted) {
        _showVerifiedDialog();
      }
    }
  }

  void _showVerifiedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Email Verified!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your email has been verified. Sports Staff portal access will be available after an administrator approves your account.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('btn_go_to_login'),
              onPressed: () {
                Navigator.pop(context);
                context.go('/auth/role');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Go to Login',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resendVerification() async {
    if (_resendCooldown > 0 || _isResending) return;

    setState(() => _isResending = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.resendVerificationEmail(
      widget.email,
      widget.password,
    );

    if (!mounted) return;
    setState(() => _isResending = false);

    if (success) {
      // Start 60-second cooldown
      setState(() => _resendCooldown = 60);
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() {
          _resendCooldown--;
          if (_resendCooldown <= 0) {
            t.cancel();
          }
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              const Text('Verification email sent! Check your inbox.'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Failed to resend. Try again.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color primary = isDark
        ? AppColors.primaryDark
        : AppColors.primaryLight;
    final Color secondary = isDark
        ? AppColors.secondaryDark
        : AppColors.secondaryLight;
    final Color onBg = isDark
        ? AppColors.onBackgroundDark
        : AppColors.onBackgroundLight;

    return Scaffold(
      body: Stack(
        children: [
          // Background
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

          // Decorative blob
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    secondary.withValues(alpha: isDark ? 0.10 : 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated email icon
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (_, child) {
                          return Transform.scale(
                            scale: 1.0 + (_pulse.value * 0.05),
                            child: child,
                          );
                        },
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: secondary.withValues(alpha: 0.08),
                            border: Border.all(
                              color: secondary.withValues(alpha: 0.25),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: secondary.withValues(alpha: 0.15),
                                blurRadius: 30,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.mark_email_unread_rounded,
                            size: 56,
                            color: secondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Title
                      Text(
                        'Verify Your Email',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: primary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Subtitle with email
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color: onBg.withValues(alpha: 0.65),
                            height: 1.6,
                          ),
                          children: [
                            const TextSpan(
                              text: 'A verification link has been sent to\n',
                            ),
                            TextSpan(
                              text: widget.email,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primary,
                                fontSize: 14,
                              ),
                            ),
                            const TextSpan(
                              text:
                                  '\n\nPlease check your inbox (and spam folder) and click the link to verify your account. Sports Staff accounts also require administrator approval before portal access.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Status card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.2 : 0.06,
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Auto-check indicator
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isChecking)
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: secondary,
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 16,
                                    color: onBg.withValues(alpha: 0.4),
                                  ),
                                const SizedBox(width: 8),
                                Text(
                                  _isChecking
                                      ? 'Checking verification status...'
                                      : 'Auto-checking every 5 seconds',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: onBg.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Manual check button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                key: const Key('btn_check_verification'),
                                onPressed: _isChecking
                                    ? null
                                    : _checkVerification,
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Check Verification Status',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Resend button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton.icon(
                                key: const Key('btn_resend_verification'),
                                onPressed: (_resendCooldown > 0 || _isResending)
                                    ? null
                                    : _resendVerification,
                                icon: _isResending
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: secondary,
                                        ),
                                      )
                                    : const Icon(Icons.send_rounded, size: 18),
                                label: Text(
                                  _resendCooldown > 0
                                      ? 'Resend in ${_resendCooldown}s'
                                      : 'Resend Verification Email',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: secondary,
                                  side: BorderSide(
                                    color: secondary.withValues(alpha: 0.5),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Help steps
                      _buildHelpSteps(onBg, isDark),

                      const SizedBox(height: 28),

                      // Back to login
                      TextButton.icon(
                        key: const Key('btn_back_to_login_verify'),
                        onPressed: () => context.go('/auth/role'),
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          size: 16,
                          color: onBg.withValues(alpha: 0.5),
                        ),
                        label: Text(
                          'Back to Login',
                          style: TextStyle(
                            color: onBg.withValues(alpha: 0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSteps(Color onBg, bool isDark) {
    final steps = [
      (Icons.inbox_rounded, 'Check your email inbox'),
      (Icons.report_gmailerrorred_rounded, 'Check the Spam / Junk folder'),
      (Icons.touch_app_rounded, 'Click the "Verify Email" link in the email'),
      (
        Icons.refresh_rounded,
        'Return here and tap "Check Verification Status"',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Didn\'t receive the email?',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: onBg.withValues(alpha: 0.6),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          ...steps.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    e.value.$1,
                    size: 15,
                    color: onBg.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${e.key + 1}. ${e.value.$2}',
                      style: TextStyle(
                        fontSize: 12,
                        color: onBg.withValues(alpha: 0.6),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
