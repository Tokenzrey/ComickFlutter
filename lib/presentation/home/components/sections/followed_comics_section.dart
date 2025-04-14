import 'package:boilerplate/presentation/home/models/comic.dart';
import 'package:boilerplate/presentation/home/components/comic_cards.dart';
import 'package:flutter/material.dart';

/// ===============================
/// Section 1: Followed Comics
/// ===============================
class FollowedComicsSection extends StatefulWidget {
  const FollowedComicsSection({super.key});

  @override
  State<FollowedComicsSection> createState() => _FollowedComicsSectionState();
}

class _FollowedComicsSectionState extends State<FollowedComicsSection> {
  final List<Comic> _comics = [];
  bool _isLoading = false;
  final int _itemsPerPage = 10;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(() {
      // Deteksi jika sudah mencapai ujung kanan
      if (_scrollController.position.atEdge &&
          _scrollController.position.pixels != 0) {
        _loadMore();
      }
    });
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
    // Simulasi delay load data (misalnya 1 detik)
    await Future.delayed(const Duration(seconds: 1));

    List<Comic> newComics = List.generate(_itemsPerPage, (index) {
      int comicNumber = _comics.length + index + 1;
      return Comic(
        name: "Followed Comic $comicNumber",
        imageUrl: 'https://meo.comick.pictures/kRX7nW-m.jpg',
      );
    });

    setState(() {
      _comics.addAll(newComics);
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            "Followed Comics",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _comics.isEmpty
            ? Container(
                height: 240,
                alignment: Alignment.center,
                child: const Text(
                  "No Followed Comics",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              )
            : SizedBox(
                height: 240,
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: _comics.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: SimpleComicCard(comic: _comics[index]),
                    );
                  },
                ),
              ),
      ],
    );
  }
}
