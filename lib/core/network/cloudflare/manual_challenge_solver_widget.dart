import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:boilerplate/utils/logger.dart';
import 'package:boilerplate/core/network/cloudflare/cookie_manager.dart';
import 'package:boilerplate/core/network/cloudflare/user_agent_factory.dart';

/// Widget to display a WebView for manual Cloudflare challenge solving.
/// Reports completion via [onChallengeCompleted] with a map of cookie name→value.
class ManualChallengeSolverWidget extends StatefulWidget {
  final String url;
  final String domain;
  final Map<String, String>? headers;
  final CookieManager cookieManager;
  final UserAgentFactory userAgentFactory;
  final void Function(Map<String, String>) onChallengeCompleted;
  final VoidCallback onCancel;
  final Logger logger;

  const ManualChallengeSolverWidget({
    super.key,
    required this.url,
    required this.domain,
    this.headers,
    required this.cookieManager,
    required this.userAgentFactory,
    required this.onChallengeCompleted,
    required this.onCancel,
    required this.logger,
  });

  @override
  State<ManualChallengeSolverWidget> createState() =>
      _ManualChallengeSolverWidgetState();
}

class _ManualChallengeSolverWidgetState
    extends State<ManualChallengeSolverWidget> {
  // Changed from late to nullable with initial null value
  WebViewController? _controller;
  bool _isLoading = true;
  bool _isInitialized = false;
  String _statusMessage = 'Loading challenge page...';
  Timer? _statusTimer;
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    _initWebView();

    // Periodically update status message
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isLoading && mounted) {
        setState(() {
          _statusMessage =
              'Awaiting your input... please complete the challenge.';
        });
        widget.logger.debug('Status message updated', domain: 'Cloudflare');
      }
    });

    // Periodically check for cookie clearance or redirect
    _checkTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkForCompletion();
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _checkTimer?.cancel();
    super.dispose();
  }

  Future<void> _initWebView() async {
    try {
      // Determine UA: try saved, else platform specific
      String? ua = widget.userAgentFactory.getLastSuccessful(widget.domain);
      ua ??= await widget.userAgentFactory.getPlatformSpecific();
      widget.logger.info('Using User-Agent: $ua', domain: 'Cloudflare');

      // Create controller
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setUserAgent(ua)
        ..setNavigationDelegate(NavigationDelegate(
          onPageStarted: (url) {
            widget.logger.debug('Page started: $url', domain: 'Cloudflare');
            if (mounted) {
              setState(() {
                _isLoading = true;
                _statusMessage = 'Loading challenge page...';
              });
            }
          },
          onPageFinished: (url) {
            widget.logger.info('Page finished: $url', domain: 'Cloudflare');
            if (mounted) {
              setState(() {
                _isLoading = false;
                _statusMessage = 'Please solve the challenge above.';
              });
            }
            // Immediate check after load
            _checkForCompletion();
          },
          onWebResourceError: (err) {
            widget.logger.error(
              'Web resource error: ${err.errorCode} ${err.description}',
              domain: 'Cloudflare',
            );
            if (mounted) {
              setState(() {
                _statusMessage = 'Error loading: ${err.description}';
              });
            }
          },
        ));

      // Apply any custom headers (e.g. initial cookies, referer)
      final headers = widget.headers?.cast<String, String>() ?? {};
      widget.logger
          .debug('Loading URL with headers: $headers', domain: 'Cloudflare');

      // Set controller and mark as initialized BEFORE loading the URL
      if (mounted) {
        setState(() {
          _controller = controller;
          _isInitialized = true;
        });
      }

      // AFTER setting the controller, load the request
      await controller.loadRequest(Uri.parse(widget.url), headers: headers);
    } catch (e, stack) {
      widget.logger.error('Error initializing WebView: $e\n$stack',
          domain: 'Cloudflare');
      if (mounted) {
        setState(() {
          _statusMessage = 'Error initializing WebView: $e';
        });
      }
    }
  }

  Future<void> _checkForCompletion() async {
    if (_isLoading || _controller == null || !_isInitialized) return;

    try {
      // 1) Get cookies JS-side
      final raw =
          await _controller!.runJavaScriptReturningResult('document.cookie');
      final cookieStr = raw.toString();
      widget.logger
          .debug('Raw document.cookie: $cookieStr', domain: 'Cloudflare');

      // 2) Parse & persist via CookieManager
      widget.cookieManager.parseCookiesFromString(cookieStr, widget.url);

      // 3) Retrieve current cookies for this URL
      final header = widget.cookieManager.getCookiesForUrl(widget.url);
      widget.logger
          .debug('Persisted cookies header: $header', domain: 'Cloudflare');

      // 4) Convert to map for callback
      final Map<String, String> cookieMap = {};
      for (final part in header.split(';')) {
        if (part.trim().isEmpty) continue;
        final kv = part.trim().split('=');
        if (kv.length >= 2) cookieMap[kv[0]] = kv.sublist(1).join('=');
      }

      // 5) If cf_clearance present, treat as solved
      if (cookieMap.containsKey('cf_clearance')) {
        widget.logger.info(
          'CF clearance obtained, invoking onChallengeCompleted',
          domain: 'Cloudflare',
        );
        // Save UA as successful
        final ua = await _controller!.getUserAgent();
        if (ua != null) {
          await widget.userAgentFactory.saveSuccessful(widget.domain, ua);
        }
        widget.onChallengeCompleted(cookieMap);
        return;
      }

      // 6) Also check redirect away from challenge
      final currentUrl = await _controller!.currentUrl();
      if (currentUrl != null &&
          currentUrl != widget.url &&
          !currentUrl.contains(RegExp(r'cf_chl_|__cf_chl_'))) {
        widget.logger.info(
          'Redirect detected (challenge likely solved): $currentUrl',
          domain: 'Cloudflare',
        );
        widget.onChallengeCompleted(cookieMap);
      }
    } catch (e, st) {
      widget.logger
          .error('Error checking solution: $e\n$st', domain: 'Cloudflare');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          color: Colors.blue.shade900,
          padding: const EdgeInsets.all(16),
          child: Text(
            _statusMessage,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        // WebView area
        Expanded(
          child: Stack(
            children: [
              // Only show WebView if controller is initialized
              if (_isInitialized && _controller != null)
                WebViewWidget(controller: _controller!),

              // Show loading indicator when loading OR when controller is not yet initialized
              if (_isLoading || !_isInitialized)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
        // Controls
        Container(
          color: Colors.grey.shade200,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: _isInitialized && _controller != null
                    ? () {
                        widget.logger
                            .debug('User tapped Reload', domain: 'Cloudflare');
                        _controller!.reload();
                        setState(() {
                          _isLoading = true;
                          _statusMessage = 'Reloading...';
                        });
                      }
                    : null, // Disable if controller isn't ready
                icon: const Icon(Icons.refresh),
                label: const Text('Reload'),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  widget.logger.warn('User cancelled CF challenge',
                      domain: 'Cloudflare');
                  widget.onCancel();
                },
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
