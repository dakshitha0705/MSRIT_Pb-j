import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AvatarCreatorScreen extends StatefulWidget {
  const AvatarCreatorScreen({super.key});
  @override
  State<AvatarCreatorScreen> createState() => _AvatarCreatorScreenState();
}

class _AvatarCreatorScreenState extends State<AvatarCreatorScreen> {
  bool _saving = false;

  // ── Avatar options ────────────────────────────────
  String _style = 'adventurer';
  String _seed = 'AmpUp';
  String _skinTone = 'f8d5c2';
  String _hairColor = '2c1b18';
  String _eyeColor = '1e3a8a';
  String _bg = 'b6e3f4';

  static const _styles = [
    'adventurer',
    'avataaars',
    'big-ears',
    'croodles',
    'fun-emoji',
    'lorelei',
    'notionists',
    'personas',
  ];
  static const _styleLabels = [
    'Adventurer',
    'Avataaars',
    'Big Ears',
    'Croodles',
    'Fun Emoji',
    'Lorelei',
    'Notionists',
    'Personas',
  ];

  static const _skinTones = [
    'ffdbb4',
    'f8d5c2',
    'e8b89a',
    'd4956a',
    'c67c52',
    '8d5524',
    '5c3317',
  ];
  static const _hairColors = [
    '2c1b18',
    '4a312c',
    '724133',
    'a0522d',
    'c8a96e',
    'f0d090',
    'e8c8a0',
    'd4d4d4',
    '888888',
    '333333',
    '1a1a1a',
    '8b0000',
    'dc143c',
    'ff6b6b',
    'ff8c00',
    'ffd700',
    '7cfc00',
    '00ced1',
    '4169e1',
    '8a2be2',
    'ff1493',
  ];
  static const _eyeColors = [
    '1e3a8a',
    '065f46',
    '7c2d12',
    '374151',
    '111827',
    '6b21a8',
  ];
  static const _bgColors = [
    'b6e3f4',
    'c0aede',
    'd1d4f9',
    'ffd5dc',
    'd4f0e8',
    'fff3d4',
    'ffe4e1',
    'e8d5f5',
    'd5e8f5',
    'f5e8d5',
    'd5f5e8',
    'f5d5e8',
    'transparent',
  ];
  static const _seeds = [
    'AmpUp',
    'Nova',
    'Zara',
    'Kai',
    'Luna',
    'Axel',
    'Mia',
    'Leo',
    'Aria',
    'Finn',
    'Iris',
    'Rex',
    'Sage',
    'Cleo',
    'Dash',
    'Ember',
  ];

  String get _avatarUrl {
    final bg = _bg == 'transparent' ? '' : '&backgroundColor=$_bg';
    return 'https://api.dicebear.com/9.x/$_style/png'
        '?seed=$_seed'
        '&size=256'
        '$bg';
  }

  Future<void> _saveAvatar() async {
    setState(() => _saving = true);
    try {
      final uid = context.read<AuthService>().uid;
      await context
          .read<FirestoreService>()
          .updateUserFields(uid, {'avatar_url': _avatarUrl});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Avatar saved!'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  border: Border(
                      bottom: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.black.withOpacity(0.06)))),
              child: Row(children: [
                GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.black.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.close_rounded,
                            size: 18,
                            color: isDark ? Colors.white : Colors.black))),
                const SizedBox(width: 12),
                Expanded(
                    child: Text('Create Avatar',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A)))),
                GestureDetector(
                    onTap: _saving ? null : _saveAvatar,
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFF2563EB), Color(0xFF4F46E5)]),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      const Color(0xFF2563EB).withOpacity(0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3))
                            ]),
                        child: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Save',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)))),
              ]),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ── Live preview ──────────────────
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                          gradient: isDark
                              ? const LinearGradient(
                                  colors: [
                                      Color(0xFF1E3A5F),
                                      Color(0xFF0D1B3E)
                                    ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight)
                              : const LinearGradient(
                                  colors: [
                                      Color(0xFFDBEAFE),
                                      Color(0xFFE0E7FF)
                                    ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : const Color(0xFF2563EB).withOpacity(0.12))),
                      child: Column(children: [
                        // Avatar image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(80),
                          child: Image.network(
                            _avatarUrl,
                            width: 160,
                            height: 160,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.05)
                                          : Colors.black.withOpacity(0.04),
                                      borderRadius: BorderRadius.circular(80)),
                                  child: const Center(
                                      child: CircularProgressIndicator(
                                          color: Color(0xFF2563EB),
                                          strokeWidth: 2)));
                            },
                            errorBuilder: (_, __, ___) => Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(80)),
                                child: const Icon(Icons.person_rounded,
                                    color: Color(0xFF2563EB), size: 64)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('Your Avatar',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A))),
                        const SizedBox(height: 4),
                        Text('Changes update instantly',
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white.withOpacity(0.4)
                                    : Colors.black.withOpacity(0.4))),
                      ]),
                    ),

                    const SizedBox(height: 20),

                    // ── Style ─────────────────────────
                    _Section(
                      label: 'Style',
                      isDark: isDark,
                      child: SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _styles.length,
                          itemBuilder: (_, i) {
                            final sel = _style == _styles[i];
                            return GestureDetector(
                              onTap: () => setState(() => _style = _styles[i]),
                              child: Container(
                                margin: const EdgeInsets.only(right: 10),
                                child: Column(children: [
                                  AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 160),
                                      width: 58,
                                      height: 58,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                              color: sel
                                                  ? const Color(0xFF2563EB)
                                                  : Colors.transparent,
                                              width: 2.5),
                                          boxShadow: sel
                                              ? [
                                                  BoxShadow(
                                                      color: const Color(
                                                              0xFF2563EB)
                                                          .withOpacity(0.3),
                                                      blurRadius: 8)
                                                ]
                                              : null),
                                      child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.network(
                                              'https://api.dicebear.com/9.x/${_styles[i]}/png?seed=$_seed&size=58',
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Container(
                                                      color: Colors
                                                          .grey.shade200)))),
                                  const SizedBox(height: 5),
                                  Text(_styleLabels[i],
                                      style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: sel
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                          color: sel
                                              ? const Color(0xFF2563EB)
                                              : (isDark
                                                  ? Colors.white
                                                      .withOpacity(0.5)
                                                  : Colors.black
                                                      .withOpacity(0.45)))),
                                ]),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Seed / Character ──────────────
                    _Section(
                      label: 'Character',
                      isDark: isDark,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _seeds.map((s) {
                          final sel = _seed == s;
                          return GestureDetector(
                              onTap: () => setState(() => _seed = s),
                              child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                      color: sel
                                          ? const Color(0xFF2563EB)
                                          : (isDark
                                              ? Colors.white.withOpacity(0.05)
                                              : Colors.white),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: sel
                                              ? const Color(0xFF2563EB)
                                              : (isDark
                                                  ? Colors.white
                                                      .withOpacity(0.08)
                                                  : Colors.black
                                                      .withOpacity(0.08)))),
                                  child: Text(s,
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: sel
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: sel
                                              ? Colors.white
                                              : (isDark
                                                  ? Colors.white
                                                      .withOpacity(0.7)
                                                  : Colors.black
                                                      .withOpacity(0.6))))));
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Background colour ─────────────
                    _Section(
                      label: 'Background',
                      isDark: isDark,
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _bgColors.map((c) {
                          final sel = _bg == c;
                          return GestureDetector(
                              onTap: () => setState(() => _bg = c),
                              child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: c == 'transparent'
                                          ? Colors.transparent
                                          : Color(int.parse('FF$c', radix: 16)),
                                      border: Border.all(
                                          color: sel
                                              ? const Color(0xFF2563EB)
                                              : (isDark
                                                  ? Colors.white
                                                      .withOpacity(0.15)
                                                  : Colors.black
                                                      .withOpacity(0.12)),
                                          width: sel ? 3 : 1),
                                      boxShadow: sel
                                          ? [
                                              BoxShadow(
                                                  color: const Color(0xFF2563EB)
                                                      .withOpacity(0.4),
                                                  blurRadius: 8)
                                            ]
                                          : null),
                                  child: c == 'transparent'
                                      ? const Center(
                                          child: Icon(Icons.block_rounded,
                                              size: 16, color: Colors.grey))
                                      : (sel
                                          ? const Center(
                                              child: Icon(Icons.check_rounded,
                                                  size: 16,
                                                  color: Colors.white))
                                          : null)));
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Save button ───────────────────
                    GestureDetector(
                      onTap: _saving ? null : _saveAvatar,
                      child: Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFF2563EB),
                                Color(0xFF4F46E5)
                              ]),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFF2563EB)
                                        .withOpacity(0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6))
                              ]),
                          child: Center(
                              child: _saving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Text('Save Avatar',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16)))),
                    ),
                    const SizedBox(height: 8),
                    Text('Powered by DiceBear — free & open source',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.white.withOpacity(0.25)
                                : Colors.black.withOpacity(0.25))),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section wrapper ─────────────────────────────────
class _Section extends StatelessWidget {
  final String label;
  final bool isDark;
  final Widget child;
  const _Section(
      {required this.label, required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: isDark
                    ? Colors.white.withOpacity(0.35)
                    : Colors.black.withOpacity(0.35))),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}
