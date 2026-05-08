import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  final bool loading;
  final Color? color;
  final IconData? icon;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.outlined = false,
    this.loading = false,
    this.color,
    this.icon,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = color ?? AppColors.primaryBlue;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: outlined
          ? OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: bg, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: loading ? null : onPressed,
              child: _child(isDark ? AppColors.starWhite : bg),
            )
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: bg,
                foregroundColor: AppColors.white,
                elevation: 2,
                shadowColor: bg.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: loading ? null : onPressed,
              child: _child(AppColors.white),
            ),
    );
  }

  Widget _child(Color textColor) {
    if (loading) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
        ],
        Text(label,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
      ],
    );
  }
}
