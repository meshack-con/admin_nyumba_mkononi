import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';

/// Admin anaweka nyumba moja kwa moja kwa niaba ya mmiliki: taarifa za
/// mmiliki + taarifa zote za nyumba + picha 3. Hakuna malipo yoyote, na
/// nyumba inaonekana kwa watumiaji mara tu inapohifadhiwa (status ni
/// 'approved' moja kwa moja).
class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _PickedPhoto {
  final Uint8List bytes;
  final String name;
  _PickedPhoto(this.bytes, this.name);
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  static const _requiredPhotos = 3;

  final _formKey = GlobalKey<FormState>();

  // Mmiliki
  final _ownerName = TextEditingController();
  final _ownerPhone = TextEditingController();
  final _ownerEmail = TextEditingController();
  final _ownerArea = TextEditingController();

  // Nyumba
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _description = TextEditingController();
  final _locationLabel = TextEditingController();
  final _coordinates = TextEditingController();

  String _type = 'nyumba'; // chumba | nyumba | kiwanja
  String _mode = 'rent'; // rent | sale

  // Funguo ni majina ya fields za backend.
  final Map<String, bool> _amenities = {
    'has_wifi': false,
    'car_parking': false,
    'indoor_toilet': false,
    'has_electricity': false,
    'water_inside': false,
    'water_nearby': false,
    'furnished': false,
    'swimming_pool': false,
  };

  static const _amenityLabels = <String, String>{
    'has_wifi': 'WiFi',
    'car_parking': 'Maegesho ya gari',
    'indoor_toilet': 'Choo cha ndani',
    'has_electricity': 'Umeme',
    'water_inside': 'Maji ndani',
    'water_nearby': 'Maji karibu',
    'furnished': 'Samani',
    'swimming_pool': 'Bwawa la kuogelea',
  };

  final _picker = ImagePicker();
  final List<_PickedPhoto> _photos = [];
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _ownerName,
      _ownerPhone,
      _ownerEmail,
      _ownerArea,
      _name,
      _price,
      _description,
      _locationLabel,
      _coordinates,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // --- Picha -------------------------------------------------------------

  /// Backend inakubali .jpg/.jpeg/.png/.webp tu (inakagua kiendelezi cha jina
  /// la faili). Picha kutoka kwa picker wakati mwingine hazina kiendelezi,
  /// kwa hiyo tunaongeza .jpg kama hakipo.
  String _safeName(XFile file, int index) {
    final name = file.name.trim();
    final lower = name.toLowerCase();
    const ok = ['.jpg', '.jpeg', '.png', '.webp'];
    if (ok.any(lower.endsWith)) return name;
    return 'picha_${DateTime.now().millisecondsSinceEpoch}_$index.jpg';
  }

  Future<void> _pickPhotos() async {
    try {
      final files = await _picker.pickMultiImage(imageQuality: 85, maxWidth: 1600);
      if (files.isEmpty) return;
      final picked = <_PickedPhoto>[];
      for (var i = 0; i < files.length; i++) {
        picked.add(_PickedPhoto(await files[i].readAsBytes(), _safeName(files[i], i)));
      }
      if (!mounted) return;
      setState(() {
        _photos.addAll(picked);
        if (_photos.length > _requiredPhotos) {
          _photos.removeRange(_requiredPhotos, _photos.length);
          _error = 'Picha 3 tu zinahitajika - za ziada ziliachwa.';
        } else {
          _error = null;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Imeshindikana kuchagua picha');
    }
  }

  // --- Eneo ---------------------------------------------------------------

  Future<void> _openMaps() async {
    final query = _locationLabel.text.trim();
    final uri = Uri.parse(
      query.isEmpty
          ? 'https://www.google.com/maps'
          : 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Inakubali "-6.7924, 39.2083" (kama Google Maps inavyonakili).
  ({double lat, double lng})? _parseCoordinates(String text) {
    final match = RegExp(r'^\s*(-?\d+(?:\.\d+)?)\s*[,;\s]\s*(-?\d+(?:\.\d+)?)\s*$').firstMatch(text);
    if (match == null) return null;
    final lat = double.tryParse(match.group(1)!);
    final lng = double.tryParse(match.group(2)!);
    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    return (lat: lat, lng: lng);
  }

  // --- Kutuma -------------------------------------------------------------

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photos.length != _requiredPhotos) {
      setState(() => _error = 'Chagua picha $_requiredPhotos za nyumba (umechagua ${_photos.length})');
      return;
    }
    final coords = _parseCoordinates(_coordinates.text)!; // validator imehakikisha
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final token = await AuthService().getToken();
      if (token == null) throw ApiException('Hujaingia', 401);
      await ApiService(token).createProperty(
        jina: _name.text.trim(),
        aina: _type,
        mode: _mode,
        price: int.parse(_price.text.trim()),
        locationLabel: _locationLabel.text.trim(),
        latitude: coords.lat,
        longitude: coords.lng,
        amenities: _amenities,
        description: _description.text.trim(),
        ownerJina: _ownerName.text.trim(),
        ownerSimu: _ownerPhone.text.trim(),
        ownerEmail: _ownerEmail.text.trim(),
        ownerEneo: _ownerArea.text.trim(),
        photos: _photos.map((p) => p.bytes).toList(),
        photoNames: _photos.map((p) => p.name).toList(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Imeshindikana kuhifadhi nyumba. Angalia mtandao kisha jaribu tena.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // --- UI -----------------------------------------------------------------

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      );

  String? _required(String? v, String message) => (v == null || v.trim().isEmpty) ? message : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ongeza Nyumba')),
      body: AbsorbPointer(
        absorbing: _saving,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Hakuna malipo. Nyumba itaonekana moja kwa moja kwa watumiaji mara tu ukihifadhi.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              _section('Taarifa za mmiliki'),
              TextFormField(
                controller: _ownerName,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Jina kamili la mmiliki', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().length < 2) ? 'Weka jina la mmiliki' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ownerPhone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Namba ya simu ya mmiliki',
                  hintText: '0712345678',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                  return digits.length < 7 ? 'Weka namba sahihi ya simu' : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ownerEmail,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Barua pepe (hiari)', border: OutlineInputBorder()),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return null;
                  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t) ? null : 'Barua pepe si sahihi';
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ownerArea,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Eneo analoishi mmiliki (hiari)', border: OutlineInputBorder()),
              ),

              _section('Taarifa za nyumba'),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Jina la tangazo', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().length < 2) ? 'Weka jina la tangazo' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Aina', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'chumba', child: Text('Chumba')),
                  DropdownMenuItem(value: 'nyumba', child: Text('Nyumba')),
                  DropdownMenuItem(value: 'kiwanja', child: Text('Kiwanja')),
                ],
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'rent', label: Text('Kupangisha')),
                  ButtonSegment(value: 'sale', label: Text('Kuuza')),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() => _mode = s.first),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: _mode == 'rent' ? 'Bei kwa mwezi (TZS)' : 'Bei ya kuuza (TZS)',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => int.tryParse((v ?? '').trim()) == null ? 'Weka bei sahihi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Maelezo', border: OutlineInputBorder()),
                validator: (v) => _required(v, 'Weka maelezo ya nyumba'),
              ),

              _section('Eneo la nyumba'),
              TextFormField(
                controller: _locationLabel,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Jina la eneo',
                  hintText: 'Mfano: Mikocheni, Dar es Salaam',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => _required(v, 'Weka jina la eneo'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _coordinates,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: const InputDecoration(
                  labelText: 'Coordinates (latitude, longitude)',
                  hintText: '-6.7924, 39.2083',
                  helperText: 'Kwenye Google Maps bonyeza eneo kwa muda mrefu kisha nakili namba zinazoonekana.',
                  helperMaxLines: 2,
                  border: OutlineInputBorder(),
                ),
                validator: (v) => _parseCoordinates(v ?? '') == null ? 'Weka kwa mfumo: -6.7924, 39.2083' : null,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _openMaps,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Fungua Google Maps'),
                ),
              ),

              _section('Huduma zilizopo'),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _amenityLabels.entries
                    .map(
                      (e) => FilterChip(
                        label: Text(e.value),
                        selected: _amenities[e.key] ?? false,
                        onSelected: (v) => setState(() => _amenities[e.key] = v),
                      ),
                    )
                    .toList(),
              ),

              _section('Picha za nyumba ($_requiredPhotos)'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _photos.length; i++)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(_photos[i].bytes, width: 100, height: 100, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: InkWell(
                            onTap: () => setState(() => _photos.removeAt(i)),
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.black54,
                              child: Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (_photos.length < _requiredPhotos)
                    InkWell(
                      onTap: _pickPhotos,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Icon(Icons.add_a_photo_outlined), SizedBox(height: 4), Text('Ongeza')],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text('${_photos.length}/$_requiredPhotos zimechaguliwa', style: const TextStyle(color: Colors.grey)),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: Text(_saving ? 'Inahifadhi...' : 'Hifadhi na uchapishe'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
