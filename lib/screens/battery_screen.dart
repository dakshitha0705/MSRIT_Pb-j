import 'package:flutter/material.dart';
import '../services/device_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_button.dart';
import '../widgets/nearby_users_widget.dart';
import '../widgets/pastel_card.dart';
import 'battery_search_screen.dart';

class BatteryScreen extends StatefulWidget {
  const BatteryScreen({super.key});
  @override
  State<BatteryScreen> createState() => _BatteryScreenState();
}

class _BatteryScreenState extends State<BatteryScreen> {
  int _battery = 0;
  int _maxShare = 20;
  int _minThreshold = 30;

  @override
  void initState() {
    super.initState();
    DeviceService.getBatteryLevel().then((v) => setState(() => _battery = v));
  }

  Color get _batteryColor {
    if (_battery > 50) return AppColors.batteryGreen;
    if (_battery > 20) return AppColors.warning;
    return AppColors.batteryRed;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            gradient: isDark ? AppColors.darkBg : AppColors.lightBg),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                        icon: Icon(Icons.arrow_back_ios_rounded,
                            color: isDark
                                ? AppColors.starWhite
                                : AppColors.textDark),
                        onPressed: () => Navigator.pop(context)),
                    Text('🔋 Battery Sharing',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.starWhite
                                : AppColors.textDark)),
                  ],
                ),
                const SizedBox(height: 20),

                // Battery level card
                PastelCard(
                  child: Column(
                    children: [
                      Text('$_battery%',
                          style: TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.w800,
                              color: _batteryColor)),
                      Text('Current Battery Level',
                          style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.dustyBlue
                                  : AppColors.textMed)),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                            value: _battery / 100,
                            minHeight: 14,
                            backgroundColor: AppColors.divider,
                            color: _batteryColor),
                      ),
                      const SizedBox(height: 12),
                      Text(
                          _battery > 50
                              ? '✅ Good battery — safe to donate'
                              : _battery > 20
                                  ? '⚠️ Medium — share with caution'
                                  : '❌ Low battery — charging recommended',
                          style: TextStyle(
                              fontSize: 13,
                              color: _batteryColor,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Text('Donor Settings',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color:
                            isDark ? AppColors.starWhite : AppColors.textDark)),
                const SizedBox(height: 10),
                PastelCard(
                  child: Column(
                    children: [
                      _SliderRow(
                        label: 'Max share %',
                        value: _maxShare,
                        min: 5,
                        max: 35,
                        onChanged: (v) => setState(() => _maxShare = v),
                      ),
                      const Divider(height: 24),
                      _SliderRow(
                        label: 'My minimum battery keep %',
                        value: _minThreshold,
                        min: 10,
                        max: 80,
                        onChanged: (v) => setState(() => _minThreshold = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                AppButton(
                  label: '📡 Search Battery Source',
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => BatterySearchScreen(
                              maxShare: _maxShare,
                              minThreshold: _minThreshold))),
                ),
                const SizedBox(height: 24),
                const NearbyUsersWidget(mode: 'battery'),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final int value, min, max;
  final ValueChanged<int> onChanged;
  const _SliderRow(
      {required this.label,
      required this.value,
      required this.min,
      required this.max,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.textMed)),
              Text('$value%',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max - min,
              activeColor: AppColors.primaryBlue,
              onChanged: (v) => onChanged(v.round())),
        ],
      );
}
