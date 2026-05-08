import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  /// Opens WhatsApp with a pre-filled message.
  /// [phone] must be in international format, e.g. +919876543210
  static Future<void> sendNotify({
    required String phone,
    required String featureType,
    required int credits,
  }) async {
    // Strip all non-digit characters except leading +
    final cleanPhone = phone.replaceAll(RegExp(r'(?<!^)[^0-9]'), '');
    if (cleanPhone.isEmpty) {
      throw Exception('Phone number is empty');
    }

    final message =
        'Hey, I sent you a Battery-Barter request for $featureType. '
        'Please check the app. You can earn $credits credits if you help!';
    final encodedMsg = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMsg');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception(
        'WhatsApp is not available on this device. '
        'Ask the person to check the app directly.',
      );
    }
  }

  static Future<bool> isAvailable(String phone) async {
    if (phone.trim().isEmpty) return false;
    final clean = phone.replaceAll(RegExp(r'(?<!^)[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    return await canLaunchUrl(uri);
  }
}
