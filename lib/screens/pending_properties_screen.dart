import 'package:flutter/material.dart';

import '../config.dart';
import '../models/property.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'property_detail_screen.dart';

class PendingPropertiesScreen extends StatefulWidget {
  const PendingPropertiesScreen({super.key});

  @override
  State<PendingPropertiesScreen> createState() => _PendingPropertiesScreenState();
}

class _PendingPropertiesScreenState extends State<PendingPropertiesScreen> {
  List<AdminProperty> _properties = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await AuthService().getToken();
      if (token == null) throw ApiException('Hujaingia', 401);
      final api = ApiService(token);
      final props = await api.getPendingProperties();
      if (!mounted) return;
      setState(() => _properties = props);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Imeshindikana kupakua matangazo');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _load, child: const Text('Jaribu tena')),
          ],
        ),
      );
    }

    if (_properties.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Hakuna matangazo yanayosubiri kwa sasa')),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _properties.length,
        itemBuilder: (context, index) {
          final p = _properties[index];
          final thumbnail = p.photoUrls.isNotEmpty ? '$baseUrl${p.photoUrls.first}' : null;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(8),
              leading: thumbnail != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        thumbnail,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.home, size: 40),
                      ),
                    )
                  : const Icon(Icons.home, size: 40),
              title: Text(p.jina, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${p.aina} · ${p.mode} · ${p.locationLabel}\nTSh ${p.price}'),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final changed = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: p)),
                );
                if (changed == true) _load();
              },
            ),
          );
        },
      ),
    );
  }
}
