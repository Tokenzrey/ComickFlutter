import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:boilerplate/utils/logger.dart';

/// Defines proxy settings including optional authentication.
class ProxyConfig {
  final String scheme; // "http", "https", "socks5", etc.
  final String host;
  final int port;
  final String? username;
  final String? password;

  const ProxyConfig({
    this.scheme = 'http',
    required this.host,
    required this.port,
    this.username,
    this.password,
  });

  /// Returns the full proxy URI (including credentials if present).
  String get proxyUri {
    final creds = (username != null && password != null)
        ? '${Uri.encodeComponent(username!)}:${Uri.encodeComponent(password!)}@'
        : '';
    return '$scheme://$creds$host:$port';
  }

  Map<String, dynamic> toJson() => {
        'scheme': scheme,
        'host': host,
        'port': port,
        'username': username,
        'password': password,
      };

  factory ProxyConfig.fromJson(Map<String, dynamic> json) {
    return ProxyConfig(
      scheme: json['scheme'] as String? ?? 'http',
      host: json['host'] as String,
      port: json['port'] as int,
      username: json['username'] as String?,
      password: json['password'] as String?,
    );
  }
}

/// Manages applying proxy settings to Dio and persistence in SharedPreferences.
class ProxyHandler {
  static const _prefsKeyConfig = 'cf_proxy_config';
  static const _prefsKeyEnabled = 'cf_proxy_enabled';

  final Logger _logger;
  final SharedPreferences _prefs;
  ProxyConfig? _configCache;
  bool? _enabledCache;

  ProxyHandler._(this._logger, this._prefs);

  /// Factory to create and initialize the handler.
  static Future<ProxyHandler> create(Logger logger) async {
    final prefs = await SharedPreferences.getInstance();
    final handler = ProxyHandler._(logger, prefs);
    handler._loadCache();
    return handler;
  }

  void _loadCache() {
    _enabledCache = _prefs.getBool(_prefsKeyEnabled) ?? false;
    final jsonStr = _prefs.getString(_prefsKeyConfig);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        _configCache =
            ProxyConfig.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
        _logger.debug('Loaded proxy config: ${_configCache!.proxyUri}',
            domain: 'Proxy');
      } catch (e) {
        _logger.error('Failed to parse proxy config: $e', domain: 'Proxy');
      }
    }
  }

  /// Returns true if proxying is enabled.
  bool get isEnabled => _enabledCache == true;

  /// Returns currently stored proxy configuration, or null.
  ProxyConfig? get config => _configCache;

  /// Enable or disable proxy usage.
  Future<void> setEnabled(bool enabled) async {
    await _prefs.setBool(_prefsKeyEnabled, enabled);
    _enabledCache = enabled;
    _logger.info('Proxy ${enabled ? 'enabled' : 'disabled'}', domain: 'Proxy');
  }

  /// Save or update the proxy configuration.
  Future<void> saveConfig(ProxyConfig config) async {
    final jsonStr = jsonEncode(config.toJson());
    await _prefs.setString(_prefsKeyConfig, jsonStr);
    _configCache = config;
    _logger.info('Proxy config saved: ${config.proxyUri}', domain: 'Proxy');
  }

  /// Clear both proxy enable flag and configuration.
  Future<void> clear() async {
    await _prefs.remove(_prefsKeyEnabled);
    await _prefs.remove(_prefsKeyConfig);
    _enabledCache = false;
    _configCache = null;
    _logger.info('Proxy configuration cleared', domain: 'Proxy');
  }

  /// Applies the proxy settings to the given Dio instance.
  /// Returns true if a proxy was applied, false if bypassed.
  bool applyTo(Dio dio) {
    if (!isEnabled || config == null) {
      _logger.debug('Proxy not applied (enabled=$isEnabled, config=$config)',
          domain: 'Proxy');
      dio.httpClientAdapter = IOHttpClientAdapter();
      return false;
    }

    final cfg = config!;
    _logger.info('Applying proxy ${cfg.proxyUri} to Dio', domain: 'Proxy');

    final adapter = IOHttpClientAdapter();
    adapter.createHttpClient = () {
      final client = HttpClient();
      client.findProxy = (uri) => 'PROXY ${cfg.host}:${cfg.port}';
      if (cfg.username != null && cfg.password != null) {
        client.addCredentials(
          Uri(host: cfg.host, port: cfg.port),
          '', // realm
          HttpClientBasicCredentials(cfg.username!, cfg.password!),
        );
      }
      // Do NOT bypass SSL here—assume SSL bypass handled elsewhere if needed.
      client.badCertificateCallback = (cert, host, port) => false;
      return client;
    };

    dio.httpClientAdapter = adapter;
    return true;
  }
}
