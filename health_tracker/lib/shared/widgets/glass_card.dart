import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final double blur;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.radius = 24.0,
    this.blur = 15.0,
    this.color,
    this.padding = const EdgeInsets.all(20.0),
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AppTheme.glassBlur(
      radius: radius,
      blur: blur,
      child: Container(
        width: width,
        height: height,
        padding: padding,
        decoration: AppTheme.glassDecoration(
          isDarkMode: isDarkMode,
          radius: radius,
          customColor: color,
        ),
        child: child,
      ),
    );
  }
}
