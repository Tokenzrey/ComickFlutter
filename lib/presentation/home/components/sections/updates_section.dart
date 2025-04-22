import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:boilerplate/presentation/home/models/comic.dart';
import 'package:boilerplate/presentation/home/components/comic_cards.dart';
import 'package:boilerplate/data/repository/manga/manga_repository.dart';
import 'package:boilerplate/utils/logger.dart';
import 'package:intl/intl.dart';

/// Section 4: Updates (Hot & New) - With API Integration
class UpdatesSection extends StatefulWidget {
  final Function(bool isNearBottom) onNearEnd;

  const UpdatesSection({super.key, required this.onNearEnd});

  @override
  State<UpdatesSection> createState() => UpdatesSectionState();
}

/// Public state class for external access
class UpdatesSectionState extends State<UpdatesSection> {
  final Logger _logger = Logger().withTag('UpdatesSection');
  final MangaRepository _mangaRepository = GetIt.instance<MangaRepository>();

  final List<Comic> _comics = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentPage = 1;
  bool _isHot = true; // true: Hot (order=hot); false: New (order=new)

  @override
  void initState() {
    super.initState();
    loadMore(); // Initial load
  }

  /// Public method to load more data (can be called from parent)
  Future<void> loadMore() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      _logger.debug(
          'Loading updates page $_currentPage, order: ${_isHot ? 'hot' : 'new'}');

      // Call the repository to get updates with the appropriate order parameter
      final results = await _mangaRepository.getUpdatesManga(
        page: _currentPage,
        order: _isHot ? 'hot' : 'new',
      );

      _logger.info('Loaded ${results.length} updates');

      final newComics = _processResults(results);

      // Parse the results into Comic objects

      if (mounted) {
        setState(() {
          _comics.addAll(newComics);
          _isLoading = false;
          _currentPage++; // Increment the page for next load
        });

        // Notify parent that we've finished loading
        widget.onNearEnd(false);
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to load updates: $e',
          exception: e, stackTrace: stackTrace);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to load updates: ${e.toString()}';
        });

        // Notify parent about the error
        widget.onNearEnd(false);
      }
    }
  }

  List<Comic> _processResults(List<dynamic> results) {
    // This is where we need to make changes to properly extract updated_at
    return results.map((result) {
      if (result is! Map<String, dynamic>) {
        return Comic(name: 'Invalid data', imageUrl: '');
      }

      // Extract md_comics data
      final mdComics = result['md_comics'] as Map<String, dynamic>?;
      if (mdComics == null) {
        return Comic(name: 'Invalid data', imageUrl: '');
      }

      // Extract the basic information from the md_comics object
      final title = mdComics['title'] as String? ?? 'Unknown Title';
      final slug = mdComics['slug'] as String? ?? '';

      // Get chapter info from parent object
      String chapter = '';
      if (result.containsKey('chap') && result['chap'] != null) {
        chapter = 'Chapter ${result['chap']}';
      }

      // Format the date if available - THIS IS THE KEY CHANGE
      // We need to get updated_at from parent object, not from md_comics
      String updateDate = '';
      if (result.containsKey('updated_at') && result['updated_at'] != null) {
        final rawDate = result['updated_at'] as String;
        try {
          final date = DateTime.parse(rawDate);
          final formatter = DateFormat('MMM d, yyyy');
          updateDate = formatter.format(date);
        } catch (e) {
          updateDate = rawDate.split('T').first;
        }
      }

      // Extract cover image URL from md_covers
      String imageUrl = '';
      if (mdComics.containsKey('md_covers') &&
          mdComics['md_covers'] is List &&
          (mdComics['md_covers'] as List).isNotEmpty) {
        final coverData = (mdComics['md_covers'] as List).first;
        if (coverData is Map && coverData.containsKey('b2key')) {
          final b2key = coverData['b2key'] as String? ?? '';
          if (b2key.isNotEmpty) {
            imageUrl = "https://meo.comick.pictures/$b2key";
          }
        }
      }

      // Create Comic object
      return Comic(
        name: title,
        imageUrl: imageUrl,
        chapter: chapter,
        updateDate: updateDate,
        slug: slug,
      );
    }).toList();
  }

  /// Toggles between Hot and New updates
  void _toggleHotNew(bool value) {
    setState(() {
      _isHot = value;
      _comics.clear();
      _currentPage = 1; // Reset to first page
    });
    loadMore();
  }

  /// Retry loading after an error
  void _retry() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });
    loadMore();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title and Hot/New switch
        _buildHeader(),

        // Error message if applicable
        if (_hasError) _buildErrorWidget(),

        // Grid view for comics
        if (_comics.isNotEmpty) _buildComicsGrid(),

        // Empty state if no comics and not loading
        if (_comics.isEmpty && !_isLoading && !_hasError) _buildEmptyState(),

        // Bottom loading indicator
        if (_isLoading) _buildLoadingIndicator(),
      ],
    );
  }

  /// Builds the section header with title and toggle switch
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Text(
            "Updates",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'New',
                  style: TextStyle(
                    fontWeight: !_isHot ? FontWeight.bold : FontWeight.normal,
                    color:
                        !_isHot ? Theme.of(context).primaryColor : Colors.grey,
                  ),
                ),
                Switch(
                  value: _isHot,
                  onChanged: _toggleHotNew,
                  activeColor: Theme.of(context).primaryColor,
                ),
                Text(
                  'Hot',
                  style: TextStyle(
                    fontWeight: _isHot ? FontWeight.bold : FontWeight.normal,
                    color:
                        _isHot ? Theme.of(context).primaryColor : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the error widget with retry button
  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 32),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _retry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Builds the comics grid
  Widget _buildComicsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _comics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final comic = _comics[index];
        return GestureDetector(
          onTap: () {
            if (comic.slug != null && comic.slug!.isNotEmpty) {
              Navigator.pushNamed(context, "/comic/${comic.slug}");
            }
          },
          child: DetailedComicCard(comic: comic),
        );
      },
    );
  }

  /// Builds the empty state widget
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.update_disabled,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              "No updates available",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Try switching to ${_isHot ? 'New' : 'Hot'} updates",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the loading indicator
  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 8),
            Text(
              _comics.isEmpty
                  ? "Loading updates..."
                  : "Loading more updates...",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
