class SessionModel {
  final String sessionId;
  final String featureType;
  final String senderUserId;
  final String receiverUserId;
  final String status;
  final int credits;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int durationSeconds;
  final Map<String, dynamic> metadata;

  const SessionModel({
    required this.sessionId,
    required this.featureType,
    required this.senderUserId,
    required this.receiverUserId,
    this.status = 'requested',
    this.credits = 0,
    this.startedAt,
    this.completedAt,
    this.durationSeconds = 0,
    this.metadata = const {},
  });

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      sessionId: map['session_id'] ?? '',
      featureType: map['feature_type'] ?? '',
      senderUserId: map['sender_user_id'] ?? '',
      receiverUserId: map['receiver_user_id'] ?? '',
      status: map['status'] ?? 'requested',
      credits: map['credits'] ?? 0,
      startedAt: (map['started_at'] as dynamic)?.toDate(),
      completedAt: (map['completed_at'] as dynamic)?.toDate(),
      durationSeconds: map['duration_seconds'] ?? 0,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() => {
        'session_id': sessionId,
        'feature_type': featureType,
        'sender_user_id': senderUserId,
        'receiver_user_id': receiverUserId,
        'status': status,
        'credits': credits,
        'started_at': startedAt,
        'completed_at': completedAt,
        'duration_seconds': durationSeconds,
        'metadata': metadata,
      };
}
