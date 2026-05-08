class NotificationModel {
  final String notificationId;
  final String toUserId;
  final String fromUserId;
  final String title;
  final String body;
  // type: request | accepted | rejected | session_started | session_ended | credits | file_received | system
  final String type;
  final String featureType;
  final String sessionId;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const NotificationModel({
    required this.notificationId,
    required this.toUserId,
    required this.fromUserId,
    required this.title,
    required this.body,
    required this.type,
    this.featureType = '',
    this.sessionId = '',
    this.isRead = false,
    required this.createdAt,
    this.metadata = const {},
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      notificationId: map['notification_id'] ?? '',
      toUserId: map['to_user_id'] ?? '',
      fromUserId: map['from_user_id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? '',
      featureType: map['feature_type'] ?? '',
      sessionId: map['session_id'] ?? '',
      isRead: map['is_read'] ?? false,
      createdAt: (map['created_at'] as dynamic)?.toDate() ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() => {
        'notification_id': notificationId,
        'to_user_id': toUserId,
        'from_user_id': fromUserId,
        'title': title,
        'body': body,
        'type': type,
        'feature_type': featureType,
        'session_id': sessionId,
        'is_read': isRead,
        'created_at': createdAt,
        'metadata': metadata,
      };
}
