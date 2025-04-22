import 'package:boilerplate/core/network/cloudflare/ssl_bypass_adapter.dart';
import 'package:boilerplate/di/service_locator.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:boilerplate/utils/logger.dart';
import 'package:boilerplate/core/network/cloudflare/challenge_detector.dart';
import 'package:boilerplate/core/network/cloudflare/cloudflare_interceptor.dart';
import 'package:boilerplate/core/network/cloudflare/proxy_handler.dart';
import 'package:boilerplate/core/network/cloudflare/cookie_manager.dart';
import 'package:boilerplate/core/network/cloudflare/user_agent_factory.dart';
import 'package:boilerplate/core/network/cloudflare/headless_data_fetch.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'doh_provider.dart';
import 'retry_policy.dart';

class ApiClientOptions {
  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Map<String, dynamic>? defaultHeaders;
  final bool enableCloudflareProtection;
  final bool enableDebugLogs;
  final bool enableRetryPolicy;
  final RetryPolicy retryPolicy;
  final bool enableProxySupport;
  final Duration? cloudflareInitialTimeout;
  final Duration? cloudflareInteractiveTimeout;
  final bool enableDnsOverHttps;
  final bool enableSslBypass;
  final DoHProviderType? dohProvider;

  ApiClientOptions({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
    this.defaultHeaders,
    this.enableCloudflareProtection = true,
    this.enableDebugLogs = false,
    this.enableRetryPolicy = true,
    this.retryPolicy = const RetryPolicy(),
    this.enableProxySupport = false,
    this.cloudflareInitialTimeout,
    this.cloudflareInteractiveTimeout,
    this.enableDnsOverHttps = true,
    this.enableSslBypass = false,
    this.dohProvider = DoHProviderType.cloudflare,
  });
}

class ApiClient {
  final Dio _dio;
  final Logger _logger;
  final CloudflareInterceptor? _cloudflareInterceptor;
  final ProxyHandler? _proxyHandler;

  ApiClient._({
    required Dio dio,
    required Logger logger,
    CloudflareInterceptor? cloudflareInterceptor,
    ProxyHandler? proxyHandler,
  })  : _dio = dio,
        _logger = logger,
        _cloudflareInterceptor = cloudflareInterceptor,
        _proxyHandler = proxyHandler;

  static Future<ApiClient> create({
    required ApiClientOptions options,
    required Logger logger,
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    logger.info('Initializing API client with ${options.baseUrl}');

    // Create the cache for DoH and other requests
    final cache = Cache(maxAge: const Duration(hours: 1));

    // Create DoH manager
    final dohManager = DohManager(logger: logger, cache: cache);

    // Get the configured DoH provider based on selected type
    final dohProviderType = options.enableDnsOverHttps
        ? options.dohProvider ?? DoHProviderType.cloudflare
        : DoHProviderType.none;

    // Log the DNS configuration
    logger.info(
        'DNS configuration: ${options.enableDnsOverHttps ? 'DoH enabled' : 'System DNS'}, provider: $dohProviderType');

    // Get the provider from the manager
    final dohProvider = dohManager.getProvider(dohProviderType);

    // Register the DoH manager and provider in GetIt for later access
    if (!getIt.isRegistered<DohManager>()) {
      getIt.registerSingleton<DohManager>(dohManager);
    }

    if (!getIt.isRegistered<DoHProvider>()) {
      getIt.registerSingleton<DoHProvider>(dohProvider);
    }

    // Initialize Dio client
    final dio = Dio(
      BaseOptions(
        baseUrl: options.baseUrl,
        connectTimeout: options.connectTimeout,
        receiveTimeout: options.receiveTimeout,
        headers: options.defaultHeaders ??
            {
              'Accept': 'application/json',
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
            },
      ),
    );

    // Add logging interceptor first (so we log requests before they're modified)
    dio.interceptors.add(LogInterceptor(
      requestBody: options.enableDebugLogs,
      responseBody: options.enableDebugLogs,
      logPrint: (obj) => logger.debug(obj.toString(), domain: 'HTTP'),
    ));

    // Configure HTTP client adapter based on DNS and SSL settings
    if (options.enableDnsOverHttps && dohProviderType != DoHProviderType.none) {
      // Use custom DoH adapter
      dio.httpClientAdapter = DohHttpClientAdapter(
        dohProvider: dohProvider,
        logger: logger,
        allowBadCertificates: options.enableSslBypass,
      );
      logger.debug(
          'DoH HTTP client adapter configured for Dio [$dohProviderType]',
          domain: 'Network');

      // Log bootstrap addresses if available
      if (dohProvider is CloudflareDnsProvider) {
        logger.debug(
            'Cloudflare DoH bootstrap addresses: ${dohProvider.bootstrapAddresses.join(", ")}',
            domain: 'Network');
      } else if (dohProvider is GoogleDnsProvider) {
        logger.debug(
            'Google DoH bootstrap addresses: ${dohProvider.bootstrapAddresses.join(", ")}',
            domain: 'Network');
      } else if (dohProvider is AdguardDnsProvider) {
        logger.debug(
            'Adguard DoH bootstrap addresses: ${dohProvider.bootstrapAddresses.join(", ")}',
            domain: 'Network');
      }
    } else if (options.enableSslBypass) {
      // If only SSL bypass is needed without DoH
      dio.httpClientAdapter = SslBypassAdapter();
      logger.debug('SSL certificate verification disabled', domain: 'Network');
    }

    // Configure Cloudflare protection if enabled
    CloudflareInterceptor? cloudflareInterceptor;
    ProxyHandler? proxyHandler;

    if (options.enableCloudflareProtection) {
      // Create UserAgentFactory
      final userAgentFactory = await UserAgentFactory.create(logger: logger);

      // Create CookieManager
      final cookieManager = StandardCookieManager(logger: logger);
      await cookieManager.loadCookiesFromStorage();

      // Create ChallengeDetector
      final challengeDetector = ChallengeDetector(logger: logger);

      // Create ProxyHandler
      proxyHandler = await ProxyHandler.create(logger);

      // Create HeadlessJsonLoader
      final headlessJsonLoader = HeadlessJsonLoader(
          logger: logger,
          userAgentFactory: userAgentFactory,
          timeout:
              options.cloudflareInitialTimeout ?? const Duration(seconds: 30));

      // Get navigator key
      GlobalKey<NavigatorState> cfNavigatorKey;
      try {
        cfNavigatorKey =
            getIt.get<GlobalKey<NavigatorState>>(instanceName: 'navigatorKey');
      } catch (e) {
        logger.warn('Failed to get navigatorKey from GetIt: $e',
            domain: 'Cloudflare');
        cfNavigatorKey = navigatorKey;
      }

      logger.info('Navigator key for CF solver: ${cfNavigatorKey.hashCode}',
          domain: 'Cloudflare');

      // Create and add Cloudflare interceptor with the new components
      cloudflareInterceptor = CloudflareInterceptor(
        logger: logger,
        cookieManager: cookieManager,
        detector: challengeDetector,
        userAgentFactory: userAgentFactory,
        proxyHandler: proxyHandler,
        headlessSolver: headlessJsonLoader,
        navigatorKey: cfNavigatorKey,
        options: CloudflareInterceptorOptions(
            enableDebug: options.enableDebugLogs,
            retryPolicy: options.retryPolicy,
            headlessTimeout:
                options.cloudflareInitialTimeout ?? const Duration(seconds: 15),
            enableAutomaticSolving: true),
      );

      dio.interceptors.add(cloudflareInterceptor);

      // Apply proxy configuration if enabled
      if (options.enableProxySupport && proxyHandler.isEnabled) {
        proxyHandler.applyTo(dio);
      }
    }

    // Create and return the API client instance
    return ApiClient._(
      dio: dio,
      logger: logger,
      cloudflareInterceptor: cloudflareInterceptor,
      proxyHandler: proxyHandler,
    );
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  // Method to force an interactive Cloudflare challenge
  Future<bool> solveInteractiveChallenge(String url) async {
    if (_cloudflareInterceptor == null) {
      _logger.error('Cannot solve Cloudflare challenge - protection disabled');
      return false;
    }

    try {
      // Create request that will trigger cloudflare challenge
      await _dio.get(url,
          options: Options(extra: {'forceChallengeSolve': true}));
      return true;
    } catch (e) {
      _logger.error('Failed to solve interactive challenge: $e');
      return false;
    }
  }

  // Method to clear all Cloudflare data
  Future<void> clearCloudflareData() async {
    if (_cloudflareInterceptor != null) {
      await _cloudflareInterceptor!.clearAllData();
      _logger.info('Cleared all Cloudflare data');
    }
  }

  // Method to update proxy settings
  Future<void> updateProxySettings(
      {bool enabled = false, ProxyConfig? config}) async {
    if (_proxyHandler != null) {
      if (config != null) {
        await _proxyHandler!.saveConfig(config);
      }

      await _proxyHandler!.setEnabled(enabled);
      _proxyHandler!.applyTo(_dio);

      _logger
          .info('Updated proxy settings: ${enabled ? "enabled" : "disabled"}');
    }
  }

  // Toggle debug mode for Cloudflare
  void setCloudflareDebugMode(bool enabled) {
    if (_cloudflareInterceptor != null) {
      _cloudflareInterceptor!.setDebugMode(enabled);
      _logger
          .info('Cloudflare debug mode: ${enabled ? "enabled" : "disabled"}');
    }
  }

  // Get Cloudflare stats
  Map<String, dynamic> getCloudflareStats() {
    if (_cloudflareInterceptor != null) {
      return _cloudflareInterceptor!.getStats();
    }
    return {'enabled': false};
  }

  // Test Cloudflare connection
  Future<bool> testCloudflareConnection(String url) async {
    if (_cloudflareInterceptor != null) {
      return await _cloudflareInterceptor!.testConnection(url);
    }
    return false;
  }

  // Clear DoH cache
  Future<void> clearDohCache() async {
    try {
      final dohProvider = getIt.get<DoHProvider>();
      dohProvider.clearCache();
      _logger.info('DoH cache cleared', domain: 'Network');
    } catch (e) {
      _logger.error('Failed to clear DoH cache: $e', domain: 'Network');
    }
  }

  /// Gets the current DoH status and cached DNS resolutions
  Future<Map<String, String>> getDohStatus() async {
    try {
      final dohProvider = getIt.get<DoHProvider>();
      final cacheSnapshot = dohProvider.getCacheSnapshot();

      // If cache is empty, perform some test lookups
      if (cacheSnapshot.isEmpty) {
        _logger.debug('DoH cache empty, performing test lookups',
            domain: 'Network');
        final testDomains = ['google.com', 'cloudflare.com', 'api.comick.io'];

        for (final domain in testDomains) {
          final ip = await dohProvider.lookupHost(domain);
          if (ip != null) {
            cacheSnapshot[domain] = ip;
          } else {
            cacheSnapshot[domain] = 'Resolution failed';
          }
        }
      }

      // Add provider type information
      if (dohProvider is CloudflareDnsProvider) {
        cacheSnapshot['_provider'] = 'Cloudflare DoH';
      } else if (dohProvider is GoogleDnsProvider) {
        cacheSnapshot['_provider'] = 'Google DoH';
      } else if (dohProvider is AdguardDnsProvider) {
        cacheSnapshot['_provider'] = 'Adguard DoH';
      } else if (dohProvider is SystemDnsProvider) {
        cacheSnapshot['_provider'] = 'System DNS';
      }

      return cacheSnapshot;
    } catch (e) {
      _logger.error('Error getting DoH status: $e', domain: 'Network');
      return {'status': 'Error: $e'};
    }
  }

  /// Updates the current DoH provider type
  /// Note: Changes will only take effect after app restart
  Future<void> updateDohProvider(DoHProviderType type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('doh_provider_type', type.index);
      _logger.info('DoH provider updated to $type (effective after restart)',
          domain: 'Network');
    } catch (e) {
      _logger.error('Failed to update DoH provider: $e', domain: 'Network');
    }
  }
}
