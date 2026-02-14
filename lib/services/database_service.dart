import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../models/user_model.dart';
import '../models/document_model.dart';

class DatabaseService {
  static const String baseUrl = 'http://172.20.10.5:3000/api';

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<int?> createUser({
    required String name,
    required String email,
    required String phoneNumber,
    required String password,
    required String nomineeNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone_number': phoneNumber,
          'password': _hashPassword(password),
          'nominee_number': nomineeNumber,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id'];
      }
      return null;
    } catch (e) {
      print('Create User Error: $e');
      return null;
    }
  }

  Future<UserModel?> authenticateUser({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/signin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone_number': phoneNumber,
          'password': _hashPassword(password),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Authenticate User Error: $e');
      return null;
    }
  }

  Future<List<DocumentModel>> getUserDocuments(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/documents/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((doc) => DocumentModel.fromJson(doc)).toList();
      }
      return [];
    } catch (e) {
      print('Get Documents Error: $e');
      return [];
    }
  }

  Future<bool> uploadDocument({
    required int userId,
    required String fileName,
    required String firebaseUrl,
    required String firebasePath,
    required int fileSize,
    required String fileType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/documents/upload'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'file_name': fileName,
          'firebase_url': firebaseUrl,
          'firebase_path': firebasePath,
          'file_size': fileSize,
          'file_type': fileType,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Upload Document Error: $e');
      return false;
    }
  }

  Future<int> getDocumentCount(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/documents/$userId/count'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Get Document Count Error: $e');
      return 0;
    }
  }

  Future<UserModel?> loginWithFingerprint(int fingerprintId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/fingerprint/check'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fingerprint_id': fingerprintId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['exists'] == true) {
          return UserModel.fromJson(data['user']);
        }
      }
      return null;
    } catch (e) {
      print('Fingerprint Login Error: $e');
      return null;
    }
  }

  Future<int?> signupWithFingerprint({
    required int fingerprintId,
    required String name,
    required String email,
    required String phoneNumber,
    required String password,
    required String nomineeNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/fingerprint/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fingerprint_id': fingerprintId,
          'name': name,
          'email': email,
          'phone_number': phoneNumber,
          'password': _hashPassword(password),
          'nominee_number': nomineeNumber,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id'];
      }
      return null;
    } catch (e) {
      print('Fingerprint Signup Error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getLatestFingerprintScan() async {
    try {
      final url = '$baseUrl/fingerprint/latest';
      print('🔍 [DEBUG] Fetching from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('🔍 [DEBUG] Response status: ${response.statusCode}');
      print('🔍 [DEBUG] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ [DEBUG] Parsed data: $data');
        return data;
      }
      print('⚠️ [DEBUG] No scan available (status ${response.statusCode})');
      return null;
    } catch (e) {
      print('❌ [DEBUG] Get Latest Fingerprint Error: $e');
      return null;
    }
  }

  Future<bool> deleteDocument(int documentId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/documents/$documentId'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Delete Document Error: $e');
      return false;
    }
  }

  Future<bool> updateProfilePicture(int userId, String url) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/profile-picture'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'profile_picture_url': url,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Update Profile Picture Error: $e');
      return false;
    }
  }

  Future<bool> clearLatestFingerprintScan() async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/fingerprint/latest'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Clear Fingerprint Scan Error: $e');
      return false;
    }
  }
}
