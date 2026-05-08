import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/session_service.dart';
import '../services/location_service.dart';
import '../services/whatsapp_service.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/app_button.dart';
import '../widgets/nearby_users_widget.dart';
import '../widgets/pastel_card.dart';
import '../widgets/loading_scan_animation.dart';
import '../widgets/permission_block_card.dart';

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});
  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  double _radius = 100;
  bool _scanning = false, _locDenied = false;
  List<Map<String, dynamic>> _results = [];

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _results.clear();
      _locDenied = false;
    });
    final fs = context.read<FirestoreService>();
    final pos = await LocationService.getCurrentPosition();
    if (pos == null) {
      setState(() {
        _scanning = false;
        _locDenied = true;
      });
      return;
    }
    final nearby = await fs.getNearbyUsers(
        pos.latitude, pos.longitude, _radius / 1000);
    setState(() {
      _results = nearby;
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
          featureType: 'data',
          credits: AppConstants.dataShareDonorCredits);
      if (!mounted) return;
      _showWhatsApp(donor);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  void _showWhatsApp(Map<String, dynamic> donor) {
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('✅ Request Sent!',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                    'Waiting for ${donor['name']} to accept and enable hotspot.',
                    style: const TextStyle(color: AppColors.textMed),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                AppButton(
                    label: '💬 Notify via WhatsApp',
                    outlined: true,
                    color: const Color(0xFF25D366),
                    onPressed: () async {
                      Navigator.pop(context);
                      try {
                        await WhatsAppService.sendNotify(
                            phone: donor['phone'] as String? ?? '',
                            featureType: 'data',
                            credits: AppConstants.dataShareDonorCredits);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$e')));
                        }
                      }
                    }),
                const SizedBox(height: 10),
                AppButton(
                    label: 'Done', onPressed: () => Navigator.pop(context)),
              ]),
            ));
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 20, 4),
                    child: Row(children: [
                      IconButton(
                          icon: Icon(Icons.arrow_back_ios_rounded,
                              color: isDark
                                  ? AppColors.starWhite
                                  : AppColors.textDark),
                          onPressed: () => Navigator.pop(context)),
                      Text('📶 Data Sharing',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.starWhite
                                  : AppColors.textDark)),
                    ])),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: PastelCard(
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                          for (final r in [5.0, 20.0, 100.0])
                            GestureDetector(
                                onTap: () => setState(() => _radius = r),
                                child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 22, vertical: 9),
                                    decoration: BoxDecoration(
                                        color: _radius == r
                                            ? AppColors.primaryBlue
                                            : Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: Text('${r.round()}m',
                                        style: TextStyle(
                                            color: _radius == r
                                                ? Colors.white
                                                : AppColors.textMed,
                                            fontWeight:
                                                FontWeight.w600)))),
                        ]))),
                const SizedBox(height: 12),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AppButton(
                        label: '📡 Scan for Donors',
                        loading: _scanning,
                        onPressed: _scan)),
                const SizedBox(height: 16),
                if (_locDenied)
                  const Padding(
                      padding: EdgeInsets.all(20),
                      child: PermissionBlockCard(
                          emoji: '📍',
                          title: 'Location Required',
                          description:
                              'Location permission needed to find nearby donors.'))
                else if (_scanning)
                  const Center(
                      child: Padding(
                          padding: EdgeInsets.all(40),
                          child: LoadingScanAnimation()))
                else if (_results.isEmpty)
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Center(
                                child: Text('📶',
                                    style: TextStyle(fontSize: 52))),
                            SizedBox(height: 12),
                            Center(
                                child: Text(
                                    'Tap Scan to find nearby hotspot donors',
                                    style: TextStyle(
                                        color: AppColors.textLight))),
                          ]))
                else
                  Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                          children: _results.map((u) {
                        final av =
                            AppConstants.avatarEmoji[u['avatar']] ?? '🐼';
                        return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: PastelCard(
                                child: Row(children: [
                              Text(av,
                                  style: const TextStyle(fontSize: 32)),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(u['name'] as String,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15)),
                                    Text('${u['distance']}m away',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textLight)),
                                  ])),
                              AppButton(
                                  label:
                                      'Request  +${AppConstants.dataShareDonorCredits} ⚡',
                                  height: 38,
                                  onPressed: () => _sendRequest(u)),
                            ])));
                      }).toList())),
                const SizedBox(height: 24),
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: NearbyUsersWidget(mode: 'data')),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
