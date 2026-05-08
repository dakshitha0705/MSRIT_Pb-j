import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.read<AuthService>();

    return SafeArea(
        child: Column(children: [
      // Header
      Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
          child: Row(children: [
            const Expanded(
                child: Text('Messages',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5))),
            GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const _NewMessageScreen())),
                child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(11)),
                    child: const Icon(Icons.edit_rounded,
                        color: Colors.white, size: 18))),
          ])),

      // Chat list
      Expanded(
          child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('users', arrayContains: auth.uid)
                  .orderBy('last_at', descending: true)
                  .snapshots(),
              builder: (_, snap) {
                if (snap.hasError) {
                  return Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        Icon(Icons.error_outline_rounded,
                            size: 32,
                            color: Colors.white.withValues(alpha: 0.3)),
                        const SizedBox(height: 10),
                        Text('Unable to load messages',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.4))),
                      ]));
                }
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.05)),
                            child: Icon(Icons.chat_rounded,
                                size: 28,
                                color: Colors.white.withOpacity(0.2))),
                        const SizedBox(height: 14),
                        Text('No messages yet',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.4))),
                        const SizedBox(height: 4),
                        Text('Start a conversation with a friend',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.2))),
                      ]));
                }

                return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final users = List<String>.from(data['users'] ?? []);
                      final friendUid = users.firstWhere((u) => u != auth.uid,
                          orElse: () => '');
                      final lastMsg = data['last_message'] as String? ?? '';
                      final lastAt = (data['last_at'] as Timestamp?)?.toDate();

                      if (friendUid.isEmpty) return const SizedBox();

                      return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(friendUid)
                              .get(),
                          builder: (_, snap) {
                            if (!snap.hasData) return const SizedBox();
                            final u =
                                snap.data!.data() as Map<String, dynamic>? ??
                                    {};
                            final name = u['name'] as String? ?? 'Unknown';

                            return GestureDetector(
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                            friendUid: friendUid,
                                            friendName: name))),
                                child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.04),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                            color: Colors.white
                                                .withOpacity(0.07))),
                                    child: Row(children: [
                                      CircleAvatar(
                                          radius: 22,
                                          backgroundColor:
                                              const Color(0xFF6366F1)
                                                  .withOpacity(0.15),
                                          child: Text(
                                              name.isNotEmpty
                                                  ? name[0].toUpperCase()
                                                  : '?',
                                              style: const TextStyle(
                                                  color: Color(0xFF818CF8),
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16))),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            Text(name,
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white)),
                                            const SizedBox(height: 2),
                                            Text(lastMsg,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white
                                                        .withOpacity(0.35))),
                                          ])),
                                      if (lastAt != null)
                                        Text(_timeLabel(lastAt),
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.white
                                                    .withOpacity(0.25))),
                                    ])));
                          });
                    });
              })),
    ]));
  }

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

// ── New message (pick a friend) ───────────────────────
class _NewMessageScreen extends StatelessWidget {
  const _NewMessageScreen();

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return Scaffold(
        backgroundColor: const Color(0xFF09090B),
        body: SafeArea(
            child: Column(children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 16),
              child: Row(children: [
                IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context)),
                const Text('New message',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ])),
          Expanded(
              child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('friends')
                      .where('user1', isEqualTo: auth.uid)
                      .snapshots(),
                  builder: (_, snap) {
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Center(
                          child: Text('Add friends first to message them',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.3))));
                    }
                    return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        itemCount: docs.length,
                        itemBuilder: (_, i) {
                          final friendUid = docs[i]['user2'] as String;
                          return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(friendUid)
                                  .get(),
                              builder: (_, snap) {
                                if (!snap.hasData) return const SizedBox();
                                final u = snap.data!.data()
                                        as Map<String, dynamic>? ??
                                    {};
                                final name = u['name'] as String? ?? 'Unknown';
                                return ListTile(
                                    leading: CircleAvatar(
                                        backgroundColor: const Color(0xFF6366F1)
                                            .withOpacity(0.15),
                                        child: Text(
                                            name.isNotEmpty
                                                ? name[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                                color: Color(0xFF818CF8),
                                                fontWeight: FontWeight.w700))),
                                    title: Text(name,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600)),
                                    subtitle: Text('@${u['username'] ?? ''}',
                                        style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.35),
                                            fontSize: 12)),
                                    onTap: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => ChatScreen(
                                                  friendUid: friendUid,
                                                  friendName: name)));
                                    });
                              });
                        });
                  })),
        ])));
  }
}
