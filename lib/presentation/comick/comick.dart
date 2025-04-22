import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:boilerplate/data/repository/manga/manga_repository.dart';
import 'package:boilerplate/utils/logger.dart';

class ComicDetailScreen extends StatefulWidget {
  final String comicSlug;

  const ComicDetailScreen({super.key, required this.comicSlug});

  @override
  State<ComicDetailScreen> createState() => _ComicDetailScreenState();
}

class _ComicDetailScreenState extends State<ComicDetailScreen> {
  final Logger _logger = Logger().withTag('ComicDetailScreen');
  final MangaRepository _mangaRepository = GetIt.instance<MangaRepository>();

  // State variables
  bool isFollowed = false;
  bool isDescriptionExpanded = false;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // Data from API
  Map<String, dynamic>? _comicDetail;
  List<Map<String, dynamic>> _chapters = [];

  @override
  void initState() {
    super.initState();
    _loadComicData();
  }

  Future<void> _loadComicData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // 1. Load comic details - now returns a list with the detail as first item
      _logger.debug('Loading comic detail for slug: ${widget.comicSlug}');
      final detailList =
          await _mangaRepository.getDetailManga(widget.comicSlug);

      // Make sure we have data
      if (detailList.isEmpty) {
        throw Exception('Empty response from API');
      }

      // Get the first (and only) item from the list
      final detailMap = detailList.first;

      // 2. Get the HID from the comic object
      final comic = detailMap['comic'] as Map<String, dynamic>? ?? {};
      final hid = comic['hid'] as String? ?? '';

      if (hid.isEmpty) {
        throw Exception('Could not get comic HID');
      }

      // 3. Load chapters using the HID
      _logger.debug('Loading chapters for HID: $hid');
      final chaptersList = await _mangaRepository.getChapterManga(hid, 1);

      // 4. Update state with the fetched data
      setState(() {
        _comicDetail =
            detailMap; // Now properly using the first item from the list
        _chapters = chaptersList; // This is already a list of chapter items
        _isLoading = false;
      });

      _logger.info(
          'Successfully loaded comic details and ${chaptersList.length} chapters');
    } catch (e, stackTrace) {
      _logger.error('Error loading comic data: $e',
          exception: e, stackTrace: stackTrace);

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load comic: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Loading...',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show error screen
    if (_hasError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Error',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Failed to load comic details',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadComicData,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // Extract data from comic detail
    final comic = _comicDetail!['comic'] as Map<String, dynamic>;
    final title = comic['title'] as String? ?? 'Unknown Title';

    // Extract alternative titles
    final List<dynamic> mdTitles = comic['md_titles'] as List<dynamic>? ?? [];
    final String altTitles = mdTitles
        .map((t) => (t as Map<String, dynamic>)['title'] as String? ?? '')
        .where((t) => t.isNotEmpty)
        .join(' - ');

    // Extract country and year
    final String origination = comic['country'] as String? ?? 'Unknown';
    final String published = (comic['year'] as int? ?? 0).toString();

    // Extract status
    final int statusCode = comic['status'] as int? ?? 0;
    final String status = _getStatusString(statusCode);

    // Extract follow count
    final int followCount = comic['follow_count'] as int? ?? 0;
    final String followedCount = _formatNumber(followCount);

    // Extract description
    final String description = comic['parsed'] as String? ??
        comic['desc'] as String? ??
        'No description available';

    // Extract genres
    final List<dynamic> mdGenres =
        comic['md_comic_md_genres'] as List<dynamic>? ?? [];
    final List<String> genres = mdGenres
        .map((g) {
          final genreObj =
              (g as Map<String, dynamic>)['md_genres'] as Map<String, dynamic>?;
          return genreObj?['name'] as String? ?? '';
        })
        .where((g) => g.isNotEmpty)
        .toList();

    // Extract cover image
    final List<dynamic> mdCovers = comic['md_covers'] as List<dynamic>? ?? [];
    String coverUrl = '';
    if (mdCovers.isNotEmpty) {
      final coverData = mdCovers.first as Map<String, dynamic>;
      final b2key = coverData['b2key'] as String? ?? '';
      if (b2key.isNotEmpty) {
        coverUrl = 'https://meo.comick.pictures/$b2key';
      }
    }

    // Extract chapters and sort by newest first
    List<Map<String, dynamic>> chaptersList = [];
    if (_chapters.isNotEmpty) {
      chaptersList = _chapters.map((c) => c).toList();
      chaptersList.sort((a, b) {
        final dateA = DateTime.tryParse(a['created_at'] as String? ?? '') ??
            DateTime.now();
        final dateB = DateTime.tryParse(b['created_at'] as String? ?? '') ??
            DateTime.now();
        return dateB.compareTo(dateA); // Newest first
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Comic cover and info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover image with error handling
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: coverUrl.isNotEmpty
                      ? Image.network(
                          coverUrl,
                          width: 120,
                          height: 180,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 120,
                              height: 180,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.broken_image,
                                    color: Colors.grey),
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 120,
                          height: 180,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.image_not_supported,
                                color: Colors.grey),
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                // Info beside the cover
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Alternative titles
                      if (altTitles.isNotEmpty)
                        Text(
                          altTitles,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            height: 1.3,
                          ),
                        ),
                      const SizedBox(height: 8),
                      // Origination, Published, Status, Followed by
                      Text("Origination: $origination",
                          style: const TextStyle(fontSize: 14)),
                      Text("Published: $published",
                          style: const TextStyle(fontSize: 14)),
                      Text("Status: $status",
                          style: const TextStyle(fontSize: 14)),
                      Text("Followed by: $followedCount users",
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 12),
                      // Follow button
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            isFollowed = !isFollowed;
                          });
                        },
                        icon: Icon(
                          isFollowed ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: Colors.white,
                        ),
                        label: Text(
                          isFollowed ? "Following" : "Follow",
                          style: const TextStyle(fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor:
                              isFollowed ? Colors.redAccent : Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            // Description with collapse/expand feature
            const Text(
              "Description",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () {
                setState(() {
                  isDescriptionExpanded = !isDescriptionExpanded;
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    maxLines: isDescriptionExpanded ? null : 3,
                    overflow: isDescriptionExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isDescriptionExpanded ? "Show Less" : "Show More",
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            // Genres info
            const Text(
              "More Info",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const Divider(),
            Row(
              children: [
                const Text(
                  "Genres: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: Text(
                    genres.join(", "),
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            // Chapters section
            const Text(
              "Chapters",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const Divider(),
            // Chapter list
            if (chaptersList.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text("No chapters available")),
              )
            else
              Column(
                children: chaptersList.map((chapter) {
                  // Extract chapter data and handle both String and numeric types
                  String chapterNumber;
                  final chap = chapter['chap'];

                  // Fix for type error: Handle both String and numeric chapter numbers
                  if (chap is String) {
                    chapterNumber = chap;
                  } else if (chap is num) {
                    chapterNumber = chap.toString();
                  } else {
                    chapterNumber = 'Unknown';
                  }

                  final createdAt = chapter['created_at'] as String? ?? '';
                  final timeAgo = _getTimeAgo(createdAt);
                  final chapHid = chapter['hid'] as String? ?? '';

                  return ChapterRow(
                    chapter: "Ch. $chapterNumber",
                    time: timeAgo,
                    onTap: () {
                      if (chapHid.isNotEmpty) {
                        _navigateToChapter(context, chapHid);
                      }
                    },
                  );
                }).toList(),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helper method to format status code
  String _getStatusString(int statusCode) {
    switch (statusCode) {
      case 1:
        return 'Ongoing';
      case 2:
        return 'Completed';
      case 3:
        return 'Cancelled';
      case 4:
        return 'Hiatus';
      default:
        return 'Unknown';
    }
  }

  // Helper method to format large numbers
  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  // Helper method to format date to relative time
  String _getTimeAgo(String dateString) {
    if (dateString.isEmpty) return 'Unknown';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()} years ago';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()} months ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} days ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hours ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minutes ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  // Navigation to chapter reader
  void _navigateToChapter(BuildContext context, String chapHid) {
    _logger.info('Navigating to chapter with HID: $chapHid');
    Navigator.pushNamed(context, '/reader/$chapHid');
  }
}

// Enhanced chapter row with onTap callback
class ChapterRow extends StatelessWidget {
  final String chapter;
  final String time;
  final VoidCallback? onTap;

  const ChapterRow({
    super.key,
    required this.chapter,
    required this.time,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(
              Icons.menu_book,
              size: 20,
              color: Colors.blueAccent,
            ),
            const SizedBox(width: 8),
            Text(
              chapter,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              time,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
