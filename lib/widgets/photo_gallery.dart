import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/report_style.dart';
import 'adopt_pet_photo.dart';

/// Big photo area for a details screen. One photo = just the image.
/// 2+ photos = swipeable with dots. Tap = full-screen viewer (swipe + zoom).
class PhotoGallery extends StatefulWidget {
  final List<String> photos;
  final double height;

  /// Optional widget drawn on top-left of the photo (e.g. a status chip).
  final Widget? overlay;

  const PhotoGallery({
    super.key,
    required this.photos,
    this.height = 300,
    this.overlay,
  });

  @override
  State<PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<PhotoGallery> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _fallback() {
    return Container(
      color: kPeach,
      child: const Center(
        child: Icon(Icons.pets, size: 48, color: ReportColors.grey),
      ),
    );
  }

  void _openViewer(int start) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PhotoViewerScreen(photos: widget.photos, initialIndex: start),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          children: [
            if (photos.isEmpty)
              Positioned.fill(child: _fallback())
            else
              PageView.builder(
                controller: _controller,
                itemCount: photos.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _openViewer(i),
                  child: PetPhoto(path: photos[i], fallback: _fallback()),
                ),
              ),
            if (widget.overlay != null)
              Positioned(top: 12, left: 12, child: widget.overlay!),
            if (photos.length > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(photos.length, (i) {
                    final active = i == _index;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 10 : 8,
                      height: active ? 10 : 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active ? kBlue : Colors.white70,
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen viewer. Swipe to change photo; pinch to zoom (swiping is
/// paused while zoomed in so panning the photo doesn't change the page).
class PhotoViewerScreen extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const PhotoViewerScreen({
    super.key,
    required this.photos,
    this.initialIndex = 0,
  });

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late final PageController _controller =
  PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;
  bool _zoomed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: photos.length > 1
            ? Text('${_index + 1} / ${photos.length}',
            style: const TextStyle(fontSize: 16))
            : null,
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: photos.length,
        physics: _zoomed
            ? const NeverScrollableScrollPhysics()
            : const PageScrollPhysics(),
        onPageChanged: (i) => setState(() {
          _index = i;
          _zoomed = false;
        }),
        itemBuilder: (_, i) => _ZoomablePhoto(
          path: photos[i],
          onZoomChanged: (z) {
            if (z != _zoomed) setState(() => _zoomed = z);
          },
        ),
      ),
    );
  }
}

class _ZoomablePhoto extends StatefulWidget {
  final String path;
  final ValueChanged<bool> onZoomChanged;

  const _ZoomablePhoto({required this.path, required this.onZoomChanged});

  @override
  State<_ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends State<_ZoomablePhoto> {
  final TransformationController _tc = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _tc.addListener(() {
      final z = _tc.value.getMaxScaleOnAxis() > 1.02;
      if (z != _zoomed) {
        setState(() => _zoomed = z);
        widget.onZoomChanged(z);
      }
    });
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _tc,
      minScale: 1,
      maxScale: 5,
      panEnabled: _zoomed,
      child: SizedBox.expand(
        child: PetPhoto(
          path: widget.path,
          fit: BoxFit.contain,
          fallback: const Center(
            child: Icon(Icons.broken_image_outlined,
                size: 48, color: Colors.white54),
          ),
        ),
      ),
    );
  }
}