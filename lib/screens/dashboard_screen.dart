import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/music_player_service.dart';
import '../theme/app_theme.dart';
import '../models/notification_model.dart';
import '../widgets/profile_sidebar.dart';
import 'battery_screen.dart';
import 'data_screen.dart';
import 'file_screen.dart';
import 'media_screen.dart';
import 'contact_screen.dart';
import 'game_screen.dart';
import 'notifications_screen.dart';
import 'voice_to_doc_screen.dart';
import 'ai_chat_screen.dart';
import 'music_screen.dart';
import 'friends_screen.dart';
import 'messages_screen.dart';
import 'spin_wheel_screen.dart';
import 'amp_screen.dart';

// ── Theme helpers ────────────────────────────────────
Color _tc(bool d) => d ? Colors.white : const Color(0xFF09090B);
Color _tc2(bool d) => d ? Colors.white54 : const Color(0xFF71717A);
Color _card(bool d) => d ? const Color(0xFF18181B) : Colors.white;
Color _border(bool d) => d ? Colors.white12 : const Color(0xFFE4E4E7);
Color _bg(bool d) => d ? const Color(0xFF09090B) : const Color(0xFFF4F4F5);

// ════════════════════════════════════════════════════
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _nav = 0;

  @override
  Widget build(BuildContext context) {
    final fs = context.watch<FirestoreService>();
    final auth = context.read<AuthService>();
    final d = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      _HomePage(
          d: d,
          user: fs.currentUser,
          auth: auth,
          fs: fs,
          onSidebar: () => _sidebar(context)),
      const FriendsScreen(),
      const MessagesScreen(),
    ];

    return Scaffold(
      backgroundColor: _bg(d),
      body: pages[_nav],
      bottomNavigationBar: _BottomNav(
        nav: _nav,
        d: d,
        onTap: (i) => setState(() => _nav = i),
      ),
    );
  }

  void _sidebar(BuildContext ctx) => showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.88,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, __) => const ProfileSidebar()));
}

// ════════════════════════════════════════════════════
class _HomePage extends StatelessWidget {
  final bool d;
  final dynamic user, auth, fs;
  final VoidCallback onSidebar;
  const _HomePage(
      {required this.d,
      required this.user,
      required this.auth,
      required this.fs,
      required this.onSidebar});

  void _go(BuildContext ctx, Widget s) =>
      Navigator.push(ctx, MaterialPageRoute(builder: (_) => s));

  @override
  Widget build(BuildContext context) {
    final credits = (user?.credits as int?) ?? 0;
    final name = (user?.name as String?)?.split(' ').first ?? 'there';

    return SafeArea(
        child: Column(children: [
      // ── Header ──────────────────────────────────
      Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
          child: Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('AmpUp',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _tc(d),
                          letterSpacing: -0.5)),
                  Text('Hi $name 👋',
                      style: TextStyle(fontSize: 12, color: _tc2(d))),
                ])),
            // Dark mode toggle
            GestureDetector(
                onTap: () => context.read<AppThemeNotifier>().toggle(),
                child: Container(
                    width: 52,
                    height: 28,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                        color: d ? Colors.white12 : const Color(0xFFE4E4E7),
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(children: [
                      Icon(
                          d
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          size: 13,
                          color: _tc2(d)),
                      const Spacer(),
                      Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                              color: Color(0xFF6366F1), shape: BoxShape.circle),
                          child: Icon(
                              d
                                  ? Icons.dark_mode_rounded
                                  : Icons.light_mode_rounded,
                              size: 11,
                              color: Colors.white)),
                    ]))),
            const SizedBox(width: 8),
            // Notifications
            StreamBuilder<List<NotificationModel>>(
                stream: fs.notificationsStream(auth.uid),
                builder: (_, snap) {
                  final u = (snap.data ?? []).where((n) => !n.isRead).length;
                  return GestureDetector(
                      onTap: () => _go(context, const NotificationsScreen()),
                      child: Stack(clipBehavior: Clip.none, children: [
                        Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                                color: d
                                    ? Colors.white12
                                    : const Color(0xFFE4E4E7),
                                borderRadius: BorderRadius.circular(11)),
                            child: Icon(Icons.notifications_outlined,
                                size: 18, color: _tc(d))),
                        if (u > 0)
                          Positioned(
                              top: -3,
                              right: -3,
                              child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                      border:
                                          Border.all(color: _bg(d), width: 2)),
                                  child: Center(
                                      child: Text('$u',
                                          style: const TextStyle(
                                              fontSize: 7,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800))))),
                      ]));
                }),
            const SizedBox(width: 8),
            GestureDetector(
                onTap: onSidebar,
                child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: d ? Colors.white12 : const Color(0xFFE4E4E7),
                        borderRadius: BorderRadius.circular(11)),
                    child:
                        Icon(Icons.person_rounded, size: 18, color: _tc(d)))),
          ])),

      Expanded(
          child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Column(children: [
                // Credits card
                _CreditsCard(credits: credits, d: d),
                const SizedBox(height: 18),

                // Quick actions
                _SecHdr(title: 'Quick actions', d: d),
                const SizedBox(height: 10),
                GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.85,
                    children: [
                      _QT(
                          'Battery',
                          Icons.battery_charging_full_rounded,
                          const Color(0xFF34D399),
                          d,
                          () => _go(context, const BatteryScreen())),
                      _QT(
                          'Data',
                          Icons.wifi_tethering_rounded,
                          const Color(0xFF818CF8),
                          d,
                          () => _go(context, const DataScreen())),
                      _QT('File', Icons.folder_rounded, const Color(0xFF94A3B8),
                          d, () => _go(context, const FileScreen())),
                      _QT(
                          'Media',
                          Icons.perm_media_rounded,
                          const Color(0xFFFB7185),
                          d,
                          () => _go(context, const MediaScreen())),
                      _QT(
                          'AI Chat',
                          Icons.smart_toy_rounded,
                          const Color(0xFF38BDF8),
                          d,
                          () => _go(context, const AiChatScreen())),
                      _QT(
                          'Music',
                          Icons.music_note_rounded,
                          const Color(0xFF34D399),
                          d,
                          () => _go(context, const MusicScreen())),
                      _QT('Voice', Icons.mic_rounded, const Color(0xFFF472B6),
                          d, () => _go(context, const VoiceToDocScreen())),
                      _QT(
                          'Contact',
                          Icons.contact_phone_rounded,
                          const Color(0xFF818CF8),
                          d,
                          () => _go(context, const ContactScreen())),
                    ]),

                const SizedBox(height: 20),

                // Games
                _SecHdr(title: 'Games', d: d),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                      child: _GCard(
                          tag: 'DAILY',
                          title: 'Spin wheel',
                          sub: 'Win up to 50 credits',
                          btn: 'Spin now',
                          accent: const Color(0xFF6366F1),
                          bg: d
                              ? const Color(0xFF0D0B1A)
                              : const Color(0xFFEEF0FF),
                          border: const Color(0xFF6366F1).withOpacity(0.2),
                          icon: Icons.casino_rounded,
                          onTap: () => _go(context, const SpinWheelScreen()))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _GCard(
                          tag: 'CHALLENGE',
                          title: 'Runner game',
                          sub: 'Beat your high score',
                          btn: 'Play now',
                          accent: const Color(0xFF38BDF8),
                          bg: d
                              ? const Color(0xFF070F15)
                              : const Color(0xFFEBF8FF),
                          border: const Color(0xFF38BDF8).withOpacity(0.2),
                          icon: Icons.sports_esports_rounded,
                          onTap: () => _go(context, const GameScreen()))),
                ]),

                const SizedBox(height: 20),
                _MiniPlayer(
                    d: d, onTap: () => _go(context, const MusicScreen())),
                const SizedBox(height: 24),
              ]))),
    ]));
  }
}

// ════════════════════════════════════════════════════
class _CreditsCard extends StatelessWidget {
  final int credits;
  final bool d;
  const _CreditsCard({required this.credits, required this.d});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(22),
            border:
                Border.all(color: const Color(0xFF6366F1).withOpacity(0.25))),
        child: Column(children: [
          Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('TOTAL CREDITS',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: Colors.white.withOpacity(0.35))),
                  const SizedBox(height: 6),
                  Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('$credits',
                            style: const TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -2)),
                        const SizedBox(width: 8),
                        Text('AMP',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.3))),
                      ]),
                ])),
          ]),
          const SizedBox(height: 14),
          ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                  value: (credits % 400) / 400,
                  minHeight: 4,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF818CF8)))),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Level Silver',
                style: TextStyle(
                    fontSize: 10, color: Colors.white.withOpacity(0.3))),
            Text('${credits % 400} / 400 to Gold',
                style: TextStyle(
                    fontSize: 10, color: Colors.white.withOpacity(0.3))),
          ]),
        ]));
  }
}

// ════════════════════════════════════════════════════
class _SecHdr extends StatelessWidget {
  final String title;
  final bool d;
  const _SecHdr({required this.title, required this.d});

  @override
  Widget build(BuildContext context) => Row(children: [
        Text(title,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _tc(d),
                letterSpacing: -0.2)),
      ]);
}

// ════════════════════════════════════════════════════
Widget _QT(
        String label, IconData icon, Color color, bool d, VoidCallback tap) =>
    GestureDetector(
        onTap: tap,
        child: Container(
            decoration: BoxDecoration(
                color: _card(d),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border(d))),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(11)),
                  child: Icon(icon, size: 18, color: color)),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w600, color: _tc2(d)),
                  textAlign: TextAlign.center),
            ])));

// ════════════════════════════════════════════════════
class _GCard extends StatelessWidget {
  final String tag, title, sub, btn;
  final Color accent, bg, border;
  final IconData icon;
  final VoidCallback onTap;
  const _GCard(
      {required this.tag,
      required this.title,
      required this.sub,
      required this.btn,
      required this.accent,
      required this.bg,
      required this.border,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(tag,
                    style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: accent))),
            const SizedBox(height: 8),
            Icon(icon, color: accent, size: 22),
            const SizedBox(height: 6),
            Text(title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    letterSpacing: -0.2)),
            Text(sub,
                style: TextStyle(fontSize: 10, color: accent.withOpacity(0.5))),
            const SizedBox(height: 10),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9)),
                child: Text(btn,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: accent))),
          ])));
}

// ════════════════════════════════════════════════════
class _MiniPlayer extends StatelessWidget {
  final bool d;
  final VoidCallback onTap;
  const _MiniPlayer({required this.d, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final m = context.watch<MusicPlayerService>();
    final song = m.current;
    return GestureDetector(
        onTap: onTap,
        child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: _card(d),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border(d))),
            child: Row(children: [
              ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: song != null && song.imageUrl.isNotEmpty
                      ? Image.network(song.imageUrl,
                          width: 42,
                          height: 42,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _art())
                      : _art()),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(song?.title ?? 'AmpUp Music',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _tc(d))),
                    Text(song?.artist ?? 'Tap to play music',
                        style: TextStyle(fontSize: 11, color: _tc2(d))),
                    if (song != null) ...[
                      const SizedBox(height: 5),
                      ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                              value: m.duration.inSeconds > 0
                                  ? (m.position.inSeconds /
                                          m.duration.inSeconds)
                                      .clamp(0.0, 1.0)
                                  : 0,
                              minHeight: 2,
                              backgroundColor: d
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.black.withOpacity(0.08),
                              valueColor: const AlwaysStoppedAnimation(
                                  Color(0xFF6366F1)))),
                    ],
                  ])),
              const SizedBox(width: 8),
              if (song != null)
                Row(children: [
                  GestureDetector(
                      onTap: m.playPrev,
                      child: Icon(Icons.skip_previous_rounded,
                          color: _tc2(d), size: 20)),
                  const SizedBox(width: 4),
                  GestureDetector(
                      onTap: m.togglePlay,
                      child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: Color(0xFF6366F1)),
                          child: Icon(
                              m.playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 16))),
                  const SizedBox(width: 4),
                  GestureDetector(
                      onTap: m.playNext,
                      child: Icon(Icons.skip_next_rounded,
                          color: _tc2(d), size: 20)),
                ])
              else
                Icon(Icons.chevron_right_rounded, color: _tc2(d), size: 20),
            ])));
  }

  Widget _art() => Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF818CF8)])),
      child:
          const Icon(Icons.music_note_rounded, color: Colors.white, size: 20));
}

// ════════════════════════════════════════════════════
class _BottomNav extends StatelessWidget {
  final int nav;
  final bool d;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.nav, required this.d, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
          color: d ? const Color(0xFF0D0D0F) : Colors.white,
          border: Border(
              top: BorderSide(
                  color: d ? Colors.white12 : const Color(0xFFE4E4E7)))),
      child: SafeArea(
          top: false,
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NI(Icons.home_rounded, 'Home', nav == 0, d,
                        () => onTap(0)),
                    _NI(Icons.people_rounded, 'Friends', nav == 1, d,
                        () => onTap(1)),
                    // AMP Assistant Button (between Friends and Messages)
                    GestureDetector(
                        onTap: () => AmpAssistant.show(context),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF6366F1),
                                        Color(0xFF818CF8)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight),
                                  boxShadow: [
                                    BoxShadow(
                                        color: const Color(0xFF6366F1)
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 0)
                                  ]),
                              child: const Center(
                                  child: Text('A',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900)))),
                          const SizedBox(height: 3),
                          Text('Amp',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: _tc2(d))),
                        ])),
                    _NI(Icons.chat_rounded, 'Messages', nav == 2, d,
                        () => onTap(2)),
                  ]))));
}

Widget _NI(
        IconData icon, String label, bool active, bool d, VoidCallback tap) =>
    GestureDetector(
        onTap: tap,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 22, color: active ? const Color(0xFF6366F1) : _tc2(d)),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? const Color(0xFF6366F1) : _tc2(d))),
        ]));
