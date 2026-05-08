class TransactionModel {
  final String transactionId;
  final String userId;
  final String type; // 'credit' or 'debit'
  final String
      featureType; // 'battery', 'data', 'file', 'media', 'contact', 'game'
  final int amount;
  final String sessionId;
  final DateTime createdAt;

  const TransactionModel({
    required this.transactionId,
    required this.userId,
    required this.type,
    required this.featureType,
    required this.amount,
    required this.sessionId,
    required this.createdAt,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      transactionId: map['transaction_id'] ?? '',
      userId: map['user_id'] ?? '',
      type: map['type'] ?? '',
      featureType: map['feature_type'] ?? '',
      amount: map['amount'] ?? 0,
      sessionId: map['session_id'] ?? '',
      createdAt: (map['created_at'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'transaction_id': transactionId,
        'user_id': userId,
        'type': type,
        'feature_type': featureType,
        'amount': amount,
        'session_id': sessionId,
        'created_at': createdAt,
      };
}
