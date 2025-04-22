import 'dart:async';
import 'package:dio/dio.dart';
import 'package:boilerplate/core/network/api_client.dart';
import 'package:boilerplate/utils/logger.dart';
import 'package:boilerplate/data/repository/manga/manga_repository.dart';
import 'package:boilerplate/data/models/manga_model.dart';

class MangaRepositoryImpl implements MangaRepository {
  final ApiClient _apiClient;
  final Logger _logger;

  // ── Cache for getMangaTop ──────────────────────────────────────────────
  Map<String, dynamic>? _topCache;
  DateTime? _topCacheTime;
  static const Duration _topCacheTTL = Duration(minutes: 30);

  // ── In-flight fetch guard ──────────────────────────────────────────────
  Future<Map<String, dynamic>>? _topFetchFuture;

  // ── StreamController untuk event cache ready ───────────────────────────
  final StreamController<Map<String, dynamic>> _topCacheController =
      StreamController.broadcast();

  /// Stream yang bisa didengarkan oleh komponen lain
  @override
  Stream<Map<String, dynamic>> get onTopCacheUpdated =>
      _topCacheController.stream;

  MangaRepositoryImpl({
    required ApiClient apiClient,
    required Logger logger,
  })  : _apiClient = apiClient,
        _logger = logger.withTag('MangaRepository');

  /// Fetches and caches the "/top" endpoint.
  /// Reuses cached data until TTL expires.
  @override
  Future<Map<String, dynamic>> getMangaTop() {
    final now = DateTime.now();

    // 1) Cache masih valid?
    if (_topCache != null &&
        _topCacheTime != null &&
        now.difference(_topCacheTime!) < _topCacheTTL) {
      _logger.debug('Returning cached getMangaTop result');
      // Emit cache event
      _topCacheController.add(_topCache!);
      return Future.value(_topCache!);
    }

    // 2) Jika sudah ada fetch yang berjalan, kembalikan future tersebut
    if (_topFetchFuture != null) {
      _logger
          .debug('getMangaTop already in progress, returning existing future');
      return _topFetchFuture!;
    }

    // 3) Mulai fetch baru
    final completer = Completer<Map<String, dynamic>>();
    _topFetchFuture = completer.future;

    _logger.info('Starting network fetch for getMangaTop');
    _apiClient
        .get<Map<String, dynamic>>('/top?gender=1&accept_mature_content=true')
        .then((response) {
      final data = response.data ?? <String, dynamic>{};
      _topCache = data;
      _topCacheTime = now;
      _logger.info('Fetched and cached getMangaTop result');
      _topCacheController.add(data);
      completer.complete(data);
    }).catchError((e, st) {
      _logger.error('Failed to getMangaTop: $e', exception: e);
      if (!completer.isCompleted) completer.completeError(e, st);
    }).whenComplete(() {
      _topFetchFuture = null;
    });

    return completer.future;
  }

  /// Returns true if the getMangaTop cache is empty or expired.
  @override
  bool isTopCacheEmpty() {
    final now = DateTime.now();
    return _topCache == null ||
        _topCacheTime == null ||
        now.difference(_topCacheTime!) >= _topCacheTTL;
  }

  /// Returns the "topFollowComics" list from cache, or waits for it to load.
  /// 7 (7 days), 30 (1 month), or 90 (3 months).
  @override
  Future<List<Map<String, dynamic>>> getRecentPopularManga({
    required int days,
  }) async {
    if (![7, 30, 90].contains(days)) {
      throw ArgumentError.value(
          days, 'days', 'Must be one of 7, 30, or 90 (days/months).');
    }

    final data = await getMangaTop();
    final newMap = data['topFollowComics'] as Map<String, dynamic>? ?? {};
    final rawList = newMap[days.toString()] as List<dynamic>? ?? [];

    return rawList
        .map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns the list of newly followed comics for a given period:
  /// 7 (7 days), 30 (1 month), or 90 (3 months).
  @override
  Future<List<Map<String, dynamic>>> getFollowedManga({
    required int days,
  }) async {
    if (![7, 30, 90].contains(days)) {
      throw ArgumentError.value(
          days, 'days', 'Must be one of 7, 30, or 90 (days/months).');
    }

    final data = await getMangaTop();
    final newMap = data['TopFollowNewComics'] as Map<String, dynamic>? ?? {};
    final rawList = newMap[days.toString()] as List<dynamic>? ?? [];

    return rawList
        .map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>))
        .toList();
  }

  // ... existing methods (getMangaDetail, getChapterPages, etc.) unchanged ...
  @override
  Future<List<Map<String, dynamic>>> getUpdatesManga({
    required int page,
    String order = 'new',
  }) async {
    try {
      final response = await _apiClient.get<dynamic>(
        '/chapter'
        '?lang=en'
        '&accept_erotic_content=true'
        '&gender=1'
        '&page=$page'
        '&device-memory=8'
        '&order=$order'
        '&tachiyomi=true',
      );

      // The endpoint returns a JSON array at the top level
      final List<dynamic> rawList = response.data as List<dynamic>? ?? [];
      _logger.info(
          'Received ${rawList.length} updates (page: $page, order: $order)');

      return rawList
          .map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _logger.error(
        'Failed to getUpdatesManga (page: $page, order: $order): ${e.message}',
        exception: e,
      );
      return []; // Return empty list instead of throwing
    } catch (e, st) {
      _logger.error(
        'Unexpected error in getUpdatesManga: $e\n$st',
        exception: e,
      );
      return []; // Return empty list instead of throwing
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSearchManga({
    required String query,
    bool titleOnly = true,
  }) async {
    try {
      final response = await _apiClient.get<dynamic>(
        '/v1.0/search',
        queryParameters: {
          'q': query,
          't': titleOnly.toString(),
          'tachiyomi': 'true',
          'lang': 'en',
          'accept_mature_content': 'true',
        },
      );

      // Expecting an array at the top level
      final List<dynamic> raw = response.data as List<dynamic>? ?? [];
      _logger.info('Received ${raw.length} search results for "$query"');

      // Filter entries that include md_covers
      final results = raw.where((e) {
        if (e is Map<String, dynamic>) {
          return e.containsKey('md_covers') &&
              e['md_covers'] is List &&
              (e['md_covers'] as List).isNotEmpty;
        }
        return false;
      }).map<Map<String, dynamic>>((e) {
        return Map<String, dynamic>.from(e as Map<String, dynamic>);
      }).toList();

      _logger.debug('Filtered to ${results.length} entries with md_covers');
      return results;
    } on DioException catch (e) {
      _logger.error(
        'Failed to search manga "$query": ${e.message}',
        exception: e,
      );
      return []; // Return empty list instead of throwing
    } catch (e, st) {
      _logger.error(
        'Unexpected error in getSearchManga: $e\n$st',
        exception: e,
      );
      return []; // Return empty list instead of throwing
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getDetailManga(String slug) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/v1.0/comic/$slug'
        '?tachiyomi=true',
      );

      final Map<String, dynamic> data = response.data ?? {};
      _logger.info('Fetched comic detail for $slug');

      // Return a list with a single item (the comic details)
      return [data];
    } on DioException catch (e) {
      _logger.error(
        'Failed to fetch comic detail for $slug: ${e.message}',
        exception: e,
      );
      return []; // Return empty list instead of throwing
    } catch (e) {
      _logger.error(
        'Unexpected error in getDetailManga($slug): $e',
        exception: e,
      );
      return []; // Return empty list instead of throwing
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getChapterManga(
      String hid, int page) async {
    try {
      // Change response type expectation to Map<String, dynamic>
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/comic/$hid/chapters',
        queryParameters: {'lang': 'en', 'limit': 6000, 'page': page},
      );

      // Extract chapters array from response object
      final Map<String, dynamic> responseData = response.data ?? {};
      final List<dynamic> rawList =
          responseData['chapters'] as List<dynamic>? ?? [];

      _logger.info(
          'Fetched ${rawList.length} chapters for hid=$hid on page $page');

      // Convert each item to a Map<String, dynamic>
      return rawList.map((item) {
        return Map<String, dynamic>.from(item as Map<String, dynamic>);
      }).toList();
    } on DioException catch (e) {
      _logger.error(
        'Failed to fetch chapters for hid=$hid on page $page: ${e.message}',
        exception: e,
      );
      return []; // Return empty list instead of throwing
    } catch (e) {
      _logger.error(
        'Unexpected error in getChapterManga($hid, page=$page): $e',
        exception: e,
      );
      return []; // Return empty list instead of throwing
    }
  }

  @override
  Future<Map<String, dynamic>> getPageChapter(String chapHid) async {
    try {
      // The API might return either a Map or a List, so handle both cases
      final dynamic response = await _apiClient.get(
        '/chapter/$chapHid/get_images',
      );

      // Convert the response to a Map<String, dynamic> regardless of what we get
      Map<String, dynamic> chapterData = {};

      if (response.data is List) {
        // If it's a list, wrap it in a Map with a 'chapter' key
        final List<dynamic> listData = response.data as List;
        if (listData.isNotEmpty && listData.first is Map) {
          // Use the first item as our data if it exists
          chapterData = {'chapter': listData.first};
        } else {
          // Create an empty wrapper if the list is empty
          chapterData = {'chapter': {}, 'images': []};
        }
        _logger.info(
            'Received list response for chapter $chapHid, converted to map');
      } else if (response.data is Map) {
        // If it's a map, use it directly
        chapterData = response.data as Map<String, dynamic>? ?? {};
        _logger.info('Received map response for chapter $chapHid');
      } else {
        // Handle null or other types
        chapterData = {'chapter': {}, 'images': []};
        _logger.warn('Unexpected response type for chapter $chapHid');
      }

      return chapterData;
    } on DioException catch (e) {
      _logger.error(
        'Failed to fetch page chapter $chapHid: ${e.message}',
        exception: e,
      );
      // Return an empty map instead of an empty list
      return {'chapter': {}, 'error': true, 'message': e.message};
    } catch (e, st) {
      _logger.error(
        'Unexpected error in getPageChapter($chapHid): $e\n$st',
        exception: e,
      );
      // Return an empty map instead of an empty list
      return {'chapter': {}, 'error': true, 'message': e.toString()};
    }
  }

  // Stubs for unimplemented methods
  @override
  Future<List<Map<String, dynamic>>> getMangaList({
    required int page,
    String? query,
  }) async {
    // Stub implementation returning empty list
    return [];
  }

  @override
  Future<List<MangaListItem>> getLatestUpdates({
    required int page,
    int limit = 20,
  }) async {
    // Stub implementation returning empty list
    return [];
  }

  @override
  Future<List<MangaListItem>> getPopularManga({
    required int page,
    int limit = 20,
  }) async {
    // Stub implementation returning empty list
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> searchByGenres({
    required List<String> genres,
    required int page,
  }) async {
    // Stub implementation returning empty list
    return [];
  }

  @override
  Future<List<String>> getChapterPages(String mangaId, String chapterId) {
    return Future.value([]);
  }

  @override
  Future<MangaDetail> getMangaDetail(String id) async {
    final List<Map<String, dynamic>> detailList = await getDetailManga(id);
    if (detailList.isEmpty) {
      throw Exception("Failed to load manga detail for ID: $id");
    }
    // Convert map to MangaDetail object
    return MangaDetail.fromJson(detailList.first);
  }
}
