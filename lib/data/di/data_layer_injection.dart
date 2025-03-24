/// ## Data Layer Injection
///
/// File ini bertanggung jawab untuk mengonfigurasi dependency injection pada Data Layer.
/// Data Layer mencakup komponen-komponen yang berkaitan dengan pengelolaan data, seperti:
/// - **Local Module:** Pengaturan penyimpanan lokal (misalnya database, shared preferences).
/// - **Network Module:** Pengaturan komunikasi jaringan (API client, interceptors).
/// - **Repository Module:** Pengaturan repository yang menghubungkan sumber data (local dan network)
///   dengan domain layer.
///
/// Pendekatan modular ini memungkinkan pengelolaan setiap bagian secara terpisah dan mudah dikembangkan,
/// sehingga meningkatkan skalabilitas dan maintainability aplikasi.
library;

import 'package:boilerplate/data/di/module/local_module.dart'; // Modul untuk dependency penyimpanan lokal
import 'package:boilerplate/data/di/module/network_module.dart'; // Modul untuk dependency jaringan
import 'package:boilerplate/data/di/module/repository_module.dart'; // Modul untuk dependency repository

/// Kelas [DataLayerInjection] berfungsi sebagai pengatur utama untuk mengonfigurasi
/// dependency injection di dalam Data Layer.
///
/// Metode [configureDataLayerInjection] melakukan inisialisasi secara berurutan pada:
/// 1. **Local Module:** Inisialisasi komponen lokal seperti database dan caching.
/// 2. **Network Module:** Inisialisasi komponen jaringan, misalnya API client.
/// 3. **Repository Module:** Inisialisasi repository yang mengelola pengambilan data
///    dari berbagai sumber (local dan network).
class DataLayerInjection {
  /// Metode statis untuk mengonfigurasi dependency injection pada Data Layer.
  ///
  /// Menggunakan [await] memastikan bahwa setiap modul telah selesai dikonfigurasi
  /// sebelum melanjutkan ke modul berikutnya, sehingga dependensi siap digunakan secara konsisten.
  static Future<void> configureDataLayerInjection() async {
    await LocalModule.configureLocalModuleInjection();
    await NetworkModule.configureNetworkModuleInjection();
    await RepositoryModule.configureRepositoryModuleInjection();
  }
}
