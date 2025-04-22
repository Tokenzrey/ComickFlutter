import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:boilerplate/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'challenge_detector.dart';
import 'cookie_manager.dart';
import 'headless_data_fetch.dart';
import 'manual_challenge_solver_widget.dart';
import 'user_agent_factory.dart';
import 'proxy_handler.dart';
import '../retry_policy.dart';

/// Configuration options for the CloudflareInterceptor.
class CloudflareInterceptorOptions {
  /// Enable verbose debug logging.
  final bool enableDebug;

  /// Policy for retrying requests after errors or challenges.
  final RetryPolicy retryPolicy;

  /// Maximum time to wait for headless solving before using manual fallback.
  final Duration headlessTimeout;

  /// Whether to automatically try solving challenges or always use manual mode.
  final bool enableAutomaticSolving;

  const CloudflareInterceptorOptions({
    this.enableDebug = false,
    RetryPolicy? retryPolicy,
    this.headlessTimeout = const Duration(seconds: 15),
    this.enableAutomaticSolving = true,
  }) : retryPolicy = retryPolicy ?? const RetryPolicy();
}

/// Dio interceptor that handles Cloudflare protected endpoints by detecting
/// and solving various types of challenges automatically or through user interaction.
class CloudflareInterceptor extends Interceptor {
  final Logger _logger;
  final CookieManager _cookieManager;
  final ChallengeDetector _detector;
  final UserAgentFactory _uaFactory;
  final ProxyHandler _proxyHandler;
  final HeadlessJsonLoader _headlessSolver;
  final GlobalKey<NavigatorState>? navigatorKey;
  final CloudflareInterceptorOptions options;

  // Stats for monitoring
  int _challengesSolved = 0;
  DateTime? _lastChallengeSolvedAt;

  CloudflareInterceptor({
    required Logger logger,
    required CookieManager cookieManager,
    required ChallengeDetector detector,
    required UserAgentFactory userAgentFactory,
    required ProxyHandler proxyHandler,
    required HeadlessJsonLoader headlessSolver,
    this.navigatorKey,
    CloudflareInterceptorOptions? options,
  })  : _logger = logger.withTag('Cloudflare'),
        _cookieManager = cookieManager,
        _detector = detector,
        _uaFactory = userAgentFactory,
        _proxyHandler = proxyHandler,
        _headlessSolver = headlessSolver,
        options = options ?? const CloudflareInterceptorOptions();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Attach stored cookies
    final cookieHeader =
        _cookieManager.getCookiesForUrl(options.uri.toString());
    if (cookieHeader.isNotEmpty) {
      options.headers[HttpHeaders.cookieHeader] = cookieHeader;
      _logger.debug('Added Cookie header: $cookieHeader');
    }

    // Add domain-specific UA if available
    String? domain = Uri.parse(options.uri.toString()).host;
    if (domain.isNotEmpty &&
        !options.headers.containsKey(HttpHeaders.userAgentHeader)) {
      String? ua = _uaFactory.getLastSuccessful(domain);
      if (ua != null) {
        options.headers[HttpHeaders.userAgentHeader] = ua;
        _logger.debug('Added domain-specific User-Agent: $ua');
      }
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Store cookies from successful responses
    if (response.statusCode == 200) {
      if (response.headers.map.containsKey('set-cookie')) {
        final uri = response.requestOptions.uri.toString();
        _cookieManager.parseCookiesFromHeaders(response.headers.map, uri);
        _logger.debug('Stored cookies from successful response');
      }
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final req = err.requestOptions;
    final uri = req.uri.toString();
    final status = err.response?.statusCode ?? 0;

    // Only handle Cloudflare-related errors (usually 403 or 503)
    if (status != 403 && status != 503) {
      handler.next(err);
      return;
    }

    final cfChallenge = _detector.detect(err.response);

    // If no Cloudflare challenge detected, just propagate the error
    if (cfChallenge.type == CloudflareChallengeType.none) {
      _logger.debug('No Cloudflare challenge detected, propagating error');
      handler.next(err);
      return;
    }

    _logger.info(
        'Detected ${cfChallenge.type.toString().split('.').last} challenge (CF Ray: ${cfChallenge.rayId})');

    // Choose solution strategy based on challenge type
    switch (cfChallenge.type) {
      case CloudflareChallengeType.captcha:
        if (options.enableAutomaticSolving) {
          // Try headless first, fallback to manual
          final result = await _tryHeadlessSolving(uri, req, err.response,
              duration: const Duration(seconds: 3));
          if (result != null) {
            handler.resolve(result);
            return;
          }
        }
        // If automatic solving failed or disabled, use manual solver
        await _handleManual(uri, req, handler);
        break;

      case CloudflareChallengeType.jsChallenge:
      case CloudflareChallengeType.uaBlock:
      case CloudflareChallengeType.unknown:
        if (options.enableAutomaticSolving) {
          // Attempt headless solving
          await _handleHeadless(uri, req, handler);
        } else {
          // If automatic solving is disabled, use manual solver
          await _handleManual(uri, req, handler);
        }
        break;

      case CloudflareChallengeType.rateLimit:
        // Apply retry policy for rate limits
        final retryDelay =
            options.retryPolicy.getRetryDelay(_challengesSolved % 3);
        _logger.warn(
            'Rate limited by Cloudflare, retrying in ${retryDelay.inSeconds}s');
        await Future.delayed(retryDelay);
        final retryResponse = await _retryWithCookies(req);
        handler.resolve(retryResponse);
        break;

      case CloudflareChallengeType.none:
        // Propagate original error (should not reach this case due to earlier check)
        handler.next(err);
        break;
    }
  }

  /// Quick check if headless solving works within a short duration
  Future<Response?> _tryHeadlessSolving(
      String url, RequestOptions original, Response? errorResponse,
      {Duration duration = const Duration(seconds: 5)}) async {
    _logger.debug(
        'Attempting quick headless solving (timeout: ${duration.inSeconds}s)');

    try {
      // Quick attempt with short timeout
      final result = await _headlessSolver.load(
        url,
        headers: original.headers.cast<String, String>(),
      );

      if (result?.json != null) {
        dynamic data;
        try {
          data = json.decode(result!.json!);
        } catch (e) {
          data = result!.json;
        }

        _logger.info('Quick headless solving succeeded!');
        return Response(
          requestOptions: original,
          data: data,
          statusCode: 200,
          statusMessage: 'OK (via headless extraction)',
        );
      }
    } catch (e) {
      _logger.debug('Quick headless solving failed: $e');
    }

    return null;
  }

  Future<void> _handleManual(
    String url,
    RequestOptions original,
    ErrorInterceptorHandler handler,
  ) async {
    if (navigatorKey?.currentContext == null) {
      _logger.error('No NavigatorKey: cannot show manual solver');
      handler.next(DioException(
        requestOptions: original,
        error: 'No UI context for manual CF solver',
        type: DioExceptionType.unknown,
      ));
      return;
    }

    final context = navigatorKey!.currentContext!;
    _logger.info('Showing manual challenge solver dialog');

    final cookies = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ManualChallengeSolverWidget(
        url: url,
        domain: Uri.parse(url).host,
        headers: original.headers.cast<String, String>(),
        cookieManager: _cookieManager,
        userAgentFactory: _uaFactory,
        logger: _logger,
        onChallengeCompleted: (c) => Navigator.of(context).pop(c),
        onCancel: () => Navigator.of(context).pop(<String, String>{}),
      ),
    );

    if (cookies == null || cookies.isEmpty) {
      _logger.warn('Manual CF solver cancelled or failed');
      handler.next(DioException(
        requestOptions: original,
        error: 'User cancelled or failed to solve CF challenge',
        type: DioExceptionType.unknown,
      ));
      return;
    }

    // Challenge solved successfully
    _challengesSolved++;
    _lastChallengeSolvedAt = DateTime.now();
    _logger.info('Manual solve succeeded, retrying original request');

    final response = await _retryWithCookies(original);
    handler.resolve(response);
  }

  Future<void> _handleHeadless(
    String url,
    RequestOptions original,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      _logger.info('Using headless solver to extract JSON content from $url');

      // Load the URL in headless WebView to get JSON data directly
      final result = await _headlessSolver.load(
        url,
        headers: original.headers.cast<String, String>(),
      );

      if (result == null) {
        _logger.error('Headless solver returned no result');

        // Try manual fallback if we have a navigator
        if (navigatorKey?.currentContext != null) {
          _logger.info('Falling back to manual solver');
          await _handleManual(url, original, handler);
        } else {
          handler.next(DioException(
            requestOptions: original,
            error: 'Headless JSON extraction failed',
            type: DioExceptionType.unknown,
          ));
        }
        return;
      }

      // Check if we got JSON from the headless load
      if (result.json == null) {
        _logger.warn('No JSON content found in headless result');

        // If no JSON but we got past Cloudflare, retry the original request
        _logger.info('Attempting to retry original request with cookies');
        final retryResponse = await _retryWithCookies(original);

        // Challenge solved successfully
        _challengesSolved++;
        _lastChallengeSolvedAt = DateTime.now();

        handler.resolve(retryResponse);
        return;
      }

      // We have JSON data, parse it
      dynamic data;
      try {
        data = json.decode(result.json!);
        _logger.info('Successfully parsed JSON from headless result');
      } catch (e) {
        _logger.warn('Failed to parse JSON: $e, using raw content');
        data = result.json; // Use raw string if parsing fails
      }

      // Return synthetic successful response with the extracted data
      final newResponse = Response(
        requestOptions: original,
        data: data,
        statusCode: 200,
        statusMessage: 'OK (via headless extraction)',
      );

      // Challenge solved successfully
      _challengesSolved++;
      _lastChallengeSolvedAt = DateTime.now();
      _logger.info('Resolved request with extracted JSON data');

      handler.resolve(newResponse);

      // Store the successful user agent for this domain if possible
      try {
        final domain = Uri.parse(url).host;
        if (domain.isNotEmpty) {
          // Use the available method from UserAgentFactory
          final currentUserAgent =
              original.headers[HttpHeaders.userAgentHeader] as String? ??
                  await _uaFactory.getPlatformSpecific();
          await _uaFactory.saveSuccessful(domain, currentUserAgent);
          _logger.debug('Saved successful UA for $domain: $currentUserAgent');
        }
      } catch (e) {
        _logger.debug('Failed to record UA success: $e');
      }
    } catch (e, st) {
      _logger.error('Error in headless solver: $e\n$st');

      // Try manual fallback if we have a navigator
      if (navigatorKey?.currentContext != null) {
        _logger.info('Headless solver failed, falling back to manual solver');
        await _handleManual(url, original, handler);
      } else {
        handler.next(DioException(
          requestOptions: original,
          error: e,
          type: DioExceptionType.unknown,
        ));
      }
    }
  }

  Future<Response> _retryWithCookies(RequestOptions original) async {
    final dio = Dio();

    // Copy all configuration except interceptors to avoid loops
    final opts = Options(
      method: original.method,
      headers: Map<String, dynamic>.from(original.headers),
      responseType: original.responseType,
      followRedirects: original.followRedirects,
      receiveDataWhenStatusError: original.receiveDataWhenStatusError,
      validateStatus: original.validateStatus,
      receiveTimeout: original.receiveTimeout,
      sendTimeout: original.sendTimeout,
      contentType: original.contentType,
      listFormat: original.listFormat,
    );

    // Make sure we have the latest cookies
    final cookieHeader =
        _cookieManager.getCookiesForUrl(original.uri.toString());
    if (cookieHeader.isNotEmpty) {
      opts.headers?[HttpHeaders.cookieHeader] = cookieHeader;
    }

    return await dio.request(
      original.uri.toString(),
      data: original.data,
      queryParameters: original.queryParameters,
      options: opts,
      cancelToken: original.cancelToken,
      onReceiveProgress: original.onReceiveProgress,
      onSendProgress: original.onSendProgress,
    );
  }

  /// Clear all Cloudflare related data (cookies, etc.)
  Future<void> clearAllData() async {
    _logger.info('Clearing all Cloudflare data');

    // Reset stats
    _challengesSolved = 0;
    _lastChallengeSolvedAt = null;

    // Clear cookies
    _cookieManager.clearAllCookies();

    // Clear user agent records
    await _uaFactory.clearAll();

    // Additional cleanup if needed
    try {
      final prefs = await SharedPreferences.getInstance();
      // Clear any Cloudflare related preferences
      await prefs.remove('cf_user_agent');
      await prefs.remove('cf_last_challenge');
      await prefs.remove('cf_last_solve');
      _logger.debug('Cleared Cloudflare preferences');
    } catch (e) {
      _logger.error('Error clearing Cloudflare preferences: $e');
    }

    _logger.info('All Cloudflare data cleared');
  }

  /// Get statistics about challenge solving
  Map<String, dynamic> getStats() {
    return {
      'challengesSolved': _challengesSolved,
      'lastSolvedAt': _lastChallengeSolvedAt?.toIso8601String(),
      'proxyEnabled': _proxyHandler.isEnabled,
    };
  }

  /// Set debug mode on/off
  void setDebugMode(bool enabled) {
    // This method exists for API compatibility
    // The logger handles debug level filtering
    _logger.debug('Debug mode ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Check if a request can be made without hitting Cloudflare protection
  Future<bool> testConnection(String url) async {
    try {
      final dio = Dio();
      final opts = Options(
        headers: {
          HttpHeaders.userAgentHeader: await _uaFactory.getPlatformSpecific(),
        },
      );

      // Get cookies for this URL
      final cookieHeader = _cookieManager.getCookiesForUrl(url);
      if (cookieHeader.isNotEmpty) {
        opts.headers?[HttpHeaders.cookieHeader] = cookieHeader;
      }

      final response = await dio.get(url, options: opts);
      return response.statusCode == 200;
    } catch (e) {
      _logger.debug('Connection test failed: $e');
      return false;
    }
  }
}
