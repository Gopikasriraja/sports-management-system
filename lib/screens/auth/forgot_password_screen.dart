import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../home/widgets/glass_card.dart';
import '../home/widgets/hover_card.dart';
import 'login_screen.dart'; // import painter

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSendResetLink() async {
    setState(() {
      _errorMessage = null;
    });

    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.sendPasswordReset(email);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Password reset link successfully sent to $email'),
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
          );
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && context.canPop()) {
              context.pop();
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = authProvider.errorMessage;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final Color secondaryColor = isDark ? AppColors.secondaryDark : AppColors.secondaryLight;
    final Color onBackgroundColor = isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight;

    final authProvider = Provider.of<AuthProvider>(context);

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

          // 2. Painted Lines
          Positioned.fill(
            child: CustomPaint(
              painter: AuthBackgroundPainter(
                lineColor: (isDark ? Colors.blue : Colors.blue.shade900).withValues(alpha: 0.08),
              ),
            ),
          ),

          // 3. Form Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: GlassCard(
                  backgroundOpacity: isDark ? 0.15 : 0.6,
                  borderOpacity: 0.2,
                  borderRadius: 24,
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.lock_reset_rounded, size: 48, color: secondaryColor),
                              const SizedBox(height: 12),
                              Text(
                                'Reset Password',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Recover your MRCAS login access link',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: onBackgroundColor.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Error Message Display
                        if (_errorMessage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Info text
                        Text(
                          'Enter your registered email address. We will verify and send you a link to reset your account password.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: onBackgroundColor.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Email Field
                        Text(
                          'Email Address',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: onBackgroundColor.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          enabled: !authProvider.isLoading,
                          decoration: InputDecoration(
                            hintText: 'Enter student/admin email',
                            prefixIcon: Icon(Icons.email_rounded, color: primaryColor.withValues(alpha: 0.6)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email is required';
                            }
                            final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                            if (!regex.hasMatch(value.trim())) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        // Action Buttons
                        if (authProvider.isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else ...[
                          HoverCard(
                            scaleFactor: 1.02,
                            child: ElevatedButton(
                              onPressed: _handleSendResetLink,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: const Text('Send Reset Link', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          HoverCard(
                            scaleFactor: 1.02,
                            enableGlow: false,
                            child: OutlinedButton(
                              onPressed: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/auth');
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryColor,
                                side: BorderSide(color: primaryColor.withValues(alpha: 0.4), width: 1.5),
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Back', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
