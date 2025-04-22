// import 'package:boilerplate/core/network/cloudflare/cookie_manager.dart';
// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import '../../../utils/logger.dart';
// import 'user_agent_factory.dart';
// import 'cookie_parser.dart'; // Use the dedicated file

// /// Options for the Cloudflare challenge solver
// class CloudflareChallengeSolverOptions {
//   /// Initial timeout for automatic challenge solving
//   final Duration initialTimeout;

//   /// Timeout for interactive challenge solving
//   final Duration interactiveTimeout;

//   /// Whether to show debug information in the WebView
//   final bool showDebugInfo;

//   const CloudflareChallengeSolverOptions({
//     this.initialTimeout = const Duration(seconds: 15),
//     this.interactiveTimeout = const Duration(minutes: 3),
//     this.showDebugInfo = false,
//   });
// }

// /// Base class for Cloudflare challenge solvers
// abstract class CloudflareChallengeSolver {
//   Future<Map<String, String>> solveChallenge(String url);

//   Widget buildChallengeWebView({
//     required String url,
//     required CloudflareChallengeSolverOptions options,
//     required Function(Map<String, String> cookies) onSolved,
//     required Function(String error) onError,
//   });
// }

// /// Advanced implementation of the Cloudflare challenge solver
// class AdvancedCloudflareSolver implements CloudflareChallengeSolver {
//   final Logger logger;
//   final CookieParser cookieParser;
//   final UserAgentFactory userAgentFactory;
//   final CookieManager cookieManager;

//   AdvancedCloudflareSolver({
//     required this.logger,
//     required this.cookieParser,
//     required this.userAgentFactory,
//     required this.cookieManager,
//   });

//   @override
//   Future<Map<String, String>> solveChallenge(String url) async {
//     throw UnimplementedError('solveChallenge method not implemented');
//   }

//   @override
//   Widget buildChallengeWebView({
//     required String url,
//     required CloudflareChallengeSolverOptions options,
//     required Function(Map<String, String> cookies) onSolved,
//     required Function(String error) onError,
//   }) {
//     return CloudflareChallengeWebView(
//       url: url,
//       options: options,
//       userAgent: userAgentFactory.getRandomUserAgent(),
//       onSolved: onSolved,
//       onError: onError,
//       logger: logger,
//       cookieParser: cookieParser,
//     );
//   }
// }

// /// WebView widget for solving Cloudflare challenges
// class CloudflareChallengeWebView extends StatefulWidget {
//   final String url;
//   final CloudflareChallengeSolverOptions options;
//   final String userAgent;
//   final Function(Map<String, String> cookies) onSolved;
//   final Function(String error) onError;
//   final Logger logger;
//   final CookieParser cookieParser;

//   const CloudflareChallengeWebView({
//     super.key,
//     required this.url,
//     required this.options,
//     required this.userAgent,
//     required this.onSolved,
//     required this.onError,
//     required this.logger,
//     required this.cookieParser,
//   });

//   @override
//   State<CloudflareChallengeWebView> createState() =>
//       _CloudflareChallengeWebViewState();
// }

// class _CloudflareChallengeWebViewState
//     extends State<CloudflareChallengeWebView> {
//   late WebViewController _controller;
//   bool _challengeSolved = false;
//   bool _isLoading = true;
//   String _debugMessage = 'Loading...';

//   @override
//   void initState() {
//     super.initState();
//     _setupWebView();
//   }

//   void _setupWebView() {
//     _controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setUserAgent(widget.userAgent)
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onPageStarted: (String url) {
//             setState(() {
//               _isLoading = true;
//               _debugMessage = 'Loading page...';
//             });
//           },
//           onPageFinished: (String url) async {
//             setState(() {
//               _isLoading = false;
//               _debugMessage = 'Page loaded. Checking for challenge...';
//             });

//             // Check for challenge completion
//             await _checkChallengeSolved();
//           },
//           onWebResourceError: (WebResourceError error) {
//             widget.logger.error(
//                 'WebView error: ${error.description} (${error.errorCode})',
//                 domain: 'Cloudflare');
//             setState(() {
//               _debugMessage = 'Error: ${error.description}';
//             });
//           },
//         ),
//       )
//       ..loadRequest(Uri.parse(widget.url));
//   }

//   Future<void> _checkChallengeSolved() async {
//     if (_challengeSolved) return;

//     try {
//       // Check if we're still on a challenge page
//       final pageContent = await _controller
//           .runJavaScriptReturningResult('document.body.innerText') as String;

//       if (!pageContent.contains('Just a moment') &&
//           !pageContent.contains('Checking your browser') &&
//           !pageContent.contains('challenge-platform')) {
//         // Get the cookies
//         final cookiesResult = await _controller
//             .runJavaScriptReturningResult('document.cookie') as String;

//         // Use parseCookiesString instead of parseCookies for consistency
//         final cookies = widget.cookieParser.parseCookiesString(cookiesResult);

//         // Check for cf_clearance cookie
//         if (cookies.containsKey('cf_clearance')) {
//           widget.logger.info('Challenge solved! cf_clearance cookie found',
//               domain: 'Cloudflare');
//           setState(() {
//             _challengeSolved = true;
//             _debugMessage = 'Challenge solved!';
//           });

//           widget.onSolved(cookies);
//         } else {
//           widget.logger.debug('Page loaded but cf_clearance cookie not found',
//               domain: 'Cloudflare');
//           setState(() {
//             _debugMessage = 'Waiting for challenge completion...';
//           });

//           // Check again after a short delay
//           Future.delayed(const Duration(seconds: 2), () {
//             if (mounted && !_challengeSolved) {
//               _checkChallengeSolved();
//             }
//           });
//         }
//       } else {
//         widget.logger.debug('Still on challenge page...', domain: 'Cloudflare');
//         setState(() {
//           _debugMessage = 'Waiting for challenge completion...';
//         });

//         // Check again after a short delay
//         Future.delayed(const Duration(seconds: 2), () {
//           if (mounted && !_challengeSolved) {
//             _checkChallengeSolved();
//           }
//         });
//       }
//     } catch (e) {
//       widget.logger
//           .error('Error checking challenge status: $e', domain: 'Cloudflare');
//       setState(() {
//         _debugMessage = 'Error: $e';
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         WebViewWidget(controller: _controller),
//         if (widget.options.showDebugInfo)
//           Positioned(
//             bottom: 0,
//             left: 0,
//             right: 0,
//             child: Container(
//               padding: const EdgeInsets.all(8),
//               color: Colors.black.withOpacity(0.7),
//               child: Text(
//                 _debugMessage,
//                 style: const TextStyle(color: Colors.white),
//               ),
//             ),
//           ),
//         if (_isLoading)
//           const Center(
//             child: CircularProgressIndicator(),
//           ),
//       ],
//     );
//   }
// }
