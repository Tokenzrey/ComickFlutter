import 'package:flutter/material.dart';
import 'package:extended_image/extended_image.dart';

class MangaGridItem extends StatelessWidget {
  final String id;
  final String title;
  final String coverUrl;
  final VoidCallback onTap;

  const MangaGridItem({
    super.key,
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ExtendedImage.network(
                    coverUrl,
                    fit: BoxFit.cover,
                    cache: true,
                    loadStateChanged: (ExtendedImageState state) {
                      if (state.extendedImageLoadState == LoadState.loading) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      } else if (state.extendedImageLoadState ==
                          LoadState.failed) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.error),
                          ),
                        );
                      }
                      return null; // Return null to display the image itself
                    },
                    // Optimizations for better performance
                    clearMemoryCacheIfFailed: true,
                    handleLoadingProgress: true,
                    // Fade in effect when image is loaded
                    enableLoadState: true,
                    // Better caching strategy
                    cacheMaxAge: const Duration(days: 3),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 8.0,
                      ),
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.0,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
