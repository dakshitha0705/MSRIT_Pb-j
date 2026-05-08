import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../widgets/share_to_friend_sheet.dart' show ShareType;

class ChatScreen extends StatefulWidget {
  final String friendUid, friendName;
  const ChatScreen(
      {super.key, required this.friendUid, required this.friendName});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  String get _chatId {
    final auth = context.read<AuthService>();
    final ids = [auth.uid, widget.friendUid]..sort();
    return ids.join('_');
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    final auth = context.read<AuthService>();
    _ctrl.clear();
    setState(() => _sending = true);
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .add({
        'text': text,
        'from': auth.uid,
        'created_at': FieldValue.serverTimestamp(),
      });
      // Update last message
      await FirebaseFirestore.instance.collection('chats').doc(_chatId).set({
        'users': [auth.uid, widget.friendUid],
        'last_message': text,
        'last_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Widget _buildMessageContent(
      Map<String, dynamic> msg, bool isMe, bool isDark) {
    final type = msg['type'] as String?;

    if (type == ShareType.media.name) {
      final url = msg['fileUrl'] as String? ?? '';
      return url.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(url,
                  width: 200,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const SizedBox(
                          height: 120,
                          child: Center(child: CircularProgressIndicator()))))
          : Text(msg['text'] as String? ?? '',
              style:
                  TextStyle(fontSize: 14, color: isMe ? Colors.white : null));
    }

    if (type == ShareType.file.name) {
      final fileName = msg['fileName'] as String? ?? 'File';
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.insert_drive_file_rounded,
            color: isMe ? Colors.white : const Color(0xFF6366F1)),
        const SizedBox(width: 8),
        Flexible(
            child: Text(fileName,
                style: TextStyle(
                    color: isMe
                        ? Colors.white
                        : (isDark ? Colors.white : const Color(0xFF09090B)),
                    fontWeight: FontWeight.w600))),
      ]);
    }

    if (type == ShareType.contact.name) {
      final contact = msg['contactData'] as Map<String, dynamic>? ?? {};
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2)),
            child: const Icon(Icons.person_rounded,
                color: Colors.white, size: 18)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(contact['name'] as String? ?? 'Contact',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          if ((contact['phone'] as String? ?? '').isNotEmpty)
            Text(contact['phone'] as String,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
        ]),
      ]);
    }

    // Default: plain text
    return Text(msg['text'] as String? ?? '',
        style: TextStyle(
            fontSize: 14.5,
            height: 1.4,
            color: isMe
                ? Colors.white
                : (isDark ? Colors.white : const Color(0xFF0F172A))));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.read<AuthService>();

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF09090B) : const Color(0xFFF4F4F5),
      body: SafeArea(
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            child: Row(children: [
              IconButton(
                  icon: Icon(Icons.arrow_back_ios_rounded,
                      color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  onPressed: () => Navigator.pop(context)),
              CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF2563EB).withOpacity(0.15),
                  child: Text(
                      widget.friendName.isNotEmpty
                          ? widget.friendName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w700))),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(widget.friendName,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A)))),
            ]),
          ),

          // Messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('created_at', descending: false)
                  .snapshots(),
              builder: (_, snap) {
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                      child: Text('Start a conversation!',
                          style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.3))));
                }
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final msg = docs[i].data() as Map<String, dynamic>;
                    // Support both old ('from') and new ('senderId') sender fields
                    final isMe =
                        msg['from'] == auth.uid || msg['senderId'] == auth.uid;
                    final time = (msg['created_at'] as Timestamp?)?.toDate() ??
                        (msg['createdAt'] as Timestamp?)?.toDate();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          if (!isMe) ...[
                            CircleAvatar(
                                radius: 14,
                                backgroundColor:
                                    const Color(0xFF2563EB).withOpacity(0.15),
                                child: Text(
                                    widget.friendName.isNotEmpty
                                        ? widget.friendName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        color: Color(0xFF2563EB),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700))),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                              child: Column(
                                  crossAxisAlignment: isMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                        color: isMe
                                            ? const Color(0xFF2563EB)
                                            : (isDark
                                                ? Colors.white.withOpacity(0.07)
                                                : Colors.white),
                                        borderRadius: BorderRadius.only(
                                            topLeft: const Radius.circular(18),
                                            topRight: const Radius.circular(18),
                                            bottomLeft:
                                                Radius.circular(isMe ? 18 : 4),
                                            bottomRight:
                                                Radius.circular(isMe ? 4 : 18)),
                                        boxShadow: [
                                          BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.06),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2))
                                        ]),
                                    child: _buildMessageContent(
                                        msg, isMe, isDark)),
                                if (time != null)
                                  Padding(
                                      padding: const EdgeInsets.only(top: 3),
                                      child: Text(
                                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: isDark
                                                  ? Colors.white
                                                      .withOpacity(0.3)
                                                  : Colors.black
                                                      .withOpacity(0.3)))),
                              ])),
                          if (isMe) const SizedBox(width: 8),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            child: Row(children: [
              Expanded(
                  child: Container(
                      decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.black.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.black.withOpacity(0.08))),
                      child: TextField(
                          controller: _ctrl,
                          maxLines: 4,
                          minLines: 1,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A)),
                          decoration: InputDecoration(
                              hintText: 'Message...',
                              hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white.withOpacity(0.3)
                                      : Colors.black.withOpacity(0.3)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10))))),
              const SizedBox(width: 8),
              GestureDetector(
                  onTap: _send,
                  child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF4F46E5)])),
                      child: _sending
                          ? const Center(
                              child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2)))
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20))),
            ]),
          ),
        ]),
      ),
    );
  }
}
