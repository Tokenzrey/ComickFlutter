import 'package:boilerplate/data/models/manga_model.dart';

/// Abstract definition of the Manga Repository
/// Defines methods for interacting with manga data sources,
/// including caching and specialized "top" endpoints.
abstract class MangaRepository {
  /// Fetches a paginated list of manga (search endpoint).
  Future<List<Map<String, dynamic>>> getMangaList({
    required int page,
    String? query,
  });

  /// Fetches detailed information about a specific manga.
  Future<MangaDetail> getMangaDetail(String id);

  /// Fetches the list of page URLs for a specific chapter.
  Future<List<String>> getChapterPages(String mangaId, String chapterId);

  /// Searches manga by genre.
  Future<List<Map<String, dynamic>>> searchByGenres({
    required List<String> genres,
    required int page,
  });

  // ── "Top" endpoint + cache support ────────────────────────────────────

  /// Fetches the "top" manga endpoint, with internal caching.
  /// Reuses cache until TTL expires.
  Future<Map<String, dynamic>> getMangaTop();

  /// Returns true if the `getMangaTop` cache is empty or expired.
  bool isTopCacheEmpty();

  /// Stream that emits whenever the `getMangaTop` cache is updated.
  Stream<Map<String, dynamic>> get onTopCacheUpdated;

  /// Returns the list of most popular comics ("topFollowComics"),
  /// 7 days, 30 days, or 90 days ("TopFollowNewComics").
  Future<List<Map<String, dynamic>>> getRecentPopularManga({
    /// Must be one of 7, 30, or 90
    required int days,
  });

  /// Returns the list of newly followed comics over a period:
  /// 7 days, 30 days, or 90 days ("TopFollowNewComics").
  Future<List<Map<String, dynamic>>> getFollowedManga({
    /// Must be one of 7, 30, or 90
    required int days,
  });

  /// Fetches updated manga chapters from the "chapter" endpoint.
  ///
  /// [page] – page number
  /// [order] – "new" or "hot"
  ///
  /// Returns a list of standardized manga objects.
  Future<List<Map<String, dynamic>>> getUpdatesManga({
    required int page,
    String order = 'new',
  });

  /// Searches manga by title.
  ///
  /// [query] – the search string (e.g. "solo")
  /// [titleOnly] – if true, restrict to exact title matches (t=true)
  ///
  /// Returns a list of result maps, only those with `md_covers` present.
  Future<List<Map<String, dynamic>>> getSearchManga({
    required String query,
    bool titleOnly = true,
  });

  /// Fetches full comic details by slug.
  /// GET https://api.comick.io/v1.0/comic/{slug}
  ///
  /// Returns a list containing the comic detail.
  Future<List<Map<String, dynamic>>> getDetailManga(String slug);

  /// Fetches chapter list for a comic by hid.
  /// GET https://api.comick.io/comic/{hid}/chapters?lang=en
  ///
  /// Returns a list of chapter objects.
  Future<List<Map<String, dynamic>>> getChapterManga(String hid, int page);

  /// Fetches the page data for a specific chapter.
  /// GET https://api.comick.io/chapter/{chapHid}/get_images
  ///
  /// Returns a list of image objects if available, or a list containing the
  /// whole chapter data if no image list is found.
  Future<Map<String, dynamic>> getPageChapter(String chapHid);

  // ── Legacy / other endpoints (optional to implement) ─────────────────

  /// Gets a list of popular manga (legacy), by page.
  Future<List<MangaListItem>> getPopularManga({
    required int page,
    int limit = 20,
  });

  /// Gets the latest updated manga (legacy), by page.
  Future<List<MangaListItem>> getLatestUpdates({
    required int page,
    int limit = 20,
  });
}
