import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/share_to_friend_sheet.dart';

class FileScreen extends StatefulWidget {
  const FileScreen({super.key});
  @override
  State<FileScreen> createState() => _FileScreenState();
}

class _FileScreenState extends State<FileScreen> {
  PlatformFile? _picked;
  bool _sharing = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      setState(() => _picked = result.files.first);
    }
  }

  Future<void> _share() async {
    if (_picked?.path == null) return;
    setState(() => _sharing = true);
    try {
      final result = await Share.shareXFiles(
        [XFile(_picked!.path!)],
        text: 'Shared via AmpUp',
        subject: _picked!.name,
      );
      // Award credits if share was completed
      if (result.status == ShareResultStatus.success) {
        final auth = context.read<AuthService>();
        final fs = context.read<FirestoreService>();
        if (auth.isLoggedIn) {
          final current = fs.currentUser?.credits ?? 0;
          final fileMB = (_picked!.size / (1024 * 1024));
          final earned = fileMB < 10 ? 10 : 20;
          await fs.updateUserFields(auth.uid, {
            'credits': current + earned,
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('+\$earned credits for sharing a file!'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: const Color(0xFF22C55E)));
          }
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  String _sizeLabel(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            gradient: isDark ? AppColors.darkBg : AppColors.lightBg),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
              child: Row(children: [
                IconButton(
                    icon: Icon(Icons.arrow_back_ios_rounded,
                        color:
                            isDark ? AppColors.starWhite : AppColors.textDark),
                    onPressed: () => Navigator.pop(context)),
                Expanded(
                    child: Text('File Sharing',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.starWhite
                                : AppColors.textDark))),
                // Credits reward badge
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF22C55E).withOpacity(0.3))),
                    child: const Row(children: [
                      Icon(Icons.bolt_rounded,
                          color: Color(0xFF22C55E), size: 13),
                      SizedBox(width: 3),
                      Text('+10/+20 per share',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF22C55E))),
                    ])),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  // Pick file card
                  GestureDetector(
                    onTap: _pickFile,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.04)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _picked != null
                                  ? const Color(0xFF2563EB).withOpacity(0.5)
                                  : (isDark
                                      ? Colors.white.withOpacity(0.07)
                                      : Colors.black.withOpacity(0.07)),
                              width: _picked != null ? 2 : 1),
                          boxShadow: _picked != null
                              ? [
                                  BoxShadow(
                                      color: const Color(0xFF2563EB)
                                          .withOpacity(0.12),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4))
                                ]
                              : null),
                      child: Column(children: [
                        Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withOpacity(0.1),
                                shape: BoxShape.circle),
                            child: Icon(
                                _picked != null
                                    ? Icons.insert_drive_file_rounded
                                    : Icons.upload_file_rounded,
                                color: const Color(0xFF2563EB),
                                size: 34)),
                        const SizedBox(height: 16),
                        Text(
                            _picked != null
                                ? _picked!.name
                                : 'Tap to choose a file',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A))),
                        const SizedBox(height: 6),
                        Text(
                            _picked != null
                                ? _sizeLabel(_picked!.size)
                                : 'Documents, PDFs, ZIPs and more',
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white.withOpacity(0.4)
                                    : Colors.black.withOpacity(0.4))),
                        if (_picked != null) ...[
                          const SizedBox(height: 14),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF2563EB).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20)),
                              child: const Text(
                                  'Tap to choose a different file',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.w500))),
                        ],
                      ]),
                    ),
                  ),

                  if (_picked != null) ...[
                    const SizedBox(height: 20),
                    // Share options
                    _buildShareOption(
                      isDark: isDark,
                      icon: Icons.share_rounded,
                      title: 'Nearby Share',
                      subtitle: 'Android AirDrop — fastest nearby transfer',
                      color: const Color(0xFF2563EB),
                      onTap: _sharing ? null : _share,
                      loading: _sharing,
                    ),
                    const SizedBox(height: 10),
                    _buildShareOption(
                      isDark: isDark,
                      icon: Icons.share_rounded,
                      title: 'Share via...',
                      subtitle: 'WhatsApp, Telegram, Email, Bluetooth & more',
                      color: const Color(0xFF8B5CF6),
                      onTap: _sharing ? null : _share,
                      loading: false,
                    ),
                    const SizedBox(height: 10),
                    _buildShareOption(
                      isDark: isDark,
                      icon: Icons.people_rounded,
                      title: 'Send to Friend',
                      subtitle: 'Share directly in-app & earn credits',
                      color: const Color(0xFF6366F1),
                      loading: false,
                      onTap: () {
                        final fileMB = _picked!.size / (1024 * 1024);
                        ShareToFriendSheet.show(context,
                          type: ShareType.file,
                          file: File(_picked!.path!),
                          fileName: _picked!.name,
                          creditsEarned: fileMB > 10 ? 20 : 10);
                      },
                    ),
                  ] else ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.04)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.07)
                                  : Colors.black.withOpacity(0.07))),
                      child: Column(children: [
                        _InfoRow(
                            icon: Icons.share_rounded,
                            text: 'Nearby Share — like AirDrop for Android',
                            color: const Color(0xFF2563EB),
                            isDark: isDark),
                        const SizedBox(height: 10),
                        _InfoRow(
                            icon: Icons.share_rounded,
                            text: 'WhatsApp, Bluetooth, Email & more',
                            color: const Color(0xFF8B5CF6),
                            isDark: isDark),
                        const SizedBox(height: 10),
                        _InfoRow(
                            icon: Icons.bolt_rounded,
                            text: 'Earn +2 credits every time you share',
                            color: const Color(0xFF22C55E),
                            isDark: isDark),
                      ]),
                    ),
                  ],
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
    required bool loading,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [color, Color.lerp(color, Colors.indigo, 0.4)!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ]),
          child: Row(children: [
            Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12)),
                child: loading
                    ? const Center(
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2)))
                    : Icon(icon, color: Colors.white, size: 22)),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  Text(subtitle,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 11)),
                ])),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white70, size: 16),
          ]),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool isDark;
  const _InfoRow(
      {required this.icon,
      required this.text,
      required this.color,
      required this.isDark});
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? Colors.white.withOpacity(0.7)
                        : const Color(0xFF374151)))),
      ]);
}
