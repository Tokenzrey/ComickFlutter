import 'package:boilerplate/presentation/home/components/customappbar.dart';
import 'package:flutter/material.dart';
import 'package:boilerplate/presentation/home/components/sections/followed_comics_section.dart';
import 'package:boilerplate/presentation/home/components/sections/history_section.dart';
import 'package:boilerplate/presentation/home/components/sections/most_recent_popular_section.dart';
import 'package:boilerplate/presentation/home/components/sections/updates_section.dart';

/// HomeScreen utama yang berisi 4 section.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _mainScrollController = ScrollController();
  bool _isLoadingMore = false;

  // Gunakan public state class untuk UpdatesSection
  final GlobalKey<UpdatesSectionState> _updatesSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _mainScrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Cek jika sudah mendekati bagian bawah main scroll view
    if (_mainScrollController.position.pixels >=
            _mainScrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore) {
      setState(() {
        _isLoadingMore = true;
      });

      // Panggil method loadMore() pada UpdatesSection melalui GlobalKey
      _updatesSectionKey.currentState?.loadMore();
    }
  }

  @override
  void dispose() {
    _mainScrollController.removeListener(_onScroll);
    _mainScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigasi ke route detail comic dinamis yang diinginkan
          Navigator.pushNamed(
            context,
            '/comic/the-archmage-s-restaurant/asdasdasda',
          );
        },
        child: const Icon(Icons.navigation),
      ),
      body: SingleChildScrollView(
        controller: _mainScrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FollowedComicsSection(),
            const SizedBox(height: 16),
            const HistorySection(),
            const SizedBox(height: 16),
            const MostRecentPopularSection(),
            const SizedBox(height: 16),
            UpdatesSection(
              key: _updatesSectionKey,
              onNearEnd: (isNearBottom) {
                setState(() {
                  _isLoadingMore = false;
                });
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
