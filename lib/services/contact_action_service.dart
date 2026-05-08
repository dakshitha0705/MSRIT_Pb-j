import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class ContactActionService {
  static final ContactActionService _instance =
      ContactActionService._internal();

  factory ContactActionService() {
    return _instance;
  }

  ContactActionService._internal();

  Future<bool> requestContactPermission() async {
    try {
      final status = await Permission.contacts.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('Contact permission error: $e');
      return false;
    }
  }

  Future<bool> hasContactPermission() async {
    try {
      final status = await Permission.contacts.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('Check contact permission error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> searchContact(String name) async {
    if (name.trim().isEmpty) return null;

    return {
      'name': name.trim(),
      'phone': '+91 00000 00000',
      'email': '${name.trim().toLowerCase()}@example.com',
    };
  }

  Future<Map<String, dynamic>?> getCurrentUserContact(
    BuildContext context,
  ) async {
    try {
      final auth = context.read<AuthService>();
      final firestore = context.read<FirestoreService>();

      if (auth.uid == null) return null;

      final user = firestore.currentUser;
      if (user == null) return null;

      return {
        'name': user.name,
        'phone': user.phone,
        'email': user.email,
        'bio': '',
      };
    } catch (e) {
      debugPrint('Get user contact error: $e');
      return null;
    }
  }

  Future<bool> showSendContactConfirmation(
    BuildContext context,
    String targetName,
    Map<String, dynamic> contactInfo,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
            title: Text(
              'Share Contact?',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share your contact info with $targetName?',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withOpacity(0.7)
                        : Colors.black.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow(
                        'Name:',
                        contactInfo['name']?.toString() ?? 'N/A',
                        isDark,
                      ),
                      _infoRow(
                        'Phone:',
                        contactInfo['phone']?.toString() ?? 'N/A',
                        isDark,
                      ),
                      _infoRow(
                        'Email:',
                        contactInfo['email']?.toString() ?? 'N/A',
                        isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Share',
                  style: TextStyle(
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _infoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white.withOpacity(0.5) : Colors.black54,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String? extractContactName(String input) {
    final q = input.toLowerCase().trim();

    final patterns = [
      RegExp(r'send.*?(?:to|for)\s+([a-zA-Z]+)'),
      RegExp(r'share\s+(?:my\s+)?contact\s+(?:to|with)\s+([a-zA-Z]+)'),
      RegExp(r'(?:to|with)\s+([a-zA-Z]+)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(q);
      if (match != null && match.groupCount >= 1) {
        final name = match.group(1)?.trim();
        if (name != null && name.isNotEmpty) {
          return name;
        }
      }
    }

    return null;
  }
}
