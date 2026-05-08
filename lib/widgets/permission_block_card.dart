import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_colors.dart';
import 'app_button.dart';

class PermissionBlockCard extends StatelessWidget {
  final String title;
  final String description;
  final String emoji;

  const PermissionBlockCard({
    super.key,
    required this.title,
    required this.description,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.peach.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryPeach.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
          const SizedBox(height: 8),
          Text(description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textMed, height: 1.5)),
          const SizedBox(height: 20),
          AppButton(
            label: 'Open App Settings',
            color: AppColors.primaryPeach,
            onPressed: () => openAppSettings(),
          ),
        ],
      ),
    );
  }
}
