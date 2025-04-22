import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class Logger {
  final String _tag;
  final LogLevel _minLevel;
  final bool _enableCloudflareDebug;

  Logger({
    String tag = 'App',
    LogLevel minLevel = LogLevel.debug,
    bool enableCloudflareDebug = false,
  })  : _tag = tag,
        _minLevel = minLevel,
        _enableCloudflareDebug = enableCloudflareDebug;

  void debug(String message, {String? domain}) {
    _log(LogLevel.debug, message, domain: domain);
  }

  void info(String message, {String? domain}) {
    _log(LogLevel.info, message, domain: domain);
  }

  void warn(String message, {String? domain}) {
    _log(LogLevel.warning, message, domain: domain);
  }

  void error(String message,
      {String? domain, Object? exception, StackTrace? stackTrace}) {
    _log(LogLevel.error, message,
        domain: domain, exception: exception, stackTrace: stackTrace);
  }

  void _log(LogLevel level, String message,
      {String? domain, Object? exception, StackTrace? stackTrace}) {
    if (level.index < _minLevel.index) return;

    if (!_enableCloudflareDebug &&
        domain == 'Cloudflare' &&
        level == LogLevel.debug) {
      return;
    }

    final prefix = domain != null ? '[$_tag][$domain]' : '[$_tag]';
    final logMessage = '$prefix ${_levelPrefix(level)} $message';

    if (kDebugMode) {
      debugPrint(logMessage);
      if (exception != null) debugPrint('$prefix Exception: $exception');
      if (stackTrace != null) debugPrint('$prefix StackTrace: $stackTrace');
    }
  }

  String _levelPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return '📢';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      }
  }

  Logger withTag(String tag) {
    return Logger(
      tag: tag,
      minLevel: _minLevel,
      enableCloudflareDebug: _enableCloudflareDebug,
    );
  }

  Logger withCloudflareDebug(bool enabled) {
    return Logger(
      tag: _tag,
      minLevel: _minLevel,
      enableCloudflareDebug: enabled,
    );
  }
}
