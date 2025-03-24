/// ## Store Module Injection
///
/// File ini bertanggung jawab untuk mengonfigurasi dependency injection pada bagian store
/// di layer presentation. Store berfungsi sebagai pengelola state dan logika untuk tampilan,
/// sehingga membantu dalam memisahkan logika UI dari logika bisnis.
///
/// Modul ini melakukan registrasi dua jenis dependency:
///
/// 1. **Factories:**
///    - Mendaftarkan factory untuk [ErrorStore] dan [FormErrorStore] yang digunakan
///      untuk mengelola error global dan error pada form secara terpisah.
///    - Mendaftarkan factory untuk [FormStore] yang memanfaatkan [FormErrorStore] dan [ErrorStore]
///      untuk mengelola validasi dan error pada form.
///
/// 2. **Stores:**
///    - [UserStore]: Mengelola state dan logika untuk proses autentikasi pengguna, memanfaatkan
///      use case seperti [IsLoggedInUseCase], [SaveLoginStatusUseCase], dan [LoginUseCase] serta
///      store error untuk penanganan error secara terpusat.
///    - [PostStore]: Mengelola state terkait data post, menggunakan [GetPostUseCase] untuk mengambil data
///      dan [ErrorStore] untuk penanganan error.
///    - [ThemeStore] & [LanguageStore]: Mengelola state untuk tema dan bahasa, masing-masing
///      mengandalkan [SettingRepository] untuk pengaturan dan [ErrorStore] untuk penanganan error.
///
/// Registrasi dependency dilakukan dengan [GetIt], sehingga setiap store dan factory dapat
/// diakses secara global di seluruh aplikasi tanpa perlu inisialisasi manual.
library;
import 'dart:async';

import 'package:boilerplate/core/stores/error/error_store.dart'; // Store untuk penanganan error global
import 'package:boilerplate/core/stores/form/form_store.dart'; // Store untuk manajemen form dan validasinya
import 'package:boilerplate/domain/repository/setting/setting_repository.dart'; // Repository untuk pengaturan (tema, bahasa, dll)
import 'package:boilerplate/domain/usecase/post/get_post_usecase.dart'; // Use case untuk mengambil data post
import 'package:boilerplate/domain/usecase/user/is_logged_in_usecase.dart'; // Use case untuk mengecek status login pengguna
import 'package:boilerplate/domain/usecase/user/login_usecase.dart'; // Use case untuk proses login pengguna
import 'package:boilerplate/domain/usecase/user/save_login_in_status_usecase.dart'; // Use case untuk menyimpan status login pengguna
import 'package:boilerplate/presentation/home/store/language/language_store.dart'; // Store untuk pengaturan bahasa
import 'package:boilerplate/presentation/home/store/theme/theme_store.dart'; // Store untuk pengaturan tema
import 'package:boilerplate/presentation/login/store/login_store.dart'; // Store untuk proses login dan autentikasi pengguna
import 'package:boilerplate/presentation/post/store/post_store.dart'; // Store untuk mengelola data post

import '../../../di/service_locator.dart'; // Instance service locator (GetIt)

/// Kelas [StoreModule] mengatur konfigurasi dependency injection untuk semua store yang
/// digunakan dalam aplikasi. Dengan memisahkan registrasi store dan factory, aplikasi
/// dapat mengelola state secara terpusat dan memudahkan pengujian serta perawatan.
class StoreModule {
  /// Metode statis untuk mengonfigurasi dependency injection pada store module.
  ///
  /// Proses registrasi mencakup dua bagian utama:
  ///
  /// 1. **Factories:**
  ///    - [ErrorStore]: Menangani error global di seluruh aplikasi.
  ///    - [FormErrorStore]: Menangani error spesifik pada validasi form.
  ///    - [FormStore]: Mengelola logika validasi form dengan memanfaatkan [FormErrorStore]
  ///      dan [ErrorStore].
  ///
  /// 2. **Stores:**
  ///    - [UserStore]: Mengelola state untuk proses login dan autentikasi, serta menangani error
  ///      yang mungkin terjadi selama proses tersebut.
  ///    - [PostStore]: Mengelola state untuk data post dengan menggunakan [GetPostUseCase] dan penanganan error.
  ///    - [ThemeStore]: Mengelola state untuk pengaturan tema aplikasi menggunakan [SettingRepository].
  ///    - [LanguageStore]: Mengelola state untuk pengaturan bahasa aplikasi menggunakan [SettingRepository].
  static Future<void> configureStoreModuleInjection() async {
    // Factories:---------------------------------------------------------------
    // Registrasi factory untuk ErrorStore, yang menangani error global.
    getIt.registerFactory(() => ErrorStore());
    // Registrasi factory untuk FormErrorStore, yang menangani error validasi form.
    getIt.registerFactory(() => FormErrorStore());
    // Registrasi factory untuk FormStore, memanfaatkan ErrorStore dan FormErrorStore untuk
    // mengelola logika validasi form dan error handling.
    getIt.registerFactory(
      () => FormStore(getIt<FormErrorStore>(), getIt<ErrorStore>()),
    );

    // Stores:------------------------------------------------------------------
    // Registrasi UserStore untuk mengelola state dan logika autentikasi pengguna.
    getIt.registerSingleton<UserStore>(
      UserStore(
        getIt<IsLoggedInUseCase>(),
        getIt<SaveLoginStatusUseCase>(),
        getIt<LoginUseCase>(),
        getIt<FormErrorStore>(),
        getIt<ErrorStore>(),
      ),
    );

    // Registrasi PostStore untuk mengelola state data post dan menangani error yang terjadi.
    getIt.registerSingleton<PostStore>(
      PostStore(
        getIt<GetPostUseCase>(),
        getIt<ErrorStore>(),
      ),
    );

    // Registrasi ThemeStore untuk mengelola pengaturan tema aplikasi.
    getIt.registerSingleton<ThemeStore>(
      ThemeStore(
        getIt<SettingRepository>(),
        getIt<ErrorStore>(),
      ),
    );

    // Registrasi LanguageStore untuk mengelola pengaturan bahasa aplikasi.
    getIt.registerSingleton<LanguageStore>(
      LanguageStore(
        getIt<SettingRepository>(),
        getIt<ErrorStore>(),
      ),
    );
  }
}
