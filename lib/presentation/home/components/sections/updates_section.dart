import 'package:flutter/material.dart';
import 'package:boilerplate/presentation/home/models/comic.dart';
import 'package:boilerplate/presentation/home/components/comic_cards.dart';

/// Section 4: Updates (Hot & New) - Fixed Infinite Scroll
class UpdatesSection extends StatefulWidget {
  final Function(bool isNearBottom) onNearEnd;

  const UpdatesSection({super.key, required this.onNearEnd});

  @override
  State<UpdatesSection> createState() =>
      UpdatesSectionState(); // Note: No underscore here
}

// Make the state class public (no underscore)
class UpdatesSectionState extends State<UpdatesSection> {
  final List<Comic> _comics = [];
  bool _isLoading = false;
  final int _itemsPerPage = 20;
  bool _isHot = true; // true: Hot; false: New

  @override
  void initState() {
    super.initState();
    loadMore(); // Initial load
  }

  // Make this method public so it can be called from outside
  Future<void> loadMore() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate network request delay
    await Future.delayed(const Duration(seconds: 1));

    List<Comic> newComics = List.generate(_itemsPerPage, (index) {
      int comicNumber = _comics.length + index + 1;
      return Comic(
        name: "Update Comic $comicNumber",
        chapter: "Chapter $comicNumber",
        imageUrl: 'https://meo.comick.pictures/kRX7nW-m.jpg',
        updateDate: DateTime.now().toString().split(' ').first,
      );
    });

    if (mounted) {
      setState(() {
        _comics.addAll(newComics);
        _isLoading = false;
      });

      // Notify parent that we've finished loading
      widget.onNearEnd(false);
    }
  }

  void _toggleHotNew(bool value) {
    setState(() {
      _isHot = value;
      _comics.clear();
    });
    loadMore();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title and Hot/New switch
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Text(
                "Updates",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(_isHot ? "Hot" : "New"),
              Switch(
                value: _isHot,
                onChanged: _toggleHotNew,
              ),
            ],
          ),
        ),

        // Grid view for comics
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: _comics.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.68,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            return DetailedComicCard(comic: _comics[index]);
          },
        ),

        // Bottom loading indicator
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
