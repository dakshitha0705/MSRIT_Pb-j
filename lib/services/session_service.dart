import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_service.dart';
import 'credit_service.dart';
import 'notification_service.dart';
import '../models/session_model.dart';
import '../models/notification_model.dart';
import '../utils/constants.dart';
import '../services/location_service.dart';

class SessionService {
  final FirestoreService _fs;
  late final CreditService _credits;

  SessionService(this._fs) {
    _credits = CreditService(_fs);
  }

  Future<String> createRequest({
    required String senderUid,
    required String receiverUid,
    required String featureType,
    required int credits,
    bool emergency = false,
  }) async {
    final sessionId = const Uuid().v4();
    final actualCredits = emergency && featureType == 'battery' ? 20 : credits;
    final verificationCode =
        featureType == 'battery' ? _generateVerificationCode() : null;

    await _fs.createSession(
      SessionModel(
        sessionId: sessionId,
        featureType: featureType,
        senderUserId: senderUid,
        receiverUserId: receiverUid,
        status: 'requested',
        credits: actualCredits,
        metadata: {
          if (emergency) 'emergency': true,
          if (verificationCode != null) 'verify_code': verificationCode,
          if (verificationCode != null) 'verified': false,
        },
      ),
    );

    final sender = await _fs.getUserById(senderUid);
    final title = emergency
        ? 'Emergency ${_cap(featureType)} Request'
        : 'New ${_cap(featureType)} Request';
    final body = emergency
        ? '${sender?.name ?? 'Someone'} requested emergency $featureType help nearby.'
        : '${sender?.name ?? 'Someone'} requested $featureType help nearby.';

    await _fs.createNotification(
      NotificationModel(
        notificationId: const Uuid().v4(),
        toUserId: receiverUid,
        fromUserId: senderUid,
        title: title,
        body: body,
        type: emergency ? 'emergency_request' : 'request',
        featureType: featureType,
        sessionId: sessionId,
        createdAt: DateTime.now(),
        metadata: {
          if (emergency) 'emergency': true,
          if (verificationCode != null) 'verify_code': verificationCode,
        },
      ),
    );

    if (emergency) {
      NotificationService.showLocal(title, body);
    }

    return sessionId;
  }

  Future<void> acceptSession(String sessionId, String receiverUid) async {
    final session = await _fs.getSession(sessionId);
    if (session == null) return;

    String? landmark;
    final receiver = await _fs.getUserById(receiverUid);
    final loc = receiver?.location;

    if (loc != null && loc['lat'] != null && loc['lng'] != null) {
      final lat = (loc['lat'] as num).toDouble();
      final lng = (loc['lng'] as num).toDouble();
      landmark = LocationService.getNearestLandmark(lat, lng);
    }

    final metadata = Map<String, dynamic>.from(session.metadata);
    if (landmark != null) {
      metadata['landmark'] = landmark;
    }

    await _fs.updateSessionStatus(
      sessionId,
      'accepted',
      extra: {
        'started_at': Timestamp.fromDate(DateTime.now()),
        'metadata': metadata,
      },
    );

    await _fs.createNotification(
      NotificationModel(
        notificationId: const Uuid().v4(),
        toUserId: session.senderUserId,
        fromUserId: receiverUid,
        title: 'Request Accepted',
        body:
            '${receiver?.name ?? 'Someone'} accepted your ${session.featureType} request. ${landmark != null ? 'Pickup near $landmark.' : ''}',
        type: 'accepted',
        featureType: session.featureType,
        sessionId: sessionId,
        createdAt: DateTime.now(),
        metadata: {if (landmark != null) 'landmark': landmark},
      ),
    );
  }

  Future<void> rejectSession(String sessionId, String receiverUid) async {
    await _fs.updateSessionStatus(sessionId, 'rejected');

    final session = await _fs.getSession(sessionId);
    if (session == null) return;

    await _fs.createNotification(
      NotificationModel(
        notificationId: const Uuid().v4(),
        toUserId: session.senderUserId,
        fromUserId: receiverUid,
        title: 'Request Declined',
        body: 'Your ${session.featureType} request was declined.',
        type: 'rejected',
        featureType: session.featureType,
        sessionId: sessionId,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> completeSession(
    String sessionId, {
    required bool senderStopped,
  }) async {
    final session = await _fs.getSession(sessionId);
    if (session == null) return;

    // Guard: if already completed, skip entirely — prevents duplicate credit transfer
    if (session.status == 'completed') return;

    final startedAt = session.startedAt ?? DateTime.now();
    final dur = DateTime.now().difference(startedAt).inSeconds;

    await _fs.updateSessionStatus(
      sessionId,
      'completed',
      extra: {
        'completed_at': Timestamp.fromDate(DateTime.now()),
        'duration_seconds': dur,
      },
    );

    final minDur =
        session.featureType == 'data' ? AppConstants.minDataSessionSeconds : 0;

    final verified = session.featureType != 'battery' ||
        (session.metadata['verified'] == true);

    final shouldGiveCredits = !senderStopped && dur >= minDur && verified;

    if (shouldGiveCredits) {
      await _credits.addCredits(
        session.receiverUserId,
        session.credits,
        session.featureType,
        sessionId,
      );

      await _credits.deductCredits(
        session.senderUserId,
        session.credits,
        session.featureType,
        sessionId,
      );
    }

    final completionText = shouldGiveCredits
        ? 'Session complete. ${session.credits} credits exchanged.'
        : session.featureType == 'battery' && !verified
            ? 'Session ended. Verification was not completed, no credits exchanged.'
            : 'Session ended. No credits exchanged.';

    for (final uid in [session.senderUserId, session.receiverUserId]) {
      await _fs.createNotification(
        NotificationModel(
          notificationId: const Uuid().v4(),
          toUserId: uid,
          fromUserId: 'system',
          title: 'Session Complete',
          body: completionText,
          type: 'session_ended',
          featureType: session.featureType,
          sessionId: sessionId,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  Future<bool> verifySession(String sessionId, String code) async {
    final session = await _fs.getSession(sessionId);
    if (session == null || session.status != 'accepted') return false;

    final storedCode = session.metadata['verify_code'] as String?;
    if (storedCode != code) return false;

    // Mark as verified
    await _fs.updateSessionStatus(sessionId, 'accepted', extra: {
      'metadata': {
        ...session.metadata,
        'verified': true,
      }
    });

    // Complete the session immediately after verification
    await completeSession(sessionId, senderStopped: false);

    return true;
  }

  Future<void> shareLocation(String sessionId, String address, double lat,
      double lng, bool isLive) async {
    final session = await _fs.getSession(sessionId);
    if (session == null || session.status != 'accepted') return;

    final metadata = Map<String, dynamic>.from(session.metadata);
    metadata['shared_address'] = address;
    metadata['shared_lat'] = lat;
    metadata['shared_lng'] = lng;
    metadata['shared_live'] = isLive;

    await _fs.updateSessionStatus(sessionId, 'accepted', extra: {
      'metadata': metadata,
    });
  }

  String _generateVerificationCode() {
    final random = Random.secure();
    final code = 100000 + random.nextInt(900000);
    return code.toString();
  }

  String _cap(String s) {
    return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  }
}
