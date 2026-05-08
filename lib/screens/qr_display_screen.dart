import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/session_model.dart';
import '../theme/app_colors.dart';

class QrDisplayScreen extends StatefulWidget {
  final String sessionId;
  const QrDisplayScreen({super.key, required this.sessionId});

  @override
  State<QrDisplayScreen> createState() => _QrDisplayScreenState();
}

class _QrDisplayScreenState extends State<QrDisplayScreen> {
  SessionModel? _session;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final fs = context.read<FirestoreService>();
    final session = await fs.getSession(widget.sessionId);
    if (mounted) {
      setState(() => _session = session);
    }
  }

  String? get _qrData {
    if (_session == null) return null;
    final code = _session!.metadata['verify_code'] as String?;
    if (code == null) return null;

    final auth = context.read<AuthService>();
    return '${widget.sessionId}|${auth.uid}|${_session!.senderUserId}|$code';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qrData = _qrData;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            gradient: isDark ? AppColors.darkBg : AppColors.lightBg),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 16, 16),
                child: Row(
                  children: [
                    IconButton(
                        icon: Icon(Icons.arrow_back_ios_rounded,
                            color: isDark
                                ? AppColors.starWhite
                                : AppColors.textDark),
                        onPressed: () => Navigator.pop(context)),
                    Expanded(
                      child: Text('Show QR Code',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.starWhite
                                  : AppColors.textDark)),
                    ),
                  ],
                ),
              ),

              // Instructions
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Have the requester scan this QR code to complete the verification.',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.textMed, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 32),

              // QR Code
              if (qrData != null)
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 250,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                )
              else
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),

              // Alternative passcode option
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Or share the passcode manually:',
                      style: TextStyle(fontSize: 14, color: AppColors.textMed),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _session?.metadata['verify_code'] as String? ??
                            'Loading...',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
