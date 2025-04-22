import 'package:flutter/material.dart';
import 'package:boilerplate/presentation/login/login.dart';
import 'package:boilerplate/presentation/register/register.dart';
import 'package:boilerplate/presentation/home/home.dart';
import 'package:boilerplate/presentation/comick/comick.dart';
import 'package:boilerplate/presentation/comick_reading/readingsection.dart';
import 'package:boilerplate/presentation/manga/manga_detail_screen.dart';
import 'package:boilerplate/presentation/manga/chapter_reader_screen.dart';
import 'package:boilerplate/presentation/manga/settings_screen.dart';

class Routes {
  Routes._();

  // Static routes for static routes
  static const String splash = '/splash';
  static const String login = '/login';
  static const String home = '/post';
  static const String register = '/register';
  static const String mangaList = '/manga';
  static const String settings = '/settings';

  // List of static routes
  static final routes = <String, WidgetBuilder>{
    login: (BuildContext context) => const LoginScreen(),
    register: (BuildContext context) => const RegisterScreen(),
    home: (BuildContext context) => const HomeScreen(),
    // mangaList: (BuildContext context) => const MangaListScreen(),
    settings: (BuildContext context) => const SettingsScreen(),
  };

  // onGenerateRoute function handles dynamic routes
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final Uri uri = Uri.parse(settings.name ?? '');

    // Comic detail screen: /comic/{slug}
    if (uri.pathSegments.isNotEmpty &&
        uri.pathSegments.length == 2 &&
        uri.pathSegments.first == 'comic') {
      String comicSlug = uri.pathSegments[1];
      return MaterialPageRoute(
        builder: (context) => ComicDetailScreen(comicSlug: comicSlug),
        settings: settings,
      );
    }
    // Legacy chapter reader route (keeping for backward compatibility)
    else if (uri.pathSegments.isNotEmpty &&
        uri.pathSegments.length == 3 &&
        uri.pathSegments.first == 'comic') {
      // Show error or redirect to appropriate screen
      return MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Route Deprecated')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'This route format is no longer supported.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
        settings: settings,
      );
    }
    // New reader route that uses chapHid: /reader/{chapHid}
    else if (uri.pathSegments.isNotEmpty &&
        uri.pathSegments.length == 2 &&
        uri.pathSegments.first == 'reader') {
      final String chapHid = uri.pathSegments[1];
      return MaterialPageRoute(
        builder: (context) => ReadingSectionScreen(
          chapHid: chapHid,
        ),
        settings: settings,
      );
    }
    // Manga detail route: /manga/{mangaId}
    else if (uri.pathSegments.isNotEmpty &&
        uri.pathSegments.length == 2 &&
        uri.pathSegments.first == 'manga') {
      final String mangaId = uri.pathSegments[1];
      return MaterialPageRoute(
        builder: (context) => MangaDetailScreen(mangaId: mangaId),
        settings: settings,
      );
    }
    // Manga chapter reader route: /manga/{mangaId}/{chapterId}/{chapterTitle}
    else if (uri.pathSegments.isNotEmpty &&
        uri.pathSegments.length == 4 &&
        uri.pathSegments.first == 'manga') {
      final String mangaId = uri.pathSegments[1];
      final String chapterId = uri.pathSegments[2];
      final String chapterTitle = uri.pathSegments[3];
      return MaterialPageRoute(
        builder: (context) => ChapterReaderScreen(
          mangaId: mangaId,
          chapterId: chapterId,
          chapterTitle: chapterTitle,
        ),
        settings: settings,
      );
    }

    // If no route matches, return default route
    return MaterialPageRoute(
      builder: (context) => const HomeScreen(),
      settings: settings,
    );
  }
}
