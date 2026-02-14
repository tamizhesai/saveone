import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<Map<String, String>?> uploadFile({
    required File file,
    required int userId,
    required String fileName,
  }) async {
    try {
      final String filePath = 'users/$userId/documents/$fileName';
      final Reference ref = _storage.ref().child(filePath);
      
      final UploadTask uploadTask = ref.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;
      
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return {
        'firebase_url': downloadUrl,
        'firebase_path': filePath,
      };
    } catch (e) {
      print('Firebase Storage Upload Error: $e');
      return null;
    }
  }

  Future<bool> deleteFile(String filePath) async {
    try {
      final Reference ref = _storage.ref().child(filePath);
      await ref.delete();
      return true;
    } catch (e) {
      print('Firebase Storage Delete Error: $e');
      return false;
    }
  }

  Future<Map<String, String>?> uploadProfilePicture({
    required File file,
    required int userId,
  }) async {
    try {
      final String filePath = 'users/$userId/profile_picture';
      final Reference ref = _storage.ref().child(filePath);

      final UploadTask uploadTask = ref.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;

      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return {
        'firebase_url': downloadUrl,
        'firebase_path': filePath,
      };
    } catch (e) {
      print('Firebase Storage Profile Picture Upload Error: $e');
      return null;
    }
  }

  Future<String?> getDownloadUrl(String filePath) async {
    try {
      final Reference ref = _storage.ref().child(filePath);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Firebase Storage Get URL Error: $e');
      return null;
    }
  }
}
