/// ## Local Module Injection
///
/// File ini bertanggung jawab untuk mengonfigurasi dependency injection pada bagian penyimpanan lokal (local storage)
/// aplikasi. Modul ini menangani inisialisasi dan registrasi beberapa layanan penting seperti:
///
/// 1. **Shared Preferences:**
///    - Mengelola data sederhana dalam format key-value untuk penyimpanan konfigurasi aplikasi.
///    - Menggunakan [SharedPreferences.getInstance] untuk menginisialisasi instance secara asinkron.
///    - Membungkus instance SharedPreferences di dalam [SharedPreferenceHelper] agar akses data menjadi lebih mudah.
///
/// 2. **Database Sembast:**
///    - Mengatur koneksi ke database lokal menggunakan [SembastClient].
///    - Konfigurasi database disesuaikan dengan platform:
///      - Untuk platform web, menggunakan path `/assets/db`.
///      - Untuk platform mobile, menggunakan path yang diperoleh dari [getApplicationDocumentsDirectory].
///
/// 3. **Data Sources:**
///    - Contoh inisialisasi [PostDataSource] yang bertanggung jawab untuk mengakses data post dari database lokal.
///
/// Registrasi dependency dilakukan dengan bantuan [GetIt] sebagai service locator, sehingga setiap layanan dapat
/// diakses secara global di seluruh aplikasi.
library;

import 'dart:async';

import 'package:boilerplate/core/data/local/sembast/sembast_client.dart'; // Koneksi dan inisialisasi database lokal dengan Sembast
import 'package:boilerplate/data/local/constants/db_constants.dart'; // Konstanta nama database dan konfigurasi lainnya
import 'package:boilerplate/data/local/datasources/post/post_datasource.dart'; // Data source untuk akses data post
import 'package:boilerplate/data/local/datasources/user/user_datasource.dart'; // Data source untuk akses data post
import 'package:boilerplate/data/sharedpref/shared_preference_helper.dart'; // Helper untuk mempermudah akses shared preferences
import 'package:flutter/foundation.dart'; // Digunakan untuk mengecek platform (misalnya kIsWeb)
import 'package:path_provider/path_provider.dart'; // Untuk mendapatkan path penyimpanan dokumen pada perangkat mobile
import 'package:shared_preferences/shared_preferences.dart'; // Package shared_preferences untuk akses penyimpanan key-value

import '../../../di/service_locator.dart'; // Import instance service locator (GetIt)

/// Kelas [LocalModule] berfungsi untuk mengonfigurasi dependency injection
/// yang berkaitan dengan penyimpanan lokal pada aplikasi.
class LocalModule {
  /// Metode statis untuk mengonfigurasi dependency injection pada local storage.
  ///
  /// Langkah-langkah inisialisasi yang dilakukan:
  ///
  /// 1. **Shared Preferences:**
  ///    - Mendaftarkan instance [SharedPreferences] secara asinkron dengan `registerSingletonAsync`.
  ///    - Mendaftarkan [SharedPreferenceHelper] yang membungkus instance [SharedPreferences].
  ///
  /// 2. **Database (Sembast):**
  ///    - Mendaftarkan instance [SembastClient] secara asinkron.
  ///    - Menentukan nama database dari [DBConstants.DB_NAME] dan path berdasarkan platform.
  ///
  /// 3. **Data Sources:**
  ///    - Mendaftarkan instance [PostDataSource] yang membutuhkan instance [SembastClient].
  static Future<void> configureLocalModuleInjection() async {
    // Preference manager:------------------------------------------------------
    // Registrasi SharedPreferences secara asinkron agar dapat digunakan di seluruh aplikasi.
    getIt.registerSingletonAsync<SharedPreferences>(
      SharedPreferences.getInstance,
    );

    // Registrasi SharedPreferenceHelper yang membungkus SharedPreferences,
    // memastikan akses data key-value menjadi lebih mudah dan terstruktur.
    getIt.registerSingleton<SharedPreferenceHelper>(
      SharedPreferenceHelper(await getIt.getAsync<SharedPreferences>()),
    );

    // Database:----------------------------------------------------------------
    // Registrasi SembastClient untuk mengelola database lokal.
    // Menyesuaikan path penyimpanan berdasarkan platform:
    // - kIsWeb: Menggunakan path /assets/db.
    // - Mobile: Menggunakan path dokumen yang diperoleh dari getApplicationDocumentsDirectory().
    getIt.registerSingletonAsync<SembastClient>(
      () async => SembastClient.provideDatabase(
        databaseName: DBConstants.DB_NAME,
        databasePath:
            kIsWeb
                ? "/assets/db"
                : (await getApplicationDocumentsDirectory()).path,
      ),
    );

    // Data sources:------------------------------------------------------------
    // Registrasi PostDataSource yang membutuhkan instance SembastClient.
    getIt.registerSingleton(
      PostDataSource(await getIt.getAsync<SembastClient>()),
    );
    getIt.registerSingleton(
      UserDataSource(await getIt.getAsync<SembastClient>()),
    );
  }
}
