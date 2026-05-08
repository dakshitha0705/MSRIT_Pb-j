import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CreditBadge extends StatelessWidget {
  final int credits;
  const CreditBadge({super.key, required this.credits});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNegative = credits < 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isNegative
            ? AppColors.danger.withOpacity(isDark ? 0.2 : 0.1)
            : isDark
                ? AppColors.spaceIndigo
                : AppColors.primaryBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isNegative
              ? AppColors.danger.withOpacity(0.4)
              : AppColors.primaryBlue.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bolt_rounded,
            size: 14,
            color: isNegative
                ? AppColors.danger
                : isDark
                    ? AppColors.starWhite
                    : AppColors.primaryBlue,
          ),
          const SizedBox(width: 4),
          Text(
            '$credits',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isNegative
                  ? AppColors.danger
                  : isDark
                      ? AppColors.starWhite
                      : AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}
