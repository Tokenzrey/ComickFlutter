import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:boilerplate/data/repository/manga/manga_repository.dart';
import 'package:boilerplate/utils/logger.dart';

class ReadingSectionScreen extends StatefulWidget {
  final String
      chapHid; // Changed from comicSlug to chapHid which is the chapter ID needed for API

  const ReadingSectionScreen({
    super.key,
    required this.chapHid,
  });

  @override
  State<ReadingSectionScreen> createState() => _ReadingSectionScreenState();
}

class _ReadingSectionScreenState extends State<ReadingSectionScreen> {
  final Logger _logger = Logger().withTag('ReadingSectionScreen');
  final MangaRepository _mangaRepository = GetIt.instance<MangaRepository>();

  // State variables
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // API response data
  List<Map<String, dynamic>> _imagesData = [];
  String _chapterTitle = '';
  String _comicSlug = '';
  String _prevChapterHid = '';
  String _nextChapterHid = '';
  String? _prevChapterNumber;
  String? _nextChapterNumber;
  String _language = 'English';

  @override
  void initState() {
    super.initState();
    _loadChapterData();
  }

  Future<void> _loadChapterData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      _logger.debug('Loading chapter data for HID: ${widget.chapHid}');

      // Fetch chapter data
      final response = await _mangaRepository.getPageChapter(widget.chapHid);

      // Process the response
      _processChapterData(response);

      setState(() {
        _isLoading = false;
      });

      _logger
          .info('Successfully loaded chapter with ${_imagesData.length} pages');
    } catch (e, stackTrace) {
      _logger.error('Failed to load chapter data: $e',
          exception: e, stackTrace: stackTrace);

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load chapter: $e';
      });
    }
  }

  void _processChapterData(Map<String, dynamic> data) {
    // Extract chapter info
    final chapter = data['chapter'] as Map<String, dynamic>? ?? {};

    // Get chapter title and number
    _chapterTitle = chapter['chap'] as String? ?? 'Chapter';

    // Extract comic info (for navigation)
    final mdComic = chapter['md_comics'] as Map<String, dynamic>? ?? {};
    _comicSlug = mdComic['slug'] as String? ?? '';

    // Extract language information
    _language = chapter['lang'] as String? ?? 'en';
    _language = _language == 'en' ? 'English' : _language.toUpperCase();

    // Extract images - check various possible locations in the response
    List<dynamic> images = [];

    if (chapter.containsKey('images') && chapter['images'] is List) {
      images = chapter['images'] as List;
    } else if (data.containsKey('images') && data['images'] is List) {
      images = data['images'] as List;
    } else if (data.containsKey('chapter_images') &&
        data['chapter_images'] is List) {
      images = data['chapter_images'] as List;
    }

    _imagesData = images.map((img) {
      if (img is Map) {
        return Map<String, dynamic>.from(img);
      }
      return <String, dynamic>{'error': true}; // Fallback for non-map items
    }).toList();

    // Get previous and next chapter info
    _prevChapterHid = chapter['prev'] as String? ?? '';
    _nextChapterHid = chapter['next'] as String? ?? '';

    // Get chapter numbers for display
    if (_prevChapterHid.isNotEmpty) {
      _prevChapterNumber = chapter['prev_num'] as String? ?? '';
    }

    if (_nextChapterHid.isNotEmpty) {
      _nextChapterNumber = chapter['next_num'] as String? ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title:
              const Text('Loading...', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show error screen
    if (_hasError) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Error', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text('Failed to load chapter',
                  style: TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text(_errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadChapterData,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final double deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      // AppBar with back button, chapter title, and language
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Chapter $_chapterTitle",
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(
              _language,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          // If comic slug is available, show button to return to comic page
          if (_comicSlug.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.menu_book, color: Colors.white),
              onPressed: () {
                Navigator.popUntil(
                    context,
                    (route) =>
                        route.settings.name == '/comic/$_comicSlug' ||
                        route.isFirst);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // SECTION 1: Page images
          Expanded(
            child: _imagesData.isEmpty
                ? const Center(
                    child: Text(
                      "No images available for this chapter",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : ListView.builder(
                    itemCount: _imagesData.length,
                    itemBuilder: (context, index) {
                      final Map<String, dynamic> imageData = _imagesData[index];

                      // Extract image dimensions and URL
                      final double height =
                          (imageData['h'] as num?)?.toDouble() ?? 800.0;
                      final double width =
                          (imageData['w'] as num?)?.toDouble() ?? 600.0;
                      final double ratio = height / width;
                      final double imageHeight = deviceWidth * ratio;

                      // Construct full image URL
                      String imageUrl;
                      if (imageData.containsKey('url')) {
                        imageUrl = imageData['url'] as String? ?? '';
                      } else {
                        final String b2key = imageData['name'] as String? ?? '';
                        imageUrl = "https://meo.comick.pictures/$b2key";
                      }

                      return ReloadableNetworkImage(
                        imageUrl: imageUrl,
                        width: deviceWidth,
                        height: imageHeight,
                        fit: BoxFit.contain,
                        cacheWidth: deviceWidth.toInt(),
                      );
                    },
                  ),
          ),

          // SECTION 2: Navigation buttons
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Previous chapter button
                ElevatedButton(
                  onPressed: _prevChapterHid.isEmpty
                      ? null
                      : () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReadingSectionScreen(
                                chapHid: _prevChapterHid,
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _prevChapterHid.isEmpty
                        ? Colors.grey[700]
                        : Colors.blue,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.grey[400],
                    disabledBackgroundColor: Colors.grey[800],
                  ),
                  child: Text(
                    _prevChapterHid.isEmpty
                        ? "Previous"
                        : "Prev Ch. $_prevChapterNumber",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),

                const Spacer(),

                // Home button
                IconButton(
                  icon: const Icon(Icons.home, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),

                const Spacer(),

                // Next chapter button or home button
                _nextChapterHid.isEmpty
                    ? ElevatedButton(
                        onPressed: () {
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: const Text(
                          "Home",
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReadingSectionScreen(
                                chapHid: _nextChapterHid,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: Text(
                          "Next Ch. $_nextChapterNumber",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget for displaying images with loading, error handling and reload functionality
class ReloadableNetworkImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double width;
  final double height;
  final int? cacheWidth;
  final int? cacheHeight;

  const ReloadableNetworkImage({
    super.key,
    required this.imageUrl,
    required this.fit,
    required this.width,
    required this.height,
    this.cacheWidth,
    this.cacheHeight,
  });

  @override
  State<ReloadableNetworkImage> createState() => _ReloadableNetworkImageState();
}

class _ReloadableNetworkImageState extends State<ReloadableNetworkImage> {
  int reloadTrigger = 0;

  @override
  Widget build(BuildContext context) {
    final String reloadUrl = "${widget.imageUrl}?reload=$reloadTrigger";
    return Image.network(
      reloadUrl,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      cacheWidth: widget.cacheWidth,
      cacheHeight: widget.cacheHeight,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: widget.width,
          height: widget.height,
          alignment: Alignment.center,
          color: Colors.black,
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey[800],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.broken_image, color: Colors.grey, size: 40),
              const SizedBox(height: 8),
              const Text(
                "Failed to load image",
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    reloadTrigger++;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text("Reload"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
