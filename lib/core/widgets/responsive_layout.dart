import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  // Breakpoints
  static const double mobileMax = 640;
  static const double tabletMax = 1024;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width <= mobileMax;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width > mobileMax &&
      MediaQuery.of(context).size.width <= tabletMax;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width > tabletMax;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > tabletMax) {
          return desktop;
        } else if (constraints.maxWidth > mobileMax) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}
