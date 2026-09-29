import 'package:flutter/material.dart';

import '../utils/media_utils.dart';

/// Picha ya mtandaoni yenye loading na error state.
class NetImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  const NetImage({super.key, required this.url, this.fit = BoxFit.cover, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      resolveMediaUrl(url),
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        final total = progress.expectedTotalBytes;
        return Center(
          child: CircularProgressIndicator(
            value: total != null ? progress.cumulativeBytesLoaded / total : null,
          ),
        );
      },
      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey)),
    );
  }
}

/// Picha zote za tangazo: telezesha au tumia mishale (web), bonyeza kufungua
/// skrini nzima (kuvuta/zoom na kupakua). Vijipicha chini vinaruka moja kwa moja.
class PropertyPhotoGallery extends StatefulWidget {
  final List<String> urls;
  const PropertyPhotoGallery({super.key, required this.urls});

  @override
  State<PropertyPhotoGallery> createState() => _PropertyPhotoGalleryState();
}

class _PropertyPhotoGalleryState extends State<PropertyPhotoGallery> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int i) {
    if (i < 0 || i >= widget.urls.length) return;
    _controller.animateToPage(i, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  void _openViewer(int i) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PhotoViewerScreen(urls: widget.urls, initialIndex: i)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.urls;
    if (urls.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
        child: const Text('Hakuna picha zilizotumwa'),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 240,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    color: Colors.grey.shade200,
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: urls.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (context, i) => GestureDetector(
                        onTap: () => _openViewer(i),
                        child: NetImage(url: urls[i]),
                      ),
                    ),
                  ),
                ),
                if (urls.length > 1 && _index > 0)
                  Positioned(
                    left: 4,
                    top: 0,
                    bottom: 0,
                    child: Center(child: _ArrowButton(icon: Icons.chevron_left, onTap: () => _goTo(_index - 1))),
                  ),
                if (urls.length > 1 && _index < urls.length - 1)
                  Positioned(
                    right: 4,
                    top: 0,
                    bottom: 0,
                    child: Center(child: _ArrowButton(icon: Icons.chevron_right, onTap: () => _goTo(_index + 1))),
                  ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      '${_index + 1}/${urls.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.zoom_in, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Bonyeza kukuza', style: TextStyle(color: Colors.white, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (urls.length > 1) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: urls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => _goTo(i),
                child: Container(
                  width: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: i == _index ? Theme.of(context).colorScheme.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: NetImage(url: urls[i]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, color: Colors.white)),
      ),
    );
  }
}

/// Skrini nzima: kuvuta kwa vidole/gurudumu la mouse, kusogeza, na kupakua.
/// Pia inatumika kwa hati ya umiliki ikiwa ni picha (urls ina kipengele kimoja).
class PhotoViewerScreen extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  final String? title;
  const PhotoViewerScreen({super.key, required this.urls, this.initialIndex = 0, this.title});

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int i) {
    if (i < 0 || i >= widget.urls.length) return;
    _controller.animateToPage(i, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.urls;
    final many = urls.length > 1;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(many ? '${widget.title ?? 'Picha'} ${_index + 1}/${urls.length}' : (widget.title ?? 'Picha')),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Pakua',
            onPressed: () => openExternal(context, urls[_index], download: true),
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: urls.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(child: NetImage(url: urls[i], fit: BoxFit.contain)),
            ),
          ),
          if (many && _index > 0)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(child: _ArrowButton(icon: Icons.chevron_left, onTap: () => _goTo(_index - 1))),
            ),
          if (many && _index < urls.length - 1)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(child: _ArrowButton(icon: Icons.chevron_right, onTap: () => _goTo(_index + 1))),
            ),
        ],
      ),
    );
  }
}
