import 'package:flutter/material.dart';

import '../config.dart';
import '../models/property.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/time_format.dart';
import 'property_detail_screen.dart';

/// Orodha ya matangazo YOTE ya nyumba (pending, approved, rejected, expired)
/// - admin anaweza kuchuja kwa status, kuona muda tangazo limekuwa ndani ya
/// app, na kulifuta kabisa moja kwa moja kwa kuburuta (swipe) au kwa
/// kubonyeza aikoni ya kufuta.
class AllPropertiesScreen extends StatefulWidget {
  const AllPropertiesScreen({super.key});

  @override
  State<AllPropertiesScreen> createState() => _AllPropertiesScreenState();
}

class _AllPropertiesScreenState extends State<AllPropertiesScreen> {
  List<AdminProperty> _properties = [];
  bool _loading = true;
  String? _error;
  String? _statusFilter; // null = zote

  static const _statusOptions = <String?, String>{
    null: 'Zote',
    'pending': 'Zinasubiri',
    'approved': 'Zimeruhusiwa',
    'rejected': 'Zimekataliwa',
    'expired': 'Zimeisha muda',
  };

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
      final props = await api.getAllProperties(statusFilter: _statusFilter);
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

  Future<bool> _confirmDelete(AdminProperty p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Futa Tangazo'),
        content: Text(
          'Una uhakika unataka kufuta "${p.jina}" kabisa? '
          'Hatua hii haiwezi kutenduliwa.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Ghairi')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Futa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _delete(AdminProperty p) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw ApiException('Hujaingia', 401);
      final api = ApiService(token);
      await api.deleteProperty(p.id);
      if (!mounted) return;
      setState(() => _properties.removeWhere((e) => e.id == p.id));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tangazo limefutwa')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imeshindikana kufuta, jaribu tena')));
      _load();
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 8,
              children: _statusOptions.entries.map((entry) {
                final selected = _statusFilter == entry.key;
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _statusFilter = entry.key);
                    _load();
                  },
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
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
              child: Center(child: Text('Hakuna matangazo')),
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
          return Dismissible(
            key: ValueKey(p.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (_) => _confirmDelete(p),
            onDismissed: (_) => _delete(p),
            child: Card(
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
                subtitle: Text(
                  '${p.aina} · ${p.mode} · ${p.locationLabel}\n'
                  'TSh ${p.price} · ${timeAgo(p.createdAt)}',
                ),
                isThreeLine: true,
                trailing: SizedBox(
                  width: 90,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _statusColor(p.status).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          p.status,
                          style: TextStyle(color: _statusColor(p.status), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Futa',
                        onPressed: () async {
                          if (await _confirmDelete(p)) await _delete(p);
                        },
                      ),
                    ],
                  ),
                ),
                onTap: () async {
                  final changed = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: p)),
                  );
                  if (changed == true) _load();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
