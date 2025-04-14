import 'package:boilerplate/presentation/home/models/comic.dart';
import 'package:boilerplate/presentation/home/components/comic_cards.dart';
import 'package:flutter/material.dart';
import 'package:boilerplate/utils/dio/webview_api_service.dart';

/// ===============================
/// Section 3: Most Recent Popular
/// ===============================
class MostRecentPopularSection extends StatefulWidget {
  const MostRecentPopularSection({super.key});

  @override
  State<MostRecentPopularSection> createState() =>
      _MostRecentPopularSectionState();
}

class _MostRecentPopularSectionState extends State<MostRecentPopularSection> {
  final List<Comic> _comics = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  final ScrollController _scrollController = ScrollController();

  // Filter dropdown
  final List<String> _filterOptions = [
    '7d',
    '1m',
    '3m',
    '6months',
    '9m',
    '1y',
    '2y'
  ];
  String _selectedFilter = '7d';

  // WebView API Service (Headless)
  final WebViewApiService _apiService = WebViewApiService();

  @override
  void initState() {
    super.initState();
    _initializeAndLoad();

    _scrollController.addListener(() {
      if (_scrollController.position.atEdge &&
          _scrollController.position.pixels != 0) {
        _loadMore();
      }
    });
  }

  Future<void> _initializeAndLoad() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Inisialisasi headless webview agar Cloudflare ditembus
      final success = await _apiService.initialize();
      if (!success) {
        setState(() {
          _hasError = true;
          _errorMessage = "Failed to initialize webview API service.";
        });
        return;
      }
      // Jika sukses, load data pertama kali
      await _loadMore();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = "Error initializing: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Panggil fetchTopComics via webview service
      final root = await _apiService.fetchTopComics(
          gender: 1, acceptMatureContent: true);

      // Dapatkan rank array
      final List<dynamic> rankList = root.rank;
      // Mapping ke model Comic
      final newComics = rankList.map((item) {
        String slug = (item["slug"] ?? "").toString();
        String title = (item["title"] ?? "").toString();
        if (title.isEmpty &&
            item["md_titles"] is List &&
            item["md_titles"].isNotEmpty) {
          title = item["md_titles"][0]["title"] ?? "Unknown";
        }

        // Ambil cover
        String imageUrl = "";
        if (item["md_covers"] is List && item["md_covers"].isNotEmpty) {
          final b2key = item["md_covers"][0]["b2key"] ?? "";
          if (b2key.isNotEmpty) {
            imageUrl = "https://meo.comick.pictures/$b2key";
          }
        }
        // Tambahkan filter ke name
        return Comic(
          name: "$title ($_selectedFilter)",
          imageUrl: imageUrl,
          slug: slug,
        );
      }).toList();

      setState(() {
        _comics.addAll(newComics);
        _hasError = false;
        _errorMessage = '';
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = "Failed to load comics: $e";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          action: SnackBarAction(label: "Retry", onPressed: _loadMore),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onFilterSelected(String filter) {
    setState(() {
      _selectedFilter = filter;
      _comics.clear();
    });
    _loadMore();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Bersihkan headless webview
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Most Recent Popular",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey.shade300),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    iconSize: 22,
                    elevation: 8,
                    isDense: true,
                    borderRadius: BorderRadius.circular(15),
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    menuMaxHeight: 300,
                    items: _filterOptions.map((String filter) {
                      return DropdownMenuItem<String>(
                        value: filter,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(filter),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _onFilterSelected(value);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // List horizontal
        SizedBox(
          height: 240,
          child: Stack(
            children: [
              if (_comics.isEmpty && !_hasError && _isLoading)
                // Saat pertama kali load, tampilkan loading
                const Center(child: CircularProgressIndicator())
              else if (_comics.isEmpty && _hasError)
                // Saat error
                Center(child: Text(_errorMessage))
              else if (_comics.isEmpty)
                // Tidak ada data
                const Center(child: Text("No comics available"))
              else
                // Data berhasil di-load
                ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: _comics.length,
                  itemBuilder: (context, index) {
                    final comic = _comics[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: GestureDetector(
                        onTap: () {
                          if (comic.slug != null && comic.slug!.isNotEmpty) {
                            Navigator.pushNamed(
                                context, "/comic/${comic.slug}");
                          }
                        },
                        child: SimpleComicCard(comic: comic),
                      ),
                    );
                  },
                ),

              // Loading indicator di pojok kanan jika sedang load more
              if (_isLoading && _comics.isNotEmpty)
                const Positioned(
                  right: 10,
                  top: 10,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
