import 'dart:async';
import 'dart:convert';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Model Response (sesuaikan dengan JSON API)
class Root {
  final List<dynamic> rank;
  final List<dynamic> recentRank;

  Root({required this.rank, required this.recentRank});

  factory Root.fromJson(Map<String, dynamic> json) {
    return Root(
      rank: json['rank'] ?? [],
      recentRank: json['recentRank'] ?? [],
    );
  }
}

/// Service Headless WebView agar Cloudflare domain `api.comick.io` bisa dilalui
class WebViewApiService {
  // Singleton
  static final WebViewApiService _instance = WebViewApiService._internal();
  factory WebViewApiService() => _instance;
  WebViewApiService._internal();

  HeadlessInAppWebView? _headlessWebView;

  bool _isInitializing = false;
  bool _isInitialized = false;
  final Completer<bool> _initCompleter = Completer<bool>();

  /// Inisialisasi headless webview dengan memuat `https://api.comick.io/`
  /// agar Cloudflare challenge pada domain `api.comick.io` terselesaikan.
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    if (_isInitializing) {
      return _initCompleter.future;
    }

    _isInitializing = true;
    debugPrint(
        "🌐 [WebViewApiService] Initializing with domain api.comick.io ...");

    try {
      _headlessWebView = HeadlessInAppWebView(
        initialSize: const Size(-1, -1), // default full screen
        initialSettings: InAppWebViewSettings(
          userAgent:
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36",
          javaScriptEnabled: true,
          cacheEnabled: true,
          useOnLoadResource: true,
          isInspectable: kDebugMode,
        ),
        // Muat domain `api.comick.io/`
        initialUrlRequest: URLRequest(url: WebUri("https://api.comick.io/")),
        onWebViewCreated: (controller) {
          debugPrint("[Headless] onWebViewCreated => $controller");
        },
        onLoadStart: (controller, url) {
          debugPrint("[Headless] onLoadStart => $url");
        },
        onLoadStop: (controller, url) async {
          debugPrint("✅ [Headless] onLoadStop => $url");
          // Tunggu sejenak agar Cloudflare selesai
          await Future.delayed(const Duration(seconds: 3));
          // Test fetch => top endpoint
          await _testApi(controller);
        },
        onConsoleMessage: (controller, consoleMessage) {
          debugPrint("[Headless Console] ${consoleMessage.message}");
        },
        onReceivedError: (controller, request, error) {
          debugPrint("⚠️ [Headless] onReceivedError => ${error.description}");
        },
      );

      await _headlessWebView?.run();
      debugPrint("🔃 [Headless] Running WebView...");

      // Tunggu initCompleter (max 20 detik)
      return await _initCompleter.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          debugPrint("⏰ [WebViewApiService] Initialization timed out!");
          _isInitializing = false;
          if (!_initCompleter.isCompleted) {
            _initCompleter.complete(false);
          }
          return false;
        },
      );
    } catch (e) {
      debugPrint("❌ [WebViewApiService] Error initializing: $e");
      _isInitializing = false;
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete(false);
      }
      return false;
    }
  }

  /// Cek apakah fetch https://api.comick.io/top?gender=1&accept_mature_content=true sudah 200
  Future<void> _testApi(InAppWebViewController controller) async {
    try {
      final result = await controller.evaluateJavascript(source: '''
        fetch('https://api.comick.io/top?gender=1&accept_mature_content=true', {
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest'
          },
          credentials: 'include'
        })
        .then(r => r.status)
        .catch(err => 'ERROR:' + err);
      ''');

      debugPrint("🧪 [Headless] testApi => $result");

      // Cek result 200
      if (result is num && result == 200) {
        _isInitialized = true;
        _isInitializing = false;
        if (!_initCompleter.isCompleted) {
          _initCompleter.complete(true);
        }
      } else {
        debugPrint("🧪 [Headless] testApi => Not 200, can't pass");
        if (!_initCompleter.isCompleted) {
          _initCompleter.complete(false);
        }
      }
    } catch (e) {
      debugPrint("❌ [Headless] testApi error => $e");
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete(false);
      }
    }
  }

  /// Memanggil endpoint /top via headless webview
  Future<Root> fetchTopComics(
      {int gender = 1, bool acceptMatureContent = true}) async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) {
        throw Exception(
            "WebViewApiService init failed (Cloudflare or CORS block).");
      }
    }

    final completer = Completer<String>();

    // Hapus handler sebelumnya (jika ada)
    _headlessWebView?.webViewController
        ?.removeJavaScriptHandler(handlerName: "apiData");
    _headlessWebView?.webViewController
        ?.removeJavaScriptHandler(handlerName: "apiError");

    // Tambah handler
    _headlessWebView?.webViewController?.addJavaScriptHandler(
      handlerName: "apiData",
      callback: (args) {
        if (args.isNotEmpty && args[0] is String) {
          completer.complete(args[0]);
        } else {
          completer.completeError("Invalid data from JS");
        }
      },
    );

    _headlessWebView?.webViewController?.addJavaScriptHandler(
      handlerName: "apiError",
      callback: (args) {
        final errorMsg = args.isNotEmpty ? args[0].toString() : "Unknown error";
        completer.completeError(errorMsg);
      },
    );

    // Jalankan fetch di JS
    await _headlessWebView?.webViewController?.evaluateJavascript(source: '''
      fetch('https://api.comick.io/top?gender=$gender&accept_mature_content=$acceptMatureContent', {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        },
        credentials: 'include'
      })
      .then(response => {
        if(response.ok) return response.json();
        throw new Error('Request failed with status: ' + response.status);
      })
      .then(data => {
        window.flutter_inappwebview.callHandler('apiData', JSON.stringify(data));
      })
      .catch(err => {
        window.flutter_inappwebview.callHandler('apiError', err.toString());
      });
    ''');

    try {
      final resultString = await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException("fetchTopComics timed out"),
      );
      final data = jsonDecode(resultString);
      return Root.fromJson(data);
    } catch (e) {
      debugPrint("❌ [Headless] fetchTopComics => $e");
      rethrow;
    }
  }

  void dispose() {
    _headlessWebView?.dispose();
    _headlessWebView = null;
    _isInitialized = false;
    _isInitializing = false;
  }
}
