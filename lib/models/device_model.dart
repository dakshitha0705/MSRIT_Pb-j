class DeviceModel {
  final String model;
  final String os;
  final String osVersion;
  final int batteryPercentage;
  final int? batteryCapacity;
  final bool wirelessCharging;
  final bool reverseWirelessCharging;
  final String chargingStandard;
  final bool bluetoothSupported;
  final bool wifiDirectSupported;

  const DeviceModel({
    this.model = 'Unknown',
    this.os = 'Android',
    this.osVersion = 'Unknown',
    this.batteryPercentage = 0,
    this.batteryCapacity,
    this.wirelessCharging = false,
    this.reverseWirelessCharging = false,
    this.chargingStandard = 'Unknown',
    this.bluetoothSupported = true,
    this.wifiDirectSupported = false,
  });

  factory DeviceModel.fromMap(Map<String, dynamic> map) {
    return DeviceModel(
      model: map['model'] ?? 'Unknown',
      os: map['os'] ?? 'Android',
      osVersion: map['os_version'] ?? 'Unknown',
      batteryPercentage: map['battery_percentage'] ?? 0,
      batteryCapacity: map['battery_capacity'],
      wirelessCharging: map['wireless_charging'] ?? false,
      reverseWirelessCharging: map['reverse_wireless_charging'] ?? false,
      chargingStandard: map['charging_standard'] ?? 'Unknown',
      bluetoothSupported: map['bluetooth_supported'] ?? true,
      wifiDirectSupported: map['wifi_direct_supported'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'model': model,
        'os': os,
        'os_version': osVersion,
        'battery_percentage': batteryPercentage,
        'battery_capacity': batteryCapacity,
        'wireless_charging': wirelessCharging,
        'reverse_wireless_charging': reverseWirelessCharging,
        'charging_standard': chargingStandard,
        'bluetooth_supported': bluetoothSupported,
        'wifi_direct_supported': wifiDirectSupported,
      };
}
