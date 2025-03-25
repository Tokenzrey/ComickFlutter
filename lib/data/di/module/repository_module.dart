/// ## Repository Module Injection
///
/// File ini bertanggung jawab untuk mengonfigurasi dependency injection
/// pada layer repository. Repository berfungsi sebagai jembatan antara sumber data
/// (data sources, API, shared preferences) dengan Domain Layer. Dengan pendekatan
/// repository, logika bisnis dapat mengakses data tanpa perlu mengetahui
/// detail implementasi dari sumber data.
///
/// Modul ini mendaftarkan tiga repository:
/// 1. **Setting Repository:**
///    - Mengelola data dan konfigurasi terkait pengaturan aplikasi, dengan memanfaatkan
///      [SharedPreferenceHelper] untuk penyimpanan lokal.
/// 2. **User Repository:**
///    - Bertanggung jawab atas pengelolaan data user, juga menggunakan [SharedPreferenceHelper].
/// 3. **Post Repository:**
///    - Menggabungkan data dari [PostApi] (sumber data jaringan) dan [PostDataSource]
///      (sumber data lokal) untuk menyediakan data terkait posting.
///
/// Dependency injection dilakukan melalui [GetIt] sehingga repository dapat diakses secara global
/// dan digunakan oleh Domain Layer tanpa perlu mengkhawatirkan inisialisasi atau pengelolaan siklus hidup.
library;

import 'dart:async';

import 'package:boilerplate/data/local/datasources/post/post_datasource.dart'; // Data source untuk akses data post dari penyimpanan lokal
import 'package:boilerplate/data/local/datasources/user/user_datasource.dart';
import 'package:boilerplate/data/network/apis/posts/post_api.dart'; // API untuk mengakses endpoint post dari jaringan
import 'package:boilerplate/data/repository/post/post_repository_impl.dart'; // Implementasi repository post
import 'package:boilerplate/data/repository/setting/setting_repository_impl.dart'; // Implementasi repository setting
import 'package:boilerplate/data/repository/user/user_repository_impl.dart'; // Implementasi repository user
import 'package:boilerplate/data/sharedpref/shared_preference_helper.dart'; // Helper untuk akses shared preferences
import 'package:boilerplate/domain/repository/post/post_repository.dart'; // Abstraksi repository post
import 'package:boilerplate/domain/repository/setting/setting_repository.dart'; // Abstraksi repository setting
import 'package:boilerplate/domain/repository/user/user_repository.dart'; // Abstraksi repository user

import '../../../di/service_locator.dart'; // Import instance service locator (GetIt)

/// Kelas [RepositoryModule] mengatur konfigurasi dependency injection pada layer repository.
///
/// Metode [configureRepositoryModuleInjection] mendaftarkan repository yang diperlukan,
/// sehingga masing-masing repository dapat mengakses sumber data yang sesuai melalui dependency injection.
class RepositoryModule {
  /// Metode statis untuk mengonfigurasi dependency injection pada repository module.
  ///
  /// Langkah-langkah konfigurasi:
  ///
  /// 1. **Setting Repository:**
  ///    - Mendaftarkan [SettingRepositoryImpl] yang memanfaatkan [SharedPreferenceHelper]
  ///      untuk mengelola data pengaturan aplikasi.
  ///
  /// 2. **User Repository:**
  ///    - Mendaftarkan [UserRepositoryImpl] yang juga menggunakan [SharedPreferenceHelper]
  ///      untuk mengelola data pengguna.
  ///
  /// 3. **Post Repository:**
  ///    - Mendaftarkan [PostRepositoryImpl] yang menggabungkan [PostApi] (untuk data dari jaringan)
  ///      dan [PostDataSource] (untuk data lokal) guna menyediakan data posting.
  static Future<void> configureRepositoryModuleInjection() async {
    // Repository:--------------------------------------------------------------
    // Mendaftarkan SettingRepository dengan implementasi yang membutuhkan SharedPreferenceHelper.
    getIt.registerSingleton<SettingRepository>(
      SettingRepositoryImpl(getIt<SharedPreferenceHelper>()),
    );

    // Mendaftarkan UserRepository dengan implementasi yang membutuhkan SharedPreferenceHelper.
    getIt.registerSingleton<UserRepository>(
      UserRepositoryImpl(
        getIt<SharedPreferenceHelper>(),
        getIt<UserDataSource>(),
      ),
    );

    // Mendaftarkan PostRepository dengan implementasi yang membutuhkan PostApi dan PostDataSource.
    getIt.registerSingleton<PostRepository>(
      PostRepositoryImpl(
        getIt<PostApi>(),
        getIt<PostDataSource>(),
      ),
    );
  }
}
