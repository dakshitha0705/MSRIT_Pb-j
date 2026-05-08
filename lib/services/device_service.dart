import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/device_model.dart';

class DeviceService {
  static final Battery _battery = Battery();
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<DeviceModel> detect() async {
    String model = 'Unknown';
    String osVersion = 'Unknown';

    try {
      final info = await _deviceInfo.androidInfo;
      model = '${info.manufacturer} ${info.model}'.trim();
      osVersion = info.version.release;
    } catch (_) {}

    int batteryPct = 0;
    try {
      batteryPct = await _battery.batteryLevel;
    } catch (_) {}

    return DeviceModel(
      model: model,
      os: 'Android',
      osVersion: osVersion,
      batteryPercentage: batteryPct,
      batteryCapacity: null,
      wirelessCharging: false,
      reverseWirelessCharging: false,
      chargingStandard: 'USB-C',
      bluetoothSupported: true,
      wifiDirectSupported: false,
    );
  }

  static Future<int> getBatteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (_) {
      return 0;
    }
  }

  static Stream<BatteryState> get batteryStateStream =>
      _battery.onBatteryStateChanged;
}
