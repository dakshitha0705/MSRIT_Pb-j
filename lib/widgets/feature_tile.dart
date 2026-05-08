import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class FeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final bool locked;

  const FeatureTile({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Opacity(
      opacity: locked ? 0.4 : 1.0,
      child: Material(
        color: isDark ? AppColors.spaceMidnight : AppColors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: isDark ? 0 : 2,
        shadowColor: color.withOpacity(0.12),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: locked ? null : onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color:
                    isDark ? color.withOpacity(0.2) : color.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: color,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.starWhite : AppColors.textDark,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.dustyBlue : AppColors.textLight,
                    height: 1.3,
                  ),
                ),
                if (locked) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: const [
                      Icon(
                        Icons.lock_rounded,
                        size: 10,
                        color: AppColors.danger,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Locked',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
