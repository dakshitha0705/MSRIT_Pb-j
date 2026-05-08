import '../models/device_model.dart';

class CompatibilityResult {
  final double score;
  final String label; // 'Good', 'Risky', 'Not Supported'
  final bool canProceed; // false only when score < 30
  const CompatibilityResult(this.score, this.label, this.canProceed);
}

class CompatibilityService {
  /// Battery wireless sharing compatibility score 0-100
  /// Formula: Score = 0.35W + 0.20O + 0.15C + 0.15B + 0.15D
  static CompatibilityResult compute(
      DeviceModel a, DeviceModel b, double distanceMeters) {
    final W = _wirelessScore(a, b);
    final O = _osScore(a, b);
    final Ch = _chargingScore(a, b);
    final B = _capacityScore(a, b);
    final D = _distanceScore(distanceMeters);

    final score = W * 0.35 + O * 0.20 + Ch * 0.15 + B * 0.15 + D * 0.15;
    final label = score < 30
        ? 'Not Supported'
        : score < 70
            ? 'Risky'
            : 'Good';
    return CompatibilityResult(score, label, score >= 30);
  }

  static double _wirelessScore(DeviceModel a, DeviceModel b) {
    if (a.reverseWirelessCharging && b.wirelessCharging) return 100;
    if (a.wirelessCharging || b.wirelessCharging) return 40;
    return 0;
  }

  static double _osScore(DeviceModel a, DeviceModel b) {
    if (a.os == 'Unknown' || b.os == 'Unknown') return 50;
    if (a.os == b.os) return 100;
    return 60; // Android + iOS mixed
  }

  static double _chargingScore(DeviceModel a, DeviceModel b) {
    if (a.chargingStandard == 'Unknown' || b.chargingStandard == 'Unknown') {
      return 50;
    }
    if (a.chargingStandard == b.chargingStandard) return 100;
    const compatible = {'USB-C', 'USB-A'};
    if (compatible.contains(a.chargingStandard) &&
        compatible.contains(b.chargingStandard)) {
      return 70;
    }
    return 30;
  }

  static double _capacityScore(DeviceModel a, DeviceModel b) {
    final c1 = a.batteryCapacity;
    final c2 = b.batteryCapacity;
    if (c1 == null || c2 == null || c1 == 0 || c2 == 0) return 50;
    final maxC = c1 > c2 ? c1 : c2;
    return 100 - ((c1 - c2).abs() / maxC * 100);
  }

  static double _distanceScore(double meters) {
    if (meters < 5) return 100;
    if (meters < 20) return 80;
    if (meters < 50) return 60;
    return 40;
  }
}
