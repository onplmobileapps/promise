import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/media/sized_network_image.dart';

class AccidentPhotoPreview extends StatelessWidget {
  final List<String> imageUrls;

  const AccidentPhotoPreview({super.key, required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    final photoCount = imageUrls.length;
    if (photoCount == 0) return const SizedBox.shrink();

    // Grab the first image for the preview tile
    final previewUrl = imageUrls.first;

    return GestureDetector(
      onTap: () {
        // Open iOS-style full-screen viewer
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) =>
                _FullScreenPhotoGallery(imageUrls: imageUrls, initialIndex: 0),
          ),
        );
      },
      child: Container(
        height: 140,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          image: DecorationImage(
            // Decoded at the screen's width, not the camera's.
            image: sizedNetworkImage(
              previewUrl,
              width: physicalWidth(context, MediaQuery.sizeOf(context).width),
            ),
            fit: .cover,
            // A photo that won't download leaves the card plain rather
            // than reporting an error.
            onError: (_, _) {},
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Align(
          alignment: .bottomEnd,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              color: Colors.black.withValues(alpha: 0.6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppGlyphIcon(
                    AppGlyphs.camera,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '+$photoCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// iOS-style full screen photo viewer with page indicator
class _FullScreenPhotoGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullScreenPhotoGallery({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_FullScreenPhotoGallery> createState() =>
      _FullScreenPhotoGalleryState();
}

class _FullScreenPhotoGalleryState extends State<_FullScreenPhotoGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.black.withValues(alpha: 0.6),
        border: null,
        // The close key leaves; the bar's own back arrow is a glyph the
        // app doesn't ship, so it would show as an empty box.
        automaticallyImplyLeading: false,
        middle: Text(
          '${_currentIndex + 1} of ${widget.imageUrls.length}',
          style: const TextStyle(color: Colors.white),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const AppGlyphIcon(
            AppGlyphs.close,
            color: Colors.white70,
            size: 28,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: SafeArea(
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.imageUrls.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  widget.imageUrls[index],
                  // Twice the screen's width: sharp when zoomed in, without
                  // the camera's full size in memory.
                  cacheWidth: physicalWidth(
                    context,
                    MediaQuery.sizeOf(context).width * 2,
                  ),
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CupertinoActivityIndicator(color: Colors.white),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 48,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
