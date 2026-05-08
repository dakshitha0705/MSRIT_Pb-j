import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestLocation() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  static Future<bool> requestBluetooth() async {
    // Android 12+ requires these three separate permissions
    final scan = await Permission.bluetoothScan.request();
    final connect = await Permission.bluetoothConnect.request();
    return scan.isGranted && connect.isGranted;
  }

  static Future<bool> requestStorage() async {
    // Android 12 and below
    final legacy = await Permission.storage.request();
    if (legacy.isGranted) return true;
    // Android 13+ uses granular media permissions
    final photos = await Permission.photos.request();
    final videos = await Permission.videos.request();
    return photos.isGranted || videos.isGranted;
  }

  static Future<bool> requestNotifications() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  static Future<Map<String, bool>> checkAll() async {
    return {
      'location': await Permission.locationWhenInUse.isGranted,
      'bluetooth': await Permission.bluetoothScan.isGranted,
      'storage': await Permission.storage.isGranted ||
          await Permission.photos.isGranted,
      'notifications': await Permission.notification.isGranted,
      'usage_stats': false, // Not available without special system permission
    };
  }
}
