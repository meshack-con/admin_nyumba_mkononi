import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../utils/media_utils.dart';
import 'photo_gallery.dart';

/// Hati ya umiliki wa nyumba: admin anaweza KUIONA ndani ya app na KUIPAKUA.
/// Inasaidia PDF na picha (jpg/png/webp).
class VerificationDocumentSection extends StatefulWidget {
  final String? url;
  final int propertyId;
  const VerificationDocumentSection({super.key, required this.url, required this.propertyId});

  @override
  State<VerificationDocumentSection> createState() => _VerificationDocumentSectionState();
}

class _VerificationDocumentSectionState extends State<VerificationDocumentSection> {
  bool _downloading = false;

  String get _pdfName => 'hati_ya_umiliki_${widget.propertyId}.pdf';

  Future<void> _downloadPdf(String url) async {
    setState(() => _downloading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await fetchMediaBytes(url);
      await savePdf(bytes, _pdfName);
    } on MediaException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Imeshindikana kupakua hati')));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.url;
    if (url == null || url.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
        child: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(child: Text('Hakuna hati ya umiliki iliyotumwa')),
          ],
        ),
      );
    }

    if (isPdfUrl(url)) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.picture_as_pdf, color: Colors.red, size: 36),
                  SizedBox(width: 12),
                  Expanded(child: Text('Hati ya umiliki (PDF)', style: TextStyle(fontWeight: FontWeight.w600))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PdfViewerScreen(url: url, filename: _pdfName),
                        ),
                      ),
                      icon: const Icon(Icons.visibility),
                      label: const Text('Angalia'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _downloading ? null : () => _downloadPdf(url),
                      icon: _downloading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.download),
                      label: const Text('Pakua'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (isImageUrl(url)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PhotoViewerScreen(urls: [url], title: 'Hati ya umiliki'),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 220,
                width: double.infinity,
                color: Colors.grey.shade200,
                child: NetImage(url: url, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PhotoViewerScreen(urls: [url], title: 'Hati ya umiliki'),
                    ),
                  ),
                  icon: const Icon(Icons.zoom_in),
                  label: const Text('Angalia / Kuza'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => openExternal(context, url, download: true),
                  icon: const Icon(Icons.download),
                  label: const Text('Pakua'),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Aina isiyojulikana - ifungue nje ya app.
    return OutlinedButton.icon(
      onPressed: () => openExternal(context, url),
      icon: const Icon(Icons.open_in_new),
      label: const Text('Fungua hati'),
    );
  }
}

/// Inaonyesha PDF ndani ya app (kurasa zote, kuvuta) na kupakua.
class PdfViewerScreen extends StatefulWidget {
  final String url;
  final String filename;
  const PdfViewerScreen({super.key, required this.url, required this.filename});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  Uint8List? _bytes;
  String? _error;
  bool _loading = true;

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
      final bytes = await fetchMediaBytes(widget.url);
      if (!mounted) return;
      setState(() => _bytes = bytes);
    } on MediaException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Imeshindikana kufungua PDF');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hati ya umiliki'),
        actions: [
          if (bytes != null)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Pakua',
              onPressed: () => savePdf(bytes, widget.filename),
            ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Fungua nje ya app',
            onPressed: () => openExternal(context, widget.url),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _load, child: const Text('Jaribu tena')),
                        TextButton(
                          onPressed: () => openExternal(context, widget.url),
                          child: const Text('Fungua kwenye browser'),
                        ),
                      ],
                    ),
                  ),
                )
              : PdfPreview(
                  build: (_) => bytes!,
                  useActions: false,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  pdfFileName: widget.filename,
                ),
    );
  }
}
