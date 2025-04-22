import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:boilerplate/utils/logger.dart';

/// DNS over HTTPS (DoH) provider with support for multiple services
class DohManager {
  final Logger _logger;
  final Cache? _cache;

  // Cached DNS provider to avoid recreating it
  DoHProvider? _cachedProvider;
  DoHProviderType? _cachedProviderType;

  DohManager({
    required Logger logger,
    Cache? cache,
  })  : _logger = logger,
        _cache = cache;

  /// Creates or returns a cached DoH provider
  DoHProvider getProvider(dynamic providerType) {
    // Convert string to enum if needed
    DoHProviderType type;
    if (providerType is String) {
      try {
        type = DoHProviderType.values.firstWhere(
          (t) =>
              t.toString().split('.').last.toLowerCase() ==
              providerType.toLowerCase(),
          orElse: () => DoHProviderType.cloudflare, // Default fallback
        );
      } catch (e) {
        _logger.error('Invalid DoH provider type: $providerType, using default',
            domain: 'DoH');
        type = DoHProviderType.cloudflare;
      }
    } else if (providerType is int) {
      // Ensure the index is valid
      type = providerType >= 0 && providerType < DoHProviderType.values.length
          ? DoHProviderType.values[providerType]
          : DoHProviderType.cloudflare;
    } else if (providerType is DoHProviderType) {
      type = providerType;
    } else {
      type = DoHProviderType.cloudflare; // Default fallback
    }

    if (_cachedProvider != null && _cachedProviderType == type) {
      return _cachedProvider!;
    }

    final provider = _createProvider(type);
    _cachedProvider = provider;
    _cachedProviderType = type;
    return provider;
  }

  /// Creates a new DoH provider based on the specified type
  DoHProvider _createProvider(DoHProviderType type) {
    switch (type) {
      case DoHProviderType.none:
        return SystemDnsProvider(_logger);
      case DoHProviderType.cloudflare:
        return CloudflareDnsProvider(
          logger: _logger,
          cache: _cache,
          bootstrapAddresses: [
            '1.1.1.1',
            '1.0.0.1',
            '162.159.36.1',
            '162.159.46.1',
            '162.159.132.53',
            // IPv6 addresses can be added too
          ],
        );
      case DoHProviderType.google:
        return GoogleDnsProvider(
          logger: _logger,
          cache: _cache,
          bootstrapAddresses: [
            '8.8.8.8',
            '8.8.4.4',
            // IPv6 addresses can be added too
          ],
        );
      case DoHProviderType.adguard:
        return AdguardDnsProvider(
          logger: _logger,
          cache: _cache,
          bootstrapAddresses: [
            '94.140.14.140',
            '94.140.14.141',
            // IPv6 addresses can be added too
          ],
        );
    }
  }
}

/// DNS provider types
enum DoHProviderType {
  none, // System DNS
  cloudflare, // Cloudflare DNS
  google, // Google DNS
  adguard, // Adguard DNS unfiltered
}

/// Base class for all DoH providers
abstract class DoHProvider {
  final Logger logger;
  final Map<String, String> dnsCache = {};
  static const int maxCacheSize = 100;
  static const Duration cacheDuration = Duration(hours: 24);

  DoHProvider({required this.logger});

  /// Resolves a hostname to an IP address
  Future<String?> lookupHost(String hostname);

  /// Clears the DNS cache
  void clearCache() {
    dnsCache.clear();
    logger.debug('DoH cache cleared', domain: 'DoH');
  }

  /// Gets a snapshot of the current cache
  Map<String, String> getCacheSnapshot() {
    return Map.from(dnsCache);
  }

  /// Adds an entry to the DNS cache
  void addToCache(String hostname, String ip) {
    // Implement LRU (Least Recently Used) cache behavior
    if (dnsCache.length >= maxCacheSize) {
      final keyToRemove = dnsCache.keys.first;
      dnsCache.remove(keyToRemove);
    }
    dnsCache[hostname] = ip;
  }

  /// Checks if the hostname is in the cache
  String? getCachedHost(String hostname) {
    if (dnsCache.containsKey(hostname)) {
      final ip = dnsCache[hostname];
      logger.debug('Using cached DoH result for $hostname: $ip', domain: 'DoH');
      return ip;
    }
    return null;
  }
}

/// System DNS provider (no DoH)
class SystemDnsProvider extends DoHProvider {
  SystemDnsProvider(Logger logger) : super(logger: logger);

  @override
  Future<String?> lookupHost(String hostname) async {
    try {
      logger.debug('Using system DNS for $hostname', domain: 'DoH');
      final addresses = await InternetAddress.lookup(hostname);
      if (addresses.isNotEmpty) {
        final ip = addresses.first.address;
        addToCache(hostname, ip);
        return ip;
      }
    } catch (e) {
      logger.error('System DNS lookup error for $hostname: $e', domain: 'DoH');
    }
    return null;
  }
}

/// Cloudflare DNS provider
class CloudflareDnsProvider extends DoHProvider {
  final Dio _dio;
  final List<String> bootstrapAddresses;

  static const String _endpoint = 'https://cloudflare-dns.com/dns-query';
  static const String _familyEndpoint =
      'https://family.cloudflare-dns.com/dns-query';
  static const String _securityEndpoint =
      'https://security.cloudflare-dns.com/dns-query';

  CloudflareDnsProvider({
    required super.logger,
    required this.bootstrapAddresses,
    Cache? cache,
    CloudflareDoHProfile profile = CloudflareDoHProfile.standard,
  }) : _dio = Dio(BaseOptions(
          baseUrl: _getEndpoint(profile),
          headers: {
            'accept': 'application/dns-json',
          },
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        )) {
    // Configure cache if provided
    if (cache != null) {
      _dio.interceptors.add(cache);
    }
  }

  static String _getEndpoint(CloudflareDoHProfile profile) {
    switch (profile) {
      case CloudflareDoHProfile.family:
        return _familyEndpoint;
      case CloudflareDoHProfile.security:
        return _securityEndpoint;
      case CloudflareDoHProfile.standard:
        return _endpoint;
    }
  }

  @override
  Future<String?> lookupHost(String hostname) async {
    // Check cache first
    final cachedIp = getCachedHost(hostname);
    if (cachedIp != null) return cachedIp;

    try {
      // Make DoH request using JSON format
      final response = await _dio.get('', queryParameters: {
        'name': hostname,
        'type': 'A',
      });

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['Answer'] != null && (data['Answer'] as List).isNotEmpty) {
          final firstAnswer = data['Answer'][0];
          if (firstAnswer['type'] == 1) {
            // Type 1 = A record
            final ip = firstAnswer['data'];
            logger.debug('Cloudflare DoH resolved $hostname to $ip',
                domain: 'DoH');

            // Cache result
            addToCache(hostname, ip);
            return ip;
          }
        }
      }

      logger.warn(
        'Failed to resolve $hostname using Cloudflare DoH, falling back to system DNS',
        domain: 'DoH',
      );

      // Fallback to system DNS
      return await _fallbackToSystemDns(hostname);
    } catch (e) {
      logger.error('Cloudflare DoH lookup error for $hostname: $e',
          domain: 'DoH');
      return await _fallbackToSystemDns(hostname);
    }
  }

  Future<String?> _fallbackToSystemDns(String hostname) async {
    try {
      final addresses = await InternetAddress.lookup(hostname);
      if (addresses.isNotEmpty) {
        final ip = addresses.first.address;
        addToCache(hostname, ip);
        return ip;
      }
    } catch (e) {
      logger.error('System DNS lookup error for $hostname: $e', domain: 'DoH');
    }
    return null;
  }

  /// Alternative method to resolve using DNS wireformat (POST method)
  /// For advanced use cases
  Future<String?> lookupHostWireformat(String hostname) async {
    // Implementation would use POST method with application/dns-message
    // This is more complex and requires DNS message encoding
    throw UnimplementedError('Wire format not implemented yet');
  }
}

/// Google DNS provider
class GoogleDnsProvider extends DoHProvider {
  final Dio _dio;
  final List<String> bootstrapAddresses;

  static const String _endpoint = 'https://dns.google/dns-query';

  GoogleDnsProvider({
    required super.logger,
    required this.bootstrapAddresses,
    Cache? cache,
  }) : _dio = Dio(BaseOptions(
          baseUrl: _endpoint,
          headers: {
            'accept': 'application/dns-json',
          },
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        )) {
    // Configure cache if provided
    if (cache != null) {
      _dio.interceptors.add(cache);
    }
  }

  @override
  Future<String?> lookupHost(String hostname) async {
    // Check cache first
    final cachedIp = getCachedHost(hostname);
    if (cachedIp != null) return cachedIp;

    try {
      final response = await _dio.get('', queryParameters: {
        'name': hostname,
        'type': 'A',
      });

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['Answer'] != null && (data['Answer'] as List).isNotEmpty) {
          final firstAnswer = data['Answer'][0];
          if (firstAnswer['type'] == 1) {
            // Type 1 = A record
            final ip = firstAnswer['data'];
            logger.debug('Google DoH resolved $hostname to $ip', domain: 'DoH');

            // Cache result
            addToCache(hostname, ip);
            return ip;
          }
        }
      }

      logger.warn(
        'Failed to resolve $hostname using Google DoH, falling back to system DNS',
        domain: 'DoH',
      );

      // Fallback to system DNS
      return await _fallbackToSystemDns(hostname);
    } catch (e) {
      logger.error('Google DoH lookup error for $hostname: $e', domain: 'DoH');
      return await _fallbackToSystemDns(hostname);
    }
  }

  Future<String?> _fallbackToSystemDns(String hostname) async {
    try {
      final addresses = await InternetAddress.lookup(hostname);
      if (addresses.isNotEmpty) {
        final ip = addresses.first.address;
        addToCache(hostname, ip);
        return ip;
      }
    } catch (e) {
      logger.error('System DNS lookup error for $hostname: $e', domain: 'DoH');
    }
    return null;
  }
}

/// Adguard DNS provider
class AdguardDnsProvider extends DoHProvider {
  final Dio _dio;
  final List<String> bootstrapAddresses;

  static const String _endpoint =
      'https://dns-unfiltered.adguard.com/dns-query';

  AdguardDnsProvider({
    required super.logger,
    required this.bootstrapAddresses,
    Cache? cache,
  }) : _dio = Dio(BaseOptions(
          baseUrl: _endpoint,
          headers: {
            'accept': 'application/dns-json',
          },
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        )) {
    // Configure cache if provided
    if (cache != null) {
      _dio.interceptors.add(cache);
    }
  }

  @override
  Future<String?> lookupHost(String hostname) async {
    // Check cache first
    final cachedIp = getCachedHost(hostname);
    if (cachedIp != null) return cachedIp;

    try {
      final response = await _dio.get('', queryParameters: {
        'name': hostname,
        'type': 'A',
      });

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['Answer'] != null && (data['Answer'] as List).isNotEmpty) {
          final firstAnswer = data['Answer'][0];
          if (firstAnswer['type'] == 1) {
            // Type 1 = A record
            final ip = firstAnswer['data'];
            logger.debug('Adguard DoH resolved $hostname to $ip',
                domain: 'DoH');

            // Cache result
            addToCache(hostname, ip);
            return ip;
          }
        }
      }

      logger.warn(
        'Failed to resolve $hostname using Adguard DoH, falling back to system DNS',
        domain: 'DoH',
      );

      // Fallback to system DNS
      return await _fallbackToSystemDns(hostname);
    } catch (e) {
      logger.error('Adguard DoH lookup error for $hostname: $e', domain: 'DoH');
      return await _fallbackToSystemDns(hostname);
    }
  }

  Future<String?> _fallbackToSystemDns(String hostname) async {
    try {
      final addresses = await InternetAddress.lookup(hostname);
      if (addresses.isNotEmpty) {
        final ip = addresses.first.address;
        addToCache(hostname, ip);
        return ip;
      }
    } catch (e) {
      logger.error('System DNS lookup error for $hostname: $e', domain: 'DoH');
    }
    return null;
  }
}

/// Cloudflare DoH profiles
enum CloudflareDoHProfile {
  standard, // No filtering
  family, // Blocks adult content
  security, // Blocks malware and phishing domains
}

/// HttpClientAdapter with DoH support for Dio
class DohHttpClientAdapter extends IOHttpClientAdapter {
  final DoHProvider dohProvider;
  final Logger logger;
  final bool allowBadCertificates;

  DohHttpClientAdapter({
    required this.dohProvider,
    required this.logger,
    this.allowBadCertificates = false,
  }) {
    createHttpClient = () {
      final client = HttpClient();

      // Configure SSL verification
      if (allowBadCertificates) {
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        logger.debug('SSL certificate verification disabled', domain: 'DoH');
      }

      // Set direct connection (no proxy)
      client.findProxy = (uri) => 'DIRECT';

      return client;
    };
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    try {
      final uri = options.uri;
      final host = uri.host;

      // Try DoH resolution first
      final resolvedIp = await dohProvider.lookupHost(host);

      if (resolvedIp != null) {
        logger.debug('Using DoH-resolved IP $resolvedIp for $host',
            domain: 'DoH');

        // Create a new URI with the resolved IP, keeping all other parts the same
        final resolvedUri = Uri(
          scheme: uri.scheme,
          host: resolvedIp,
          port: uri.port,
          path: uri.path,
          query: uri.query,
          fragment: uri.fragment,
          userInfo: uri.userInfo,
        );

        // Clone options with the new URI
        final newOptions = options.copyWith(
          path: null, // Set to null since we're providing the full URI
          data: resolvedUri,
          headers: {
            ...options.headers,
            'Host': host, // Keep original host header
          },
        );

        // Forward to super with the resolved IP
        return super.fetch(newOptions, requestStream, cancelFuture);
      }
    } catch (e) {
      logger.error('Error in DoH resolution: $e', domain: 'DoH');
      // Continue with original request on error
    }

    // Fallback to regular DNS resolution
    return super.fetch(options, requestStream, cancelFuture);
  }
}

/// Cache implementation for Dio
class Cache extends Interceptor {
  final Map<String, dynamic> _cache = {};
  final Duration maxAge;

  Cache({this.maxAge = const Duration(hours: 1)});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final key = options.uri.toString();
    final cachedResponse = _cache[key];
    if (cachedResponse != null) {
      final timestamp = cachedResponse['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - timestamp < maxAge.inMilliseconds) {
        // Cache is still valid
        return handler.resolve(
          Response(
            requestOptions: options,
            data: cachedResponse['data'],
            statusCode: cachedResponse['statusCode'],
            headers: Headers.fromMap(cachedResponse['headers']),
          ),
        );
      }
    }
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final key = response.requestOptions.uri.toString();
    _cache[key] = {
      'data': response.data,
      'statusCode': response.statusCode,
      'headers': response.headers.map,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    return super.onResponse(response, handler);
  }

  void clear() {
    _cache.clear();
  }
}
