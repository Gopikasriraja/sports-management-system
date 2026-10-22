import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_roles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Setup animations (duration: 1.5 seconds)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOutBack),
    );

    // Start animations
    _animationController.forward();

    // 2. Check session and automatically navigate after 3 seconds
    Timer(const Duration(seconds: 3), () async {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final role = await authProvider.checkPersistedSession();
        if (mounted) {
          if (role == AppRoles.admin) {
            context.go('/admin');
          } else if (AppRoles.canAccessOperationsPortal(role)) {
            context.go('/staff');
          } else if (role == AppRoles.student) {
            context.go('/user');
          } else {
            // No valid session → navigate to the Welcome/Auth landing page
            context.go('/welcome');
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Premium sports colors matching app theme
    final Color primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final Color secondaryColor = isDark ? AppColors.secondaryDark : AppColors.secondaryLight;
    final Color onBackgroundColor = isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Premium Sports-Themed Gradient Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF0F172A), // Deep Slate 900
                          const Color(0xFF1E1B4B), // Deep Indigo 950
                          const Color(0xFF0F172A), // Deep Slate 900
                        ]
                      : [
                          const Color(0xFFF8FAFC), // Slate 50
                          const Color(0xFFEEF2F6), // Cool Grey 100
                          const Color(0xFFE2E8F0), // Slate 200
                        ],
                ),
              ),
            ),
          ),

          // 2. Custom Painted Diagonal Sports Lines Overlay
          Positioned.fill(
            child: CustomPaint(
              painter: SportsBackgroundPainter(
                lineColor: (isDark ? Colors.blue : Colors.blue.shade900).withAlpha(15),
                gridColor: (isDark ? secondaryColor : primaryColor).withAlpha(10),
              ),
            ),
          ),

          // 3. Responsive Content Structure
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double maxWidth = constraints.maxWidth;
                final double maxHeight = constraints.maxHeight;

                // Breakpoint checks
                final bool isMobile = maxWidth < 600;
                final bool isTablet = maxWidth >= 600 && maxWidth < 1024;

                // Scaling parameters based on device type
                final double logoSize = isMobile ? 120 : (isTablet ? 160 : 200);
                final double collegeFontSize = isMobile ? 14 : (isTablet ? 16 : 18);
                final double deptFontSize = isMobile ? 12 : (isTablet ? 14 : 16);
                final double titleFontSize = isMobile ? 24 : (isTablet ? 36 : 44);
                final double spacing = isMobile ? 12 : 20;

                return Center(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: maxHeight - 32,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top Header: College & Department details
                          AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _fadeAnimation.value,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - _fadeAnimation.value) * -20),
                                  child: child,
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                  Text(
                                    'MRCAS',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: collegeFontSize + 6,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2.0,
                                      color: primaryColor,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  'Manikam Ramaswami College of Arts & Science',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: collegeFontSize,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    color: onBackgroundColor.withAlpha(204),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: 40,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: secondaryColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Department of Physical Education & Sports',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: deptFontSize,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                    color: onBackgroundColor.withAlpha(153),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Center Piece: Scale and Fade Animated Logo & App Title
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ScaleTransition(
                                scale: _scaleAnimation,
                                child: FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: Container(
                                    width: logoSize,
                                    height: logoSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryColor.withAlpha(isDark ? 80 : 40),
                                          blurRadius: 24,
                                          spreadRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/images/mrcas_logo.png',
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          // Beautiful Premium Fallback Vector Logo
                                          return Container(
                                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                            padding: EdgeInsets.all(logoSize * 0.15),
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Icon(
                                                  Icons.shield_rounded,
                                                  size: logoSize * 0.7,
                                                  color: primaryColor,
                                                ),
                                                Positioned(
                                                  bottom: logoSize * 0.18,
                                                  child: Icon(
                                                    Icons.sports_basketball_rounded,
                                                    size: logoSize * 0.3,
                                                    color: secondaryColor,
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.emoji_events_rounded,
                                                  size: logoSize * 0.32,
                                                  color: Colors.amber,
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: spacing * 1.5),
                              AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _fadeAnimation.value,
                                    child: Transform.translate(
                                      offset: Offset(0, (1 - _fadeAnimation.value) * 15),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Column(
                                  children: [
                                    Text(
                                      'Sports Management',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: titleFontSize,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                        height: 1.1,
                                        color: primaryColor,
                                      ),
                                    ),
                                    Text(
                                      'System',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: titleFontSize,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                        height: 1.1,
                                        color: onBackgroundColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Bottom Section: Material 3 Loading Indicator & Footer
                          AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _fadeAnimation.value,
                                child: child,
                              );
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 48,
                                  height: 4,
                                  child: LinearProgressIndicator(
                                    backgroundColor: (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                                    color: secondaryColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  '© MRCAS Department of Physical Education. All Rights Reserved.',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                    color: onBackgroundColor.withAlpha(102),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter to draw a subtle sports-themed background mesh pattern
class SportsBackgroundPainter extends CustomPainter {
  final Color lineColor;
  final Color gridColor;

  SportsBackgroundPainter({
    required this.lineColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw dynamic diagonal athletic lines
    for (double i = -size.height; i < size.width; i += 60) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }

    final Paint accentPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw a subtle stadium boundary track or layout outline curve
    final Path path = Path()
      ..moveTo(size.width * 0.1, size.height)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.4,
        size.width * 0.9,
        size.height,
      );
    canvas.drawPath(path, accentPaint);

    final Path path2 = Path()
      ..moveTo(0, size.height * 0.3)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.1,
        size.width,
        size.height * 0.2,
      );
    canvas.drawPath(path2, accentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
