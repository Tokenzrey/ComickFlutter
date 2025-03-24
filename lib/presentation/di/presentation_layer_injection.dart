/// ## Presentation Layer Injection
///
/// File ini bertanggung jawab untuk mengonfigurasi dependency injection pada Presentation Layer.
/// Presentation Layer berfokus pada pengelolaan UI, state management, dan interaksi pengguna.
/// Dengan menggunakan dependency injection, komponen-komponen presentasi dapat diinisialisasi secara
/// terpusat dan konsisten, sehingga memudahkan pengembangan, pengujian, dan pemeliharaan aplikasi.
///
/// Modul yang digunakan:
/// - **Store Module:** Menyediakan inisialisasi dan pengelolaan dependency yang berkaitan dengan
///   state management dan store, sehingga memudahkan pengaturan state aplikasi.
///
/// Pendekatan ini memungkinkan pemisahan yang jelas antara logika bisnis dan logika presentasi,
/// sehingga meningkatkan skalabilitas dan maintainability kode.
library;

import 'package:boilerplate/presentation/di/module/store_module.dart'; // Modul untuk inisialisasi dependency store

/// Kelas [PresentationLayerInjection] berfungsi sebagai pengatur utama untuk mengonfigurasi
/// dependency injection pada Presentation Layer.
///
/// Metode [configurePresentationLayerInjection] memanggil konfigurasi pada modul Store,
/// memastikan semua dependency untuk state management dan UI telah diinisialisasi sebelum digunakan.
class PresentationLayerInjection {
  /// Metode statis untuk mengonfigurasi dependency injection pada Presentation Layer.
  ///
  /// Menggunakan [await] memastikan bahwa konfigurasi pada modul Store selesai dilakukan
  /// secara asinkronus sebelum aplikasi mulai mengakses dependency tersebut.
  static Future<void> configurePresentationLayerInjection() async {
    await StoreModule.configureStoreModuleInjection();
  }
}
