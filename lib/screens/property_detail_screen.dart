import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../models/property.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final p = widget.property;
    return Scaffold(
      appBar: AppBar(title: Text(p.jina)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (p.photoUrls.isNotEmpty)
            SizedBox(
              height: 220,
              child: PageView(
                children: p.photoUrls
                    .map(
                      (url) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            '$baseUrl$url',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 60)),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
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
          const SizedBox(height: 16),
          const Text('Maelezo', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(p.description),
          const SizedBox(height: 16),
          const Text('Hati ya Uthibitisho', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (p.verificationDocUrl != null)
            _DocPreview(url: '$baseUrl${p.verificationDocUrl}')
          else
            const Text('Hakuna hati iliyotumwa'),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _decide(false),
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text('Kataa', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : () => _decide(true),
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
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocPreview extends StatelessWidget {
  final String url;
  const _DocPreview({required this.url});

  bool get _isImage {
    final lower = url.toLowerCase();
    return lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png') || lower.endsWith('.webp');
  }

  Future<void> _open() async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (_isImage) {
      return GestureDetector(
        onTap: _open,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 60)),
          ),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: _open,
      icon: const Icon(Icons.picture_as_pdf),
      label: const Text('Fungua Hati (PDF)'),
    );
  }
}
