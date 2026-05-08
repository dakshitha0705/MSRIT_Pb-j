import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/nearby_service.dart';
import '../theme/app_colors.dart';

const _kGeocodingKey = 'YOUR_GOOGLE_PLACES_API_KEY';

class FindPowerbankScreen extends StatefulWidget {
  const FindPowerbankScreen({super.key});
  @override
  State<FindPowerbankScreen> createState() => _FindPowerbankScreenState();
}

class _FindPowerbankScreenState extends State<FindPowerbankScreen> {
  bool _loading = false;
  bool _toggling = false;
  bool _isAvailable = false;
  String? _landmark;
  double? _lat, _lng;
  List<Map<String, dynamic>> _nearby = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    try {
      final doc = await FirebaseFirestore.instance
          .collection('powerbank_available')
          .doc(auth.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        _isAvailable = data['active'] as bool? ?? false;
        _landmark = data['landmark'] as String?;
      }
      final pos = await NearbyService.getLocation();
      if (pos != null) {
        _lat = pos.latitude;
        _lng = pos.longitude;
        await _loadNearby();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _getLandmark(double lat, double lng) async {
    try {
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$_kGeocodingKey');
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final results = (data['results'] as List?) ?? [];
        if (results.isNotEmpty) {
          return results[0]['formatted_address'] as String?;
        }
      }
    } catch (_) {}
    return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }

  Future<void> _toggleAvailability() async {
    if (_lat == null || _lng == null) return;
    setState(() => _toggling = true);
    final auth = context.read<AuthService>();
    final fs = context.read<FirestoreService>();
    try {
      final newState = !_isAvailable;
      String? landmark = _landmark;
      if (newState && landmark == null) {
        landmark = await _getLandmark(_lat!, _lng!);
      }
      await FirebaseFirestore.instance
          .collection('powerbank_available')
          .doc(auth.uid)
          .set({
        'uid': auth.uid,
        'name': fs.currentUser?.name ?? 'Unknown',
        'active': newState,
        'landmark': newState ? landmark : null,
        'lat': _lat,
        'lng': _lng,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) {
        setState(() {
          _isAvailable = newState;
          if (newState) _landmark = landmark;
        });
      }
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _loadNearby() async {
    if (_lat == null || _lng == null) return;
    final auth = context.read<AuthService>();
    final snap = await FirebaseFirestore.instance
        .collection('powerbank_available')
        .where('active', isEqualTo: true)
        .get();
    final list = <Map<String, dynamic>>[];
    for (final doc in snap.docs) {
      if (doc.id == auth.uid) continue;
      final data = doc.data();
      list.add({
        'uid': doc.id,
        'name': data['name'] ?? 'Unknown',
        'landmark': data['landmark'] ?? 'Nearby',
      });
    }
    if (mounted) setState(() => _nearby = list);
  }

  Future<void> _sendRequest(String toUid, String toName) async {
    final auth = context.read<AuthService>();
    final fs = context.read<FirestoreService>();
    try {
      final docRef = FirebaseFirestore.instance.collection('notifications').doc();
      await docRef.set({
        'notification_id': docRef.id,
        'to_user_id': toUid,
        'from_user_id': auth.uid,
        'title': 'Powerbank Request',
        'body': '${fs.currentUser?.name ?? 'Someone'} wants to borrow your powerbank',
        'type': 'powerbank_request',
        'feature_type': 'powerbank',
        'session_id': '',
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
        'metadata': {'fromName': fs.currentUser?.name ?? ''},
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Request sent to $toName!'),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                        color: isDark ? AppColors.starWhite : AppColors.textDark),
                    onPressed: () => Navigator.pop(context)),
                Expanded(
                    child: Text('Find Powerbank',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.starWhite : AppColors.textDark))),
              ]),
            ),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    // My availability card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: _isAvailable
                                  ? [const Color(0xFF22C55E), const Color(0xFF16A34A)]
                                  : [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: (_isAvailable
                                    ? const Color(0xFF22C55E)
                                    : const Color(0xFF6366F1))
                                    .withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6)),
                          ]),
                      child: Row(children: [
                        Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle),
                            child: Icon(
                                _isAvailable
                                    ? Icons.battery_full_rounded
                                    : Icons.battery_charging_full_rounded,
                                color: Colors.white, size: 28)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                              _isAvailable ? 'You\'re available' : 'Share your powerbank',
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(
                              _isAvailable
                                  ? (_landmark ?? 'Location shared')
                                  : 'Toggle to let nearby users find you',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
                              maxLines: 2),
                        ])),
                        const SizedBox(width: 10),
                        _toggling
                            ? const SizedBox(
                                width: 24, height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : Switch.adaptive(
                                value: _isAvailable,
                                onChanged: (_) => _toggleAvailability(),
                                activeThumbColor: Colors.white,
                                inactiveThumbColor: Colors.white70),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    Row(children: [
                      Text('Available Nearby',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF09090B))),
                      const SizedBox(width: 8),
                      Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10)),
                          child: Text('${_nearby.length}',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700,
                                  color: Color(0xFF22C55E)))),
                      const Spacer(),
                      GestureDetector(
                          onTap: _loadNearby,
                          child: const Icon(Icons.refresh_rounded,
                              size: 20, color: Color(0xFF6366F1))),
                    ]),
                    const SizedBox(height: 10),
                    if (_nearby.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: isDark ? Colors.white12 : const Color(0xFFE4E4E7))),
                        child: Column(children: [
                          Icon(Icons.battery_unknown_rounded, size: 44,
                              color: isDark ? Colors.white24 : Colors.black26),
                          const SizedBox(height: 12),
                          Text('No one nearby with a powerbank',
                              style: TextStyle(
                                  color: isDark ? Colors.white38 : Colors.black38)),
                        ]),
                      )
                    else
                      ...(_nearby.map((u) => _PowerbankUserCard(
                            user: u,
                            isDark: isDark,
                            onRequest: () => _sendRequest(
                                u['uid'] as String, u['name'] as String),
                          ))),
                  ]),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class _PowerbankUserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isDark;
  final VoidCallback onRequest;
  const _PowerbankUserCard(
      {required this.user, required this.isDark, required this.onRequest});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFE4E4E7))),
    child: Row(children: [
      CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFF22C55E).withValues(alpha: 0.12),
          child: Text(
              (user['name'] as String).isNotEmpty
                  ? (user['name'] as String)[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  color: Color(0xFF22C55E),
                  fontWeight: FontWeight.w700,
                  fontSize: 16))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(user['name'] as String? ?? 'User',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF09090B))),
        const SizedBox(height: 2),
        Row(children: [
          const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFF6366F1)),
          const SizedBox(width: 3),
          Expanded(
              child: Text(user['landmark'] as String? ?? 'Nearby',
                  style: TextStyle(fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black45),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
      ])),
      GestureDetector(
          onTap: onRequest,
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('Request',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)))),
    ]),
  );
}
