import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import 'chat_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});
  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    final auth = context.read<AuthService>();
    try {
      final db = FirebaseFirestore.instance;
      final q = query.toLowerCase().trim();

      final byUsername = await db
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: q)
          .where('username', isLessThanOrEqualTo: '$q\uf8ff')
          .limit(10)
          .get();

      final byName = await db
          .collection('users')
          .where('name_lower', isGreaterThanOrEqualTo: q)
          .where('name_lower', isLessThanOrEqualTo: '$q\uf8ff')
          .limit(10)
          .get();

      final seen = <String>{};
      final results = <Map<String, dynamic>>[];
      for (final doc in [...byUsername.docs, ...byName.docs]) {
        if (doc.id == auth.uid) continue;
        if (seen.contains(doc.id)) continue;
        seen.add(doc.id);
        final data = doc.data();
        results.add({
          'uid': doc.id,
          'name': data['name'] as String? ?? 'Unknown',
          'username': data['username'] as String? ?? '',
        });
      }
      setState(() {
        _searchResults = results;
        _searching = false;
      });
    } catch (e) {
      // Fallback: client-side filter on small user base
      try {
        final all = await FirebaseFirestore.instance
            .collection('users')
            .limit(50)
            .get();
        final q2 = query.toLowerCase();
        final results = all.docs
            .where((d) => d.id != auth.uid)
            .where((d) {
              final name = (d['name'] as String? ?? '').toLowerCase();
              final user = (d['username'] as String? ?? '').toLowerCase();
              return name.contains(q2) || user.contains(q2);
            })
            .map((d) => {
                  'uid': d.id,
                  'name': d['name'] as String? ?? 'Unknown',
                  'username': d['username'] as String? ?? '',
                })
            .toList();
        setState(() {
          _searchResults = results;
          _searching = false;
        });
      } catch (_) {
        setState(() => _searching = false);
      }
    }
  }

  Future<void> _sendFriendRequest(String toUid, String toName) async {
    final auth = context.read<AuthService>();
    final me = context.read<FirestoreService>().currentUser;
    final db = FirebaseFirestore.instance;

    // Guard: don't send duplicate pending requests
    final existing = await db
        .collection('friend_requests')
        .where('fromUid', isEqualTo: auth.uid)
        .where('toUid', isEqualTo: toUid)
        .where('status', isEqualTo: 'pending')
        .get();
    if (existing.docs.isNotEmpty) return;

    // Guard: don't re-add existing friend
    final alreadyFriend = await db
        .collection('friends')
        .where('user1', isEqualTo: auth.uid)
        .where('user2', isEqualTo: toUid)
        .get();
    if (alreadyFriend.docs.isNotEmpty) return;

    await db.collection('friend_requests').add({
      'fromUid': auth.uid,
      'toUid': toUid,
      'fromName': me?.name ?? 'Someone',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    final notifRef = db.collection('notifications').doc();
    await notifRef.set({
      'notification_id': notifRef.id,
      'to_user_id': toUid,
      'from_user_id': auth.uid,
      'from_name': me?.name ?? 'Someone',
      'title': 'Friend request',
      'body': '${me?.name ?? 'Someone'} sent you a friend request',
      'type': 'friend_request',
      'feature_type': 'social',
      'session_id': '',
      'is_read': false,
      'created_at': FieldValue.serverTimestamp(),
    });

    _snack('Friend request sent!');
  }

  Future<void> _acceptRequest(String requestId, String fromUid) async {
    final auth = context.read<AuthService>();
    final me = context.read<FirestoreService>().currentUser;
    final db = FirebaseFirestore.instance;
    final batch = db.batch();

    batch.update(db.collection('friend_requests').doc(requestId),
        {'status': 'accepted'});

    batch.set(db.collection('friends').doc('${auth.uid}_$fromUid'), {
      'user1': auth.uid,
      'user2': fromUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(db.collection('friends').doc('${fromUid}_${auth.uid}'), {
      'user1': fromUid,
      'user2': auth.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    final notifRef = db.collection('notifications').doc();
    await notifRef.set({
      'notification_id': notifRef.id,
      'to_user_id': fromUid,
      'from_user_id': auth.uid,
      'from_name': me?.name ?? 'Someone',
      'title': 'Friend request accepted',
      'body': '${me?.name ?? 'Someone'} accepted your friend request!',
      'type': 'friend_accepted',
      'feature_type': 'social',
      'session_id': '',
      'is_read': false,
      'created_at': FieldValue.serverTimestamp(),
    });

    _snack('Friend added!');
  }

  Future<void> _declineRequest(String requestId) async {
    await FirebaseFirestore.instance
        .collection('friend_requests')
        .doc(requestId)
        .update({'status': 'declined'});
  }

  Future<void> _removeFriend(String friendUid) async {
    final auth = context.read<AuthService>();
    final db = FirebaseFirestore.instance;
    await db.collection('friends').doc('${auth.uid}_$friendUid').delete();
    await db.collection('friends').doc('${friendUid}_${auth.uid}').delete();
    _snack('Friend removed');
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.read<AuthService>();

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF09090B)
          : const Color(0xFFF4F4F5),
      body: SafeArea(
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            child: Column(children: [
              Row(children: [
                IconButton(
                    icon: Icon(Icons.arrow_back_ios_rounded,
                        color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    onPressed: () => Navigator.pop(context)),
                Expanded(
                    child: Text('Friends',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                            letterSpacing: -0.5))),
              ]),
              const SizedBox(height: 10),
              // Search bar
              Container(
                  margin: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                  decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.08))),
                  child: TextField(
                      controller: _searchCtrl,
                      onChanged: _search,
                      style: TextStyle(
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A)),
                      decoration: InputDecoration(
                          hintText: 'Search by username...',
                          hintStyle: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.white.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.3)),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: isDark
                                  ? Colors.white.withOpacity(0.4)
                                  : Colors.black.withOpacity(0.4)),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchResults = []);
                                  })
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 4)))),
              const SizedBox(height: 10),
              // Tabs
              TabBar(
                  controller: _tabs,
                  labelColor: const Color(0xFF2563EB),
                  unselectedLabelColor: isDark
                      ? Colors.white.withOpacity(0.4)
                      : Colors.black.withOpacity(0.4),
                  indicatorColor: const Color(0xFF2563EB),
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: const [
                    Tab(text: 'Friends'),
                    Tab(text: 'Requests'),
                    Tab(text: 'Search'),
                  ]),
            ]),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                // Friends list
                _buildFriendsList(auth.uid, isDark),
                // Requests
                _buildRequests(auth.uid, isDark),
                // Search results
                _buildSearchResults(auth.uid, isDark),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildFriendsList(String uid, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('friends')
          .where('user1', isEqualTo: uid)
          .snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty)
          return _empty(isDark,
              icon: Icons.people_rounded,
              msg: 'No friends yet',
              sub: 'Search for users to add friends');
        return ListView.builder(
          padding: const EdgeInsets.all(16),
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
                final data = snap.data!.data() as Map<String, dynamic>? ?? {};
                return _FriendTile(
                    uid: friendUid,
                    name: data['name'] as String? ?? 'Unknown',
                    username: data['username'] as String? ?? '',
                    isDark: isDark,
                    onChat: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ChatScreen(
                                friendUid: friendUid,
                                friendName:
                                    data['name'] as String? ?? 'Unknown'))),
                    onRemove: () => _removeFriend(friendUid));
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRequests(String uid, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('friend_requests')
          .where('toUid', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (_, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty)
          return _empty(isDark,
              icon: Icons.person_add_rounded,
              msg: 'No pending requests',
              sub: 'Friend requests will appear here');
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final doc = docs[i];
            final fromUid = doc['fromUid'] as String;
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(fromUid)
                  .get(),
              builder: (_, snap) {
                if (!snap.hasData) return const SizedBox();
                final data = snap.data!.data() as Map<String, dynamic>? ?? {};
                return _RequestTile(
                    name: data['name'] as String? ?? 'Unknown',
                    username: data['username'] as String? ?? '',
                    isDark: isDark,
                    onAccept: () => _acceptRequest(doc.id, fromUid),
                    onDecline: () => _declineRequest(doc.id));
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSearchResults(String myUid, bool isDark) {
    if (_searching) return const Center(child: CircularProgressIndicator());
    if (_searchResults.isEmpty)
      return _empty(isDark,
          icon: Icons.search_rounded,
          msg: 'Search for users',
          sub: 'Type a username above');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (_, i) {
        final u = _searchResults[i];
        return _SearchResultTile(
            uid: u['uid'] as String,
            name: u['name'] as String? ?? 'Unknown',
            username: u['username'] as String? ?? '',
            isDark: isDark,
            onAdd: () => _sendFriendRequest(
                u['uid'] as String, u['name'] as String? ?? ''));
      },
    );
  }

  Widget _empty(bool isDark,
      {required IconData icon, required String msg, required String sub}) {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.04)),
          child: Icon(icon,
              size: 28,
              color: isDark
                  ? Colors.white.withOpacity(0.25)
                  : Colors.black.withOpacity(0.2))),
      const SizedBox(height: 14),
      Text(msg,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white.withOpacity(0.5)
                  : Colors.black.withOpacity(0.4))),
      const SizedBox(height: 4),
      Text(sub,
          style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? Colors.white.withOpacity(0.25)
                  : Colors.black.withOpacity(0.25))),
    ]));
  }
}

// ── Friend tile ──────────────────────────────────────
class _FriendTile extends StatelessWidget {
  final String uid, name, username;
  final bool isDark;
  final VoidCallback onChat, onRemove;
  const _FriendTile(
      {required this.uid,
      required this.name,
      required this.username,
      required this.isDark,
      required this.onChat,
      required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.06))),
      child: Row(children: [
        CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF2563EB).withOpacity(0.15),
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w700,
                    fontSize: 16))),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A))),
          Text('@$username',
              style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? Colors.white.withOpacity(0.4)
                      : Colors.black.withOpacity(0.4))),
        ])),
        GestureDetector(
            onTap: onChat,
            child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2563EB).withOpacity(0.1)),
                child: const Icon(Icons.chat_rounded,
                    color: Color(0xFF2563EB), size: 18))),
        const SizedBox(width: 8),
        GestureDetector(
            onTap: onRemove,
            child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: Colors.red.withOpacity(0.1)),
                child: Icon(Icons.person_remove_rounded,
                    color: Colors.red.withOpacity(0.7), size: 18))),
      ]),
    );
  }
}

// ── Request tile ─────────────────────────────────────
class _RequestTile extends StatelessWidget {
  final String name, username;
  final bool isDark;
  final VoidCallback onAccept, onDecline;
  const _RequestTile(
      {required this.name,
      required this.username,
      required this.isDark,
      required this.onAccept,
      required this.onDecline});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.2))),
      child: Row(children: [
        CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF2563EB).withOpacity(0.15),
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w700,
                    fontSize: 16))),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A))),
          Text('@$username',
              style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? Colors.white.withOpacity(0.4)
                      : Colors.black.withOpacity(0.4))),
        ])),
        GestureDetector(
            onTap: onAccept,
            child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('Accept',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)))),
        const SizedBox(width: 8),
        GestureDetector(
            onTap: onDecline,
            child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('Decline',
                    style: TextStyle(
                        color: isDark
                            ? Colors.white.withOpacity(0.5)
                            : Colors.black.withOpacity(0.4),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)))),
      ]),
    );
  }
}

// ── Search result tile ────────────────────────────────
class _SearchResultTile extends StatefulWidget {
  final String uid, name, username;
  final bool isDark;
  final VoidCallback onAdd;
  const _SearchResultTile(
      {required this.uid,
      required this.name,
      required this.username,
      required this.isDark,
      required this.onAdd});
  @override
  State<_SearchResultTile> createState() => _SearchResultTileState();
}

class _SearchResultTileState extends State<_SearchResultTile> {
  bool _sent = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: widget.isDark ? Colors.white.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: widget.isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.06))),
      child: Row(children: [
        CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.15),
            child: Text(
                widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontWeight: FontWeight.w700,
                    fontSize: 16))),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.name,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      widget.isDark ? Colors.white : const Color(0xFF0F172A))),
          Text('@${widget.username}',
              style: TextStyle(
                  fontSize: 12,
                  color: widget.isDark
                      ? Colors.white.withOpacity(0.4)
                      : Colors.black.withOpacity(0.4))),
        ])),
        GestureDetector(
            onTap: _sent
                ? null
                : () {
                    widget.onAdd();
                    setState(() => _sent = true);
                  },
            child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                    color: _sent
                        ? Colors.green.withOpacity(0.1)
                        : const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(_sent ? 'Sent' : 'Add',
                    style: TextStyle(
                        color: _sent ? Colors.green : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)))),
      ]),
    );
  }
}
