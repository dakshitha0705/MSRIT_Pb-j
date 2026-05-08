class AppConstants {
  static const int minCreditsAllowed = -10;
  static const int dailyGameCreditCap = 50;
  static const int batteryDonorCredits = 10;
  static const int batteryReceiverDebit = 10;
  static const int dataShareDonorCredits = 12;
  static const int dataShareReceiverDebit = 12;
  static const int contactShareCredits = 2;
  static const int fileCreditSmall = 2;
  static const int fileCreditMedium = 7;
  static const int fileCreditLarge = 15;
  static const int minDataSessionSeconds = 30;
  static const int maxBatterySharePercent = 35;

  static const String collectionUsers = 'users';
  static const String collectionSessions = 'sessions';
  static const String collectionNotifications = 'notifications';
  static const String collectionTransactions = 'transactions';
  static const String collectionFiles = 'files';

  // Parse layered avatar key: 'animal|outfit|top|bottom|shoes|hat|glasses|extra'
  static Map<String, String?> parseAvatar(String key) {
    final p = key.split('|');
    String? s(int i) => p.length > i && p[i].isNotEmpty ? p[i] : null;
    return {
      'animal': p.isNotEmpty && p[0].isNotEmpty ? p[0] : 'panda',
      'outfit': s(1),
      'top': s(2),
      'bottom': s(3),
      'shoes': s(4),
      'hat': s(5),
      'glasses': s(6),
      'extra': s(7),
    };
  }

  // Base animal emoji for header display
  static const Map<String, String> avatarEmoji = {
    'panda': '🐼',
    'fox': '🦊',
    'cat': '🐱',
    'bear': '🐻',
    'bunny': '🐰',
    'koala': '🐨',
    'tiger': '🐯',
    'wolf': '🐺',
  };

  // Legacy — kept for compatibility
  static const List<String> avatarOptions = [
    'panda',
    'fox',
    'cat',
    'bear',
    'bunny',
    'koala',
    'tiger',
    'wolf',
  ];
  static const Map<String, String> avatarAccessory = {};
  static const Map<String, String> avatarLabel = {};
}
