import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/analytics.dart';
import '../models/property.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  final String token;
  ApiService(this.token);

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  // --- Auth (static - haihitaji token) ------------------------------

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode == 401) {
      throw ApiException('Username au password si sahihi', 401);
    }
    if (response.statusCode >= 400) {
      throw ApiException('Imeshindikana kuingia. Angalia backend inaendesha.', response.statusCode);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // --- Helpers ---------------------------------------------------------

  Map<String, dynamic> _decodeObject(http.Response response) {
    _checkStatus(response);
    if (response.body.isEmpty) return {};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  List<dynamic> _decodeList(http.Response response) {
    _checkStatus(response);
    if (response.body.isEmpty) return [];
    return jsonDecode(response.body) as List<dynamic>;
  }

  void _checkStatus(http.Response response) {
    if (response.statusCode == 401) {
      throw ApiException('Muda wa kuingia umeisha, ingia tena', 401);
    }
    if (response.statusCode == 403) {
      throw ApiException('Huna ruhusa ya admin', 403);
    }
    if (response.statusCode >= 400) {
      String detail = 'Hitilafu imetokea';
      try {
        final body = jsonDecode(response.body);
        detail = body['detail']?.toString() ?? detail;
      } catch (_) {
        // body si JSON - tumia default message
      }
      throw ApiException(detail, response.statusCode);
    }
  }

  // --- Properties ------------------------------------------------------

  Future<List<AdminProperty>> getPendingProperties() async {
    final response = await http.get(Uri.parse('$baseUrl/admin/properties/pending'), headers: _headers);
    return _decodeList(response).map((e) => AdminProperty.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AdminProperty> approveProperty(int id) async {
    final response = await http.post(Uri.parse('$baseUrl/admin/properties/$id/approve'), headers: _headers);
    return AdminProperty.fromJson(_decodeObject(response));
  }

  Future<AdminProperty> rejectProperty(int id) async {
    final response = await http.post(Uri.parse('$baseUrl/admin/properties/$id/reject'), headers: _headers);
    return AdminProperty.fromJson(_decodeObject(response));
  }

  // --- Analytics ---------------------------------------------------------

  Future<AnalyticsSummary> getAnalyticsSummary() async {
    final response = await http.get(Uri.parse('$baseUrl/admin/analytics/summary'), headers: _headers);
    return AnalyticsSummary.fromJson(_decodeObject(response));
  }

  Future<List<MonthlyPoint>> getRegistrationsByMonth({int months = 12}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/analytics/registrations-by-month?months=$months'),
      headers: _headers,
    );
    return _decodeList(response).map((e) => MonthlyPoint.fromJson(e as Map<String, dynamic>)).toList();
  }
}
