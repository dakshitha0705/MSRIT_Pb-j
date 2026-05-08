import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/session_model.dart';
import '../models/notification_model.dart';
import '../models/transaction_model.dart';
import '../models/app_file_model.dart';
import '../utils/constants.dart';

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  // ---- USER ----
  Future<void> loadUser(String uid) async {
    try {
      final doc =
          await _db.collection(AppConstants.collectionUsers).doc(uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data()!);
        notifyListeners();
      } else {
        debugPrint('⚠️ User document not found for uid: $uid');
      }
    } catch (e) {
      debugPrint('❌ Error loading user: $e');
      rethrow;
    }
  }

  Future<bool> isUsernameTaken(String username) async {
    final q = await _db
        .collection(AppConstants.collectionUsers)
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    return q.docs.isNotEmpty;
  }

  Future<String?> getEmailByUsername(String username) async {
    final q = await _db
        .collection(AppConstants.collectionUsers)
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return q.docs.first.data()['email'];
  }

  Future<String?> getEmailByPhone(String phone) async {
    final q = await _db
        .collection(AppConstants.collectionUsers)
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return q.docs.first.data()['email'];
  }

  Future<void> createUser(UserModel user) async {
    await _db
        .collection(AppConstants.collectionUsers)
        .doc(user.userId)
        .set({...user.toMap(), 'name_lower': user.name.toLowerCase()});
    _currentUser = user;
    notifyListeners();
  }

  Future<void> updateUserFields(String uid, Map<String, dynamic> fields) async {
    await _db.collection(AppConstants.collectionUsers).doc(uid).update(fields);
    if (_currentUser?.userId == uid) await loadUser(uid);
  }

  Future<UserModel?> getUserById(String uid) async {
    final doc =
        await _db.collection(AppConstants.collectionUsers).doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  // ---- SESSIONS ----
  Future<void> createSession(SessionModel session) async {
    await _db
        .collection(AppConstants.collectionSessions)
        .doc(session.sessionId)
        .set(session.toMap());
  }

  Future<void> updateSessionStatus(String sessionId, String status,
      {Map<String, dynamic>? extra}) async {
    final data = {'status': status, ...?extra};
    await _db
        .collection(AppConstants.collectionSessions)
        .doc(sessionId)
        .update(data);
  }

  Future<SessionModel?> getSession(String sessionId) async {
    final doc = await _db
        .collection(AppConstants.collectionSessions)
        .doc(sessionId)
        .get();
    if (!doc.exists) return null;
    return SessionModel.fromMap(doc.data()!);
  }

  Stream<SessionModel?> sessionStream(String sessionId) {
    return _db
        .collection(AppConstants.collectionSessions)
        .doc(sessionId)
        .snapshots()
        .map((s) {
      if (!s.exists) return null;
      return SessionModel.fromMap(s.data()!);
    });
  }

  // ---- NOTIFICATIONS ----
  Future<void> createNotification(NotificationModel n) async {
    await _db
        .collection(AppConstants.collectionNotifications)
        .doc(n.notificationId)
        .set(n.toMap());
  }

  Stream<List<NotificationModel>> notificationsStream(String userId) {
    return _db
        .collection(AppConstants.collectionNotifications)
        .where('to_user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => NotificationModel.fromMap(d.data())).toList());
  }

  Future<void> markNotificationRead(String notifId) async {
    await _db
        .collection(AppConstants.collectionNotifications)
        .doc(notifId)
        .update({'is_read': true});
  }

  Future<void> markAllNotificationsRead(String userId) async {
    final q = await _db
        .collection(AppConstants.collectionNotifications)
        .where('to_user_id', isEqualTo: userId)
        .where('is_read', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in q.docs) {
      batch.update(doc.reference, {'is_read': true});
    }
    await batch.commit();
  }

  // ---- TRANSACTIONS ----
  Future<void> addTransaction(TransactionModel t) async {
    await _db
        .collection(AppConstants.collectionTransactions)
        .doc(t.transactionId)
        .set(t.toMap());
  }

  Stream<List<TransactionModel>> transactionsStream(String userId) {
    return _db
        .collection(AppConstants.collectionTransactions)
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .limit(100)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => TransactionModel.fromMap(d.data())).toList());
  }

  // ---- FILES ----
  Future<void> saveFile(AppFileModel file) async {
    await _db
        .collection(AppConstants.collectionFiles)
        .doc(file.fileId)
        .set(file.toMap());
  }

  Stream<List<AppFileModel>> filesStream(String userId) {
    return _db
        .collection(AppConstants.collectionFiles)
        .where('receiver_user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => AppFileModel.fromMap(d.data())).toList());
  }

  // ---- NEARBY USERS ----
  Future<void> updateUserLocation(double lat, double lng) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _db.collection(AppConstants.collectionUsers).doc(uid).update({
      'location': {
        'lat': lat,
        'lng': lng,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    });
  }

  Future<List<Map<String, dynamic>>> getNearbyUsers(
      double lat, double lng, double radiusKm) async {
    final double delta = radiusKm / 111.0;
    final snap = await _db
        .collection(AppConstants.collectionUsers)
        .where('location.lat', isGreaterThan: lat - delta)
        .where('location.lat', isLessThan: lat + delta)
        .get();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final results = <Map<String, dynamic>>[];

    for (final doc in snap.docs) {
      if (doc.id == uid) continue;
      final data = doc.data();
      final loc = data['location'] as Map<String, dynamic>?;
      if (loc == null) continue;

      final uLat = (loc['lat'] as num).toDouble();
      final uLng = (loc['lng'] as num).toDouble();

      final lngDelta = radiusKm / (111.0 * cos(lat * pi / 180));
      if (uLng < lng - lngDelta || uLng > lng + lngDelta) continue;

      final distM = _distanceMeters(lat, lng, uLat, uLng);
      if (distM > radiusKm * 1000) continue;

      results.add({
        'uid': doc.id,
        'name': data['name'] as String? ?? 'Unknown',
        'username': data['username'] as String? ?? '',
        'avatar': data['avatar'] as String? ?? 'panda',
        'phone': data['phone'] as String? ?? '',
        'device': data['device'] ?? <String, dynamic>{},
        'distance': distM.round(),
      });
    }

    results.sort(
        (a, b) => (a['distance'] as int).compareTo(b['distance'] as int));
    return results;
  }

  double _distanceMeters(
      double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}
