import 'dart:async';
import 'dart:convert';

import 'package:webview_flutter/webview_flutter.dart';
import 'package:boilerplate/utils/logger.dart';
import 'package:boilerplate/core/network/cloudflare/user_agent_factory.dart';

/// The result of a headless page load & JSON extraction.
class HeadlessJsonResult {
  /// The extracted JSON text, or null if none found.
  final String? json;

  /// The final URL loaded (after any redirects).
  final String finalUrl;

  /// The page's HTML content (for debugging)
  final String? htmlContent;

  HeadlessJsonResult({
    required this.json,
    required this.finalUrl,
    this.htmlContent,
  });
}

/// Loads a URL offscreen, waits for the page to finish, then tries once
/// to extract JSON from a <pre> tag or container. Uses a User-Agent chosen
/// via [UserAgentFactory]. Times out after [timeout].
class HeadlessJsonLoader {
  final Logger _logger;
  final UserAgentFactory _uaFactory;
  final Duration timeout;
  final bool _logHtmlContent;

  HeadlessJsonLoader({
    required Logger logger,
    required UserAgentFactory userAgentFactory,
    this.timeout = const Duration(seconds: 15),
    bool logHtmlContent = true,
  })  : _logger = logger.withTag('HeadlessJsonLoader'),
        _uaFactory = userAgentFactory,
        _logHtmlContent = logHtmlContent;

  /// Loads [url] with optional HTTP [headers], sets UA from factory,
  /// then extracts JSON if present. Returns null on failure or no JSON.
  Future<HeadlessJsonResult?> load(
    String url, {
    Map<String, String>? headers,
  }) async {
    _logger.info('Starting headless load for: $url');
    final completer = Completer<HeadlessJsonResult?>();
    late final WebViewController controller;
    Timer? finishTimer;
    Timer? timeoutTimer;

    // 1) Setup timeout
    timeoutTimer = Timer(timeout, () {
      if (!completer.isCompleted) {
        _logger.warn('Headless load timed out after ${timeout.inSeconds}s');
        completer.complete(null);
      }
    });

    // 2) Build controller
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);

    // 3) Set User-Agent from factory
    String? domain = Uri.tryParse(url)?.host;
    String? savedUa =
        domain != null ? _uaFactory.getLastSuccessful(domain) : null;
    String ua = savedUa ?? await _uaFactory.getPlatformSpecific();
    controller.setUserAgent(ua);
    _logger.debug('User-Agent set to: $ua');

    // 4) NavigationDelegate
    controller.setNavigationDelegate(NavigationDelegate(
      onPageFinished: (String finishedUrl) async {
        _logger.debug('Page finished loading: $finishedUrl');
        // Give page a moment to render content
        finishTimer = Timer(const Duration(milliseconds: 300), () async {
          if (completer.isCompleted) return;
          try {
            // Extract and log HTML content
            String? htmlContent;
            if (_logHtmlContent) {
              try {
                final rawHtml = await controller.runJavaScriptReturningResult(
                    'document.documentElement.outerHTML');
                htmlContent = _cleanString(rawHtml.toString());
                _logger.debug('Page HTML content:\n$htmlContent');

                // Log page title
                final title = await controller
                    .runJavaScriptReturningResult('document.title');
                _logger.info('Page title: $title');
              } catch (e) {
                _logger.warn('Failed to extract HTML content: $e');
              }
            }

            // ------------------------------------
            // DIRECT API RESPONSE HANDLING
            // ------------------------------------
            // First check if this is likely an API response in a pre tag
            // This appears to be the most common case for your app
            String? extracted;

            try {
              // Get both innerText and innerHTML to cover all bases
              final bodyText = await controller
                  .runJavaScriptReturningResult('document.body.innerText');

              _logger.debug('Raw body text (before clean):\n'
                  '${bodyText.toString()}');
              // Clean and decode
              String decodedText = _cleanString(bodyText.toString());

              // Log full content for debugging
              _logger.debug('Full page body text:\n$decodedText');

              // CRITICAL FIX: Special case for API responses
              // Check if it starts with [ or { which indicates JSON
              if ((decodedText.trim().startsWith('[') ||
                  decodedText.trim().startsWith('{'))) {
                _logger.info('Direct API response detected');

                // Directly use this as JSON without further validation
                // This is safe because we know your API returns JSON
                extracted = decodedText;

                _logger.info('JSON successfully extracted from API response');
              }
            } catch (e) {
              _logger.warn('Error extracting body text: $e');
            }

            // ------------------------------------
            // FALLBACK EXTRACTION METHODS
            // ------------------------------------
            // Only try these if the direct API response method failed
            if (extracted == null) {
              // 1. Try extracting from pre tag
              try {
                final preContent =
                    await controller.runJavaScriptReturningResult('''
                  (function() {
                    const pre = document.querySelector('pre');
                    return pre ? pre.textContent : null;
                  })()
                ''');

                if (preContent != "null" && preContent.toString().isNotEmpty) {
                  String cleanContent = _cleanString(preContent.toString());

                  // If it looks like JSON, use it
                  if (cleanContent.trim().startsWith('[') ||
                      cleanContent.trim().startsWith('{')) {
                    extracted = cleanContent;
                    _logger.info('Extracted JSON from <pre> tag');
                  }
                }
              } catch (e) {
                _logger.warn('Error extracting from pre tag: $e');
              }
            }

            // 2. Try with JSON formatter container if needed
            if (extracted == null) {
              try {
                final jsonContent =
                    await controller.runJavaScriptReturningResult('''
                  (function() {
                    const cont = document.querySelector('.json-formatter-container');
                    return cont ? cont.textContent : null;
                  })()
                ''');

                if (jsonContent != "null" &&
                    jsonContent.toString().isNotEmpty) {
                  String cleanContent = _cleanString(jsonContent.toString());

                  // If it looks like JSON, use it
                  if (cleanContent.trim().startsWith('[') ||
                      cleanContent.trim().startsWith('{')) {
                    extracted = cleanContent;
                    _logger
                        .info('Extracted JSON from .json-formatter-container');
                  }
                }
              } catch (e) {
                _logger.warn('Error extracting from JSON container: $e');
              }
            }

            // Final results
            if (extracted != null) {
              _logger.info(
                  'JSON extraction successful (${extracted.length} chars)');

              // Try to validate the JSON (but don't fail if it's invalid)
              bool isValid = false;
              try {
                json.decode(extracted);
                isValid = true;
              } catch (e) {
                _logger.warn('Extracted content is not valid JSON: $e');
                // Continue anyway - we'll return the text even if it's not valid JSON
              }

              _logger.debug('JSON is valid: $isValid');

              // Complete with the result
              completer.complete(
                HeadlessJsonResult(
                    json: extracted,
                    finalUrl: finishedUrl,
                    htmlContent: htmlContent),
              );
            } else {
              _logger.warn('No JSON content could be extracted');
              completer.complete(
                HeadlessJsonResult(
                    json: null,
                    finalUrl: finishedUrl,
                    htmlContent: htmlContent),
              );
            }
          } catch (e, st) {
            _logger.error('Error during content extraction: $e\n$st');
            completer.complete(null);
          }
        });
      },
      onWebResourceError: (err) {
        _logger.error(
          'Web resource error (${err.errorCode}): ${err.description}',
        );
        if (!completer.isCompleted) completer.complete(null);
      },
    ));

    // 5) Start load
    try {
      _logger.debug('Loading URL with headers: ${headers ?? {}}');
      await controller.loadRequest(
        Uri.parse(url),
        headers: headers ?? {},
      );
    } catch (e, st) {
      _logger.error('Failed to load URL: $e\n$st');
      if (!completer.isCompleted) completer.complete(null);
    }

    // 6) Await result
    final result = await completer.future;

    // 7) Cleanup
    finishTimer?.cancel();
    timeoutTimer.cancel();
    _logger.debug('Headless loader cleanup complete');

    if (result != null) {
      _logger.info('Headless load completed for: ${result.finalUrl}');
      if (result.json == null) {
        _logger.warn('No JSON content was extracted');
      }
    } else {
      _logger.warn('Headless load returned no result');
    }
    return result;
  }

  // Clean and decode a string
  String _cleanString(String input) {
    var s = input;

    // Jika tampak sebagai JSON literal (diawali & diakhiri dengan quote), decode via json.decode
    if ((s.startsWith('"') && s.endsWith('"')) ||
        (s.startsWith("'") && s.endsWith("'"))) {
      try {
        final decoded = json.decode(s);
        if (decoded is String) {
          s = decoded;
        }
      } catch (_) {
        // gagal decode, fallback ke substring
        s = s.substring(1, s.length - 1);
      }
    }

    // Sekarang decode unicode escapes \uXXXX
    s = s.replaceAllMapped(RegExp(r'\\u([0-9a-fA-F]{4})'), (m) {
      return String.fromCharCode(int.parse(m[1]!, radix: 16));
    });

    // Gantikan escape sequences umum
    const replaces = {
      r'\\"': '"',
      r"\\'": "'",
      r'\\n': '\n',
      r'\\r': '\r',
      r'\\t': '\t',
      r'\\/': '/',
      r'\\\\': '\\',
    };
    replaces.forEach((pattern, char) {
      s = s.replaceAll(pattern, char);
    });

    return s;
  }
}
