/// ## MyApp - Root Widget Aplikasi
///
/// File ini merupakan titik masuk (entry point) untuk aplikasi Flutter.
/// Widget [MyApp] bertugas untuk mengatur tema, bahasa, routing, dan tampilan awal
/// berdasarkan status autentikasi pengguna. Implementasi menggunakan MobX (Observer)
/// untuk memantau perubahan pada store sehingga UI dapat terupdate secara otomatis.
///
/// Komponen utama yang digunakan:
/// - **ThemeStore:** Mengelola pengaturan tema (light/dark mode) aplikasi.
/// - **LanguageStore:** Mengelola pengaturan bahasa dan lokal aplikasi.
/// - **UserStore:** Mengelola status autentikasi pengguna untuk menentukan tampilan awal (Home atau Login).
///
/// Selain itu, aplikasi ini mendukung multi-lingual dengan bantuan [AppLocalizations]
/// dan menyediakan route secara terpusat menggunakan [Routes.routes].
///
/// Package tambahan yang digunakan:
/// - `flutter_localizations`: Untuk dukungan lokal internasional (multi-language).
/// - `flutter_mobx`: Untuk reaktivitas state management dengan MobX.
library;

import 'package:boilerplate/constants/app_theme.dart'; // Konfigurasi tema aplikasi (light dan dark mode)
import 'package:boilerplate/constants/strings.dart'; // Konstanta string, seperti nama aplikasi
import 'package:boilerplate/presentation/home/home.dart'; // Halaman HomeScreen
import 'package:boilerplate/presentation/home/store/language/language_store.dart'; // Store pengaturan bahasa
import 'package:boilerplate/presentation/home/store/theme/theme_store.dart'; // Store pengaturan tema
import 'package:boilerplate/presentation/login/login.dart'; // Halaman LoginScreen
import 'package:boilerplate/presentation/login/store/login_store.dart'; // Store untuk proses login (jika diperlukan)
import 'package:boilerplate/utils/locale/app_localization.dart'; // Konfigurasi lokal dan penerjemahan
import 'package:boilerplate/utils/routes/routes.dart'; // Konfigurasi route aplikasi
import 'package:flutter/material.dart'; // Material Design widgets
import 'package:flutter_localizations/flutter_localizations.dart'; // Dukungan lokal untuk widget Flutter
import 'package:flutter_mobx/flutter_mobx.dart'; // Observer untuk reaktivitas state management

import '../di/service_locator.dart'; // Mengakses dependency injection dengan GetIt

/// Widget [MyApp] adalah root widget aplikasi yang menyediakan konfigurasi global seperti tema,
/// bahasa, route, dan tampilan awal berdasarkan status autentikasi pengguna.
class MyApp extends StatelessWidget {
  // Mengambil instance store dari service locator agar tersedia secara global.
  final ThemeStore _themeStore = getIt<ThemeStore>();
  final LanguageStore _languageStore = getIt<LanguageStore>();
  final UserStore _userStore = getIt<UserStore>();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Menggunakan Observer untuk mendengarkan perubahan pada store dan merender ulang UI
    // ketika terjadi perubahan state (misalnya, perubahan tema atau bahasa).
    return Observer(
      builder: (context) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: Strings.appName,
          // Konfigurasi tema berdasarkan nilai darkMode dari ThemeStore
          theme: _themeStore.darkMode
              ? AppThemeData.darkThemeData
              : AppThemeData.lightThemeData,
          // Mendefinisikan route yang dikelola secara terpusat
          routes: Routes.routes,
          // Menetapkan locale aplikasi berdasarkan pengaturan dari LanguageStore
          locale: Locale(_languageStore.locale),
          // Mendukung beberapa bahasa yang telah didefinisikan di LanguageStore
          supportedLocales: _languageStore.supportedLanguages
              .map((language) => Locale(language.locale, language.code))
              .toList(),
          // Delegasi untuk lokal dan penerjemahan aplikasi
          localizationsDelegates: const [
            // Memuat terjemahan dari file JSON atau sumber lokal lainnya
            AppLocalizations.delegate,
            // Lokalisasi dasar untuk widget Material
            GlobalMaterialLocalizations.delegate,
            // Lokalisasi untuk arah penulisan (LTR/RTL)
            GlobalWidgetsLocalizations.delegate,
            // Lokalisasi dasar untuk widget Cupertino
            GlobalCupertinoLocalizations.delegate,
          ],
          // Menentukan tampilan awal: HomeScreen jika pengguna sudah login, atau LoginScreen jika belum
          home:
              _userStore.isLoggedIn ? const HomeScreen() : const LoginScreen(),
        );
      },
    );
  }
}
