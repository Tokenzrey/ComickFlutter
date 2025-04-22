import 'package:boilerplate/presentation/home/models/comic.dart';
import 'package:flutter/material.dart';

/// Widget for simple comic cards (displaying image & name)
/// used in Section 1 & 3.
class SimpleComicCard extends StatelessWidget {
  final Comic comic;

  const SimpleComicCard({super.key, required this.comic});

  @override
  Widget build(BuildContext context) {
    // Ensure URL is valid by trimming whitespace and encoding the URL
    final String imageUrl = Uri.encodeFull(comic.imageUrl.trim());

    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display image with error handling
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            child: SizedBox(
              height: 200,
              width: 150,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                // Loading indicator
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                // Error handling if image fails to load
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              comic.name,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

/// Widget for History card (displaying image, name & chapter)
class HistoryComicCard extends StatelessWidget {
  final Comic comic;

  const HistoryComicCard({super.key, required this.comic});

  @override
  Widget build(BuildContext context) {
    final String imageUrl = Uri.encodeFull(comic.imageUrl.trim());

    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image at top with border radius
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            child: Image.network(
              imageUrl,
              height: 200,
              width: 150,
              fit: BoxFit.cover,
              // Loading indicator for image
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              // Error handling if image fails to load
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 140,
                  height: 150,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Comic name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              comic.name,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          // Chapter (if available)
          if (comic.chapter != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                comic.chapter!,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget for detailed card (displaying full update info)
/// used in Section 4.
class DetailedComicCard extends StatelessWidget {
  final Comic comic;

  const DetailedComicCard({super.key, required this.comic});

  @override
  Widget build(BuildContext context) {
    final String imageUrl = Uri.encodeFull(comic.imageUrl.trim());

    return Container(
      width: double.infinity,
      height: 350,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image at top with border radius
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              // Display loading indicator while image is loading
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              // Error handling if image fails to load
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 140,
                  height: 120,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Display comic name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              comic.name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Display chapter if available
          if (comic.chapter != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                comic.chapter!,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          // Display update date if available
          if (comic.updateDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                comic.updateDate!,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
