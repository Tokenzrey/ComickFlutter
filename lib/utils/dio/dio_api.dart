// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

/// Model respon API (sesuaikan dengan struktur JSON sebenarnya)
class Root {
  final List<dynamic> rank;
  final List<dynamic> recentRank;

  Root({required this.rank, required this.recentRank});

  factory Root.fromJson(Map<String, dynamic> json) {
    return Root(
      rank: json['rank'] ?? [],
      recentRank: json['recentRank'] ?? [],
    );
  }
}

class ApiService {
  final Dio _dio;
  final int maxRetries;
  late CookieJar cookieJar;
  bool _isInitialized = false;

  ApiService._({required this.maxRetries, required Dio dio}) : _dio = dio;

  static Future<ApiService> create({int maxRetries = 3}) async {
    // Create initial Dio instance
    final dio = Dio();

    // Create the API service
    final service = ApiService._(maxRetries: maxRetries, dio: dio);

    // Initialize cookies and other setup
    await service._initialize();

    return service;
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;

    // Setup persistent cookie storage
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String appDocPath = appDocDir.path;
    cookieJar = PersistCookieJar(storage: FileStorage("$appDocPath/.cookies/"));

    // Add cookie manager to Dio
    _dio.interceptors.add(CookieManager(cookieJar));

    // Configure Dio options
    _dio.options = BaseOptions(
      baseUrl: 'https://api.comick.io',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      followRedirects: true,
      headers: {
        "Accept": "application/json, text/plain, */*",
        "Accept-Language": "en-US,en;q=0.9",
        "Connection": "keep-alive",
        "Origin": "https://comick.io",
        "Referer": "https://comick.io/",
        "Sec-Fetch-Dest": "empty",
        "Sec-Fetch-Mode": "cors",
        "Sec-Fetch-Site": "same-site",
        "User-Agent":
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36",
        "sec-ch-ua":
            "\"Google Chrome\";v=\"135\", \"Not-A.Brand\";v=\"8\", \"Chromium\";v=\"135\"",
        "sec-ch-ua-mobile": "?0",
        "sec-ch-ua-platform": "\"Windows\"",
      },
      validateStatus: (status) => status != null && status < 500,
    );

    // Add a request interceptor to handle Cloudflare challenges
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add timestamp to avoid cache issues
        options.queryParameters['_t'] = DateTime.now().millisecondsSinceEpoch;
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // Check if we got a Cloudflare challenge
        if (response.statusCode == 403 &&
            response.data is String &&
            (response.data as String).contains('Just a moment')) {
          // Return a special error that our retry logic will handle
          return handler.reject(DioException(
            requestOptions: response.requestOptions,
            error: 'Cloudflare challenge detected',
            response: response,
            type: DioExceptionType.badResponse,
          ));
        }
        return handler.next(response);
      },
    ));

    // Add logging interceptor
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      logPrint: (obj) => print(obj),
    ));

    _isInitialized = true;
  }

  /// Fungsi retry untuk mencoba ulang request dengan exponential backoff
  Future<T> _retry<T>(Future<T> Function() request) async {
    int retryCount = 0;
    while (true) {
      try {
        return await request();
      } catch (e) {
        final isDioError = e is DioException;
        final isCloudflareChallengeError = isDioError &&
            e.error is String &&
            (e.error as String).contains('Cloudflare challenge');

        retryCount++;
        if (retryCount >= maxRetries) {
          rethrow;
        }

        // Use longer delay for Cloudflare challenges
        final delay = isCloudflareChallengeError
            ? Duration(seconds: 5 * retryCount)
            : Duration(seconds: 2 * retryCount);

        if (isCloudflareChallengeError) {
          print(
              '🔄 Cloudflare challenge detected, waiting longer before retry attempt $retryCount');

          // For Cloudflare challenges, we should perform the initial setup visit
          await _visitMainSite();
        } else {
          print(
              '🔄 Request failed, retrying in ${delay.inSeconds}s (attempt $retryCount)');
        }

        await Future.delayed(delay);
      }
    }
  }

  /// Visit the main website to get initial cookies and pass Cloudflare
  Future<void> _visitMainSite() async {
    try {
      // Create a separate Dio instance for this to avoid cookie interference
      final mainSiteDio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        followRedirects: true,
        headers: {
          "Accept":
              "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
          "Accept-Language": "en-US,en;q=0.9",
          "Cache-Control": "no-cache",
          "Connection": "keep-alive",
          "Pragma": "no-cache",
          "Sec-Fetch-Dest": "document",
          "Sec-Fetch-Mode": "navigate",
          "Sec-Fetch-Site": "none",
          "Sec-Fetch-User": "?1",
          "Upgrade-Insecure-Requests": "1",
          "User-Agent":
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36",
          "sec-ch-ua":
              "\"Google Chrome\";v=\"135\", \"Not-A.Brand\";v=\"8\", \"Chromium\";v=\"135\"",
          "sec-ch-ua-mobile": "?0",
          "sec-ch-ua-platform": "\"Windows\"",
        },
      ));

      mainSiteDio.interceptors.add(CookieManager(cookieJar));

      // Visit the main site to get cookies
      final response = await mainSiteDio.get('https://comick.io/');
      print('🌐 Visited main site: ${response.statusCode}');

      // Visit the API site directly to get any API-specific cookies
      final apiResponse = await mainSiteDio.get('https://api.comick.io/');
      print('🌐 Visited API site: ${apiResponse.statusCode}');
    } catch (e) {
      print('⚠️ Error visiting main site: $e');
    }
  }

  /// Mengambil data top comics dengan GET request.
  Future<Root> fetchTopComics({
    int gender = 1,
    bool acceptMatureContent = true,
  }) async {
    // Ensure we're initialized
    if (!_isInitialized) await _initialize();

    final String endpoint = '/top';
    final queryParams = {
      'gender': gender,
      'accept_mature_content': acceptMatureContent,
    };

    return await _retry(() async {
      final Response response = await _dio.get(
        endpoint,
        queryParameters: queryParams,
        options: Options(
            // Add additional headers that are often checked
            headers: {
              "X-Requested-With": "XMLHttpRequest",
            }),
      );

      // Handle successful response
      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          return Root.fromJson(response.data);
        } else {
          throw Exception('Unexpected response format: ${response.data}');
        }
      } else {
        throw Exception(
            'Request failed: ${response.statusCode} ${response.statusMessage}');
      }
    });
  }
}
