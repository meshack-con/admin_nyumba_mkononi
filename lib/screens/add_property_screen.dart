import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/owner_account.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';

/// Admin anaweka nyumba kwa niaba ya mmiliki.
///
/// 1. Mmiliki: admin anaunda AKAUNTI MPYA ya mmiliki (username + password
///    ambazo mmiliki atatumia kuingia) AU anachagua akaunti iliyopo.
/// 2. Nyumba inakaa kwenye akaunti hiyo ya mmiliki.
/// 3. Eneo linachukuliwa kiotomatiki kwa kitufe (GPS) - admin haandiki
///    coordinates.
///
/// Hakuna malipo yoyote, na nyumba inaonekana kwa watumiaji mara tu
/// inapohifadhiwa (status ni 'approved' moja kwa moja).
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

  // --- Mmiliki ---
  bool _newOwner = true; // true = akaunti mpya, false = akaunti iliyopo
  final _ownerName = TextEditingController();
  final _ownerPhone = TextEditingController();
  final _ownerEmail = TextEditingController();
  final _ownerArea = TextEditingController();
  final _ownerUsername = TextEditingController();
  final _ownerPassword = TextEditingController();

  final _ownerSearch = TextEditingController();
  List<OwnerAccount> _ownerResults = [];
  OwnerAccount? _selectedOwner;
  bool _searching = false;
  bool _searched = false;
  String? _searchError;

  // --- Nyumba ---
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _description = TextEditingController();
  final _locationLabel = TextEditingController();
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

  // --- Eneo (kiotomatiki kwa GPS) ---
  double? _latitude;
  double? _longitude;
  bool _detecting = false;
  String? _locationError;
  LocationFailureAction _locationAction = LocationFailureAction.none;

  // --- Picha ---
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
      _ownerUsername,
      _ownerPassword,
      _ownerSearch,
      _name,
      _price,
      _description,
      _locationLabel,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // --- Mmiliki: password na utafutaji ------------------------------------

  void _generatePassword() {
    // Bila herufi zinazochanganya (0/O, 1/l/I) ili iwe rahisi kusomwa kwa mmiliki.
    const chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    final password = List.generate(10, (_) => chars[random.nextInt(chars.length)]).join();
    setState(() => _ownerPassword.text = password);
  }

  Future<void> _searchOwners() async {
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final token = await AuthService().getToken();
      if (token == null) throw ApiException('Hujaingia', 401);
      final results = await ApiService(token).searchUsers(_ownerSearch.text.trim());
      if (!mounted) return;
      setState(() {
        _ownerResults = results;
        _searched = true;
        if (_selectedOwner != null && !results.any((o) => o.id == _selectedOwner!.id)) {
          _selectedOwner = null;
        }
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _searchError = e.message);
    } catch (_) {
      if (mounted) setState(() => _searchError = 'Imeshindikana kutafuta akaunti');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  // --- Eneo ---------------------------------------------------------------

  Future<void> _detectLocation() async {
    setState(() {
      _detecting = true;
      _locationError = null;
      _locationAction = LocationFailureAction.none;
    });
    try {
      final location = await LocationService.detectCurrent();
      if (!mounted) return;
      setState(() {
        _latitude = location.latitude;
        _longitude = location.longitude;
        _locationLabel.text = location.label;
      });
    } on LocationFailure catch (e) {
      if (mounted) {
        setState(() {
          _locationError = e.message;
          _locationAction = e.action;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _locationError = 'Imeshindikana kupata eneo. Jaribu tena.');
    } finally {
      if (mounted) setState(() => _detecting = false);
    }
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

  // --- Kutuma -------------------------------------------------------------

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_newOwner && _selectedOwner == null) {
      setState(() => _error = 'Chagua akaunti ya mmiliki kutoka kwenye matokeo ya utafutaji');
      return;
    }
    if (_latitude == null || _longitude == null) {
      setState(() => _error = 'Bonyeza "Chukua eneo la sasa" ili kuweka eneo la nyumba');
      return;
    }
    if (_photos.length != _requiredPhotos) {
      setState(() => _error = 'Chagua picha $_requiredPhotos za nyumba (umechagua ${_photos.length})');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final token = await AuthService().getToken();
      if (token == null) throw ApiException('Hujaingia', 401);
      final username = _ownerUsername.text.trim();
      final password = _ownerPassword.text;
      final ownerName = _ownerName.text.trim();
      await ApiService(token).createProperty(
        jina: _name.text.trim(),
        aina: _type,
        mode: _mode,
        price: int.parse(_price.text.trim()),
        locationLabel: _locationLabel.text.trim(),
        latitude: _latitude!,
        longitude: _longitude!,
        amenities: _amenities,
        description: _description.text.trim(),
        ownerId: _newOwner ? null : _selectedOwner!.id,
        ownerJina: _newOwner ? ownerName : null,
        ownerSimu: _newOwner ? _ownerPhone.text.trim() : null,
        ownerUsername: _newOwner ? username : null,
        ownerPassword: _newOwner ? password : null,
        ownerEmail: _newOwner ? _ownerEmail.text.trim() : null,
        ownerEneo: _newOwner ? _ownerArea.text.trim() : null,
        photos: _photos.map((p) => p.bytes).toList(),
        photoNames: _photos.map((p) => p.name).toList(),
      );
      if (!mounted) return;
      if (_newOwner) {
        await _showCredentials(ownerName, username, password);
        if (!mounted) return;
      }
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Imeshindikana kuhifadhi nyumba. Angalia mtandao kisha jaribu tena.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Password haihifadhiwi popote inayosomeka - hii ndiyo nafasi ya pekee ya
  /// kuiona, kwa hiyo admin lazima aimpe mmiliki kabla ya kufunga.
  Future<void> _showCredentials(String ownerName, String username, String password) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Akaunti imeundwa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mpe $ownerName taarifa hizi ili aingie kwenye app:'),
            const SizedBox(height: 12),
            const Text('Username', style: TextStyle(color: Colors.grey)),
            SelectableText(username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Password', style: TextStyle(color: Colors.grey)),
            SelectableText(password, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            const Text(
              'Password haitaonekana tena baada ya kufunga dirisha hili.',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: 'Username: $username\nPassword: $password'));
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Zimenakiliwa')));
              }
            },
            icon: const Icon(Icons.copy),
            label: const Text('Nakili'),
          ),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Nimemaliza')),
        ],
      ),
    );
  }

  // --- UI -----------------------------------------------------------------

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      );

  String? _required(String? v, String message) => (v == null || v.trim().isEmpty) ? message : null;

  Widget _newOwnerFields() {
    return Column(
      children: [
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
            labelText: 'Namba ya simu',
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
          decoration: const InputDecoration(labelText: 'Eneo analoishi (hiari)', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _ownerUsername,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(
            labelText: 'Username ya kuingia',
            helperText: 'Herufi 3 au zaidi, bila nafasi',
            border: OutlineInputBorder(),
          ),
          validator: (v) {
            final t = (v ?? '').trim();
            if (t.length < 3) return 'Username iwe herufi 3 au zaidi';
            if (RegExp(r'\s').hasMatch(t)) return 'Username isiwe na nafasi';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _ownerPassword,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: 'Password ya mmiliki',
            helperText: 'Angalau herufi 8',
            border: const OutlineInputBorder(),
            suffixIcon: TextButton(onPressed: _generatePassword, child: const Text('Tengeneza')),
          ),
          validator: (v) => (v == null || v.length < 8) ? 'Password iwe angalau herufi 8' : null,
        ),
      ],
    );
  }

  Widget _existingOwnerPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ownerSearch,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _searchOwners(),
                decoration: const InputDecoration(
                  labelText: 'Tafuta kwa jina, username au simu',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _searching ? null : _searchOwners,
              child: _searching
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Tafuta'),
            ),
          ],
        ),
        if (_searchError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_searchError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        if (_searched && _ownerResults.isEmpty)
          const Padding(padding: EdgeInsets.only(top: 8), child: Text('Hakuna akaunti iliyopatikana')),
        for (final owner in _ownerResults)
          Card(
            margin: const EdgeInsets.only(top: 8),
            color: _selectedOwner?.id == owner.id ? Theme.of(context).colorScheme.primaryContainer : null,
            child: ListTile(
              leading: Icon(_selectedOwner?.id == owner.id ? Icons.check_circle : Icons.person_outline),
              title: Text(owner.jina),
              subtitle: Text('${owner.username} • ${owner.simu}'),
              onTap: () => setState(() => _selectedOwner = owner),
            ),
          ),
      ],
    );
  }

  Widget _locationCard() {
    final detected = _latitude != null && _longitude != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilledButton.tonalIcon(
          onPressed: _detecting ? null : _detectLocation,
          icon: _detecting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.my_location),
          label: Text(
            _detecting
                ? 'Inatafuta eneo...'
                : detected
                    ? 'Chukua eneo upya'
                    : 'Chukua eneo la sasa',
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Simama mahali nyumba ilipo kisha bonyeza kitufe - eneo linajazwa lenyewe.',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        if (_locationError != null) ...[
          const SizedBox(height: 8),
          Text(_locationError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          if (_locationAction != LocationFailureAction.none)
            TextButton(
              onPressed: () => LocationService.openSettings(_locationAction),
              child: const Text('Fungua mipangilio'),
            ),
        ],
        if (detected) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Eneo limepatikana: ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                  style: const TextStyle(color: Colors.green),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _locationLabel,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Jina la eneo',
              helperText: 'Limejazwa kiotomatiki - unaweza kulirekebisha kama halijafaa',
              helperMaxLines: 2,
              border: OutlineInputBorder(),
            ),
            validator: (v) => _required(v, 'Weka jina la eneo'),
          ),
        ],
      ],
    );
  }

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
                          'Hakuna malipo. Nyumba itaonekana moja kwa moja kwa watumiaji na itakaa kwenye akaunti ya mmiliki.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              _section('Akaunti ya mmiliki'),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Akaunti mpya'), icon: Icon(Icons.person_add_alt_1)),
                  ButtonSegment(value: false, label: Text('Iliyopo'), icon: Icon(Icons.manage_search)),
                ],
                selected: {_newOwner},
                onSelectionChanged: (s) => setState(() {
                  _newOwner = s.first;
                  _error = null;
                }),
              ),
              const SizedBox(height: 12),
              if (_newOwner) _newOwnerFields() else _existingOwnerPicker(),

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
              _locationCard(),

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
