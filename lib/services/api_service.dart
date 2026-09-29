import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
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

  /// Admin anaweka nyumba moja kwa moja kwa niaba ya mmiliki. Hakuna malipo,
  /// na tangazo linaingia kama 'approved' - linaonekana kwa watumiaji mara moja.
  /// Picha lazima ziwe 3 (kama ilivyo kwa watumiaji wa kawaida).
  Future<AdminProperty> createProperty({
    required String jina,
    required String aina,
    required String mode,
    required int price,
    required String locationLabel,
    required double latitude,
    required double longitude,
    required Map<String, bool> amenities,
    required String description,
    required String ownerJina,
    required String ownerSimu,
    String? ownerEmail,
    String? ownerEneo,
    required List<Uint8List> photos,
    required List<String> photoNames,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/admin/properties'));
    // Content-Type ya multipart huwekwa na MultipartRequest yenyewe.
    request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll({
      'jina': jina,
      'aina': aina,
      'mode': mode,
      'price': '$price',
      'location_label': locationLabel,
      'latitude': '$latitude',
      'longitude': '$longitude',
      'description': description,
      'owner_jina': ownerJina,
      'owner_simu': ownerSimu,
      if (ownerEmail != null && ownerEmail.isNotEmpty) 'owner_email': ownerEmail,
      if (ownerEneo != null && ownerEneo.isNotEmpty) 'owner_eneo': ownerEneo,
    });
    amenities.forEach((key, value) => request.fields[key] = '$value');
    for (var i = 0; i < photos.length; i++) {
      request.files.add(http.MultipartFile.fromBytes('photos', photos[i], filename: photoNames[i]));
    }
    final streamed = await request.send().timeout(const Duration(minutes: 3));
    final response = await http.Response.fromStream(streamed);
    return AdminProperty.fromJson(_decodeObject(response));
  }

  Future<AdminProperty> approveProperty(int id) async {
    final response = await http.post(Uri.parse('$baseUrl/admin/properties/$id/approve'), headers: _headers);
    return AdminProperty.fromJson(_decodeObject(response));
  }

  Future<AdminProperty> rejectProperty(int id) async {
    final response = await http.post(Uri.parse('$baseUrl/admin/properties/$id/reject'), headers: _headers);
    return AdminProperty.fromJson(_decodeObject(response));
  }

  /// Matangazo yote (historia kamili), yenye uwezo wa kuchuja kwa status
  /// (mfano: 'pending', 'approved', 'rejected', 'expired'). Ikiwa
  /// [statusFilter] ni null, matangazo yote yanarudishwa bila kuchujwa.
  Future<List<AdminProperty>> getAllProperties({String? statusFilter}) async {
    final uri = Uri.parse('$baseUrl/admin/properties').replace(
      queryParameters: statusFilter != null ? {'status_filter': statusFilter} : null,
    );
    final response = await http.get(uri, headers: _headers);
    return _decodeList(response).map((e) => AdminProperty.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Admin anafuta tangazo la nyumba kabisa kutoka kwenye mfumo. Hatua hii
  /// ni ya kudumu - haiwezi kutenduliwa.
  Future<void> deleteProperty(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/admin/properties/$id'), headers: _headers);
    _checkStatus(response);
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
