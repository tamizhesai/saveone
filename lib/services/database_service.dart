import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../models/user_model.dart';
import '../models/document_model.dart';

class DatabaseService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';

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
    required String fileContent,
    required int fileSize,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/documents/upload'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'file_name': fileName,
          'file_content': fileContent,
          'file_size': fileSize,
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
}
