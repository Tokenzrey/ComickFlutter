import 'package:flutter/material.dart';

class ComicDetailScreen extends StatefulWidget {
  final String comicSlug;

  const ComicDetailScreen({
    super.key,
    required this.comicSlug
  });

  @override
  State<ComicDetailScreen> createState() => _ComicDetailScreenState();
}

class _ComicDetailScreenState extends State<ComicDetailScreen> {
  // State untuk tombol Follow dan collapse description
  bool isFollowed = false;
  bool isDescriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Contoh data dummy
    const String dummyTitle = "Dungeon Architect";
    const String dummyAltTitle =
        "최강 던전을 위하여 - Архитектор подземелий - Radi sil'neyshego podzemel'ya";
    const String dummyOrigination = "Manhwa";
    const String dummyPublished = "2025";
    const String dummyStatus = "Ongoing";
    const String dummyFollowedCount = "14,931 users";
    const String dummyDescription =
        "Kang Chiwoo lost his life in an accident and got reincarnated as the son of a great demon lord in another world.\n\n"
        "Unlike his previous life as a map designer, he is now a loser named Kella.\n\n"
        "However, in a world where magic exists and having the inherited power of Kella, Chiwoo sets out to achieve his goal of creating a dream map that he couldn't make in his past life!\n\n"
        "Will Kella be able to create his own map while fending off his brothers who constantly try to kill him, the countless threats upon his life, and the pressure of those around him who want him to succeed the throne?";
    final List<String> dummyGenres = ["Action", "Adventure", "Fantasy"];
    final List<Map<String, String>> dummyChapters = [
      {"chapter": "Ch. 78", "time": "6 days ago"},
      {"chapter": "Ch. 77", "time": "1 week ago"},
      {"chapter": "Ch. 76", "time": "2 weeks ago"},
      {"chapter": "Ch. 75", "time": "3 weeks ago"},
      {"chapter": "Ch. 74", "time": "1 month ago"},
      {"chapter": "Ch. 73", "time": "1 month ago"},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          dummyTitle,
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bagian Atas: Cover & Info Singkat
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gambar cover dengan error handling
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    "https://meo.comick.pictures/GXmW31-m.jpg",
                    width: 120,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 120,
                        height: 180,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Info di sebelah cover
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul
                      Text(
                        dummyTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Alternative judul
                      Text(
                        dummyAltTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Origination, Published, Status, Followed by
                      Text("Origination: $dummyOrigination",
                          style: const TextStyle(fontSize: 14)),
                      Text("Published: $dummyPublished",
                          style: const TextStyle(fontSize: 14)),
                      Text("Status: $dummyStatus",
                          style: const TextStyle(fontSize: 14)),
                      Text("Followed by: $dummyFollowedCount",
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 12),
                      // Tombol Follow dengan icon love di kiri dan style berbeda jika isFollowed true/false
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            isFollowed = !isFollowed;
                          });
                        },
                        icon: Icon(
                          isFollowed ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: Colors.white,
                        ),
                        label: Text(
                          isFollowed ? "Following" : "Follow",
                          style: const TextStyle(fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor:
                              isFollowed ? Colors.redAccent : Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            // Deskripsi dengan fitur collapse/expand
            const Text(
              "Description",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            // Gunakan GestureDetector untuk toggle expand/collapse
            GestureDetector(
              onTap: () {
                setState(() {
                  isDescriptionExpanded = !isDescriptionExpanded;
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dummyDescription,
                    maxLines: isDescriptionExpanded ? null : 3,
                    overflow: isDescriptionExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isDescriptionExpanded ? "Show Less" : "Show More",
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            // More Info (misal: genres)
            const Text(
              "More Info",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const Divider(),
            Row(
              children: [
                const Text(
                  "Genres: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: Text(
                    dummyGenres.join(", "),
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            // Bagian Chapters
            const Text(
              "Chapters",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const Divider(),
            // Tabel chapters (versi sederhana)
            Column(
              children: dummyChapters.map((chap) {
                return ChapterRow(
                  chapter: chap["chapter"] ?? "",
                  time: chap["time"] ?? "",
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Widget untuk menampilkan baris chapter
class ChapterRow extends StatelessWidget {
  final String chapter;
  final String time;

  const ChapterRow({
    super.key,
    required this.chapter,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Aksi jika chapter ditekan
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(
              Icons.flag,
              size: 20,
              color: Colors.redAccent,
            ),
            const SizedBox(width: 8),
            Text(
              chapter,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              time,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
