import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/nearby_service.dart';

enum ShareType { file, media, contact }

class ShareToFriendSheet extends StatefulWidget {
  final ShareType type;
  final File? file;
  final String? fileName;
  final Map<String, dynamic>? contactData;
  final int creditsEarned;

  const ShareToFriendSheet({
    super.key,
    required this.type,
    this.file,
    this.fileName,
    this.contactData,
    required this.creditsEarned,
  });

  static Future<void> show(
    BuildContext context, {
    required ShareType type,
    File? file,
    String? fileName,
    Map<String, dynamic>? contactData,
    required int creditsEarned,
  }) async {
    await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ShareToFriendSheet(
            type: type,
            file: file,
            fileName: fileName,
            contactData: contactData,
            creditsEarned: creditsEarned));
  }

  @override
  State<ShareToFriendSheet> createState() => _ShareToFriendSheetState();
}

class _ShareToFriendSheetState extends State<ShareToFriendSheet>
    with TickerProviderStateMixin {
  bool _sending = false;
  String? _sentTo;
  late TabController _tabController;
  List<Map<String, dynamic>> _nearbyUsers = [];
  bool _loadingNearby = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNearbyUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNearbyUsers() async {
    setState(() => _loadingNearby = true);
    try {
      final pos = await NearbyService.getLocation();
      if (pos != null && mounted) {
        final fs = context.read<FirestoreService>();
        final nearby = await fs.getNearbyUsers(
            pos.latitude, pos.longitude, 5.0); // 5km radius
        setState(() => _nearbyUsers = nearby);
      }
    } catch (e) {
      // Ignore errors for nearby users
    } finally {
      if (mounted) {
        setState(() => _loadingNearby = false);
      }
    }
  }

  String _chatId(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Future<void> _sendToFriend(String friendUid, String friendName) async {
    setState(() => _sending = true);
    final auth = context.read<AuthService>();
    final fs = context.read<FirestoreService>();
    final db = FirebaseFirestore.instance;

    try {
      final chatId = _chatId(auth.uid, friendUid);
      final chatRef = db.collection('chats').doc(chatId);
      await chatRef.set({
        'users': [auth.uid, friendUid],
        'last_at': FieldValue.serverTimestamp(),
        'last_message': widget.type == ShareType.contact
            ? '📇 Contact shared'
            : widget.type == ShareType.media
                ? '🖼️ Image shared'
                : '📁 File shared',
      }, SetOptions(merge: true));

      final Map<String, dynamic> msgData = {
        'senderId': auth.uid,
        'senderName': fs.currentUser?.name ?? 'You',
        'type': widget.type.name,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      if (widget.type == ShareType.contact && widget.contactData != null) {
        msgData['contactData'] = widget.contactData;
        msgData['text'] = '📇 Contact: ${widget.contactData!['name'] ?? ''}';
      } else if (widget.file != null) {
        final ext = widget.fileName?.split('.').last ?? 'bin';
        final path =
            'shared/${auth.uid}/${DateTime.now().millisecondsSinceEpoch}.$ext';
        final ref = FirebaseStorage.instance.ref(path);
        await ref.putFile(widget.file!);
        final url = await ref.getDownloadURL();
        msgData['fileUrl'] = url;
        msgData['fileName'] = widget.fileName ?? 'file.$ext';
        msgData['text'] = widget.type == ShareType.media
            ? '🖼️ Image shared'
            : '📁 ${widget.fileName ?? 'File'}';
      }

      await chatRef.collection('messages').add(msgData);

      await db.collection('users').doc(auth.uid).update({
        'credits': FieldValue.increment(widget.creditsEarned),
      });

      final notifRef = db.collection('notifications').doc();
      await notifRef.set({
        'notification_id': notifRef.id,
        'to_user_id': friendUid,
        'from_user_id': auth.uid,
        'from_name': fs.currentUser?.name ?? 'Someone',
        'title': 'Share received',
        'body':
            '${fs.currentUser?.name ?? 'Someone'} shared a ${widget.type.name} with you!',
        'type': 'share_${widget.type.name}',
        'feature_type': 'share',
        'session_id': '',
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _sending = false;
          _sentTo = friendName;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildFriendsTab() {
    final auth = context.read<AuthService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('friends')
            .where('user1', isEqualTo: auth.uid)
            .snapshots(),
        builder: (_, snap) {
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Icon(Icons.people_outline_rounded,
                      size: 40,
                      color: isDark ? Colors.white24 : Colors.black26),
                  const SizedBox(height: 12),
                  Text('No friends yet',
                      style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? Colors.white38
                              : const Color(0xFF71717A))),
                  const SizedBox(height: 4),
                  Text('Add friends to share with them',
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white24
                              : const Color(0xFFA1A1AA))),
                ]));
          }
          return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      final u =
                          snap.data!.data() as Map<String, dynamic>? ?? {};
                      final name = u['name'] as String? ?? 'Unknown';
                      return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : const Color(0xFFF8F8F8),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: isDark
                                      ? Colors.white12
                                      : const Color(0xFFE4E4E7))),
                          child: Row(children: [
                            CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(0xFF6366F1)
                                    .withValues(alpha: 0.12),
                                child: Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        color: Color(0xFF6366F1),
                                        fontWeight: FontWeight.w700))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(name,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF09090B)))),
                            GestureDetector(
                                onTap: _sending
                                    ? null
                                    : () => _sendToFriend(friendUid, name),
                                child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1),
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: _sending
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2))
                                        : const Text('Send',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white)))),
                          ]));
                    });
              });
        });
  }

  Widget _buildNearbyTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loadingNearby) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_nearbyUsers.isEmpty) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.location_off_rounded,
            size: 40, color: isDark ? Colors.white24 : Colors.black26),
        const SizedBox(height: 12),
        Text('No nearby users found',
            style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white38 : const Color(0xFF71717A))),
        const SizedBox(height: 4),
        Text('Enable location to find nearby users',
            style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white24 : const Color(0xFFA1A1AA))),
      ]));
    }

    return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _nearbyUsers.length,
        itemBuilder: (_, i) {
          final user = _nearbyUsers[i];
          final name = user['name'] as String? ?? 'Unknown';
          final distance = user['distance'] as int? ?? 0;
          final username = user['username'] as String? ?? '';
          return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color:
                          isDark ? Colors.white12 : const Color(0xFFE4E4E7))),
              child: Row(children: [
                CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        const Color(0xFF6366F1).withValues(alpha: 0.12),
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                            color: Color(0xFF6366F1),
                            fontWeight: FontWeight.w700))),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(name,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF09090B))),
                      Text('@$username · ${distance}m away',
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white38 : Colors.black38)),
                    ])),
                GestureDetector(
                    onTap: _sending
                        ? null
                        : () => _sendToFriend(user['uid'], name),
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                            color: const Color(0xFF6366F1),
                            borderRadius: BorderRadius.circular(20)),
                        child: _sending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Send',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)))),
              ]));
        });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF09090B) : Colors.white;

    if (_sentTo != null) {
      return Container(
          height: 220,
          decoration: BoxDecoration(
              color: bg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF34D399), size: 52),
            const SizedBox(height: 12),
            Text('Sent to $_sentTo!',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF09090B))),
            const SizedBox(height: 4),
            Text('+${widget.creditsEarned} credits earned',
                style: const TextStyle(fontSize: 13, color: Color(0xFF34D399))),
          ]));
    }

    return Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
            color: bg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(children: [
          Center(
              child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2)))),
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(children: [
                Text('Send to',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color:
                            isDark ? Colors.white : const Color(0xFF09090B))),
                const Spacer(),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('+${widget.creditsEarned} credits',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6366F1)))),
              ])),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Friends'),
              Tab(text: 'Nearby'),
            ],
            labelColor: isDark ? Colors.white : const Color(0xFF09090B),
            unselectedLabelColor: isDark ? Colors.white38 : Colors.black38,
            indicatorColor: const Color(0xFF6366F1),
          ),
          Divider(
              height: 1,
              color: isDark ? Colors.white12 : const Color(0xFFE4E4E7)),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsTab(),
                _buildNearbyTab(),
              ],
            ),
          ),
        ]));
  }
}
