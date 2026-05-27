import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env_config.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class ApiException implements Exception {
  ApiException(this.status, this.message, {this.code, this.details});
  final int status;
  final String message;
  final String? code;
  final Map<String, dynamic>? details;

  bool get isQuotaError =>
      code == 'FILE_QUOTA_EXCEEDED' ||
          code == 'CHAT_QUOTA_EXCEEDED' ||
          code == 'FLASHCARD_QUOTA_EXCEEDED' ||
          code == 'PLAN_DURATION_EXCEEDED';

  String? get upgradeMessage => details?['upgrade_message'] as String?;

  @override
  String toString() => 'ApiException($status): $message';
}

class ApiClient {
  String get baseUrl => EnvConfig.apiBaseUrl;

  Future<Map<String, String>> _headers({bool json = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role');
    final adminToken = prefs.getString('token'); // Admin login qilsa email token bo'lib tushadi

    final headers = <String, String>{
      if (json) 'Content-Type': 'application/json',
    };

    // Agar foydalanuvchi Admin bo'lsa, Firebase tokenni qidirmasdan Admin tokenini yuboramiz
    if (role == 'admin' && adminToken != null && adminToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $adminToken';
      headers['User-Email'] = adminToken;
    } else {
      // Oddiy foydalanuvchi uchun Firebase token olinadi
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email ?? '';
      String? idToken;
      try {
        idToken = await user?.getIdToken();
      } catch (_) {}

      if (email.isNotEmpty) headers['User-Email'] = email;
      if (idToken != null && idToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $idToken';
      }
    }
    return headers;
  }

  Future<dynamic> _decode(http.Response r) async {
    if (r.statusCode >= 200 && r.statusCode < 300) {
      if (r.body.isEmpty) return <String, dynamic>{};
      return jsonDecode(r.body);
    }
    String msg = r.body;
    String? code;
    Map<String, dynamic>? details;
    try {
      final m = jsonDecode(r.body);
      if (m is Map) {
        if (m['message'] is String) {
          msg = m['message'];
        } else if (m['error'] is String) {
          msg = m['error'];
        }
        if (m['code'] is String) code = m['code'];
        if (m['details'] is Map) {
          details = Map<String, dynamic>.from(m['details'] as Map);
        }
      }
    } catch (_) {}
    throw ApiException(r.statusCode, msg, code: code, details: details);
  }

  Future<dynamic> get(String endpoint) async {
    final r = await http.get(Uri.parse('$baseUrl$endpoint'), headers: await _headers(json: false));
    return _decode(r);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final r = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode(r);
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final r = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode(r);
  }

  Future<dynamic> delete(String endpoint) async {
    final r = await http.delete(Uri.parse('$baseUrl$endpoint'), headers: await _headers(json: false));
    return _decode(r);
  }

  Future<dynamic> uploadFile(
      String endpoint, {
        required List<int> bytes,
        required String filename,
        String field = 'document',
      }) async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role');
    final adminToken = prefs.getString('token');

    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));

    if (role == 'admin' && adminToken != null) {
      req.headers['Authorization'] = 'Bearer $adminToken';
      req.headers['User-Email'] = adminToken;
    } else {
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email ?? '';
      String? idToken;
      try {
        idToken = await user?.getIdToken();
      } catch (_) {}

      if (email.isNotEmpty) req.headers['User-Email'] = email;
      if (idToken != null && idToken.isNotEmpty) {
        req.headers['Authorization'] = 'Bearer $idToken';
      }
    }

    req.files.add(http.MultipartFile.fromBytes(field, bytes, filename: filename));
    final streamed = await req.send();
    final r = await http.Response.fromStream(streamed);
    return _decode(r);
  }
}