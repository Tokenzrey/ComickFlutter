import 'package:dio/dio.dart';
import 'package:boilerplate/utils/logger.dart';

/// Types of Cloudflare challenges we might detect.
enum CloudflareChallengeType {
  none,
  jsChallenge,
  captcha,
  rateLimit,
  uaBlock,
  unknown,
}

/// Result of a Cloudflare challenge detection.
class CloudflareChallenge {
  /// What kind of challenge (none if nothing detected).
  final CloudflareChallengeType type;

  /// The CF ray ID header if present.
  final String? rayId;

  /// Any extracted form parameters (for JS challenges).
  final Map<String, String> data;

  CloudflareChallenge({
    required this.type,
    this.rayId,
    this.data = const {},
  });
}

/// Detects various Cloudflare challenge responses in Dio [Response]s.
class ChallengeDetector {
  final Logger logger;

  ChallengeDetector({required this.logger});

  /// Analyzes [response] to determine if it's a Cloudflare challenge.
  CloudflareChallenge detect(Response? response) {
    if (response == null) {
      logger.debug('No response passed in for CF detection',
          domain: 'Cloudflare');
      return _none();
    }

    final status = response.statusCode ?? 0;
    final headers = response.headers;
    final body = response.data is String ? response.data as String : '';

    // CF ray ID if present
    final ray = headers.value('cf-ray');

    // Only statuses 403, 429, or 503 are interesting for CF
    if (![403, 429, 503].contains(status)) {
      return _none(ray);
    }

    // Must be served by Cloudflare
    final server = headers.value('server')?.toLowerCase() ?? '';
    if (!server.contains('cloudflare') && ray == null) {
      return _none(ray);
    }

    logger.debug(
      'Cloudflare response detected: status=$status, server=$server, ray=$ray',
      domain: 'Cloudflare',
    );

    // 1) Captcha-based challenge (Turnstile, reCAPTCHA, HCaptcha)
    if (_hasCaptcha(body)) {
      logger.info('Captcha challenge detected', domain: 'Cloudflare');
      return CloudflareChallenge(
          type: CloudflareChallengeType.captcha, rayId: ray);
    }

    // 2) JavaScript challenge (cf-chl-*, jschl_* tokens)
    if (_hasJsChallenge(body)) {
      logger.info('JavaScript challenge detected', domain: 'Cloudflare');
      final data = _extractJsChallengeData(body);
      return CloudflareChallenge(
        type: CloudflareChallengeType.jsChallenge,
        rayId: ray,
        data: data,
      );
    }

    // 3) Rate limit (429, cf-error-rate-limit)
    if (_hasRateLimit(body) || status == 429) {
      logger.info('Rate limit challenge detected', domain: 'Cloudflare');
      return CloudflareChallenge(
          type: CloudflareChallengeType.rateLimit, rayId: ray);
    }

    // 4) User‑agent block
    if (_hasUaBlock(body)) {
      logger.info('User‑Agent block detected', domain: 'Cloudflare');
      return CloudflareChallenge(
          type: CloudflareChallengeType.uaBlock, rayId: ray);
    }

    // 5) Fallback generic detection
    if (_looksLikeChallenge(body)) {
      logger.info('Generic CF challenge fallback detected',
          domain: 'Cloudflare');
      return CloudflareChallenge(
          type: CloudflareChallengeType.unknown, rayId: ray);
    }

    logger.debug('No Cloudflare challenge patterns matched',
        domain: 'Cloudflare');
    return _none(ray);
  }

  CloudflareChallenge _none([String? ray]) =>
      CloudflareChallenge(type: CloudflareChallengeType.none, rayId: ray);

  bool _hasCaptcha(String b) =>
      b.contains('cf_captcha_kind') ||
      b.contains('cf-captcha-container') ||
      b.contains('hcaptcha') ||
      b.contains('g-recaptcha') ||
      b.contains('turnstile');

  bool _hasJsChallenge(String b) =>
      b.contains('jschl_') ||
      b.contains('jschl-answer') ||
      b.contains('cf-please-wait') ||
      b.contains('challenge-form');

  bool _hasRateLimit(String b) =>
      b.contains('cf-error-rate-limit') ||
      b.contains('rate limited') ||
      b.contains('429 Too Many Requests');

  bool _hasUaBlock(String b) =>
      b.contains('user agent is not allowed') ||
      b.contains('parses_your_browser') ||
      b.contains('browser checking');

  bool _looksLikeChallenge(String b) =>
      b.contains('Just a moment') ||
      b.contains('checking your browser') ||
      b.contains('_cf_chl_') ||
      b.contains('challenge-platform');

  /// Extracts JS challenge form parameters needed to solve the CF JS check.
  Map<String, String> _extractJsChallengeData(String body) {
    final data = <String, String>{};
    final patterns = {
      'r': RegExp(r'name="r"\s+value="([^"]+)"'),
      'jschl_vc': RegExp(r'name="jschl_vc"\s+value="([^"]+)"'),
      'pass': RegExp(r'name="pass"\s+value="([^"]+)"'),
      'action': RegExp(r'<form[^>]+\saction="([^"]+)"'),
    };
    for (final entry in patterns.entries) {
      final match = entry.value.firstMatch(body);
      if (match != null) data[entry.key] = match.group(1)!;
    }
    logger.debug('Extracted JS challenge data: $data', domain: 'Cloudflare');
    return data;
  }
}
