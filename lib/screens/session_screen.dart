import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firestore_service.dart';
import '../services/session_service.dart';
import '../services/nearby_service.dart';
import '../models/session_model.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/app_button.dart';
import '../widgets/pastel_card.dart';
import 'qr_display_screen.dart';
import 'passcode_entry_screen.dart';
import 'qr_screen.dart';

class SessionScreen extends StatefulWidget {
  final String sessionId;
  final bool isSender;
  const SessionScreen(
      {super.key, required this.sessionId, required this.isSender});
  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final int _elapsed = 0;
  bool _stopping = false;

  Future<Map<String, dynamic>?> _getOtherUserDetails(
      SessionModel session) async {
    final fs = context.read<FirestoreService>();
    final otherUid =
        widget.isSender ? session.receiverUserId : session.senderUserId;
    final user = await fs.getUserById(otherUid);
    if (user == null) return null;
    return {
      'uid': user.userId,
      'name': user.name,
      'username': user.username,
      'email': user.email,
      'phone': user.phone,
    };
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMed)),
          ),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontSize: 14, color: AppColors.textDark)),
          ),
        ],
      ),
    );
  }

  Future<void> _openInMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _shareLocation(String sessionId, {required bool isLive}) async {
    final pos = await NearbyService.getLocation();
    if (pos == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to get location')),
        );
      }
      return;
    }
    // For simplicity, use lat,lng as address text. In real app, reverse geocode.
    final address =
        '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
    await SessionService(context.read<FirestoreService>())
        .shareLocation(sessionId, address, pos.latitude, pos.longitude, isLive);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isLive
              ? 'Live location shared as current snapshot'
              : 'Address shared successfully'),
        ),
      );
    }
  }

  Future<void> _shareCurrentAddress(String sessionId) async {
    await _shareLocation(sessionId, isLive: false);
  }

  Future<void> _shareLiveLocation(String sessionId) async {
    await _shareLocation(sessionId, isLive: true);
  }

  Future<void> _verifyWithQr() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => QrScreen(onScanned: (code) => code)),
    );

    if (result != null && mounted) {
      final parts = result.split('|');
      if (parts.length >= 4 && parts[0] == widget.sessionId) {
        final code = parts[3];
        final fs = context.read<FirestoreService>();
        final success =
            await SessionService(fs).verifySession(widget.sessionId, code);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Verification successful! Credits transferred.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Invalid QR code. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Invalid QR code for this session.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fs = context.read<FirestoreService>();
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            gradient: isDark ? AppColors.darkBg : AppColors.lightBg),
        child: SafeArea(
          child: StreamBuilder<SessionModel?>(
            stream: fs.sessionStream(widget.sessionId),
            builder: (ctx, snap) {
              final session = snap.data;
              if (session == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      IconButton(
                          icon: Icon(Icons.arrow_back_ios_rounded,
                              color: isDark
                                  ? AppColors.starWhite
                                  : AppColors.textDark),
                          onPressed: () => Navigator.pop(context)),
                      Text(
                          session.status == 'accepted'
                              ? 'Verify Session'
                              : 'Active Session',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.starWhite
                                  : AppColors.textDark)),
                    ]),
                    const SizedBox(height: 20),
                    PastelCard(
                        child: Column(children: [
                      Text(session.featureType.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textLight,
                              letterSpacing: 1)),
                      const SizedBox(height: 8),
                      if (session.status == 'accepted')
                        const Text('WAITING FOR VERIFICATION',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryBlue))
                      else
                        Text(AppFormatters.duration(_elapsed),
                            style: const TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryBlue)),
                      const SizedBox(height: 4),
                      Text('Status: ${session.status}',
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.textMed)),
                      const SizedBox(height: 4),
                      Text('Credits: ${session.credits} ⚡',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                    ])),
                    const SizedBox(height: 20),
                    // Contact details — only reveal AFTER acceptance (privacy guard)
                    if (session.status == 'requested' && !widget.isSender)
                      PastelCard(
                        child: Row(children: [
                          const Text('⏳', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Waiting for the lender to respond…\nContact details will appear once accepted.',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textMed,
                                  height: 1.4),
                            ),
                          ),
                        ]),
                      )
                    else if (session.status == 'rejected')
                      PastelCard(
                        child: Row(children: [
                          const Text('❌', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'This request was declined. No contact details shared.',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.danger,
                                  height: 1.4),
                            ),
                          ),
                        ]),
                      )
                    else
                      // accepted / completed / lender view
                      FutureBuilder<Map<String, dynamic>?>(
                        future: _getOtherUserDetails(session),
                        builder: (ctx, userSnap) {
                          final user = userSnap.data;
                          if (user == null) return const SizedBox();
                          return PastelCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Contact Details',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.starWhite
                                            : AppColors.textDark)),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                    'Name', user['name'] ?? 'Unknown'),
                                _buildDetailRow('Username',
                                    '@${user['username'] ?? 'unknown'}'),
                                _buildDetailRow(
                                    'Phone', user['phone'] ?? 'Not provided'),
                                if (session.metadata['landmark'] != null)
                                  _buildDetailRow('Nearest Landmark',
                                      session.metadata['landmark']),
                                if (session.metadata['shared_address'] != null)
                                  _buildDetailRow('Shared Address',
                                      session.metadata['shared_address']),
                                if (session.metadata['shared_live'] == true)
                                  _buildDetailRow(
                                      'Location Type', 'Live snapshot'),
                                if (session.metadata['shared_lat'] != null &&
                                    session.metadata['shared_lng'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: AppButton(
                                      label: 'Open in Maps',
                                      onPressed: () => _openInMaps(
                                          session.metadata['shared_lat'],
                                          session.metadata['shared_lng']),
                                    ),
                                  ),
                                // Optional location sharing — lender only, after accept
                                if (widget.isSender &&
                                    session.status == 'accepted')
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 16),
                                      const Text(
                                          'Share Additional Location (Optional)',
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textMed)),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: AppButton(
                                              label: 'Share Current Address',
                                              onPressed: () =>
                                                  _shareCurrentAddress(
                                                      session.sessionId),
                                              outlined: true,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: AppButton(
                                              label: 'Share Live Location',
                                              onPressed: () =>
                                                  _shareLiveLocation(
                                                      session.sessionId),
                                              outlined: true,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    const Spacer(),

                    // Show different actions based on status and role
                    if (session.status == 'accepted' &&
                        session.featureType == 'battery')
                      if (widget.isSender)
                        // Sender shows QR
                        Column(
                          children: [
                            AppButton(
                              label: 'Show QR Code',
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QrDisplayScreen(
                                      sessionId: widget.sessionId),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Show this QR code to the requester, or share the passcode manually.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textLight,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                      else
                        // Receiver shows verification options
                        Column(
                          children: [
                            AppButton(
                              label: 'Scan QR Code',
                              onPressed: _verifyWithQr,
                            ),
                            const SizedBox(height: 12),
                            AppButton(
                              label: 'Enter Passcode',
                              outlined: true,
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PasscodeEntryScreen(
                                      sessionId: widget.sessionId),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Scan the donor\'s QR code or enter the passcode they show you.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textLight,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                    else
                      // Regular session controls
                      AppButton(
                          label: 'Stop Session',
                          color: AppColors.danger,
                          loading: _stopping,
                          onPressed: () async {
                            setState(() => _stopping = true);
                            await SessionService(fs).completeSession(
                                widget.sessionId,
                                senderStopped: widget.isSender);
                            if (mounted) Navigator.pop(context);
                          }),

                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
