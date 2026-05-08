import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PastelCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double? borderRadius;
  final Gradient? gradient;

  const PastelCard({
    super.key,
    required this.child,
    this.color,
    this.padding,
    this.onTap,
    this.borderRadius,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = color ?? (isDark ? AppColors.spaceMidnight : AppColors.white);
    final radius = borderRadius ?? 20.0;

    return Material(
      color: gradient != null ? Colors.transparent : bg,
      borderRadius: BorderRadius.circular(radius),
      elevation: isDark ? 0 : 2,
      shadowColor: AppColors.primaryBlue.withOpacity(0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: Container(
          padding: padding ?? const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null ? bg : null,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: isDark ? AppColors.spaceIndigo : AppColors.divider,
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
