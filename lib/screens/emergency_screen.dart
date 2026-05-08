import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/nearby_service.dart';
import '../theme/app_colors.dart';

const _kEmergencyPlacesKey = 'YOUR_GOOGLE_PLACES_API_KEY';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});
  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  bool _active = false;
  bool _loading = false;
  Timer? _locationTimer;
  double? _lat, _lng;
  List<Map<String, dynamic>> _services = [];

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _activate() async {
    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    final fs = context.read<FirestoreService>();
    try {
      final pos = await NearbyService.getLocation();
      if (pos == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Location unavailable. Check permissions.'),
              behavior: SnackBarBehavior.floating));
          setState(() => _loading = false);
        }
        return;
      }
      _lat = pos.latitude;
      _lng = pos.longitude;

      await FirebaseFirestore.instance
          .collection('emergencies')
          .doc(auth.uid)
          .set({
        'uid': auth.uid,
        'name': fs.currentUser?.name ?? 'Unknown',
        'active': true,
        'lat': _lat,
        'lng': _lng,
        'startedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notify all friends
      final friendsSnap = await FirebaseFirestore.instance
          .collection('friends')
          .where('user1', isEqualTo: auth.uid)
          .get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in friendsSnap.docs) {
        final friendUid = doc['user2'] as String;
        final notifRef = FirebaseFirestore.instance.collection('notifications').doc();
        batch.set(notifRef, {
          'notification_id': notifRef.id,
          'to_user_id': friendUid,
          'from_user_id': auth.uid,
          'title': '🆘 Emergency Alert',
          'body': '${fs.currentUser?.name ?? 'Someone'} activated Emergency Mode!',
          'type': 'emergency',
          'feature_type': 'emergency',
          'session_id': '',
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
          'metadata': {},
        });
      }
      await batch.commit();

      await _fetchEmergencyServices();

      _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
        final p = await NearbyService.getLocation();
        if (p != null && mounted) {
          _lat = p.latitude;
          _lng = p.longitude;
          await FirebaseFirestore.instance
              .collection('emergencies')
              .doc(auth.uid)
              .update({
            'lat': _lat,
            'lng': _lng,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      if (mounted) setState(() { _active = true; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
      }
    }
  }

  Future<void> _deactivate() async {
    final auth = context.read<AuthService>();
    _locationTimer?.cancel();
    _locationTimer = null;
    await FirebaseFirestore.instance
        .collection('emergencies')
        .doc(auth.uid)
        .update({'active': false});
    if (mounted) setState(() => _active = false);
  }

  Future<void> _fetchEmergencyServices() async {
    if (_lat == null || _lng == null) return;
    final types = ['hospital', 'police', 'pharmacy'];
    final found = <Map<String, dynamic>>[];
    for (final t in types) {
      try {
        final url = Uri.parse(
            'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
            '?location=$_lat,$_lng&radius=3000&type=$t&key=$_kEmergencyPlacesKey');
        final resp = await http.get(url);
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final results = (data['results'] as List?) ?? [];
          if (results.isNotEmpty) {
            final r = results[0] as Map<String, dynamic>;
            found.add({
              'type': t,
              'name': r['name'] ?? '',
              'address': r['vicinity'] ?? '',
            });
          }
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _services = found);
  }

  Future<void> _call(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'hospital': return Icons.local_hospital_rounded;
      case 'police': return Icons.local_police_rounded;
      default: return Icons.local_pharmacy_rounded;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'hospital': return const Color(0xFFEF4444);
      case 'police': return const Color(0xFF2563EB);
      default: return const Color(0xFF22C55E);
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
                    onPressed: () {
                      if (_active) _deactivate();
                      Navigator.pop(context);
                    }),
                Expanded(
                    child: Text('Emergency Mode',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.starWhite : AppColors.textDark))),
                if (_active)
                  Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.4))),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        SizedBox(
                            width: 8, height: 8,
                            child: DecoratedBox(
                                decoration: BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle))),
                        SizedBox(width: 6),
                        Text('LIVE',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFEF4444))),
                      ])),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  const SizedBox(height: 20),
                  // SOS button
                  GestureDetector(
                    onTap: _loading ? null : (_active ? _deactivate : _activate),
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                              colors: _active
                                  ? [const Color(0xFFEF4444), const Color(0xFFB91C1C)]
                                  : [const Color(0xFFFF6B6B), const Color(0xFFEF4444)]),
                          boxShadow: [
                            BoxShadow(
                                color: const Color(0xFFEF4444)
                                    .withValues(alpha: _active ? 0.6 : 0.3),
                                blurRadius: _active ? 40 : 20,
                                spreadRadius: _active ? 10 : 0),
                          ]),
                      child: _loading
                          ? const Center(
                              child: SizedBox(
                                  width: 40, height: 40,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 3)))
                          : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Text('SOS',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 42,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2)),
                              const SizedBox(height: 6),
                              Text(
                                  _active ? 'Tap to cancel' : 'Tap for emergency',
                                  style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 11)),
                            ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                      _active
                          ? 'Emergency active — friends notified & location sharing on'
                          : 'Tap SOS to alert friends and find nearby help',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.black45)),
                  const SizedBox(height: 28),
                  // Quick call row
                  Row(children: [
                    _QuickCallBtn(label: 'Police', number: '100',
                        icon: Icons.local_police_rounded, color: const Color(0xFF2563EB),
                        onTap: () => _call('100')),
                    const SizedBox(width: 10),
                    _QuickCallBtn(label: 'Ambulance', number: '108',
                        icon: Icons.local_hospital_rounded, color: const Color(0xFFEF4444),
                        onTap: () => _call('108')),
                    const SizedBox(width: 10),
                    _QuickCallBtn(label: 'Fire', number: '101',
                        icon: Icons.local_fire_department_rounded, color: const Color(0xFFF97316),
                        onTap: () => _call('101')),
                  ]),
                  if (_services.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Nearest Help',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF09090B)))),
                    const SizedBox(height: 10),
                    ..._services.map((s) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: isDark ? Colors.white12 : const Color(0xFFE4E4E7))),
                      child: Row(children: [
                        Container(
                            width: 46, height: 46,
                            decoration: BoxDecoration(
                                color: _colorFor(s['type'] as String)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12)),
                            child: Icon(_iconFor(s['type'] as String),
                                color: _colorFor(s['type'] as String), size: 22)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(s['name'] as String? ?? '',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF09090B))),
                          const SizedBox(height: 2),
                          Text(s['address'] as String? ?? '',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white54 : Colors.black45),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ])),
                        const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
                      ]),
                    )),
                  ],
                  if (_active && _lat != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.2))),
                      child: Row(children: [
                        const Icon(Icons.location_on_rounded,
                            color: Color(0xFFEF4444), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(
                                'Live location: ${_lat!.toStringAsFixed(5)}, '
                                '${_lng!.toStringAsFixed(5)}',
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFFEF4444)))),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _QuickCallBtn extends StatelessWidget {
  final String label, number;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickCallBtn({
    required this.label, required this.number,
    required this.icon, required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [color, Color.lerp(color, Colors.black, 0.2)!]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 10, offset: const Offset(0, 4)),
              ]),
          child: Column(children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
            Text(number,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
          ])),
    ),
  );
}
