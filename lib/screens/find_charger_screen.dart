import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/nearby_service.dart';
import '../theme/app_colors.dart';

const _kPlacesKey = 'YOUR_GOOGLE_PLACES_API_KEY';

class FindChargerScreen extends StatefulWidget {
  const FindChargerScreen({super.key});
  @override
  State<FindChargerScreen> createState() => _FindChargerScreenState();
}

class _FindChargerScreenState extends State<FindChargerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _places = [];
  double? _lat, _lng;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadLocation();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pos = await NearbyService.getLocation();
      if (pos == null) {
        if (mounted) {
          setState(() {
            _error = 'Location unavailable. Please check permissions.';
            _loading = false;
          });
        }
        return;
      }
      _lat = pos.latitude;
      _lng = pos.longitude;
      await _fetchPlaces();
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _fetchPlaces() async {
    if (_lat == null || _lng == null) return;
    setState(() => _loading = true);
    try {
      final types = ['cafe', 'library', 'shopping_mall', 'restaurant'];
      final all = <Map<String, dynamic>>[];
      for (final t in types) {
        final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
          '?location=$_lat,$_lng&radius=1500&type=$t&key=$_kPlacesKey',
        );
        final resp = await http.get(url);
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final results = (data['results'] as List?) ?? [];
          for (final r in results) {
            all.add({
              'name': r['name'] ?? '',
              'address': r['vicinity'] ?? '',
              'type': t,
              'lat': (r['geometry']?['location']?['lat'] as num?)?.toDouble(),
              'lng': (r['geometry']?['location']?['lng'] as num?)?.toDouble(),
              'rating': (r['rating'] as num?)?.toDouble() ?? 0.0,
              'open': r['opening_hours']?['open_now'] ?? false,
            });
          }
        }
      }
      final seen = <String>{};
      final unique = all.where((p) => seen.add(p['name'] as String)).toList();
      if (mounted) setState(() { _places = unique; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _reportSpot() async {
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available yet.')));
      return;
    }
    final auth = context.read<AuthService>();
    final name = await _showReportDialog();
    if (name == null || name.isEmpty) return;
    try {
      final docRef = FirebaseFirestore.instance.collection('charger_spots').doc();
      await docRef.set({
        'name': name,
        'reportedBy': auth.uid,
        'lat': _lat,
        'lng': _lng,
        'createdAt': FieldValue.serverTimestamp(),
        'upvotes': 0,
      });
      await FirebaseFirestore.instance
          .collection('users')
          .doc(auth.uid)
          .update({'credits': FieldValue.increment(10)});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Spot reported! +10 credits earned'),
          backgroundColor: Color(0xFF22C55E),
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

  Future<String?> _showReportDialog() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Charging Spot'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'e.g. McDonald\'s on Main St (USB ports available)',
            labelText: 'Spot name / description',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Report (+10 credits)'),
          ),
        ],
      ),
    );
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
              padding: const EdgeInsets.fromLTRB(8, 12, 12, 0),
              child: Row(children: [
                IconButton(
                    icon: Icon(Icons.arrow_back_ios_rounded,
                        color: isDark ? AppColors.starWhite : AppColors.textDark),
                    onPressed: () => Navigator.pop(context)),
                Expanded(
                    child: Text('Find Charger',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.starWhite : AppColors.textDark))),
                IconButton(
                    icon: Icon(Icons.refresh_rounded,
                        color: isDark ? AppColors.starWhite : AppColors.textDark),
                    onPressed: _loadLocation),
                GestureDetector(
                    onTap: _reportSpot,
                    child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            borderRadius: BorderRadius.circular(10)),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.add_location_alt_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 5),
                          Text('Report', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
                        ]))),
              ]),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12)),
              child: TabBar(
                controller: _tabs,
                indicator: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(10)),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: const [Tab(text: 'Nearby Places'), Tab(text: 'Community Spots')],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _NearbyTab(loading: _loading, error: _error, places: _places, isDark: isDark),
                  _CommunityTab(isDark: isDark),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _NearbyTab extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<Map<String, dynamic>> places;
  final bool isDark;
  const _NearbyTab({required this.loading, required this.error, required this.places, required this.isDark});

  IconData _iconFor(String type) {
    switch (type) {
      case 'cafe': return Icons.local_cafe_rounded;
      case 'library': return Icons.local_library_rounded;
      case 'shopping_mall': return Icons.shopping_bag_rounded;
      default: return Icons.restaurant_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(error!, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red))));
    }
    if (places.isEmpty) {
      return Center(child: Text('No places found nearby.',
          style: TextStyle(color: isDark ? Colors.white54 : Colors.black45)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: places.length,
      itemBuilder: (_, i) {
        final p = places[i];
        final open = p['open'] as bool? ?? false;
        final rating = p['rating'] as double? ?? 0.0;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE4E4E7))),
          child: Row(children: [
            Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(_iconFor(p['type'] as String? ?? ''),
                    color: const Color(0xFF2563EB), size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p['name'] as String? ?? '',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF09090B))),
              const SizedBox(height: 2),
              Text(p['address'] as String? ?? '',
                  style: TextStyle(fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black45),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                if (rating > 0) ...[
                  const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFBBF24)),
                  const SizedBox(width: 2),
                  Text(rating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 11, color: Color(0xFFFBBF24))),
                  const SizedBox(width: 8),
                ],
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                        color: open
                            ? const Color(0xFF22C55E).withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(open ? 'Open' : 'Closed',
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w700,
                            color: open ? const Color(0xFF22C55E) : Colors.red))),
              ]),
            ])),
            const Icon(Icons.bolt_rounded, color: Color(0xFF2563EB), size: 18),
          ]),
        );
      },
    );
  }
}

class _CommunityTab extends StatelessWidget {
  final bool isDark;
  const _CommunityTab({required this.isDark});

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('charger_spots')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots(),
    builder: (_, snap) {
      final docs = snap.data?.docs ?? [];
      if (docs.isEmpty) {
        return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.location_off_rounded, size: 44,
              color: isDark ? Colors.white24 : Colors.black26),
          const SizedBox(height: 12),
          Text('No community spots yet',
              style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)),
          const SizedBox(height: 4),
          const Text('Be the first to report a charging spot!',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ]));
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: docs.length,
        itemBuilder: (_, i) {
          final d = docs[i].data() as Map<String, dynamic>;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE4E4E7))),
            child: Row(children: [
              Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.ev_station_rounded,
                      color: Color(0xFF22C55E), size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d['name'] as String? ?? 'Spot',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF09090B))),
                const SizedBox(height: 2),
                Text('Reported by ${d['reportedBy'] ?? 'Anonymous'}',
                    style: TextStyle(fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.black45)),
              ])),
              Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.thumb_up_rounded, size: 12, color: Color(0xFF22C55E)),
                    const SizedBox(width: 4),
                    Text('${d['upvotes'] ?? 0}',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF22C55E), fontWeight: FontWeight.w700)),
                  ])),
            ]),
          );
        },
      );
    },
  );
}
