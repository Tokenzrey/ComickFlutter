import 'package:boilerplate/data/repository/manga/manga_repository.dart';
import 'package:boilerplate/presentation/home/components/customappbar.dart';
import 'package:flutter/material.dart';
import 'package:boilerplate/presentation/home/components/sections/followed_comics_section.dart';
import 'package:boilerplate/presentation/home/components/sections/history_section.dart';
import 'package:boilerplate/presentation/home/components/sections/most_recent_popular_section.dart';
import 'package:boilerplate/presentation/home/components/sections/updates_section.dart';
import 'package:get_it/get_it.dart';

/// HomeScreen utama yang berisi 4 section + fetch API baru.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MangaRepository _mangaRepo = GetIt.instance<MangaRepository>();
  final ScrollController _mainScrollController = ScrollController();
  bool _isLoadingMore = false;

  // Gunakan public state class untuk UpdatesSection
  final GlobalKey<UpdatesSectionState> _updatesSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initTopCache();
    _mainScrollController.addListener(_onScroll);
  }

  Future<void> _initTopCache() async {
    try {
      // Kita tak butuh hasilnya di‐UI sekarang,
      // tapi ini akan mengisi _topCache dalam repository
      await _mangaRepo.getMangaTop();
      // (opsional) Live‐update section lain kalau perlu:
      // setState(() { /* baca repo.onTopCacheUpdated */ });
    } catch (e) {
      // Tidak fatal jika gagal—bisa dicoba lagi nanti
      debugPrint('Failed to prime topCache: $e');
    }
  }

  void _onScroll() {
    // Cek jika sudah mendekati bawah
    if (_mainScrollController.position.pixels >=
            _mainScrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore) {
      setState(() {
        _isLoadingMore = true;
      });
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
      floatingActionButton: _buildFloatingActionButtons(),
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

  bool _isFabMenuOpen = false;

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Menu items will appear when _isFabMenuOpen is true
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isFabMenuOpen ? 260 : 0,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_isFabMenuOpen) ...[
                  FloatingActionButton.extended(
                    heroTag: "comic",
                    backgroundColor: Colors.orangeAccent,
                    label: const Text('Read Comic'),
                    icon: const Icon(Icons.book),
                    onPressed: () {
                      setState(() => _isFabMenuOpen = false);
                      Navigator.pushNamed(
                        context,
                        '/comic/the-archmage-s-restaurant/asdasdasda',
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.extended(
                    heroTag: "manga",
                    backgroundColor: Colors.purpleAccent,
                    label: const Text('Open Manga'),
                    icon: const Icon(Icons.menu_book),
                    onPressed: () {
                      setState(() => _isFabMenuOpen = false);
                      Navigator.pushNamed(context, '/manga/awdaadaw');
                    },
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.extended(
                    heroTag: "mangaList",
                    backgroundColor: Colors.blueAccent,
                    label: const Text('Manga List'),
                    icon: const Icon(Icons.grid_view),
                    onPressed: () {
                      setState(() => _isFabMenuOpen = false);
                      Navigator.pushNamed(context, '/manga');
                    },
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.extended(
                    heroTag: "settings",
                    backgroundColor: Colors.teal,
                    label: const Text('Settings'),
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      setState(() => _isFabMenuOpen = false);
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
        // Main FAB to toggle the menu
        FloatingActionButton(
          backgroundColor: Theme.of(context).primaryColor,
          onPressed: () {
            setState(() {
              _isFabMenuOpen = !_isFabMenuOpen;
            });
          },
          child: Icon(
            _isFabMenuOpen ? Icons.close : Icons.menu,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
