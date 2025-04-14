import 'package:flutter/material.dart';
import 'package:boilerplate/presentation/login/login.dart';
import 'package:boilerplate/presentation/register/register.dart';
import 'package:boilerplate/presentation/home/home.dart';
import 'package:boilerplate/presentation/comick/comick.dart';
import 'package:boilerplate/presentation/comick_reading/readingsection.dart';

class Routes {
  Routes._();

  // Static routes untuk route yang statis
  static const String splash = '/splash';
  static const String login = '/login';
  static const String home = '/post';
  static const String register = '/register';

  // Daftar route statis (bisa juga menggunakan go_router atau navigator 2.0)
  static final routes = <String, WidgetBuilder>{
    login: (BuildContext context) => const LoginScreen(),
    register: (BuildContext context) => const RegisterScreen(),
    home: (BuildContext context) => const HomeScreen(),
  };

  // Fungsi onGenerateRoute menangani route dinamis
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final Uri uri = Uri.parse(settings.name ?? '');
    if (uri.pathSegments.isNotEmpty &&
        uri.pathSegments.length == 2 &&
        uri.pathSegments.first == 'comic') {
      // Misalnya, /comic/{slug_nama_comic}/
      String comicSlug = uri.pathSegments[1];
      return MaterialPageRoute(
        builder: (context) => ComicDetailScreen(comicSlug: comicSlug),
        settings: settings,
      );
    } else if (uri.pathSegments.isNotEmpty &&
        uri.pathSegments.length == 3 &&
        uri.pathSegments.first == 'comic') {
      final String comicSlug = uri.pathSegments[1];
      final String chapter = uri.pathSegments[2];
      return MaterialPageRoute(
        builder: (context) => ReadingSectionScreen(
          comicSlug: comicSlug,
          chapter: chapter,
        ),
        settings: settings,
      );
    }
    // Jika route tidak sesuai dengan pattern di atas, kembalikan route default
    return MaterialPageRoute(
      builder: (context) => const HomeScreen(),
      settings: settings,
    );
  }
}
