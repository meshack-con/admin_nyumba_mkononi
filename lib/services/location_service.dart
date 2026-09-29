import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Eneo lililopatikana kiotomatiki: alama ya GPS pamoja na jina la eneo.
class DetectedLocation {
  const DetectedLocation({required this.latitude, required this.longitude, required this.label});
  final double latitude;
  final double longitude;
  final String label;
}

/// Hatua ambayo admin anaweza kuchukua ili kutatua tatizo la eneo.
enum LocationFailureAction { none, openLocationSettings, openAppSettings }

class LocationFailure implements Exception {
  const LocationFailure(this.message, {this.action = LocationFailureAction.none});
  final String message;
  final LocationFailureAction action;
}

class LocationService {
  const LocationService._();

  /// Inaomba ruhusa ya GPS, inapata eneo la sasa la kifaa na kulijaza
  /// kiotomatiki (pamoja na jina la mtaa likipatikana). Admin lazima awe
  /// mahali nyumba ilipo. Inatupa [LocationFailure] yenye ujumbe wa
  /// Kiswahili ikishindikana.
  static Future<DetectedLocation> detectCurrent() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationFailure('Ruhusa ya eneo imekataliwa. Ruhusu eneo kisha jaribu tena.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationFailure(
        kIsWeb
            ? 'Ruhusa ya eneo imezuiwa kwenye browser. Iruhusu kwenye mipangilio ya tovuti kisha jaribu tena.'
            : 'Ruhusa ya eneo imezuiwa. Iruhusu kwenye mipangilio ya app kisha jaribu tena.',
        action: kIsWeb ? LocationFailureAction.none : LocationFailureAction.openAppSettings,
      );
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocationFailure(
        'GPS imezimwa. Iwashe kisha jaribu tena.',
        action: kIsWeb ? LocationFailureAction.none : LocationFailureAction.openLocationSettings,
      );
    }

    final Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 25),
        ),
      );
    } on TimeoutException {
      throw const LocationFailure('Imechukua muda mrefu kupata eneo. Nenda wazi zaidi (nje) kisha jaribu tena.');
    } catch (_) {
      throw const LocationFailure('Imeshindikana kupata eneo. Jaribu tena.');
    }

    final label = await _reverseGeocode(position.latitude, position.longitude) ??
        '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
    return DetectedLocation(latitude: position.latitude, longitude: position.longitude, label: label);
  }

  /// Inabadilisha alama ya GPS kuwa jina la eneo (mfano "Sinza, Dar es Salaam")
  /// kwa kutumia OpenStreetMap Nominatim. Ikishindikana inarudisha null.
  static Future<String?> _reverseGeocode(double latitude, double longitude) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': '$latitude',
        'lon': '$longitude',
        'zoom': '16',
        'addressdetails': '1',
        'accept-language': 'sw,en',
      });
      final response = await http
          .get(uri, headers: {if (!kIsWeb) 'User-Agent': 'tz.nyumbamkononi.admin'})
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return null;
      final address = body['address'];
      if (address is! Map<String, dynamic>) return null;

      String? pick(List<String> keys) {
        for (final key in keys) {
          final value = address[key];
          if (value is String && value.trim().isNotEmpty) return value.trim();
        }
        return null;
      }

      final parts = <String>[];
      final area = pick(['suburb', 'neighbourhood', 'quarter', 'city_district', 'village', 'hamlet']);
      final city = pick(['city', 'town', 'municipality', 'county', 'state']);
      if (area != null) parts.add(area);
      if (city != null && city != area) parts.add(city);
      return parts.isEmpty ? null : parts.join(', ');
    } catch (_) {
      return null;
    }
  }

  static Future<void> openSettings(LocationFailureAction action) async {
    switch (action) {
      case LocationFailureAction.openLocationSettings:
        await Geolocator.openLocationSettings();
        break;
      case LocationFailureAction.openAppSettings:
        await Geolocator.openAppSettings();
        break;
      case LocationFailureAction.none:
        break;
    }
  }
}
