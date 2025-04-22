import 'dart:io';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:boilerplate/utils/logger.dart';

/// A Dio [IOHttpClientAdapter] that bypasses SSL certificate validation
/// only for a specified whitelist of hosts. By default, bypassing occurs
/// in debug mode; in release builds it requires [allowInRelease] = true.
///
/// Usage:
/// ```dart
/// final dio = Dio();
/// dio.httpClientAdapter = SslBypassAdapter(
///   whitelist: ['example.com', 'api.dev.local'],
///   allowInRelease: false, // only bypass in debug
///   logger: Logger(tag: 'Network'),
/// );
/// ```
class SslBypassAdapter extends IOHttpClientAdapter {
  /// Hosts for which SSL errors will be ignored.
  final List<String> whitelist;

  /// If true, will also bypass in release mode. Default `false`.
  final bool allowInRelease;

  /// Logger for reporting bypass events.
  final Logger _logger;

  /// Constructs the adapter.
  ///
  /// [whitelist] is the list of hostnames (without scheme) for which
  /// `badCertificateCallback` will return `true`.
  /// [allowInRelease] controls whether bypass is enabled in release mode.
  /// [logger] is used for debug logging; if omitted, a default with tag
  /// `'SslBypassAdapter'` is created.
  SslBypassAdapter({
    this.whitelist = const [],
    this.allowInRelease = false,
    Logger? logger,
  }) : _logger = logger ?? Logger(tag: 'SslBypassAdapter') {
    // Override Dio's HttpClient creation
    createHttpClient = _createClient;
  }

  HttpClient _createClient() {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30)
      ..idleTimeout = const Duration(seconds: 15);

    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
      final shouldBypass =
          whitelist.contains(host) && (kDebugMode || allowInRelease);

      if (shouldBypass) {
        _logger.warn(
          '🔓 SSL certificate bypassed for host="$host", '
          'validity: ${cert.startValidity} → ${cert.endValidity}',
        );
      }

      return shouldBypass;
    };

    return client;
  }
}
