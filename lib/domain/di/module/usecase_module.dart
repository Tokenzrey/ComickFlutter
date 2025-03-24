/// ## Use Case Module Injection
///
/// File ini bertanggung jawab untuk mengonfigurasi dependency injection pada layer use case.
/// Use case merupakan implementasi logika bisnis yang mengatur alur data antara repository dan
/// presentation layer. Modul ini mendaftarkan use case yang mengelola proses autentikasi pengguna
/// serta operasi CRUD pada data post.
///
/// Use case yang didaftarkan meliputi:
///
/// 1. **User Use Cases:**
///    - [IsLoggedInUseCase]: Memeriksa apakah pengguna sudah melakukan login.
///    - [SaveLoginStatusUseCase]: Menyimpan status login pengguna ke dalam penyimpanan lokal.
///    - [LoginUseCase]: Menangani proses login pengguna menggunakan repository user.
///
/// 2. **Post Use Cases:**
///    - [GetPostUseCase]: Mengambil daftar post.
///    - [FindPostByIdUseCase]: Mencari post berdasarkan ID.
///    - [InsertPostUseCase]: Menambahkan post baru.
///    - [UpdatePostUseCase]: Memperbarui data post yang sudah ada.
///    - [DeletePostUseCase]: Menghapus post berdasarkan ID.
///
/// Registrasi use case dilakukan melalui [GetIt] sehingga setiap use case dapat diakses secara
/// global oleh Domain Layer tanpa perlu mengelola inisialisasi secara manual.
library;

import 'dart:async';

import 'package:boilerplate/domain/repository/post/post_repository.dart'; // Abstraksi repository untuk post
import 'package:boilerplate/domain/repository/user/user_repository.dart'; // Abstraksi repository untuk user
import 'package:boilerplate/domain/usecase/post/delete_post_usecase.dart'; // Use case untuk menghapus post
import 'package:boilerplate/domain/usecase/post/find_post_by_id_usecase.dart'; // Use case untuk mencari post berdasarkan ID
import 'package:boilerplate/domain/usecase/post/get_post_usecase.dart'; // Use case untuk mengambil daftar post
import 'package:boilerplate/domain/usecase/post/insert_post_usecase.dart'; // Use case untuk menambahkan post baru
import 'package:boilerplate/domain/usecase/post/udpate_post_usecase.dart'; // Use case untuk memperbarui post yang sudah ada
import 'package:boilerplate/domain/usecase/user/is_logged_in_usecase.dart'; // Use case untuk memeriksa status login pengguna
import 'package:boilerplate/domain/usecase/user/login_usecase.dart'; // Use case untuk menangani proses login
import 'package:boilerplate/domain/usecase/user/save_login_in_status_usecase.dart'; // Use case untuk menyimpan status login

import '../../../di/service_locator.dart'; // Instance service locator (GetIt)

/// Kelas [UseCaseModule] mengatur konfigurasi dependency injection untuk use case yang dibutuhkan
/// oleh Domain Layer. Metode [configureUseCaseModuleInjection] mendaftarkan use case dengan dependensinya,
/// sehingga dapat digunakan secara global tanpa perlu inisialisasi manual di setiap tempat.
class UseCaseModule {
  /// Metode statis untuk mengonfigurasi dependency injection pada use case module.
  ///
  /// Proses registrasi meliputi:
  ///
  /// 1. **User Use Cases:**
  ///    - [IsLoggedInUseCase]: Menggunakan [UserRepository] untuk memeriksa status login.
  ///    - [SaveLoginStatusUseCase]: Menggunakan [UserRepository] untuk menyimpan status login.
  ///    - [LoginUseCase]: Menggunakan [UserRepository] untuk menangani proses login.
  ///
  /// 2. **Post Use Cases:**
  ///    - [GetPostUseCase]: Menggunakan [PostRepository] untuk mengambil daftar post.
  ///    - [FindPostByIdUseCase]: Menggunakan [PostRepository] untuk mencari post berdasarkan ID.
  ///    - [InsertPostUseCase]: Menggunakan [PostRepository] untuk menambahkan post baru.
  ///    - [UpdatePostUseCase]: Menggunakan [PostRepository] untuk memperbarui post yang sudah ada.
  ///    - [DeletePostUseCase]: Menggunakan [PostRepository] untuk menghapus post.
  static Future<void> configureUseCaseModuleInjection() async {
    // User Use Cases:----------------------------------------------------------
    // Mendaftarkan use case untuk memeriksa apakah pengguna sudah login.
    getIt.registerSingleton<IsLoggedInUseCase>(
      IsLoggedInUseCase(getIt<UserRepository>()),
    );
    // Mendaftarkan use case untuk menyimpan status login pengguna.
    getIt.registerSingleton<SaveLoginStatusUseCase>(
      SaveLoginStatusUseCase(getIt<UserRepository>()),
    );
    // Mendaftarkan use case untuk menangani proses login pengguna.
    getIt.registerSingleton<LoginUseCase>(
      LoginUseCase(getIt<UserRepository>()),
    );

    // Post Use Cases:----------------------------------------------------------
    // Mendaftarkan use case untuk mengambil daftar post.
    getIt.registerSingleton<GetPostUseCase>(
      GetPostUseCase(getIt<PostRepository>()),
    );
    // Mendaftarkan use case untuk mencari post berdasarkan ID.
    getIt.registerSingleton<FindPostByIdUseCase>(
      FindPostByIdUseCase(getIt<PostRepository>()),
    );
    // Mendaftarkan use case untuk menambahkan post baru.
    getIt.registerSingleton<InsertPostUseCase>(
      InsertPostUseCase(getIt<PostRepository>()),
    );
    // Mendaftarkan use case untuk memperbarui post yang sudah ada.
    getIt.registerSingleton<UpdatePostUseCase>(
      UpdatePostUseCase(getIt<PostRepository>()),
    );
    // Mendaftarkan use case untuk menghapus post.
    getIt.registerSingleton<DeletePostUseCase>(
      DeletePostUseCase(getIt<PostRepository>()),
    );
  }
}
