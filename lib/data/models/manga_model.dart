/// Represents a manga list item with basic information
class MangaListItem {
  final String id;
  final String title;
  final String? coverUrl;
  final List<String> genres;
  final double? rating;
  final String? status;

  MangaListItem({
    required this.id,
    required this.title,
    this.coverUrl,
    this.genres = const [],
    this.rating,
    this.status,
  });

  factory MangaListItem.fromJson(Map<String, dynamic> json) {
    return MangaListItem(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      coverUrl: json['cover_url'],
      genres: json['genres'] != null ? List<String>.from(json['genres']) : [],
      rating:
          json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'cover_url': coverUrl,
      'genres': genres,
      'rating': rating,
      'status': status,
    };
  }
}

/// Represents a manga chapter
class MangaChapter {
  final String id;
  final String title;
  final String? number;
  final DateTime? uploadDate;
  final int pageCount;
  final String? scanlator;

  MangaChapter({
    required this.id,
    required this.title,
    this.number,
    this.uploadDate,
    this.pageCount = 0,
    this.scanlator,
  });

  factory MangaChapter.fromJson(Map<String, dynamic> json) {
    return MangaChapter(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      number: json['number']?.toString(),
      uploadDate: json['upload_date'] != null
          ? DateTime.parse(json['upload_date'])
          : null,
      pageCount: json['page_count'] ?? 0,
      scanlator: json['scanlator'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'number': number,
      'upload_date': uploadDate?.toIso8601String(),
      'page_count': pageCount,
      'scanlator': scanlator,
    };
  }
}

/// Represents detailed information about a manga
class MangaDetail {
  final String id;
  final String title;
  final String? alternateTitles;
  final String? description;
  final String? coverUrl;
  final List<String> genres;
  final List<MangaChapter> chapters;
  final String? author;
  final String? artist;
  final String status;
  final double? rating;
  final bool isNsfw;
  final int viewCount;
  final DateTime? lastUpdated;

  MangaDetail({
    required this.id,
    required this.title,
    this.alternateTitles,
    this.description,
    this.coverUrl,
    this.genres = const [],
    this.chapters = const [],
    this.author,
    this.artist,
    this.status = 'Unknown',
    this.rating,
    this.isNsfw = false,
    this.viewCount = 0,
    this.lastUpdated,
  });

  factory MangaDetail.fromJson(Map<String, dynamic> json) {
    // Process chapters
    List<MangaChapter> chaptersList = [];
    if (json['chapters'] != null) {
      chaptersList = (json['chapters'] as List)
          .map((chapter) => MangaChapter.fromJson(chapter))
          .toList();

      // Sort chapters by upload date or number if available
      chaptersList.sort((a, b) {
        if (a.uploadDate != null && b.uploadDate != null) {
          return b.uploadDate!.compareTo(a.uploadDate!); // Newest first
        } else if (a.number != null && b.number != null) {
          // Try to parse as numbers first (if they're actual numbers)
          try {
            final aNum = double.parse(a.number!);
            final bNum = double.parse(b.number!);
            return bNum.compareTo(aNum); // Descending order
          } catch (_) {
            // If parsing fails, compare as strings
            return b.number!.compareTo(a.number!);
          }
        }
        return 0;
      });
    }

    // Process genres
    final genresList =
        json['genres'] != null ? List<String>.from(json['genres']) : <String>[];

    return MangaDetail(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      alternateTitles: json['alternate_titles'],
      description: json['description'],
      coverUrl: json['cover_url'],
      genres: genresList,
      chapters: chaptersList,
      author: json['author'],
      artist: json['artist'],
      status: json['status'] ?? 'Unknown',
      rating:
          json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      isNsfw: json['is_nsfw'] ?? false,
      viewCount: json['view_count'] ?? 0,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'alternate_titles': alternateTitles,
      'description': description,
      'cover_url': coverUrl,
      'genres': genres,
      'chapters': chapters.map((c) => c.toJson()).toList(),
      'author': author,
      'artist': artist,
      'status': status,
      'rating': rating,
      'is_nsfw': isNsfw,
      'view_count': viewCount,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }

  /// Creates a MangaListItem from this MangaDetail
  MangaListItem toListItem() {
    return MangaListItem(
      id: id,
      title: title,
      coverUrl: coverUrl,
      genres: genres,
      rating: rating,
      status: status,
    );
  }
}
