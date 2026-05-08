import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'ai_chat_screen.dart';

class AiChatHistoryScreen extends StatefulWidget {
  final String? initialMode; // if passed, show only this mode
  const AiChatHistoryScreen({super.key, this.initialMode});
  @override
  State<AiChatHistoryScreen> createState() => _AiChatHistoryScreenState();
}

class _AiChatHistoryScreenState extends State<AiChatHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _modes = ['empathetic', 'medical', 'flirty', 'informative'];
  final _modeNames = ['Empathetic', 'Medical', 'Flirty', 'Informative'];

  @override
  void initState() {
    super.initState();
    final initial =
        widget.initialMode != null ? _modes.indexOf(widget.initialMode!) : 0;
    _tabs = TabController(
        length: 4, vsync: this, initialIndex: initial < 0 ? 0 : initial);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Color _modeColor(String mode) {
    switch (mode) {
      case 'medical':
        return const Color(0xFF34D399);
      case 'flirty':
        return const Color(0xFFFB7185);
      case 'informative':
        return const Color(0xFF38BDF8);
      default:
        return const Color(0xFF818CF8);
    }
  }

  IconData _modeIcon(String mode) {
    switch (mode) {
      case 'medical':
        return Icons.medical_services_rounded;
      case 'flirty':
        return Icons.favorite_rounded;
      case 'informative':
        return Icons.lightbulb_rounded;
      default:
        return Icons.favorite_border_rounded;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return Scaffold(
        backgroundColor: const Color(0xFF09090B),
        body: SafeArea(
            child: Column(children: [
          // Header
          Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
              child: Row(children: [
                IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context)),
                const Expanded(
                    child: Text('Chat History',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5))),
                GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AiChatScreen())),
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                            color: const Color(0xFF6366F1),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Row(children: [
                          Icon(Icons.add_rounded,
                              color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text('New',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ]))),
              ])),

          // Mode tabs
          TabBar(
              controller: _tabs,
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              indicatorColor: const Color(0xFF6366F1),
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              tabs: _modes
                  .map((m) => Tab(
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(_modeIcon(m), size: 14, color: _modeColor(m)),
                        const SizedBox(width: 6),
                        Text(_modeNames[_modes.indexOf(m)]),
                      ])))
                  .toList()),

          Expanded(
              child: TabBarView(
                  controller: _tabs,
                  children: _modes
                      .map((mode) => _ModeHistory(
                            mode: mode,
                            auth: auth,
                            modeColor: _modeColor(mode),
                            modeIcon: _modeIcon(mode),
                            formatTime: _formatTime,
                          ))
                      .toList())),
        ])));
  }
}

// ── Per-mode history list ────────────────────────────
class _ChatPreview {
  final String id;
  final String userMessage;
  final String assistantResponse;
  final DateTime? timestamp;

  const _ChatPreview({
    required this.id,
    required this.userMessage,
    required this.assistantResponse,
    required this.timestamp,
  });
}

class _ModeHistory extends StatefulWidget {
  final String mode;
  final dynamic auth;
  final Color modeColor;
  final IconData modeIcon;
  final String Function(DateTime) formatTime;
  const _ModeHistory(
      {required this.mode,
      required this.auth,
      required this.modeColor,
      required this.modeIcon,
      required this.formatTime});

  @override
  State<_ModeHistory> createState() => _ModeHistoryState();
}

class _ModeHistoryState extends State<_ModeHistory> {
  List<_ChatPreview> _visibleChats = const [];
  bool _hasLoadedSnapshot = false;
  String? _lastSnapshotKey;

  DateTime? _dateFrom(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }

  Future<_ChatPreview> _previewFromDoc(QueryDocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    var userMessage = data['last_user_message'] as String? ?? '';
    var assistantResponse = data['last_assistant_response'] as String? ?? '';
    var timestamp =
        _dateFrom(data['updated_at']) ?? _dateFrom(data['created_at']);

    if (userMessage.isEmpty || assistantResponse.isEmpty || timestamp == null) {
      final messages = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.auth.uid)
          .collection('ai_chats')
          .doc(doc.id)
          .collection('messages')
          .orderBy('created_at', descending: false)
          .get();

      for (final messageDoc in messages.docs) {
        final message = messageDoc.data();
        final role = message['role'] as String? ?? '';
        final text = message['text'] as String? ?? '';
        final messageTime = _dateFrom(message['created_at']);
        timestamp ??= messageTime;
        final currentTimestamp = timestamp;
        if (messageTime != null &&
            (currentTimestamp == null ||
                messageTime.isAfter(currentTimestamp))) {
          timestamp = messageTime;
        }
        if (role == 'user' && userMessage.isEmpty) {
          userMessage = text;
        } else if (role != 'user' && assistantResponse.isEmpty) {
          assistantResponse = text;
        }
      }
    }

    return _ChatPreview(
      id: doc.id,
      userMessage: userMessage,
      assistantResponse: assistantResponse,
      timestamp: timestamp,
    );
  }

  Future<void> _loadPreviews(
      List<QueryDocumentSnapshot> docs, String snapshotKey) async {
    final previews = await Future.wait(docs.map(_previewFromDoc));
    previews.sort((a, b) {
      final at = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });
    if (!mounted || snapshotKey != _lastSnapshotKey) return;
    setState(() {
      _visibleChats = previews;
      _hasLoadedSnapshot = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.auth.uid)
            .collection('ai_chats')
            .where('mode', isEqualTo: widget.mode)
            .snapshots(),
        builder: (_, snap) {
          if (snap.hasData) {
            final docs = snap.data!.docs;
            if (docs.isNotEmpty) {
              final snapshotKey = docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final updatedAt = data['updated_at'];
                final createdAt = data['created_at'];
                return '${doc.id}:${updatedAt ?? createdAt ?? ''}';
              }).join('|');
              if (snapshotKey != _lastSnapshotKey) {
                _lastSnapshotKey = snapshotKey;
                _loadPreviews(docs, snapshotKey);
              }
            } else if (!_hasLoadedSnapshot) {
              _hasLoadedSnapshot = true;
            }
          }

          final chats = _visibleChats;
          if (chats.isEmpty && !_hasLoadedSnapshot) {
            return Center(
                child: CircularProgressIndicator(color: widget.modeColor));
          }

          if (chats.isEmpty)
            return Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.modeColor.withOpacity(0.08)),
                      child: Icon(widget.modeIcon,
                          size: 24, color: widget.modeColor.withOpacity(0.4))),
                  const SizedBox(height: 12),
                  Text('No ${widget.mode} chats yet',
                      style: TextStyle(
                          fontSize: 14, color: Colors.white.withOpacity(0.3))),
                ]));

          return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: chats.length,
              itemBuilder: (_, i) {
                final chat = chats[i];
                return GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => _SessionScreen(
                                sessionId: chat.id,
                                mode: widget.mode,
                                time: chat.timestamp,
                                modeColor: widget.modeColor,
                                modeIcon: widget.modeIcon))),
                    child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.07))),
                        child: Row(children: [
                          Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                  color: widget.modeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12)),
                              child:
                                  Icon(widget.modeIcon, color: widget.modeColor, size: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(chat.userMessage.isNotEmpty
                                    ? chat.userMessage
                                    : 'User message',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white)),
                                const SizedBox(height: 2),
                                Text(chat.assistantResponse.isNotEmpty
                                    ? chat.assistantResponse
                                    : 'Assistant response pending',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 12,
                                        height: 1.3,
                                        color: Colors.white.withOpacity(0.5))),
                                const SizedBox(height: 4),
                                Text(chat.timestamp != null
                                    ? widget.formatTime(chat.timestamp!)
                                    : '',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white.withOpacity(0.3))),
                              ])),
                          Icon(Icons.chevron_right_rounded,
                              color: Colors.white.withOpacity(0.2), size: 20),
                        ])));
              });
        });
  }
}

// ── Session detail ───────────────────────────────────
class _SessionScreen extends StatelessWidget {
  final String sessionId, mode;
  final DateTime? time;
  final Color modeColor;
  final IconData modeIcon;
  const _SessionScreen(
      {required this.sessionId,
      required this.mode,
      required this.time,
      required this.modeColor,
      required this.modeIcon});

  String _modeName() {
    switch (mode) {
      case 'medical':
        return 'Medical Mode';
      case 'flirty':
        return 'Flirty Mode';
      case 'informative':
        return 'Informative Mode';
      default:
        return 'Empathetic Mode';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return Scaffold(
        backgroundColor: const Color(0xFF09090B),
        body: SafeArea(
            child: Column(children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
              child: Row(children: [
                IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context)),
                Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                        color: modeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(modeIcon, color: modeColor, size: 18)),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(_modeName(),
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      if (time != null)
                        Text('${time!.day}/${time!.month}/${time!.year}',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.3))),
                    ])),
              ])),
          Expanded(
              child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(auth.uid)
                      .collection('ai_chats')
                      .doc(sessionId)
                      .collection('messages')
                      .orderBy('created_at', descending: false)
                      .snapshots(),
                  builder: (_, snap) {
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty)
                      return Center(
                          child: Text('No messages in this session',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.3))));
                    return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: docs.length,
                        itemBuilder: (_, i) {
                          final msg = docs[i].data() as Map<String, dynamic>;
                          final isMe = msg['role'] == 'user';
                          final text = msg['text'] as String? ?? '';
                          return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                  mainAxisAlignment: isMe
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (!isMe) ...[
                                      Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color:
                                                  modeColor.withOpacity(0.12)),
                                          child: Icon(modeIcon,
                                              size: 13, color: modeColor)),
                                      const SizedBox(width: 8),
                                    ],
                                    Flexible(
                                        child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 10),
                                            decoration: BoxDecoration(
                                                color: isMe
                                                    ? const Color(0xFF6366F1)
                                                    : Colors.white
                                                        .withOpacity(0.07),
                                                borderRadius: BorderRadius.only(
                                                    topLeft: const Radius.circular(
                                                        18),
                                                    topRight:
                                                        const Radius.circular(
                                                            18),
                                                    bottomLeft: Radius.circular(
                                                        isMe ? 18 : 4),
                                                    bottomRight: Radius.circular(
                                                        isMe ? 4 : 18))),
                                            child: Text(text,
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    height: 1.4,
                                                    color: isMe ? Colors.white : Colors.white.withOpacity(0.85))))),
                                    if (isMe) const SizedBox(width: 8),
                                  ]));
                        });
                  })),
        ])));
  }
}
