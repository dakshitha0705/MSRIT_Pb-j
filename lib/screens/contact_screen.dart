import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../widgets/share_to_friend_sheet.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});
  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _jobCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _showExtra = false;
  String? _msg;
  bool _isError = false;

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _phoneCtrl,
      _emailCtrl,
      _companyCtrl,
      _jobCtrl,
      _addressCtrl,
      _websiteCtrl,
      _noteCtrl
    ]) c.dispose();
    super.dispose();
  }

  String get _shareText {
    final lines = <String>['Contact Card\n'];
    if (_nameCtrl.text.isNotEmpty) lines.add('Name: \${_nameCtrl.text.trim()}');
    if (_phoneCtrl.text.isNotEmpty)
      lines.add('Phone: \${_phoneCtrl.text.trim()}');
    if (_emailCtrl.text.isNotEmpty)
      lines.add('Email: \${_emailCtrl.text.trim()}');
    if (_companyCtrl.text.isNotEmpty)
      lines.add('Company: \${_companyCtrl.text.trim()}');
    if (_jobCtrl.text.isNotEmpty) lines.add('Job: \${_jobCtrl.text.trim()}');
    if (_addressCtrl.text.isNotEmpty)
      lines.add('Address: \${_addressCtrl.text.trim()}');
    if (_websiteCtrl.text.isNotEmpty)
      lines.add('Website: \${_websiteCtrl.text.trim()}');
    if (_noteCtrl.text.isNotEmpty) lines.add('Note: \${_noteCtrl.text.trim()}');
    lines.add('\nSent via AmpUp');
    return lines.join('\n');
  }

  bool get _hasData => _nameCtrl.text.isNotEmpty || _phoneCtrl.text.isNotEmpty;

  Future<void> _shareNative() async {
    if (!_hasData) {
      _showMsg('Enter a name or phone first.', error: true);
      return;
    }
    final result =
        await Share.share(_shareText, subject: 'Contact Card from AmpUp');
    // Award credits
    if (mounted) {
      try {
        final auth = context.read<AuthService>();
        final fs = context.read<FirestoreService>();
        if (auth.isLoggedIn) {
          final current = fs.currentUser?.credits ?? 0;
          await fs.updateUserFields(auth.uid, {'credits': current + 5});
          _showMsg('+2 credits earned!');
        }
      } catch (e) {/* ignore */}
    }
  }

  Future<void> _copyToClipboard() async {
    if (!_hasData) {
      _showMsg('Enter a name or phone first.', error: true);
      return;
    }
    await Clipboard.setData(ClipboardData(text: _shareText));
    _showMsg('Copied to clipboard!');
  }

  void _showMsg(String msg, {bool error = false}) {
    setState(() {
      _msg = msg;
      _isError = error;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _msg = null);
    });
  }

  void _clearAll() {
    for (final c in [
      _nameCtrl,
      _phoneCtrl,
      _emailCtrl,
      _companyCtrl,
      _jobCtrl,
      _addressCtrl,
      _websiteCtrl,
      _noteCtrl
    ]) c.clear();
    setState(() => _msg = null);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.read<FirestoreService>().currentUser;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            gradient: isDark ? AppColors.darkBg : AppColors.lightBg),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
              child: Row(children: [
                IconButton(
                    icon: Icon(Icons.arrow_back_ios_rounded,
                        color:
                            isDark ? AppColors.starWhite : AppColors.textDark),
                    onPressed: () => Navigator.pop(context)),
                Expanded(
                    child: Text('Contact Sharing',
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
                const SizedBox(width: 8),
                GestureDetector(
                    onTap: _clearAll,
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10)),
                        child: Text('Clear',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white.withOpacity(0.5)
                                    : Colors.black.withOpacity(0.45))))),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user != null)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _nameCtrl.text = user.name;
                              _phoneCtrl.text = user.phone;
                              _emailCtrl.text = user.email;
                            });
                            _showMsg('Filled from your profile!');
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF2563EB),
                                      Color(0xFF4F46E5)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                      color: const Color(0xFF2563EB)
                                          .withOpacity(0.25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4))
                                ]),
                            child: const Row(children: [
                              Icon(Icons.person_rounded,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                  child: Text('Auto-fill from my profile',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14))),
                              Icon(Icons.arrow_forward_ios_rounded,
                                  color: Colors.white70, size: 14),
                            ]),
                          ),
                        ),
                      const SizedBox(height: 16),
                      _Card(
                          isDark: isDark,
                          child: Column(children: [
                            _Label('BASIC INFO', isDark: isDark),
                            const SizedBox(height: 12),
                            _Field(
                                ctrl: _nameCtrl,
                                label: 'Full Name *',
                                icon: Icons.person_outline_rounded,
                                isDark: isDark),
                            const SizedBox(height: 10),
                            _Field(
                                ctrl: _phoneCtrl,
                                label: 'Phone Number *',
                                icon: Icons.phone_outlined,
                                keyboard: TextInputType.phone,
                                isDark: isDark),
                            const SizedBox(height: 10),
                            _Field(
                                ctrl: _emailCtrl,
                                label: 'Email Address',
                                icon: Icons.email_outlined,
                                keyboard: TextInputType.emailAddress,
                                isDark: isDark),
                          ])),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => setState(() => _showExtra = !_showExtra),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.04)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.07)
                                      : Colors.black.withOpacity(0.07))),
                          child: Row(children: [
                            Icon(
                                _showExtra
                                    ? Icons.remove_circle_outline_rounded
                                    : Icons.add_circle_outline_rounded,
                                color: const Color(0xFF2563EB),
                                size: 20),
                            const SizedBox(width: 10),
                            Text(
                                _showExtra
                                    ? 'Hide extra info'
                                    : 'Add extra info',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2563EB))),
                          ]),
                        ),
                      ),
                      if (_showExtra) ...[
                        const SizedBox(height: 12),
                        _Card(
                            isDark: isDark,
                            child: Column(children: [
                              _Label('WORK', isDark: isDark),
                              const SizedBox(height: 12),
                              _Field(
                                  ctrl: _companyCtrl,
                                  label: 'Company',
                                  icon: Icons.business_rounded,
                                  isDark: isDark),
                              const SizedBox(height: 10),
                              _Field(
                                  ctrl: _jobCtrl,
                                  label: 'Job Title',
                                  icon: Icons.work_outline_rounded,
                                  isDark: isDark),
                            ])),
                        const SizedBox(height: 12),
                        _Card(
                            isDark: isDark,
                            child: Column(children: [
                              _Label('MORE DETAILS', isDark: isDark),
                              const SizedBox(height: 12),
                              _Field(
                                  ctrl: _addressCtrl,
                                  label: 'Address',
                                  icon: Icons.location_on_outlined,
                                  isDark: isDark,
                                  maxLines: 2),
                              const SizedBox(height: 10),
                              _Field(
                                  ctrl: _websiteCtrl,
                                  label: 'Website',
                                  icon: Icons.language_rounded,
                                  keyboard: TextInputType.url,
                                  isDark: isDark),
                              const SizedBox(height: 10),
                              _Field(
                                  ctrl: _noteCtrl,
                                  label: 'Note',
                                  icon: Icons.note_outlined,
                                  isDark: isDark,
                                  maxLines: 3),
                            ])),
                      ],
                      if (_msg != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: _isError
                                  ? AppColors.danger.withOpacity(0.1)
                                  : AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _isError
                                      ? AppColors.danger.withOpacity(0.3)
                                      : AppColors.success.withOpacity(0.3))),
                          child: Row(children: [
                            Icon(
                                _isError
                                    ? Icons.error_outline_rounded
                                    : Icons.check_circle_outline_rounded,
                                color: _isError
                                    ? AppColors.danger
                                    : AppColors.success,
                                size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(_msg!,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: _isError
                                            ? AppColors.danger
                                            : AppColors.success,
                                        fontWeight: FontWeight.w500))),
                          ]),
                        ),
                      ],
                      const SizedBox(height: 20),
                      _Label('SHARE VIA', isDark: isDark),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _shareNative,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF25D366),
                                    Color(0xFF128C7E)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFF25D366)
                                        .withOpacity(0.35),
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
                                child: const Icon(Icons.share_rounded,
                                    color: Colors.white, size: 24)),
                            const SizedBox(width: 14),
                            const Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text('Share Contact',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16)),
                                  Text(
                                      'Nearby Share, WhatsApp, Bluetooth & more',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 12)),
                                ])),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                color: Colors.white70, size: 16),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => ShareToFriendSheet.show(context,
                            type: ShareType.contact,
                            contactData: {
                              'name': _nameCtrl.text.trim(),
                              'phone': _phoneCtrl.text.trim(),
                              'email': _emailCtrl.text.trim(),
                            },
                            creditsEarned: 5),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.04)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: const Color(0xFF6366F1)
                                      .withOpacity(0.3),
                                  width: 1.5)),
                          child: Row(children: [
                            Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.people_rounded,
                                    color: Color(0xFF6366F1), size: 20)),
                            const SizedBox(width: 14),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text('Send to Friend',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A))),
                                  Text('Share in-app & earn +5 credits',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.white.withOpacity(0.4)
                                              : Colors.black
                                                  .withOpacity(0.4))),
                                ])),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _copyToClipboard,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.04)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color:
                                      const Color(0xFF6366F1).withOpacity(0.3),
                                  width: 1.5)),
                          child: Row(children: [
                            Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.copy_rounded,
                                    color: Color(0xFF6366F1), size: 20)),
                            const SizedBox(width: 14),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text('Copy to Clipboard',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A))),
                                  Text('Paste in any app manually',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.white.withOpacity(0.4)
                                              : Colors.black.withOpacity(0.4))),
                                ])),
                          ]),
                        ),
                      ),
                    ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final bool isDark;
  final Widget child;
  const _Card({required this.isDark, required this.child});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.07)
                  : Colors.black.withOpacity(0.07))),
      child: child);
}

class _Label extends StatelessWidget {
  final String text;
  final bool isDark;
  const _Label(this.text, {required this.isDark});
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: isDark
              ? Colors.white.withOpacity(0.35)
              : Colors.black.withOpacity(0.35)));
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final bool isDark;
  final TextInputType keyboard;
  final int maxLines;
  const _Field(
      {required this.ctrl,
      required this.label,
      required this.icon,
      required this.isDark,
      this.keyboard = TextInputType.text,
      this.maxLines = 1});
  @override
  Widget build(BuildContext context) => TextField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: TextStyle(
          fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A)),
      decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
              fontSize: 13,
              color: isDark
                  ? Colors.white.withOpacity(0.45)
                  : Colors.black.withOpacity(0.45)),
          prefixIcon: Icon(icon,
              size: 18,
              color: isDark
                  ? Colors.white.withOpacity(0.35)
                  : Colors.black.withOpacity(0.3)),
          filled: true,
          fillColor: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12)));
}
