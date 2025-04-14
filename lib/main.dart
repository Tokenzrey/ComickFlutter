/// ## Flutter Application Entry Point
///
/// File ini merupakan titik masuk (entry point) untuk aplikasi Flutter.
/// Pada bagian ini, beberapa inisialisasi penting dilakukan sebelum aplikasi dijalankan:
/// - Inisialisasi binding Flutter menggunakan [WidgetsFlutterBinding.ensureInitialized()],
/// - Menetapkan orientasi layar yang didukung,
/// - Mengonfigurasi dependency injection melalui [ServiceLocator],
/// - Menjalankan aplikasi dengan [MyApp].
///
/// Dokumentasi ini memudahkan pemeliharaan dan pengembangan lebih lanjut
/// dengan memberikan penjelasan detail mengenai fungsi dan alur program.
library;

import 'dart:async'; // Untuk operasi asynchronous (Future, async/await)
import 'package:boilerplate/di/service_locator.dart'; // Dependency injection configuration
import 'package:boilerplate/presentation/my_app.dart'; // Widget utama aplikasi
import 'package:flutter/material.dart'; // Material design widgets
import 'package:flutter/services.dart'; // Untuk mengatur orientasi layar dan pengaturan sistem lainnya
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:boilerplate/data/models/comick_model.dart';

/// Fungsi utama (entry point) aplikasi.
///
/// Fungsi ini memastikan bahwa binding Flutter telah diinisialisasi,
/// kemudian menetapkan orientasi layar, mengonfigurasi dependency injection,
/// dan akhirnya menjalankan aplikasi dengan memanggil [runApp] pada [MyApp].
Future<void> main() async {
  // Pastikan Flutter binding telah diinisialisasi sebelum menjalankan operasi lain.
  WidgetsFlutterBinding.ensureInitialized();

  // Atur orientasi layar sesuai dengan preferensi yang ditentukan.
  await setPreferredOrientations();

  // Konfigurasikan dependency injection agar seluruh layanan dan dependensi dapat diakses secara global.
  await ServiceLocator.configureDependencies();

  // Initialize Hive
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);

  // Register Adapters
  Hive.registerAdapter(ComicModelAdapter());
  Hive.registerAdapter(ReadingHistoryModelAdapter());

  // Jalankan aplikasi dengan widget utama [MyApp].
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Center(child: Text('Terjadi error: ${details.exception}')),
    );
  };

  runApp(MyApp());
}

/// Mengatur orientasi layar yang didukung oleh aplikasi.
///
/// Fungsi ini menetapkan orientasi layar menggunakan [SystemChrome.setPreferredOrientations].
/// Dengan demikian, aplikasi dapat berjalan dalam mode potrait maupun lanskap.
///
/// Orientasi yang didukung:
/// - [DeviceOrientation.portraitUp]: Mode potrait standar.
/// - [DeviceOrientation.portraitDown]: Mode potrait terbalik.
/// - [DeviceOrientation.landscapeRight]: Mode lanskap (rotasi ke kanan).
/// - [DeviceOrientation.landscapeLeft]: Mode lanskap (rotasi ke kiri).
///
/// Mengembalikan [Future] yang selesai ketika pengaturan orientasi telah diterapkan.
Future<void> setPreferredOrientations() {
  return SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, // Orientasi potrait standar
    DeviceOrientation.portraitDown, // Orientasi potrait terbalik
    DeviceOrientation.landscapeRight, // Orientasi lanskap, rotasi ke kanan
    DeviceOrientation.landscapeLeft, // Orientasi lanskap, rotasi ke kiri
  ]);
}
