import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:boilerplate/data/repository/manga/manga_repository.dart';
import 'chapter_list_item.dart';
import 'chapter_reader_screen.dart';

class MangaDetailScreen extends StatefulWidget {
  final String mangaId;

  const MangaDetailScreen({
    super.key,
    required this.mangaId,
  });

  @override
  State<MangaDetailScreen> createState() => _MangaDetailScreenState();
}

class _MangaDetailScreenState extends State<MangaDetailScreen> {
  final MangaRepository _mangaRepository = GetIt.instance<MangaRepository>();

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _mangaDetail;
  List<dynamic> _chapters = [];
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadMangaDetail();
  }

  Future<void> _loadMangaDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final detail = await _mangaRepository.getMangaDetail(widget.mangaId);

      setState(() {
        _mangaDetail = detail.toJson();
        _chapters = _mangaDetail?['chapters'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load manga details: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMangaDetail,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final manga = _mangaDetail!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'manga_cover_${widget.mangaId}',
                    child: Image.network(
                      manga['cover_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.error, size: 50),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Text(
                      manga['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Metadata row
                  Row(
                    children: [
                      _buildInfoChip(
                          Icons.person, manga['author'] ?? 'Unknown'),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                          Icons.category, manga['status'] ?? 'Unknown'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Genres
                  if (manga['genres'] != null && manga['genres'].isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (manga['genres'] as List).map((genre) {
                        return Chip(
                          label: Text(genre),
                          backgroundColor:
                              Theme.of(context).colorScheme.surfaceContainerHighest,
                          labelStyle: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isDescriptionExpanded = !_isDescriptionExpanded;
                      });
                    },
                    child: Text(
                      manga['description'] ?? 'No description available.',
                      style: const TextStyle(fontSize: 14),
                      maxLines: _isDescriptionExpanded ? null : 4,
                      overflow:
                          _isDescriptionExpanded ? null : TextOverflow.ellipsis,
                    ),
                  ),
                  if (!_isDescriptionExpanded &&
                      (manga['description'] ?? '').length > 200)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isDescriptionExpanded = true;
                        });
                      },
                      child: const Text('Read More'),
                    ),

                  const SizedBox(height: 16),

                  // Chapters header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Chapters',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('${_chapters.length} chapters'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Chapters list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final chapter = _chapters[index];
                return ChapterListItem(
                  index: index,
                  chapter: chapter,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChapterReaderScreen(
                          mangaId: widget.mangaId,
                          chapterId: chapter['id'],
                          chapterTitle: chapter['title'] ??
                              'Chapter ${chapter['number']}',
                        ),
                      ),
                    );
                  },
                );
              },
              childCount: _chapters.length,
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_chapters.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChapterReaderScreen(
                  mangaId: widget.mangaId,
                  chapterId: _chapters.first['id'],
                  chapterTitle: _chapters.first['title'] ??
                      'Chapter ${_chapters.first['number']}',
                ),
              ),
            );
          }
        },
        icon: const Icon(Icons.menu_book),
        label: const Text('Read First Chapter'),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
    );
  }
}
