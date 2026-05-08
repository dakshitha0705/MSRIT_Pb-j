import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/nearby_service.dart';
import '../services/auth_service.dart';

class NearbyUsersWidget extends StatefulWidget {
  final String mode; // 'battery' or 'data'
  const NearbyUsersWidget({super.key, required this.mode});

  @override
  State<NearbyUsersWidget> createState() => _NearbyUsersWidgetState();
}

class _NearbyUsersWidgetState extends State<NearbyUsersWidget> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String _error = '';
  final _requested = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    // Capture context-dependent services before any await
    final fs = context.read<FirestoreService>();
    try {
      final pos = await NearbyService.getLocation();
      if (pos == null) {
        if (mounted) {
          setState(() {
            _error = 'Location permission required to find nearby users.';
            _loading = false;
          });
        }
        return;
      }

      await fs.updateUserLocation(pos.latitude, pos.longitude);
      final users = await fs.getNearbyUsers(pos.latitude, pos.longitude, 1.0);

      if (mounted) {
        setState(() {
          _users = users;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load nearby users.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _sendRequest(String toUid, String toName) async {
    setState(() => _requested.add(toUid));
    final auth = context.read<AuthService>();
    final me = context.read<FirestoreService>().currentUser;
    final notifRef =
        FirebaseFirestore.instance.collection('notifications').doc();
    await notifRef.set({
      'notification_id': notifRef.id,
      'to_user_id': toUid,
      'from_user_id': auth.uid,
      'from_name': me?.name ?? 'Someone',
      'title': '${widget.mode == 'battery' ? 'Battery' : 'Data'} request',
      'body': '${me?.name ?? 'Someone'} wants to share '
          '${widget.mode == 'battery' ? 'battery' : 'data'} with you nearby!',
      'type': '${widget.mode}_request',
      'feature_type': widget.mode,
      'session_id': '',
      'is_read': false,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Nearby Users',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF09090B))),
        const Spacer(),
        GestureDetector(
            onTap: _load,
            child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: const Row(children: [
                  Icon(Icons.refresh_rounded,
                      size: 14, color: Color(0xFF6366F1)),
                  SizedBox(width: 4),
                  Text('Refresh',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6366F1))),
                ]))),
      ]),
      const SizedBox(height: 10),
      if (_loading)
        const Center(
            child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: Color(0xFF6366F1)))),
      if (_error.isNotEmpty)
        Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.2))),
            child: Row(children: [
              const Icon(Icons.location_off_rounded,
                  color: Color(0xFFEF4444), size: 18),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(_error,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFFEF4444)))),
            ])),
      if (!_loading && _error.isEmpty && _users.isEmpty)
        Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE4E4E7))),
            child: Column(children: [
              Icon(Icons.person_search_rounded,
                  size: 32, color: isDark ? Colors.white24 : Colors.black26),
              const SizedBox(height: 8),
              Text('No users found nearby',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark ? Colors.white38 : const Color(0xFF71717A))),
              const SizedBox(height: 4),
              Text('Make sure others have the app open',
                  style: TextStyle(
                      fontSize: 11,
                      color:
                          isDark ? Colors.white24 : const Color(0xFFA1A1AA))),
            ])),
      if (!_loading && _users.isNotEmpty)
        ..._users.map((u) {
          final uid = u['uid'] as String;
          final name = u['name'] as String;
          final distance = u['distance'] as int;
          final sent = _requested.contains(uid);

          return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color:
                          isDark ? Colors.white12 : const Color(0xFFE4E4E7))),
              child: Row(children: [
                Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6366F1).withValues(alpha: 0.12)),
                    child: Center(
                        child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                                color: Color(0xFF6366F1),
                                fontWeight: FontWeight.w700,
                                fontSize: 16)))),
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
                      const SizedBox(height: 2),
                      Row(children: [
                        const Icon(Icons.location_on_rounded,
                            size: 11, color: Color(0xFF34D399)),
                        const SizedBox(width: 3),
                        Text(
                            distance < 1000
                                ? '${distance}m away'
                                : '${(distance / 1000).toStringAsFixed(1)}km away',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF34D399),
                                fontWeight: FontWeight.w500)),
                      ]),
                    ])),
                GestureDetector(
                    onTap: sent ? null : () => _sendRequest(uid, name),
                    child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                            color: sent
                                ? const Color(0xFF34D399).withValues(alpha: 0.1)
                                : const Color(0xFF6366F1),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(sent ? 'Sent ✓' : 'Request',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: sent
                                    ? const Color(0xFF34D399)
                                    : Colors.white)))),
              ]));
        }),
    ]);
  }
}
