class DocumentModel {
  final int? id;
  final int userId;
  final String fileName;
  final String firebaseUrl;
  final String firebasePath;
  final int fileSize;
  final String? fileType;
  final DateTime uploadedAt;

  DocumentModel({
    this.id,
    required this.userId,
    required this.fileName,
    required this.firebaseUrl,
    required this.firebasePath,
    required this.fileSize,
    this.fileType,
    required this.uploadedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'],
      userId: json['user_id'],
      fileName: json['file_name'],
      firebaseUrl: json['firebase_url'],
      firebasePath: json['firebase_path'],
      fileSize: json['file_size'],
      fileType: json['file_type'],
      uploadedAt: DateTime.parse(json['uploaded_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'file_name': fileName,
      'firebase_url': firebaseUrl,
      'firebase_path': firebasePath,
      'file_size': fileSize,
      'file_type': fileType,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }
}
