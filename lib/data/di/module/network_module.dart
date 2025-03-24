/// ## Network Module Injection
///
/// File ini bertanggung jawab untuk mengonfigurasi dependency injection pada Network Module.
/// Modul ini menangani semua konfigurasi yang berkaitan dengan komunikasi jaringan, termasuk:
///
/// 1. **Event Bus:**
///    - Memungkinkan komunikasi antar komponen menggunakan event-driven architecture.
///
/// 2. **Interceptors:**
///    - **LoggingInterceptor:** Untuk mencatat setiap request dan response guna keperluan debugging.
///    - **ErrorInterceptor:** Untuk menangani error yang terjadi selama proses request/response.
///    - **AuthInterceptor:** Untuk menambahkan token otentikasi pada setiap request.
///
/// 3. **Rest Client:**
///    - Mengelola request RESTful yang digunakan dalam aplikasi.
///
/// 4. **Dio Configuration & Client:**
///    - Mengatur konfigurasi dasar (base URL, timeout) menggunakan [DioConfigs].
///    - Membuat instance [DioClient] dan menambahkan interceptor yang telah didaftarkan.
///
/// 5. **API's:**
///    - Contoh inisialisasi [PostApi] yang menggunakan [DioClient] dan [RestClient] untuk mengakses endpoint API.
///
/// Registrasi dependency dilakukan menggunakan [GetIt] sebagai service locator, sehingga komponen-komponen
/// jaringan dapat diakses secara global di seluruh aplikasi.
library;
import 'package:boilerplate/core/data/network/dio/configs/dio_configs.dart'; // Konfigurasi dasar untuk Dio
import 'package:boilerplate/core/data/network/dio/dio_client.dart'; // Client untuk melakukan request jaringan menggunakan Dio
import 'package:boilerplate/core/data/network/dio/interceptors/auth_interceptor.dart'; // Interceptor untuk menambahkan token otentikasi pada request
import 'package:boilerplate/core/data/network/dio/interceptors/logging_interceptor.dart'; // Interceptor untuk mencatat log request/response
import 'package:boilerplate/data/network/apis/posts/post_api.dart'; // API untuk mengakses endpoint post
import 'package:boilerplate/data/network/constants/endpoints.dart'; // Konstanta untuk endpoint dan timeout koneksi
import 'package:boilerplate/data/network/interceptors/error_interceptor.dart'; // Interceptor untuk menangani error pada request/response
import 'package:boilerplate/data/network/rest_client.dart'; // Client untuk request RESTful
import 'package:boilerplate/data/sharedpref/shared_preference_helper.dart'; // Helper untuk mengakses shared preferences (misal, token otentikasi)
import 'package:event_bus/event_bus.dart'; // Package untuk event bus, memungkinkan komunikasi antar komponen

import '../../../di/service_locator.dart'; // Instance service locator (GetIt)

/// Kelas [NetworkModule] berfungsi untuk mengonfigurasi dependency injection
/// pada komponen-komponen yang berkaitan dengan komunikasi jaringan.
class NetworkModule {
  /// Metode statis untuk mengonfigurasi dependency injection pada Network Module.
  ///
  /// Langkah-langkah konfigurasi:
  ///
  /// 1. **Event Bus:**
  ///    - Mendaftarkan instance [EventBus] untuk event-driven communication.
  ///
  /// 2. **Interceptors:**
  ///    - Mendaftarkan [LoggingInterceptor] untuk pencatatan log.
  ///    - Mendaftarkan [ErrorInterceptor] untuk penanganan error, dengan dependency pada service locator.
  ///    - Mendaftarkan [AuthInterceptor] untuk menambahkan token otentikasi pada request,
  ///      dengan mengambil token dari [SharedPreferenceHelper].
  ///
  /// 3. **Rest Client:**
  ///    - Mendaftarkan instance [RestClient] untuk mengelola request RESTful.
  ///
  /// 4. **Dio Configuration & Client:**
  ///    - Mendaftarkan [DioConfigs] dengan konfigurasi dasar seperti base URL dan timeout.
  ///    - Membuat instance [DioClient] dengan konfigurasi yang telah didaftarkan dan menambahkan
  ///      interceptor (Auth, Error, Logging).
  ///
  /// 5. **API's:**
  ///    - Mendaftarkan instance [PostApi] yang menggabungkan [DioClient] dan [RestClient] untuk mengakses endpoint API.
  static Future<void> configureNetworkModuleInjection() async {
    // Event bus:---------------------------------------------------------------
    // Mendaftarkan instance EventBus untuk komunikasi antar komponen.
    getIt.registerSingleton<EventBus>(EventBus());

    // Interceptors:------------------------------------------------------------
    // Mendaftarkan interceptor untuk pencatatan log.
    getIt.registerSingleton<LoggingInterceptor>(LoggingInterceptor());
    // Mendaftarkan interceptor untuk penanganan error, dengan dependency pada service locator.
    getIt.registerSingleton<ErrorInterceptor>(ErrorInterceptor(getIt()));
    // Mendaftarkan interceptor untuk otentikasi, dengan mengambil token secara asinkron dari SharedPreferenceHelper.
    getIt.registerSingleton<AuthInterceptor>(
      AuthInterceptor(
        accessToken: () async =>
            await getIt<SharedPreferenceHelper>().authToken,
      ),
    );

    // Rest client:-------------------------------------------------------------
    // Mendaftarkan instance RestClient untuk mengelola request RESTful.
    getIt.registerSingleton(RestClient());

    // Dio configuration:-------------------------------------------------------
    // Mendaftarkan konfigurasi dasar untuk Dio, termasuk base URL dan timeout koneksi.
    getIt.registerSingleton<DioConfigs>(
      const DioConfigs(
        baseUrl: Endpoints.baseUrl,
        connectionTimeout: Endpoints.connectionTimeout,
        receiveTimeout: Endpoints.receiveTimeout,
      ),
    );

    // Dio client:--------------------------------------------------------------
    // Membuat instance DioClient dengan konfigurasi yang telah didaftarkan,
    // kemudian menambahkan interceptor yang telah dibuat (Auth, Error, Logging).
    getIt.registerSingleton<DioClient>(
      DioClient(dioConfigs: getIt())
        ..addInterceptors(
          [
            getIt<AuthInterceptor>(),
            getIt<ErrorInterceptor>(),
            getIt<LoggingInterceptor>(),
          ],
        ),
    );

    // API's:-------------------------------------------------------------------
    // Mendaftarkan instance PostApi yang menggunakan DioClient dan RestClient untuk mengakses endpoint post.
    getIt.registerSingleton(PostApi(getIt<DioClient>(), getIt<RestClient>()));
  }
}
