/// ## Service Locator untuk Dependency Injection
///
/// File ini bertanggung jawab untuk mengonfigurasi dependency injection
/// di seluruh aplikasi menggunakan package [GetIt]. Pendekatan ini memastikan
/// bahwa semua dependensi dikelola secara terpusat, sehingga memudahkan pemeliharaan
/// dan pengembangan di masa mendatang.
///
/// Dependency injection dilakukan untuk tiga layer utama:
/// - **Data Layer:** Mengatur dependensi yang berkaitan dengan akses data, API, dan database.
/// - **Domain Layer:** Mengatur logika bisnis dan aturan yang berhubungan dengan domain aplikasi.
/// - **Presentation Layer:** Mengatur komponen UI, state management, dan interaksi pengguna.
///
/// Package yang digunakan:
/// - `get_it`: Sebagai service locator untuk dependency injection.
///
/// Setiap layer memiliki kelas injection tersendiri yang mengatur bagaimana dependensi diinisialisasi.
library;
import 'package:boilerplate/data/di/data_layer_injection.dart'; // Inisialisasi dependency untuk Data Layer
import 'package:boilerplate/domain/di/domain_layer_injection.dart'; // Inisialisasi dependency untuk Domain Layer
import 'package:boilerplate/presentation/di/presentation_layer_injection.dart'; // Inisialisasi dependency untuk Presentation Layer
import 'package:get_it/get_it.dart'; // Package GetIt untuk dependency injection

/// Instance singleton dari [GetIt] yang digunakan untuk mengelola dependency.
final getIt = GetIt.instance;

/// Kelas [ServiceLocator] berfungsi untuk mengonfigurasi semua dependency injection
/// di seluruh aplikasi.
///
/// Kelas ini menyatukan konfigurasi dari tiap layer aplikasi, sehingga setiap bagian
/// dapat mengakses layanan dan dependensi yang dibutuhkan secara global.
class ServiceLocator {
  /// Metode statis untuk mengonfigurasi dependency injection.
  ///
  /// Metode ini melakukan inisialisasi secara berurutan pada:
  /// 1. **Data Layer:** Mengonfigurasi semua dependency yang berkaitan dengan
  ///    akses data, seperti API, database, dan repository.
  /// 2. **Domain Layer:** Mengonfigurasi logika bisnis dan aturan aplikasi.
  /// 3. **Presentation Layer:** Mengonfigurasi komponen UI dan state management.
  ///
  /// Dengan menggunakan [await] pada setiap langkah, kita memastikan bahwa semua
  /// dependensi telah diinisialisasi sebelum digunakan oleh komponen lain.
  static Future<void> configureDependencies() async {
    await DataLayerInjection.configureDataLayerInjection();
    await DomainLayerInjection.configureDomainLayerInjection();
    await PresentationLayerInjection.configurePresentationLayerInjection();
  }
}
