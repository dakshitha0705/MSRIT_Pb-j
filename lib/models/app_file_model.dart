class AppFileModel {
  final String fileId;
  final String fileName;
  final String fileType;
  final int fileSizeBytes;
  final String senderUserId;
  final String receiverUserId;
  final String storageUrl;
  final String localPath;
  final DateTime createdAt;
  final String sessionId;

  const AppFileModel({
    required this.fileId,
    required this.fileName,
    required this.fileType,
    required this.fileSizeBytes,
    required this.senderUserId,
    required this.receiverUserId,
    this.storageUrl = '',
    this.localPath = '',
    required this.createdAt,
    required this.sessionId,
  });

  String get fileSizeLabel {
    if (fileSizeBytes < 1024 * 1024)
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Credit cost based on file size
  int get creditCost {
    final mb = fileSizeBytes / (1024 * 1024);
    if (mb < 5) return 2;
    if (mb < 20) return 7;
    return 15;
  }

  factory AppFileModel.fromMap(Map<String, dynamic> map) {
    return AppFileModel(
      fileId: map['file_id'] ?? '',
      fileName: map['file_name'] ?? '',
      fileType: map['file_type'] ?? '',
      fileSizeBytes: map['file_size_bytes'] ?? 0,
      senderUserId: map['sender_user_id'] ?? '',
      receiverUserId: map['receiver_user_id'] ?? '',
      storageUrl: map['storage_url'] ?? '',
      localPath: map['local_path'] ?? '',
      createdAt: (map['created_at'] as dynamic)?.toDate() ?? DateTime.now(),
      sessionId: map['session_id'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'file_id': fileId,
        'file_name': fileName,
        'file_type': fileType,
        'file_size_bytes': fileSizeBytes,
        'sender_user_id': senderUserId,
        'receiver_user_id': receiverUserId,
        'storage_url': storageUrl,
        'local_path': localPath,
        'created_at': createdAt,
        'session_id': sessionId,
      };
}
