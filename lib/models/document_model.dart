class DocumentModel {
  final int? id;
  final int userId;
  final String fileName;
  final String filePath;
  final int fileSize;
  final DateTime uploadedAt;

  DocumentModel({
    this.id,
    required this.userId,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.uploadedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'],
      userId: json['user_id'],
      fileName: json['file_name'],
      filePath: json['file_path'],
      fileSize: json['file_size'],
      uploadedAt: DateTime.parse(json['uploaded_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'file_name': fileName,
      'file_path': filePath,
      'file_size': fileSize,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }
}
