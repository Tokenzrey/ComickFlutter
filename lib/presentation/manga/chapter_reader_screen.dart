import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:boilerplate/data/repository/manga/manga_repository.dart';

class ChapterReaderScreen extends StatefulWidget {
  final String mangaId;
  final String chapterId;
  final String chapterTitle;

  const ChapterReaderScreen({
    super.key,
    required this.mangaId,
    required this.chapterId,
    required this.chapterTitle,
  });

  @override
  State<ChapterReaderScreen> createState() => _ChapterReaderScreenState();
}

class _ChapterReaderScreenState extends State<ChapterReaderScreen> {
  final MangaRepository _mangaRepository = GetIt.instance<MangaRepository>();

  bool _isLoading = true;
  String? _error;
  List<String> _pages = [];
  bool _isControlsVisible = true;
  late PageController _pageController;
  int _currentPage = 0;
  bool _isVerticalReading = false; // For webtoon mode

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadChapterPages();
  }

  Future<void> _loadChapterPages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final pages = await _mangaRepository.getChapterPages(
          widget.mangaId, widget.chapterId);

      setState(() {
        _pages = pages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load chapter pages: $e';
        _isLoading = false;
      });
    }
  }

  void _toggleControls() {
    setState(() {
      _isControlsVisible = !_isControlsVisible;
    });
  }

  void _toggleReadingMode() {
    setState(() {
      _isVerticalReading = !_isVerticalReading;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.chapterTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.chapterTitle)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadChapterPages,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: _isControlsVisible
          ? AppBar(
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              foregroundColor: Colors.white,
              title: Text(widget.chapterTitle),
              actions: [
                IconButton(
                  icon: Icon(
                      _isVerticalReading ? Icons.view_day : Icons.view_array),
                  onPressed: _toggleReadingMode,
                  tooltip: _isVerticalReading ? 'Page mode' : 'Webtoon mode',
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: _toggleControls,
        child: _isVerticalReading ? _buildWebtoonView() : _buildPageView(),
      ),
      bottomNavigationBar: _isControlsVisible ? _buildBottomControls() : null,
    );
  }

  Widget _buildPageView() {
    return PageView.builder(
      controller: _pageController,
      itemCount: _pages.length,
      onPageChanged: (index) {
        setState(() {
          _currentPage = index;
        });
      },
      itemBuilder: (context, index) {
        return InteractiveViewer(
          minScale: 1.0,
          maxScale: 3.0,
          child: Center(
            child: Image.network(
              _pages[index],
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.red[300]),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {}); // Force rebuild to retry loading
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildWebtoonView() {
    return ListView.builder(
      itemCount: _pages.length,
      itemBuilder: (context, index) {
        return Image.network(
          _pages[index],
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              height: 300,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return SizedBox(
              height: 300,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.red[300]),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {}); // Force rebuild to retry loading
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomControls() {
    return BottomAppBar(
      color: Colors.black.withValues(alpha: 0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous),
            color: Colors.white,
            onPressed: _currentPage > 0
                ? () {
                    _pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.navigate_before),
            color: Colors.white,
            onPressed: _currentPage > 0
                ? () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
          ),
          Text(
            '${_currentPage + 1} / ${_pages.length}',
            style: const TextStyle(color: Colors.white),
          ),
          IconButton(
            icon: const Icon(Icons.navigate_next),
            color: Colors.white,
            onPressed: _currentPage < _pages.length - 1
                ? () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.skip_next),
            color: Colors.white,
            onPressed: _currentPage < _pages.length - 1
                ? () {
                    _pageController.animateToPage(
                      _pages.length - 1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
