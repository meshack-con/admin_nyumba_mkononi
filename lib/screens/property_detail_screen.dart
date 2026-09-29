import 'package:flutter/material.dart';

import '../models/property.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/time_format.dart';
import '../widgets/photo_gallery.dart';
import '../widgets/verification_document.dart';

class PropertyDetailScreen extends StatefulWidget {
  final AdminProperty property;
  const PropertyDetailScreen({super.key, required this.property});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  bool _busy = false;

  Future<void> _decide(bool approve) async {
    setState(() => _busy = true);
    try {
      final token = await AuthService().getToken();
      if (token == null) throw ApiException('Hujaingia', 401);
      final api = ApiService(token);
      if (approve) {
        await api.approveProperty(widget.property.id);
      } else {
        await api.rejectProperty(widget.property.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approve ? 'Tangazo limeruhusiwa' : 'Tangazo limekataliwa')),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imeshindikana, jaribu tena')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Uthibitisho kabla ya kuruhusu/kukataa - admin aone tahadhari ikiwa
  /// hakuna hati ya umiliki.
  Future<void> _confirmDecision(bool approve) async {
    final p = widget.property;
    final hasDoc = p.verificationDocUrl != null && p.verificationDocUrl!.isNotEmpty;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'Ruhusu Tangazo' : 'Kataa Tangazo'),
        content: Text(
          approve
              ? 'Tangazo la "${p.jina}" litaonekana kwa umma na mmiliki atapata arifa.'
                  '${hasDoc ? '' : '\n\nTahadhari: hakuna hati ya umiliki iliyotumwa.'}'
              : 'Tangazo la "${p.jina}" litakataliwa na mmiliki atapata arifa.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Ghairi')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              approve ? 'Ruhusu' : 'Kataa',
              style: TextStyle(color: approve ? Colors.teal : Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) await _decide(approve);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Futa Tangazo'),
        content: Text(
          'Una uhakika unataka kufuta "${widget.property.jina}" kabisa? '
          'Hatua hii haiwezi kutenduliwa - tangazo, picha, na taarifa zake zote zitaondolewa milele.',
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
    if (confirmed != true) return;
    await _delete();
  }

  Future<void> _delete() async {
    setState(() => _busy = true);
    try {
      final token = await AuthService().getToken();
      if (token == null) throw ApiException('Hujaingia', 401);
      final api = ApiService(token);
      await api.deleteProperty(widget.property.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tangazo limefutwa')),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imeshindikana kufuta, jaribu tena')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.property;
    return Scaffold(
      appBar: AppBar(
        title: Text(p.jina),
        actions: [
          IconButton(
            onPressed: _busy ? null : _confirmDelete,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Futa Tangazo',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Picha za nyumba (${p.photoUrls.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          PropertyPhotoGallery(urls: p.photoUrls),
          const SizedBox(height: 16),
          Text(p.jina, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${p.aina} · ${p.mode}'),
          const SizedBox(height: 4),
          Text(
            'TSh ${p.price}',
            style: const TextStyle(fontSize: 18, color: Colors.teal, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 18),
              const SizedBox(width: 4),
              Expanded(child: Text(p.locationLabel)),
            ],
          ),
          Row(
            children: [
              Icon(p.hasWifi ? Icons.wifi : Icons.wifi_off, size: 18),
              const SizedBox(width: 4),
              Text(p.hasWifi ? 'Ina Wifi' : 'Haina Wifi'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.schedule, size: 18, color: Colors.grey),
              const SizedBox(width: 4),
              Text('Imekuwa ndani ya app: ${timeAgo(p.createdAt)}', style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Maelezo', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(p.description),
          const SizedBox(height: 16),
          const Text('Hati ya Umiliki', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          VerificationDocumentSection(url: p.verificationDocUrl, propertyId: p.id),
          const SizedBox(height: 32),
          if (p.status == 'pending' || p.status == 'rejected')
            Row(
              children: [
                if (p.status == 'pending') ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _confirmDecision(false),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text('Kataa', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : () => _confirmDecision(true),
                    icon: _busy
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Ruhusu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          if (p.status == 'pending' || p.status == 'rejected') const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _confirmDelete,
              icon: _busy
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                    )
                  : const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text('Futa Tangazo Kabisa', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
