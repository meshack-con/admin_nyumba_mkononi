import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';

class MediaException implements Exception {
  final String message;
  MediaException(this.message);

  @override
  String toString() => message;
}

/// Backend sasa inahifadhi picha/hati kwenye Cloudinary, kwa hiyo URL zinakuja
/// kamili (https://res.cloudinary.com/...). URL za zamani (local) zinaanza na
/// "/uploads/..." na zinahitaji [baseUrl] mbele yake.
String resolveMediaUrl(String url) {
  final u = url.trim();
  if (u.startsWith('http://') || u.startsWith('https://')) return u;
  if (u.startsWith('/')) return '$baseUrl$u';
  return '$baseUrl/$u';
}

String _pathOnly(String url) => url.toLowerCase().split('?').first;

/// PDF za Cloudinary huhifadhiwa kama "raw" na URL yake HAINA `.pdf` mwishoni,
/// kwa hiyo tunaangalia pia `/raw/upload/`.
bool isPdfUrl(String url) {
  final path = _pathOnly(url);
  return path.endsWith('.pdf') || path.contains('/raw/upload/');
}

bool isImageUrl(String url) {
  final path = _pathOnly(url);
  return path.endsWith('.jpg') ||
      path.endsWith('.jpeg') ||
      path.endsWith('.png') ||
      path.endsWith('.webp') ||
      path.contains('/image/upload/');
}

/// URL ya kulazimisha browser/simu ipakue faili badala ya kuifungua.
/// Cloudinary inaunga mkono `fl_attachment` kwenye njia ya `/upload/`.
String downloadUrl(String url) {
  final resolved = resolveMediaUrl(url);
  if (resolved.contains('res.cloudinary.com') &&
      resolved.contains('/upload/') &&
      !resolved.contains('fl_attachment')) {
    return resolved.replaceFirst('/upload/', '/upload/fl_attachment/');
  }
  return resolved;
}

/// Fungua URL nje ya app (browser / app ya kutazama).
Future<void> openExternal(BuildContext context, String url, {bool download = false}) async {
  final target = download ? downloadUrl(url) : resolveMediaUrl(url);
  final messenger = ScaffoldMessenger.of(context);
  try {
    final ok = await launchUrl(Uri.parse(target), mode: LaunchMode.externalApplication);
    if (!ok) messenger.showSnackBar(const SnackBar(content: Text('Imeshindikana kufungua faili')));
  } catch (_) {
    messenger.showSnackBar(const SnackBar(content: Text('Imeshindikana kufungua faili')));
  }
}

/// Pakua faili kama bytes (inatumika kwa PDF - kuonyesha ndani ya app na kupakua).
Future<Uint8List> fetchMediaBytes(String url) async {
  final http.Response response;
  try {
    response = await http.get(Uri.parse(resolveMediaUrl(url)));
  } catch (_) {
    throw MediaException('Imeshindikana kupakua faili. Angalia mtandao wako.');
  }
  if (response.statusCode == 401 || response.statusCode == 403) {
    throw MediaException(
      'Cloudinary imezuia kutoa PDF hii. Washa "Allow delivery of PDF and ZIP files" '
      'kwenye Cloudinary (Settings > Security).',
    );
  }
  if (response.statusCode == 404) {
    throw MediaException('Faili haipatikani (huenda ilifutwa).');
  }
  if (response.statusCode != 200) {
    throw MediaException('Imeshindikana kupakua faili (${response.statusCode}).');
  }
  return response.bodyBytes;
}

/// Hifadhi/pakua PDF: kwenye web inapakuliwa moja kwa moja, kwenye simu
/// inafungua menyu ya kuhifadhi/kushiriki.
Future<void> savePdf(Uint8List bytes, String filename) async {
  await Printing.sharePdf(bytes: bytes, filename: filename);
}
