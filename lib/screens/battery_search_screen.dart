import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/compatibility_service.dart';
import '../services/session_service.dart';
import '../services/whatsapp_service.dart';
import '../models/device_model.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/loading_scan_animation.dart';
import '../widgets/permission_block_card.dart';
import '../widgets/pastel_card.dart';
import '../widgets/app_button.dart';

class BatterySearchScreen extends StatefulWidget {
  final int maxShare, minThreshold;
  const BatterySearchScreen(
      {super.key, required this.maxShare, required this.minThreshold});
  @override
  State<BatterySearchScreen> createState() => _BatterySearchScreenState();
}

class _BatterySearchScreenState extends State<BatterySearchScreen> {
  double _radius = 100;
  bool _scanning = false;
  bool _locDenied = false;
  List<(Map<String, dynamic>, CompatibilityResult, double)> _results = [];
  String? _sentFor;

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _results.clear();
      _locDenied = false;
    });

    final fs = context.read<FirestoreService>();
    final me = fs.currentUser;
    if (me == null) {
      setState(() => _scanning = false);
      return;
    }

    final pos = await LocationService.getCurrentPosition();
    if (pos == null) {
      setState(() {
        _scanning = false;
        _locDenied = true;
      });
      return;
    }

    final nearby =
        await fs.getNearbyUsers(pos.latitude, pos.longitude, _radius / 1000);

    final results = nearby.map((u) {
      final dist = (u['distance'] as int).toDouble();
      final uDevice = DeviceModel.fromMap(
          Map<String, dynamic>.from(u['device'] as Map? ?? {}));
      final compat = CompatibilityService.compute(me.device, uDevice, dist);
      return (u, compat, dist);
    }).toList()
      ..sort((a, b) => b.$2.score.compareTo(a.$2.score));

    setState(() {
      _results = results;
      _scanning = false;
    });
  }

  Future<void> _sendRequest(Map<String, dynamic> donor) async {
    final auth = context.read<AuthService>();
    final fs = context.read<FirestoreService>();
    try {
      await SessionService(fs).createRequest(
        senderUid: auth.uid,
        receiverUid: donor['uid'] as String,
        featureType: 'battery',
        credits: AppConstants.batteryDonorCredits,
      );
      if (!mounted) return;
      setState(() => _sentFor = donor['uid'] as String);
      _showWhatsAppSheet(donor);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showWhatsAppSheet(Map<String, dynamic> donor) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✅ Request Sent!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Waiting for ${donor['name'] ?? 'donor'} to accept.',
                style: const TextStyle(color: AppColors.textMed)),
            const SizedBox(height: 24),
            AppButton(
              label: '💬 Notify via WhatsApp (optional)',
              outlined: true,
              color: const Color(0xFF25D366),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await WhatsAppService.sendNotify(
                    phone: donor['phone'] as String? ?? '',
                    featureType: 'battery',
                    credits: AppConstants.batteryDonorCredits,
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('$e')));
                  }
                }
              },
            ),
            const SizedBox(height: 10),
            AppButton(
                label: 'I will wait in-app',
                onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  void _showUserDetails(
      Map<String, dynamic> user, CompatibilityResult compat, double dist) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final av =
        AppConstants.avatarEmoji[user['avatar'] as String? ?? 'panda'] ?? '🐼';
    final canReq = compat.canProceed;
    final compatColor = compat.label == 'Good'
        ? AppColors.batteryGreen
        : compat.label == 'Risky'
            ? AppColors.warning
            : AppColors.danger;
    final uDevice = DeviceModel.fromMap(
        Map<String, dynamic>.from(user['device'] as Map? ?? {}));
    final uid = user['uid'] as String? ?? '';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(av, style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['name'] as String? ?? 'Unknown',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 18)),
                      Text(
                          'Battery: ${uDevice.batteryPercentage}% · ${dist.round()}m away',
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.textLight)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: compatColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(compat.label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: compatColor))),
            const SizedBox(height: 20),
            canReq
                ? AppButton(
                    label:
                        'Send Request · +${AppConstants.batteryDonorCredits} ⚡',
                    onPressed: _sentFor == uid
                        ? null
                        : () {
                            Navigator.pop(context);
                            _sendRequest(user);
                          },
                  )
                : Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Text(
                        'Not Supported — Incompatible devices for wireless charging',
                        style:
                            TextStyle(color: AppColors.danger, fontSize: 14))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            gradient: isDark ? AppColors.darkBg : AppColors.lightBg),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 20, 4),
                child: Row(
                  children: [
                    IconButton(
                        icon: Icon(Icons.arrow_back_ios_rounded,
                            color: isDark
                                ? AppColors.starWhite
                                : AppColors.textDark),
                        onPressed: () => Navigator.pop(context)),
                    Text('Search Battery Source',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.starWhite
                                : AppColors.textDark)),
                  ],
                ),
              ),

              // Radius selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: PastelCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final r in [5.0, 20.0, 100.0])
                        GestureDetector(
                          onTap: () => setState(() => _radius = r),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 22, vertical: 9),
                            decoration: BoxDecoration(
                                color: _radius == r
                                    ? AppColors.primaryBlue
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20)),
                            child: Text('${r.round()}m',
                                style: TextStyle(
                                    color: _radius == r
                                        ? Colors.white
                                        : AppColors.textMed,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AppButton(
                    label: '📡 Scan Nearby',
                    loading: _scanning,
                    onPressed: _scan),
              ),
              const SizedBox(height: 16),

              // Circle visualization
              if (!_scanning && _results.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 300,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Center user avatar
                        CircleAvatar(
                          radius: 25,
                          backgroundColor:
                              AppColors.primaryBlue.withOpacity(0.2),
                          child: Text(
                            context
                                        .read<FirestoreService>()
                                        .currentUser
                                        ?.name
                                        .isNotEmpty ==
                                    true
                                ? context
                                    .read<FirestoreService>()
                                    .currentUser!
                                    .name[0]
                                    .toUpperCase()
                                : 'Y',
                            style: const TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        // 5m circle
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryBlue.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              '5m',
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        // 50m circle
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryBlue.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              '50m',
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        // 100m circle
                        Container(
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryBlue.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        // Nearby users positioned on circles
                        ..._results.map((result) {
                          final (user, compat, dist) = result;
                          final angle = (_results.indexOf(result) *
                                  360 /
                                  _results.length) *
                              (3.14159 / 180);
                          final radius = dist < 5
                              ? 35.0
                              : dist < 50
                                  ? 85.0
                                  : 135.0;
                          final x = radius * cos(angle);
                          final y = radius * sin(angle);

                          return Positioned(
                            left: 150 +
                                x -
                                15, // Center offset minus avatar radius
                            top: 150 + y - 15,
                            child: GestureDetector(
                              onTap: () => _showUserDetails(user, compat, dist),
                              child: CircleAvatar(
                                radius: 15,
                                backgroundColor:
                                    AppColors.primaryBlue.withOpacity(0.8),
                                child: Text(
                                  (user['name'] as String?)?.isNotEmpty == true
                                      ? (user['name'] as String)[0]
                                          .toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

              if (_locDenied)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: PermissionBlockCard(
                    emoji: '📍',
                    title: 'Location Required',
                    description: 'Location is needed to find nearby users. '
                        'Please enable it in Settings.',
                  ),
                )
              else if (_scanning)
                const Expanded(child: Center(child: LoadingScanAnimation()))
              else if (_results.isEmpty)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('📡', style: TextStyle(fontSize: 52)),
                        SizedBox(height: 12),
                        Text('Tap Scan to find nearby donors',
                            style: TextStyle(color: AppColors.textLight)),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final (user, compat, dist) = _results[i];
                      final av = AppConstants.avatarEmoji[
                              user['avatar'] as String? ?? 'panda'] ??
                          '🐼';
                      final canReq = compat.canProceed;
                      final compatColor = compat.label == 'Good'
                          ? AppColors.batteryGreen
                          : compat.label == 'Risky'
                              ? AppColors.warning
                              : AppColors.danger;
                      final uDevice = DeviceModel.fromMap(
                          Map<String, dynamic>.from(
                              user['device'] as Map? ?? {}));
                      final uid = user['uid'] as String? ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PastelCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(av,
                                      style: const TextStyle(fontSize: 34)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            user['name'] as String? ??
                                                'Unknown',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15)),
                                        Text(
                                            'Battery: ${uDevice.batteryPercentage}%  ·  ${dist.round()}m away',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textLight)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                          color: compatColor.withValues(
                                              alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: Text(compat.label,
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: compatColor))),
                                ],
                              ),
                              const SizedBox(height: 12),
                              canReq
                                  ? AppButton(
                                      label:
                                          'Send Request  ·  +${AppConstants.batteryDonorCredits} ⚡',
                                      onPressed: _sentFor == uid
                                          ? null
                                          : () => _sendRequest(user),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                          color: AppColors.danger
                                              .withValues(alpha: 0.07),
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: const Text(
                                          'Not Supported — Incompatible devices for wireless charging',
                                          style: TextStyle(
                                              color: AppColors.danger,
                                              fontSize: 12))),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
