/// ## Domain Layer Injection
///
/// File ini bertanggung jawab untuk mengonfigurasi dependency injection pada Domain Layer.
/// Domain Layer merupakan inti dari logika bisnis aplikasi, yang berisi use case dan aturan-aturan
/// yang mengatur alur bisnis. Dengan memisahkan konfigurasi dependency ke dalam modul tersendiri,
/// aplikasi dapat mempertahankan struktur yang bersih dan modular.
///
/// Modul yang digunakan:
/// - **UseCase Module:** Menyediakan inisialisasi dan pengelolaan dependency untuk use case,
///   yaitu unit-unit logika bisnis yang memproses data dari data layer dan mempersiapkannya
///   untuk presentation layer.
///
/// Pendekatan ini membantu dalam pemeliharaan dan pengujian karena setiap bagian domain dapat
/// diisolasi dan dikelola secara independen.
library;

import 'package:boilerplate/domain/di/module/usecase_module.dart'; // Modul untuk inisialisasi dependency use case

/// Kelas [DomainLayerInjection] bertugas untuk mengonfigurasi dependency injection
/// pada Domain Layer aplikasi.
///
/// Metode [configureDomainLayerInjection] memanggil konfigurasi pada modul UseCase, sehingga
/// semua use case yang diperlukan siap digunakan di seluruh aplikasi.
class DomainLayerInjection {
  /// Metode statis untuk mengonfigurasi dependency injection pada Domain Layer.
  ///
  /// Metode ini memastikan bahwa semua dependency yang berkaitan dengan logika bisnis,
  /// terutama use case, telah diinisialisasi dengan benar sebelum digunakan oleh komponen lain.
  static Future<void> configureDomainLayerInjection() async {
    await UseCaseModule.configureUseCaseModuleInjection();
  }
}
