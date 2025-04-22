import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:boilerplate/utils/logger.dart';

/// Generates and persists User‑Agent strings per domain, with sensible defaults
/// and platform‑specific fallbacks.
class UserAgentFactory {
  static const _prefsKey = 'cloudflare_user_agents';

  final Logger _logger;
  final Random _random;
  final DeviceInfoPlugin _deviceInfo;
  final SharedPreferences _prefs;

  final List<String> _desktopUAs;
  final List<String> _mobileUAs;

  // In‑memory cache of saved agents
  final Map<String, String> _savedAgents = {};

  UserAgentFactory._({
    required Logger logger,
    required SharedPreferences prefs,
    Random? random,
    DeviceInfoPlugin? deviceInfo,
    List<String>? desktopUAs,
    List<String>? mobileUAs,
  })  : _logger = logger,
        _prefs = prefs,
        _random = random ?? Random.secure(),
        _deviceInfo = deviceInfo ?? DeviceInfoPlugin(),
        _desktopUAs = desktopUAs ?? _defaultDesktopUAs,
        _mobileUAs = mobileUAs ?? _defaultMobileUAs {
    _loadSavedAgents();
  }

  /// Async factory to initialize with SharedPreferences loaded.
  static Future<UserAgentFactory> create({required Logger logger}) async {
    final prefs = await SharedPreferences.getInstance();
    return UserAgentFactory._(logger: logger, prefs: prefs);
  }

  // Default lists of UAs
  static const List<String> _defaultDesktopUAs = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 '
        '(KHTML, like Gecko) Version/17.0 Safari/605.1.15',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) '
        'Gecko/20100101 Firefox/119.0',
  ];

  static const List<String> _defaultMobileUAs = [
    'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0_3 like Mac OS X) '
        'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 '
        'Mobile/15E148 Safari/604.1',
    'Mozilla/5.0 (Linux; Android 14; Pixel 7) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
    'Mozilla/5.0 (Linux; Android 13; SM-S918B) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
  ];

  void _loadSavedAgents() {
    final raw = _prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final Map<String, dynamic> map = jsonDecode(raw);
      map.forEach((domain, ua) {
        if (ua is String) _savedAgents[domain] = ua;
      });
      _logger.debug(
        'Loaded ${_savedAgents.length} saved user agents',
        domain: 'Cloudflare',
      );
    } catch (e, st) {
      _logger.error('Failed to decode saved UAs: $e\n$st',
          domain: 'Cloudflare');
    }
  }

  /// Returns a random UA. If [mobile] is true, picks from mobile list.
  String getRandom({bool mobile = false}) {
    final list = mobile ? _mobileUAs : _desktopUAs;
    return list[_random.nextInt(list.length)];
  }

  /// Returns a UA tailored to the current platform (iOS/Android).
  /// Falls back to a random UA if device info lookup fails.
  Future<String> getPlatformSpecific() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final info = await _deviceInfo.iosInfo;
        return 'Mozilla/5.0 (iPhone; CPU iPhone OS '
            '${info.systemVersion.replaceAll('.', '_')} like Mac OS X) '
            'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 '
            'Mobile/15E148 Safari/604.1';
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        final info = await _deviceInfo.androidInfo;
        return 'Mozilla/5.0 (Linux; Android ${info.version.release}; '
            '${info.model}) AppleWebKit/537.36 (KHTML, like Gecko) '
            'Chrome/119.0.0.0 Mobile Safari/537.36';
      }
    } catch (e, st) {
      _logger.warn('Platform UA lookup failed: $e\n$st', domain: 'Cloudflare');
    }
    // Fallback
    return getRandom(
      mobile: defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android,
    );
  }

  /// Returns the previously saved UA for [domain], or null if none.
  String? getLastSuccessful(String domain) => _savedAgents[domain];

  /// Saves [userAgent] for [domain], persisting it.
  Future<void> saveSuccessful(String domain, String userAgent) async {
    _savedAgents[domain] = userAgent;
    try {
      await _prefs.setString(_prefsKey, jsonEncode(_savedAgents));
      _logger.debug('Saved UA for $domain: $userAgent', domain: 'Cloudflare');
    } catch (e, st) {
      _logger.error('Failed saving UA for $domain: $e\n$st',
          domain: 'Cloudflare');
    }
  }

  /// Resets the saved UA for [domain].
  Future<void> reset(String domain) async {
    _savedAgents.remove(domain);
    await _prefs.setString(_prefsKey, jsonEncode(_savedAgents));
    _logger.debug('Reset UA for $domain', domain: 'Cloudflare');
  }

  /// Clears all saved user agents.
  Future<void> clearAll() async {
    _savedAgents.clear();
    await _prefs.remove(_prefsKey);
    _logger.debug('Cleared all saved UAs', domain: 'Cloudflare');
  }
}
