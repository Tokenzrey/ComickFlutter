import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:boilerplate/utils/logger.dart';

/// Represents a single cookie value with optional expiry.
class CookieEntry {
  final String value;
  final DateTime? expiry;

  CookieEntry({required this.value, this.expiry});

  Map<String, dynamic> toJson() => {
        'value': value,
        'expiry': expiry?.toUtc().toIso8601String(),
      };

  factory CookieEntry.fromJson(Map<String, dynamic> json) => CookieEntry(
        value: json['value'] as String,
        expiry: json['expiry'] != null
            ? DateTime.parse(json['expiry'] as String).toLocal()
            : null,
      );

  bool get isExpired => expiry != null && DateTime.now().isAfter(expiry!);
}

/// Base class for cookie management
abstract class CookieManager {
  Future<void> loadCookiesFromStorage();
  void setCookie(String url, String cookieStr);
  void deleteCookie(String url, String cookieName);
  String getCookiesForUrl(String url);
  void parseCookiesFromHeaders(Map<String, List<String>> headers, String url);
  void parseCookiesFromString(String cookiesStr, String url);
  void clearAllCookies();
  void clearDomainCookies(String domain);
}

/// Standard implementation of the CookieManager
class StandardCookieManager implements CookieManager {
  final Logger logger;
  static const String _prefsKey = 'cf_cookies';

  // domain -> cookieName -> CookieEntry
  final Map<String, Map<String, CookieEntry>> _cookies = {};

  StandardCookieManager({required this.logger});

  @override
  Future<void> loadCookiesFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefsKey);
      if (jsonStr == null || jsonStr.isEmpty) return;

      final Map<String, dynamic> data = json.decode(jsonStr);
      data.forEach((domain, map) {
        final domainMap = <String, CookieEntry>{};
        (map as Map<String, dynamic>).forEach((name, entryData) {
          domainMap[name] =
              CookieEntry.fromJson(entryData as Map<String, dynamic>);
        });
        _cookies[domain] = domainMap;
      });

      logger.debug(
        'Loaded cookies from storage for domains: ${_cookies.keys.toList()}',
        domain: 'Cookie',
      );
    } catch (e) {
      logger.error('Failed to load cookies from storage: $e', domain: 'Cookie');
    }
  }

  @override
  void setCookie(String url, String cookieStr) {
    final domain = _extractDomain(url);
    if (domain.isEmpty) return;

    final set = StandardCookieManager.parseSetCookieHeaders([cookieStr]);
    final expiry = StandardCookieManager.parseExpiryDate(cookieStr);

    if (set.isEmpty) return;
    _cookies.putIfAbsent(domain, () => {});

    set.forEach((name, value) {
      _cookies[domain]![name] = CookieEntry(value: value, expiry: expiry);
      logger.debug(
        'Set cookie [$name=$value] for $domain '
        '${expiry != null ? "(expires: $expiry)" : ""}',
        domain: 'Cookie',
      );
    });

    _saveCookiesToStorage();
  }

  @override
  void deleteCookie(String url, String cookieName) {
    final domain = _extractDomain(url);
    if (domain.isEmpty) return;

    final domainMap = _cookies[domain];
    if (domainMap != null && domainMap.remove(cookieName) != null) {
      logger.debug('Deleted cookie $cookieName for domain $domain',
          domain: 'Cookie');
      _saveCookiesToStorage();
    }
  }

  @override
  String getCookiesForUrl(String url) {
    final domain = _extractDomain(url);
    if (domain.isEmpty) return '';

    final List<String> pairs = [];

    // Exact domain cookies
    _cookies[domain]?.forEach((name, entry) {
      if (!entry.isExpired) pairs.add('$name=${entry.value}');
    });

    // Parent domain cookies (.example.com)
    _cookies.forEach((cookieDomain, domainMap) {
      if (cookieDomain.startsWith('.') &&
          domain.endsWith(cookieDomain.substring(1))) {
        domainMap.forEach((name, entry) {
          if (!entry.isExpired) pairs.add('$name=${entry.value}');
        });
      }
    });

    return pairs.join('; ');
  }

  @override
  void parseCookiesFromHeaders(Map<String, List<String>> headers, String url) {
    final setCookieHeaders = headers['set-cookie'] ?? [];
    for (final header in setCookieHeaders) {
      setCookie(url, header);
    }
  }

  @override
  void parseCookiesFromString(String cookiesStr, String url) {
    final parsed = StandardCookieManager.parseCookiesString(cookiesStr);
    final domain = _extractDomain(url);
    if (domain.isEmpty) return;

    _cookies.putIfAbsent(domain, () => {});
    parsed.forEach((name, value) {
      _cookies[domain]![name] = CookieEntry(value: value);
      logger.debug('Parsed cookie [$name=$value] from string for $domain',
          domain: 'Cookie');
    });
    _saveCookiesToStorage();
  }

  @override
  void clearAllCookies() {
    _cookies.clear();
    _saveCookiesToStorage();
    logger.debug('All cookies cleared', domain: 'Cookie');
  }

  @override
  void clearDomainCookies(String domain) {
    if (_cookies.remove(domain) != null) {
      _saveCookiesToStorage();
      logger.debug('Cookies cleared for domain $domain', domain: 'Cookie');
    }
  }

  //───────────────────────────────────────────────────
  // Helpers & Parsers
  //───────────────────────────────────────────────────

  static Map<String, String> parseCookiesString(String cookiesString) {
    if (cookiesString.isEmpty || cookiesString == 'null') return {};

    final processed =
        cookiesString.replaceAll('"', '').replaceAll("'", '').trim();
    final parts = processed.split(RegExp(r';\s*'));
    final result = <String, String>{};

    for (final part in parts) {
      final kv = part.split('=');
      if (kv.length >= 2) {
        result[kv[0]] = kv.sublist(1).join('=');
      }
    }
    return result;
  }

  static Map<String, String> parseSetCookieHeaders(List<String> headers) {
    final result = <String, String>{};
    for (final header in headers) {
      final parts = header.split(';');
      if (parts.isEmpty) continue;

      final kv = parts[0].trim().split('=');
      if (kv.length >= 2) {
        result[kv[0]] = kv.sublist(1).join('=');
      }
    }
    return result;
  }

  static DateTime? parseExpiryDate(String headerValue) {
    try {
      final parts = headerValue.split(';');
      for (var part in parts) {
        part = part.trim();
        if (part.toLowerCase().startsWith('expires=')) {
          final dateStr = part.substring(8);
          // HttpDate.parse handles RFC1123 dates
          return HttpDate.parse(dateStr).toLocal();
        }
      }
    } catch (_) {
      // ignore parse errors
    }
    return null;
  }

  Future<void> _saveCookiesToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = <String, dynamic>{};

      _cookies.forEach((domain, map) {
        final domainMap = <String, dynamic>{};
        map.forEach((name, entry) {
          domainMap[name] = entry.toJson();
        });
        data[domain] = domainMap;
      });

      await prefs.setString(_prefsKey, json.encode(data));
    } catch (e) {
      logger.error('Failed to save cookies to storage: $e', domain: 'Cookie');
    }
  }

  String _extractDomain(String url) {
    try {
      return Uri.parse(url).host;
    } catch (e) {
      logger.error('Invalid URL for cookie domain extraction: $url',
          domain: 'Cookie');
      return '';
    }
  }
}

/// Secure implementation that logs when Cloudflare clearance cookies are set
class SecureCookieManager extends StandardCookieManager {
  SecureCookieManager({required super.logger});

  @override
  void setCookie(String url, String cookieStr) {
    if (cookieStr.contains('cf_clearance')) {
      logger.info('Storing Cloudflare clearance cookie for $url',
          domain: 'Cookie');
    }
    super.setCookie(url, cookieStr);
  }
}
