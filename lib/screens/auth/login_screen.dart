import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../home/widgets/glass_card.dart';
import '../home/widgets/hover_card.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
          // 1. Gradient Background
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

          // 2. Custom Painted Background Lines (Stadium Layout)
          Positioned.fill(
            child: CustomPaint(
              painter: AuthBackgroundPainter(
                lineColor: (isDark ? Colors.blue : Colors.blue.shade900).withValues(alpha: 0.08),
              ),
            ),
          ),

          // 3. Main Center Card Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: GlassCard(
                  backgroundOpacity: isDark ? 0.15 : 0.6,
                  borderOpacity: 0.2,
                  borderRadius: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // MRCAS LOGO PLACEHOLDER
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.15),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/mrcas_logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                padding: const EdgeInsets.all(15),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(Icons.shield_rounded, size: 70, color: primaryColor),
                                    Positioned(
                                      bottom: 18,
                                      child: Icon(Icons.sports_basketball_rounded, size: 30, color: secondaryColor),
                                    ),
                                    const Icon(Icons.emoji_events_rounded, size: 32, color: Colors.amber),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // MRCAS COLLEGE BRANDING
                      Text(
                        'MRCAS',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manikam Ramaswami College of Arts & Science',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: onBackgroundColor.withValues(alpha: 0.8),
                        ),
                      ),
                      Text(
                        'Department of Physical Education & Sports',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: onBackgroundColor.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 40,
                        height: 2,
                        color: secondaryColor,
                      ),
                      const SizedBox(height: 16),

                      // APP DETAILS
                      Text(
                        'Sports Management System',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isMobile ? 22 : 26,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Welcome! Please login to access your customized dashboard, register for sport meets, and view schedules.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: onBackgroundColor.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 36),

                      // BUTTONS
                      HoverCard(
                        scaleFactor: 1.02,
                        child: ElevatedButton(
                          onPressed: () => context.go('/auth/role'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      HoverCard(
                        scaleFactor: 1.02,
                        enableGlow: false,
                        child: OutlinedButton(
                          onPressed: () => context.go('/home'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: primaryColor.withValues(alpha: 0.4), width: 1.5),
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Back to Home',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
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
}

// Custom painter to draw sport/stadium background layout curve lines
class AuthBackgroundPainter extends CustomPainter {
  final Color lineColor;

  AuthBackgroundPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw curves replicating soccer field goal/athletics track curve lines
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.2), size.width * 0.3, paint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.8), size.width * 0.4, paint);

    final Path path = Path()
      ..moveTo(0, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.3, size.width, size.height * 0.6);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
