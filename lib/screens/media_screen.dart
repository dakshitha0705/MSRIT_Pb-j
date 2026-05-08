import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/share_to_friend_sheet.dart';

class MediaScreen extends StatefulWidget {
  const MediaScreen({super.key});
  @override
  State<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> {
  PlatformFile? _picked;
  bool _sharing = false;
  String _type = 'photo';

  Future<void> _pickMedia() async {
    final type = _type == 'photo' ? FileType.image : FileType.video;
    final result = await FilePicker.platform.pickFiles(type: type);
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
      if (result.status == ShareResultStatus.success) {
        final auth = context.read<AuthService>();
        final fs = context.read<FirestoreService>();
        if (auth.isLoggedIn) {
          final current = fs.currentUser?.credits ?? 0;
          await fs.updateUserFields(auth.uid, {'credits': current + 5});
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('+5 credits for sharing media!'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Color(0xFF22C55E)));
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
    final accentC =
        _type == 'photo' ? const Color(0xFFEC4899) : const Color(0xFF8B5CF6);

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
                    child: Text('Media Sharing',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.starWhite
                                : AppColors.textDark))),
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
                      Text('+5 per share',
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
                  // Type toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      _TypeBtn(
                          label: 'Photos',
                          icon: Icons.photo_rounded,
                          selected: _type == 'photo',
                          isDark: isDark,
                          onTap: () => setState(() {
                                _type = 'photo';
                                _picked = null;
                              })),
                      _TypeBtn(
                          label: 'Videos',
                          icon: Icons.videocam_rounded,
                          selected: _type == 'video',
                          isDark: isDark,
                          onTap: () => setState(() {
                                _type = 'video';
                                _picked = null;
                              })),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  // Pick card
                  GestureDetector(
                    onTap: _pickMedia,
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
                                  ? accentC.withOpacity(0.5)
                                  : (isDark
                                      ? Colors.white.withOpacity(0.07)
                                      : Colors.black.withOpacity(0.07)),
                              width: _picked != null ? 2 : 1)),
                      child: Column(children: [
                        Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                                color: accentC.withOpacity(0.1),
                                shape: BoxShape.circle),
                            child: Icon(
                                _picked != null
                                    ? (_type == 'photo'
                                        ? Icons.image_rounded
                                        : Icons.videocam_rounded)
                                    : Icons.add_photo_alternate_rounded,
                                color: accentC,
                                size: 34)),
                        const SizedBox(height: 16),
                        Text(
                            _picked != null
                                ? _picked!.name
                                : 'Tap to choose a ${_type == "photo" ? "photo" : "video"}',
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
                                : (_type == 'photo'
                                    ? 'JPG, PNG, HEIC supported'
                                    : 'MP4, MOV, AVI supported'),
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white.withOpacity(0.4)
                                    : Colors.black.withOpacity(0.4))),
                      ]),
                    ),
                  ),
                  if (_picked != null) ...[
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => ShareToFriendSheet.show(context,
                          type: ShareType.media,
                          file: File(_picked!.path!),
                          fileName: _picked!.name,
                          creditsEarned: 5),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF6366F1),
                                  Color(0xFF4F46E5),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      const Color(0xFF6366F1).withValues(alpha: 0.4),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5))
                            ]),
                        child: const Row(children: [
                          SizedBox(width: 48, height: 48,
                            child: Icon(Icons.people_rounded,
                                color: Colors.white, size: 26)),
                          SizedBox(width: 14),
                          Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('Send to Friend',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16)),
                            Text('Share in-app & earn +5 credits',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ])),
                          Icon(Icons.arrow_forward_ios_rounded,
                              color: Colors.white70, size: 16),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _sharing ? null : _share,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [
                                  accentC,
                                  Color.lerp(accentC, Colors.indigo, 0.4)!
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: accentC.withOpacity(0.4),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5))
                            ]),
                        child: Row(children: [
                          Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(14)),
                              child: _sharing
                                  ? const Center(
                                      child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2)))
                                  : const Icon(Icons.share_rounded,
                                      color: Colors.white, size: 24)),
                          const SizedBox(width: 14),
                          const Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text('Share Media',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16)),
                                Text('Nearby Share, WhatsApp, Bluetooth & more',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 12)),
                              ])),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              color: Colors.white70, size: 16),
                        ]),
                      ),
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
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected, isDark;
  final VoidCallback onTap;
  const _TypeBtn(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.isDark,
      required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
      child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                  color: selected
                      ? (isDark ? const Color(0xFF1E3A5F) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selected && !isDark
                      ? [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2))
                        ]
                      : null),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon,
                    size: 16,
                    color: selected
                        ? const Color(0xFF2563EB)
                        : (isDark
                            ? Colors.white.withOpacity(0.4)
                            : Colors.black.withOpacity(0.4))),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected
                            ? const Color(0xFF2563EB)
                            : (isDark
                                ? Colors.white.withOpacity(0.5)
                                : Colors.black.withOpacity(0.45)))),
              ]))));
}
