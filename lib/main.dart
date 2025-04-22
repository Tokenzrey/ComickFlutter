/// ## Flutter Application Entry Point
///
/// File ini merupakan titik masuk (entry point) untuk aplikasi Flutter.
/// Pada bagian ini, beberapa inisialisasi penting dilakukan sebelum aplikasi dijalankan:
/// - Inisialisasi binding Flutter menggunakan [WidgetsFlutterBinding.ensureInitialized()],
/// - Menetapkan orientasi layar yang didukung,
/// - Mengonfigurasi dependency injection melalui [ServiceLocator],
/// - Menjalankan aplikasi dengan [MyApp].
///
/// Dokumentasi ini memudahkan pemeliharaan dan pengembangan lebih lanjut
/// dengan memberikan penjelasan detail mengenai fungsi dan alur program.
library;

import 'dart:async'; // Untuk operasi asynchronous (Future, async/await)
// import 'package:boilerplate/core/network/doh_provider.dart';
import 'package:boilerplate/di/service_locator.dart'; // Dependency injection configuration
import 'package:boilerplate/presentation/my_app.dart'; // Widget utama aplikasi
// import 'package:dio/dio.dart';
import 'package:flutter/material.dart'; // Material design widgets
import 'package:flutter/services.dart'; // Untuk mengatur orientasi layar dan pengaturan sistem lainnya
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:boilerplate/data/models/comick_model.dart';
// import 'package:boilerplate/utils/logger.dart';
// import 'package:boilerplate/core/network/api_client.dart';
// import 'package:boilerplate/core/network/retry_policy.dart';
// import 'package:boilerplate/data/repository/manga/manga_repository.dart';
// import 'package:boilerplate/data/repository/manga/manga_repository_impl.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:boilerplate/core/network/cloudflare/cookie_manager.dart';
// import 'package:boilerplate/core/network/cloudflare/user_agent_factory.dart';
// import 'package:boilerplate/core/network/cloudflare/challenge_detector.dart';
// import 'package:boilerplate/core/network/cloudflare/proxy_handler.dart';

/// Fungsi utama (entry point) aplikasi.
///
/// Fungsi ini memastikan bahwa binding Flutter telah diinisialisasi,
/// kemudian menetapkan orientasi layar, mengonfigurasi dependency injection,
/// dan akhirnya menjalankan aplikasi dengan memanggil [runApp] pada [MyApp].
Future<void> main() async {
  try {
    // Pastikan Flutter binding telah diinisialisasi sebelum menjalankan operasi lain.
    WidgetsFlutterBinding.ensureInitialized();

    // Atur orientasi layar sesuai dengan preferensi yang ditentukan.
    await setPreferredOrientations();

    // Konfigurasikan dependency injection agar seluruh layanan dan dependensi dapat diakses secara global.
    // await ServiceLocator.configureDependencies();

    // Initialize Hive database
    await initializeLocalStorage();

    // Setup application dependencies
    // await setupDependencies();

    // Custom error handler
    setupErrorHandling();

    // Jalankan aplikasi dengan widget utama [MyApp].
    runApp(MyApp());
  } catch (e, stackTrace) {
    debugPrint('Error during app initialization: $e');
    debugPrint(stackTrace.toString());

    // Display error screen as fallback
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Application Error',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('$e', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Try restarting the app
                    main();
                  },
                  child: const Text('Restart App'),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

/// Mengatur orientasi layar yang didukung oleh aplikasi.
///
/// Fungsi ini menetapkan orientasi layar menggunakan [SystemChrome.setPreferredOrientations].
/// Dengan demikian, aplikasi dapat berjalan dalam mode potrait maupun lanskap.
Future<void> setPreferredOrientations() {
  return SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, // Orientasi potrait standar
    DeviceOrientation.portraitDown, // Orientasi potrait terbalik
    DeviceOrientation.landscapeRight, // Orientasi lanskap, rotasi ke kanan
    DeviceOrientation.landscapeLeft, // Orientasi lanskap, rotasi ke kiri
  ]);
}

/// Initialize Hive local storage database
Future<void> initializeLocalStorage() async {
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);

  // Register Hive adapters
  Hive.registerAdapter(ComicModelAdapter());
  Hive.registerAdapter(ReadingHistoryModelAdapter());
}

/// Custom error handler for the application
void setupErrorHandling() {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'Oops! Something went wrong',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${details.exception}',
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  // Attempt to recover by reloading the app
                  main();
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  };
}

/// Setup all dependencies for the application
// Future<void> setupDependencies() async {
//   // Register logger
//   final logger = Logger(tag: 'MangaApp');
//   getIt.registerSingleton(logger);

//   logger.info('Starting application setup', domain: 'App');

//   // Create navigator keys for global context access
//   final navigatorKey = GlobalKey<NavigatorState>();
//   getIt.registerSingleton<GlobalKey<NavigatorState>>(navigatorKey);

//   if (!getIt.isRegistered<GlobalKey<NavigatorState>>(
//       instanceName: 'navigatorKey')) {
//     getIt.registerSingleton<GlobalKey<NavigatorState>>(navigatorKey,
//         instanceName: 'navigatorKey');
//   }

//   // Load network configuration settings from SharedPreferences
//   final prefs = await SharedPreferences.getInstance();
//   final dohEnabled = prefs.getBool('doh_enabled') ?? true;
//   final sslBypass = prefs.getBool('ssl_bypass_enabled') ?? false;
//   final dohProviderIndex =
//       prefs.getInt('doh_provider_type') ?? DoHProviderType.cloudflare.index;
//   final dohProvider = DoHProviderType.values[dohProviderIndex];
//   final cfProtectionEnabled = prefs.getBool('cf_protection_enabled') ?? true;

//   logger.info(
//       'Network config: DoH=${dohEnabled ? dohProvider.toString().split('.').last : 'off'}, SSL bypass=$sslBypass, CF protection=$cfProtectionEnabled',
//       domain: 'App');

//   // Register network components
//   final userAgentFactory = await UserAgentFactory.create(logger: logger);
//   getIt.registerSingleton<UserAgentFactory>(userAgentFactory);

//   final cookieManager = StandardCookieManager(logger: logger);
//   await cookieManager.loadCookiesFromStorage();
//   getIt.registerSingleton<CookieManager>(cookieManager);

//   final challengeDetector = ChallengeDetector(logger: logger);
//   getIt.registerSingleton<ChallengeDetector>(challengeDetector);

//   final proxyHandler = await ProxyHandler.create(logger);
//   getIt.registerSingleton<ProxyHandler>(proxyHandler);

//   // Create and register API client
//   final apiClient = await ApiClient.create(
//     options: ApiClientOptions(
//       baseUrl: 'https://api.comick.fun',
//       enableCloudflareProtection: cfProtectionEnabled,
//       enableDebugLogs:
//           true, // Set to true for development, false for production
//       enableRetryPolicy: true,
//       enableSslBypass: sslBypass,
//       enableDnsOverHttps: dohEnabled,
//       dohProvider: dohProvider,
//       retryPolicy: const RetryPolicy(
//         maxRetries: 3,
//         exponentialBackoff: true,
//         statusCodesToRetry: [408, 429, 500, 502, 503, 504],
//         errorTypesToRetry: [
//           DioExceptionType.connectionTimeout,
//           DioExceptionType.sendTimeout,
//           DioExceptionType.receiveTimeout,
//           DioExceptionType.connectionError,
//         ],
//       ),
//       cloudflareInitialTimeout: const Duration(seconds: 20),
//       cloudflareInteractiveTimeout: const Duration(minutes: 2),
//     ),
//     logger: logger,
//     navigatorKey: navigatorKey,
//   );
//   getIt.registerSingleton<ApiClient>(apiClient);

//   // Register repositories
//   getIt.registerSingleton<MangaRepository>(
//     MangaRepositoryImpl(
//       apiClient: getIt<ApiClient>(),
//       logger: logger,
//     ),
//   );

//   logger.info('Application setup complete', domain: 'App');
// }
