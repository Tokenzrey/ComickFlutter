import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:boilerplate/presentation/home/models/comic.dart';
import 'package:boilerplate/presentation/home/components/comic_cards.dart';
import 'package:boilerplate/data/repository/manga/manga_repository.dart';
import 'package:boilerplate/utils/logger.dart';

/// Section displaying the most popular manga over different time periods
/// Uses the MangaRepository to fetch data via the /top endpoint
class MostRecentPopularSection extends StatefulWidget {
  const MostRecentPopularSection({super.key});

  @override
  State<MostRecentPopularSection> createState() =>
      _MostRecentPopularSectionState();
}

class _MostRecentPopularSectionState extends State<MostRecentPopularSection> {
  final Logger _logger = Logger().withTag('MostRecentPopularSection');
  final MangaRepository _mangaRepository = GetIt.instance<MangaRepository>();

  // State variables
  final List<Comic> _comics = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  // Filter selection
  final List<FilterOption> _filterOptions = [
    FilterOption(label: '7d', days: 7),
    FilterOption(label: '1m', days: 30),
    FilterOption(label: '3m', days: 90),
  ];
  FilterOption _selectedFilter = FilterOption(label: '7d', days: 7);

  // Stream subscription for cache updates
  StreamSubscription<Map<String, dynamic>>? _cacheSubscription;

  @override
  void initState() {
    super.initState();
    // Load data on widget initialization
    _loadData();

    // Subscribe to cache updates
    _cacheSubscription = _mangaRepository.onTopCacheUpdated.listen((data) {
      _logger.debug('Received cache update, refreshing data');
      if (mounted) _loadData();
    });
  }

  @override
  void dispose() {
    _cacheSubscription?.cancel();
    super.dispose();
  }

  /// Loads data using the MangaRepository's getRecentPopularManga method
  Future<void> _loadData() async {
    if (_isLoading || !mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _comics.clear();
    });

    try {
      _logger.debug(
          'Loading recent popular manga for ${_selectedFilter.days} days');

      // Fetch data using the repository
      final mangaList = await _mangaRepository.getRecentPopularManga(
        days: _selectedFilter.days,
      );

      // Map the response to Comic objects
      final newComics = mangaList.map((item) {
        // Extract slug
        final slug = item["slug"] as String? ?? "";

        // Extract title - try main title first, then fall back to md_titles
        String title = item["title"] as String? ?? "";
        if (title.isEmpty &&
            item["md_titles"] is List &&
            (item["md_titles"] as List).isNotEmpty) {
          title = (item["md_titles"] as List).first["title"] as String? ??
              "Unknown";
        }

        // Extract cover image
        String imageUrl = "";
        if (item["md_covers"] is List &&
            (item["md_covers"] as List).isNotEmpty) {
          final b2key =
              (item["md_covers"] as List).first["b2key"] as String? ?? "";
          if (b2key.isNotEmpty) {
            imageUrl = "https://meo.comick.pictures/$b2key";
          }
        }

        // Create the Comic object
        return Comic(
          name: title,
          imageUrl: imageUrl,
          slug: slug,
        );
      }).toList();

      setState(() {
        _comics.addAll(newComics);
      });

      _logger
          .info('Successfully loaded ${newComics.length} recent popular manga');
    } catch (e, stackTrace) {
      _logger.error('Failed to load recent popular manga: $e',
          exception: e, stackTrace: stackTrace);

      setState(() {
        _hasError = true;
        _errorMessage =
            'Failed to load popular manga: ${e.toString().split('\n').first}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: "Retry",
              onPressed: _loadData,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Handles filter selection and reloads data
  void _onFilterSelected(FilterOption option) {
    if (option.days == _selectedFilter.days) return;

    setState(() {
      _selectedFilter = option;
    });

    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title and filter dropdown
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Most Recent Popular",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              _buildFilterDropdown(),
            ],
          ),
        ),

        // Comics horizontal list
        SizedBox(
          height: 240,
          child: _buildContentArea(),
        ),
      ],
    );
  }

  /// Builds the filter dropdown widget
  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<FilterOption>(
          value: _selectedFilter,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          iconSize: 20,
          elevation: 8,
          isDense: true,
          borderRadius: BorderRadius.circular(15),
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          items: _filterOptions.map((FilterOption option) {
            return DropdownMenuItem<FilterOption>(
              value: option,
              child: Text(option.label),
            );
          }).toList(),
          onChanged: (FilterOption? value) {
            if (value != null) {
              _onFilterSelected(value);
            }
          },
        ),
      ),
    );
  }

  /// Builds the content area based on current state
  Widget _buildContentArea() {
    // Initial loading state
    if (_comics.isEmpty && _isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Error state
    if (_comics.isEmpty && _hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (_comics.isEmpty) {
      return const Center(
        child: Text(
          "No popular manga available",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    // Content state
    return Stack(
      children: [
        // Main horizontal list
        ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: _comics.length,
          itemBuilder: (context, index) {
            final comic = _comics[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GestureDetector(
                onTap: () {
                  if (comic.slug != null && comic.slug!.isNotEmpty) {
                    Navigator.pushNamed(
                      context,
                      "/comic/${comic.slug}",
                    );
                  }
                },
                child: SimpleComicCard(comic: comic),
              ),
            );
          },
        ),

        // Loading indicator overlay
        if (_isLoading)
          Positioned(
            right: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Data class for filter options
class FilterOption {
  final String label;
  final int days;

  FilterOption({required this.label, required this.days});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FilterOption && other.days == days;
  }

  @override
  int get hashCode => days.hashCode;
}
