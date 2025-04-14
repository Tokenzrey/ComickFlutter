import 'package:flutter/material.dart';

class ReadingSectionScreen extends StatefulWidget {
  final String comicSlug;
  final String chapter;

  const ReadingSectionScreen({
    super.key,
    required this.comicSlug,
    required this.chapter,
  });

  @override
  State<ReadingSectionScreen> createState() => _ReadingSectionScreenState();
}

class _ReadingSectionScreenState extends State<ReadingSectionScreen> {
  // Contoh dummy untuk navigasi chapter (ubah sesuai logika aplikasi)
  final String? prevChapter = "ch.14"; // null jika tidak ada chapter sebelumnya
  final String? nextChapter = "ch.16"; // null jika tidak ada chapter berikutnya

  // Data JSON gambar sebagai list of maps
  final List<Map<String, dynamic>> imagesData = [
    {
      "h": 443,
      "w": 800,
      "name": "0-nvbdZxojUu0B4.jpg",
      "s": 388487,
      "b2key": "0-nvbdZxojUu0B4.jpg",
      "optimized": 97366
    },
    {
      "h": 8365,
      "w": 800,
      "name": "1-Q4DH8_NbVegXu.webp",
      "s": 943090,
      "b2key": "1-Q4DH8_NbVegXu.webp",
      "optimized": 1105625
    },
    {
      "h": 8925,
      "w": 800,
      "name": "2-gikQ84FnjyIU6.webp",
      "s": 1156676,
      "b2key": "2-gikQ84FnjyIU6.webp",
      "optimized": 1306154
    },
    {
      "h": 8115,
      "w": 800,
      "name": "3-7mc2QS-IJUO9N.webp",
      "s": 578778,
      "b2key": "3-7mc2QS-IJUO9N.webp",
      "optimized": 738178
    },
    {
      "h": 7360,
      "w": 800,
      "name": "4-QDc4_Ii7MCRKh.webp",
      "s": 479086,
      "b2key": "4-QDc4_Ii7MCRKh.webp",
      "optimized": 623694
    },
    {
      "h": 8925,
      "w": 800,
      "name": "5-MZtwfF5zHFrUG.webp",
      "s": 738078,
      "b2key": "5-MZtwfF5zHFrUG.webp",
      "optimized": 915586
    },
    {
      "h": 7370,
      "w": 800,
      "name": "6-OMzTDNctkynly.webp",
      "s": 505958,
      "b2key": "6-OMzTDNctkynly.webp",
      "optimized": 622976
    },
    {
      "h": 8610,
      "w": 800,
      "name": "7-Sl1mAh_TK7kXU.webp",
      "s": 689610,
      "b2key": "7-Sl1mAh_TK7kXU.webp",
      "optimized": 833762
    },
    {
      "h": 7535,
      "w": 800,
      "name": "8-fillWJ32oS6H4.webp",
      "s": 1051274,
      "b2key": "8-fillWJ32oS6H4.webp",
      "optimized": 1074082
    },
    {
      "h": 8250,
      "w": 800,
      "name": "9-ZSN43xSoM6hVL.webp",
      "s": 562700,
      "b2key": "9-ZSN43xSoM6hVL.webp",
      "optimized": 708459
    },
    {
      "h": 8640,
      "w": 800,
      "name": "10-vCJMzYiT2B5zU.webp",
      "s": 744306,
      "b2key": "10-vCJMzYiT2B5zU.webp",
      "optimized": 853635
    },
    {
      "h": 8015,
      "w": 800,
      "name": "11-d2VCOItRCI5fZ.webp",
      "s": 521302,
      "b2key": "11-d2VCOItRCI5fZ.webp",
      "optimized": 667741
    },
    {
      "h": 8750,
      "w": 800,
      "name": "12-dmuuvAO4RMhon.webp",
      "s": 677574,
      "b2key": "12-dmuuvAO4RMhon.webp",
      "optimized": 887630
    },
    {
      "h": 9000,
      "w": 800,
      "name": "13-L5QDrdiguzNIb.webp",
      "s": 588904,
      "b2key": "13-L5QDrdiguzNIb.webp",
      "optimized": 768725
    },
    {
      "h": 9000,
      "w": 800,
      "name": "14-7GJL2RB4gL3Fn.webp",
      "s": 744308,
      "b2key": "14-7GJL2RB4gL3Fn.webp",
      "optimized": 990293
    },
    {
      "h": 8595,
      "w": 800,
      "name": "15-2mzEAzZH_IXk0.webp",
      "s": 721204,
      "b2key": "15-2mzEAzZH_IXk0.webp",
      "optimized": 850632
    },
    {
      "h": 8780,
      "w": 800,
      "name": "16-k8q0nZF29PgCZ.webp",
      "s": 844814,
      "b2key": "16-k8q0nZF29PgCZ.webp",
      "optimized": 983930
    },
    {
      "h": 8810,
      "w": 800,
      "name": "17-KLD0xXfwBO6WH.webp",
      "s": 819284,
      "b2key": "17-KLD0xXfwBO6WH.webp",
      "optimized": 990562
    },
    {
      "h": 8720,
      "w": 800,
      "name": "18-A7wK5XScSLqtK.webp",
      "s": 712890,
      "b2key": "18-A7wK5XScSLqtK.webp",
      "optimized": 903678
    },
    {
      "h": 8825,
      "w": 800,
      "name": "19-LeO-5Z0sghtYl.webp",
      "s": 749818,
      "b2key": "19-LeO-5Z0sghtYl.webp",
      "optimized": 877306
    },
    {
      "h": 8965,
      "w": 800,
      "name": "20-Cr_-HI1cOslhj.webp",
      "s": 726316,
      "b2key": "20-Cr_-HI1cOslhj.webp",
      "optimized": 900181
    },
    {
      "h": 6720,
      "w": 800,
      "name": "21-VAo9wX1W0cCYF.webp",
      "s": 563960,
      "b2key": "21-VAo9wX1W0cCYF.webp",
      "optimized": 707634
    },
    {
      "h": 8630,
      "w": 800,
      "name": "22-hzj81c3wAvsxW.webp",
      "s": 915098,
      "b2key": "22-hzj81c3wAvsxW.webp",
      "optimized": 1123143
    },
    {
      "h": 8020,
      "w": 800,
      "name": "23-zr_ydmVj80Gl2.webp",
      "s": 630870,
      "b2key": "23-zr_ydmVj80Gl2.webp",
      "optimized": 770289
    },
    {
      "h": 8970,
      "w": 800,
      "name": "24-H0jU5w43xqwgM.webp",
      "s": 606404,
      "b2key": "24-H0jU5w43xqwgM.webp",
      "optimized": 790274
    },
    {
      "h": 8940,
      "w": 800,
      "name": "25-7O0TSYU0ahuP0.webp",
      "s": 763158,
      "b2key": "25-7O0TSYU0ahuP0.webp",
      "optimized": 897171
    },
    {
      "h": 9000,
      "w": 800,
      "name": "26-SkW0NablYmSHB.webp",
      "s": 564886,
      "b2key": "26-SkW0NablYmSHB.webp",
      "optimized": 729056
    },
    {
      "h": 1419,
      "w": 800,
      "name": "27-a5yWU1NiHFKxM.webp",
      "s": 210618,
      "b2key": "27-a5yWU1NiHFKxM.webp",
      "optimized": 263396
    }
  ];

  // Prefix URL untuk gambar
  final String imagePrefix = "https://meo.comick.pictures/";

  @override
  Widget build(BuildContext context) {
    final double deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      // AppBar: tombol kembali ke Home di kiri, title menampilkan chapter, dan ikon di kanan untuk kembali ke halaman detail comic
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.black,
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Chapter: ${widget.chapter}",
              style: const TextStyle(color: Colors.black),
            ),
            const SizedBox(width: 12),
            const Text(
              "English",
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: ClipOval(
              child: Image.network(
                "https://via.placeholder.com/50?text=Logo",
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 40,
                    height: 40,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  );
                },
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // SECTION 1: ListView continuous tanpa margin antar gambar
          Expanded(
            child: ListView.builder(
              itemCount: imagesData.length,
              itemBuilder: (context, index) {
                final Map<String, dynamic> imageData = imagesData[index];
                // Hitung rasio berdasarkan data
                final double ratio = imageData["h"] / imageData["w"];
                final double imageHeight = deviceWidth * ratio;
                final String imageUrl = imagePrefix + imageData["name"];
                return ReloadableNetworkImage(
                  imageUrl: imageUrl,
                  width: deviceWidth,
                  height: imageHeight,
                  fit: BoxFit.fill,
                  cacheWidth: deviceWidth.toInt(),
                );
              },
            ),
          ),
          // SECTION 2: Navigasi Tombol (Prev, Home, Next)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Tombol Prev (disable jika prevChapter null)
                ElevatedButton(
                  onPressed: prevChapter == null
                      ? null
                      : () {
                          Navigator.pushNamed(
                            context,
                            '/comic/${widget.comicSlug}/$prevChapter',
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        prevChapter == null ? Colors.grey[400] : Colors.blue,
                  ),
                  child: Text(
                    prevChapter == null ? "Prev" : "Prev ($prevChapter)",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const Spacer(),
                // Tombol Home
                IconButton(
                  icon: const Icon(Icons.home),
                  color: Colors.grey,
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
                const Spacer(),
                // Tombol Next (jika nextChapter null, ganti dengan tombol Home)
                Builder(
                  builder: (context) {
                    if (nextChapter == null) {
                      return ElevatedButton(
                        onPressed: () {
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: const Text(
                          "Home",
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    } else {
                      return ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/comic/${widget.comicSlug}/$nextChapter',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: Text(
                          "Next ($nextChapter)",
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget untuk mengoptimalkan load gambar dengan loading animasi, error fallback
/// dan tombol reload jika terjadi error.
class ReloadableNetworkImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double width;
  final double height;
  final int? cacheWidth;
  final int? cacheHeight;

  const ReloadableNetworkImage({
    super.key,
    required this.imageUrl,
    required this.fit,
    required this.width,
    required this.height,
    this.cacheWidth,
    this.cacheHeight,
  });

  @override
  State<ReloadableNetworkImage> createState() => _ReloadableNetworkImageState();
}

class _ReloadableNetworkImageState extends State<ReloadableNetworkImage> {
  int reloadTrigger = 0;

  @override
  Widget build(BuildContext context) {
    final String reloadUrl = "${widget.imageUrl}?reload=$reloadTrigger";
    return Image.network(
      reloadUrl,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      cacheWidth: widget.cacheWidth,
      cacheHeight: widget.cacheHeight,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: widget.width,
          height: widget.height,
          alignment: Alignment.center,
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey[300],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.broken_image, color: Colors.grey, size: 40),
              const SizedBox(height: 8),
              const Text("Failed to load image"),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    reloadTrigger++;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text("Reload"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
