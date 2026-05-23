import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget web;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.web,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 800;

  static bool isWeb(BuildContext context) =>
      MediaQuery.of(context).size.width >= 800;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 800) {
          return web;
        } else {
          return mobile;
        }
      },
    );
  }
}

/// Screen-width-proportional scale factor.
/// Baseline: 390 dp (iPhone 14). Range: 0.78 (320 dp) – 1.15 (430 dp+).
/// Use [R.fs] for fonts and [R.s] for spacing/heights.
class R {
  R._();
  static const double _kDesign = 390.0;

  static double scale(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return (w / _kDesign).clamp(0.78, 1.15);
  }

  static double fs(BuildContext context, double base) => base * scale(context);
  static double s(BuildContext context, double base) => base * scale(context);
}
