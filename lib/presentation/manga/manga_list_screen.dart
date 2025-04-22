// import 'package:boilerplate/core/network/api_client.dart';
// import 'package:flutter/material.dart';
// import 'package:get_it/get_it.dart';
// import 'package:boilerplate/data/repository/manga/manga_repository.dart';
// import 'manga_grid_item.dart';
// import 'manga_detail_screen.dart';

// class MangaListScreen extends StatefulWidget {
//   const MangaListScreen({super.key});

//   @override
//   State<MangaListScreen> createState() => _MangaListScreenState();
// }

// class _MangaListScreenState extends State<MangaListScreen> {
//   final MangaRepository _mangaRepository = GetIt.instance<MangaRepository>();
//   final TextEditingController _searchController = TextEditingController();

//   List<dynamic> _mangaList = [];
//   bool _isLoading = false;
//   String? _error;
//   int _currentPage = 1;
//   bool _hasMorePages = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadMangaList();
//   }

//   Future<void> _loadMangaList({String? query}) async {
//     if (_isLoading) return;
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });

//     try {
//       final result = await _mangaRepository.getMangaList(
//         page: _currentPage,
//         query: query,
//       );

//       // Ambil array "follows" yang berisi objek Follow
//       final follows = (result['follows'] as List<dynamic>?) ?? [];

//       // Map ke struktur card yang kita butuhkan: id, title, cover_url
//       final cards = follows.map<Map<String, String>>((entry) {
//         final md = entry['md_comics'] as Map<String, dynamic>;

//         // ID = slug
//         final slug = md['slug'] as String;

//         // Title = md_titles[0].title (fallback ke md['title'])
//         final titles = md['md_titles'] as List<dynamic>;
//         final title = titles.isNotEmpty
//             ? (titles[0] as Map<String, dynamic>)['title'] as String
//             : md['title'] as String;

//         // Cover URL = md_covers[0].b2key
//         final covers = md['md_covers'] as List<dynamic>;
//         final coverUrl = covers.isNotEmpty
//             ? (covers[0] as Map<String, dynamic>)['b2key'] as String
//             : '';

//         return {
//           'id': slug,
//           'title': title,
//           'cover_url': coverUrl,
//         };
//       }).toList();

//       setState(() {
//         if (_currentPage == 1) {
//           _mangaList = cards;
//         } else {
//           _mangaList.addAll(cards);
//         }
//         // Jika API punya flag has_next_page, gunakan; kalau tidak, infer dari cards
//         _hasMorePages = (result['has_next_page'] as bool?) ?? cards.isNotEmpty;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _error = 'Failed to load manga list: $e';
//         _isLoading = false;
//       });
//     }
//   }

//   void _loadMoreManga() {
//     if (_hasMorePages && !_isLoading) {
//       _currentPage++;
//       _loadMangaList(
//           query: _searchController.text.isNotEmpty
//               ? _searchController.text
//               : null);
//     }
//   }

//   void _refreshMangaList() {
//     _currentPage = 1;
//     _loadMangaList(
//         query:
//             _searchController.text.isNotEmpty ? _searchController.text : null);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Manga Reader'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.settings),
//             onPressed: () {
//               Navigator.pushNamed(context, '/settings');
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.security),
//             tooltip: 'Solve Cloudflare Challenge',
//             onPressed: _solveCloudflareChallenge,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: 'Search manga...',
//                 prefixIcon: const Icon(Icons.search),
//                 suffixIcon: IconButton(
//                   icon: const Icon(Icons.clear),
//                   onPressed: () {
//                     _searchController.clear();
//                     _refreshMangaList();
//                   },
//                 ),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8.0),
//                 ),
//               ),
//               onSubmitted: (value) {
//                 _currentPage = 1;
//                 _loadMangaList(query: value);
//               },
//             ),
//           ),
//           Expanded(
//             child: _error != null
//                 ? Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(_error!,
//                             style: const TextStyle(color: Colors.red)),
//                         const SizedBox(height: 16),
//                         ElevatedButton(
//                           onPressed: _refreshMangaList,
//                           child: const Text('Retry'),
//                         ),
//                       ],
//                     ),
//                   )
//                 : RefreshIndicator(
//                     onRefresh: () async {
//                       _refreshMangaList();
//                     },
//                     child: _mangaList.isEmpty && _isLoading
//                         ? const Center(child: CircularProgressIndicator())
//                         : _mangaList.isEmpty
//                             ? const Center(child: Text('No manga found'))
//                             : NotificationListener<ScrollNotification>(
//                                 onNotification:
//                                     (ScrollNotification scrollInfo) {
//                                   if (scrollInfo.metrics.pixels ==
//                                       scrollInfo.metrics.maxScrollExtent) {
//                                     _loadMoreManga();
//                                     return true;
//                                   }
//                                   return false;
//                                 },
//                                 child: GridView.builder(
//                                   padding: const EdgeInsets.all(8.0),
//                                   gridDelegate:
//                                       const SliverGridDelegateWithFixedCrossAxisCount(
//                                     crossAxisCount: 2,
//                                     childAspectRatio: 0.7,
//                                     crossAxisSpacing: 8.0,
//                                     mainAxisSpacing: 8.0,
//                                   ),
//                                   itemCount: _mangaList.length +
//                                       (_hasMorePages ? 1 : 0),
//                                   itemBuilder: (context, index) {
//                                     if (index >= _mangaList.length) {
//                                       return const Center(
//                                           child: CircularProgressIndicator());
//                                     }

//                                     final card = _mangaList[index]
//                                         as Map<String, String>;

//                                     return MangaGridItem(
//                                       id: card['id']!, // slug sebagai ID
//                                       title: card[
//                                           'title']!, // judul dari md_titles[0]
//                                       coverUrl:
//                                           'https://meo.comick.pictures/${card['cover_url']!}', // b2key dari md_covers[0]
//                                       onTap: () {
//                                         Navigator.push(
//                                           context,
//                                           MaterialPageRoute(
//                                             builder: (_) => MangaDetailScreen(
//                                                 mangaId: card['id']!),
//                                           ),
//                                         );
//                                       },
//                                     );
//                                   },
//                                 ),
//                               ),
//                   ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _solveCloudflareChallenge() async {
//     final apiClient = GetIt.instance<ApiClient>();

//     // Show a dialog explaining what's happening
//     final shouldProceed = await showDialog<bool>(
//           context: context,
//           barrierDismissible: false,
//           builder: (context) => AlertDialog(
//             title: const Text('Cloudflare Challenge'),
//             content: const Text(
//                 'We need to solve a security challenge to access the manga server. '
//                 'This will open a browser page where you might need to complete a CAPTCHA '
//                 'or other verification step. After solving, the app will continue normally.'),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.of(context).pop(false);
//                 },
//                 child: const Text('Cancel'),
//               ),
//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.of(context).pop(true);
//                 },
//                 child: const Text('Proceed'),
//               ),
//             ],
//           ),
//         ) ??
//         false;

//     // Check if dialog was dismissed or canceled
//     if (!shouldProceed) return;

//     // Check if the widget is still mounted
//     if (!mounted) return;

//     // Try to solve challenge for the base API URL
//     final success = await apiClient.solveInteractiveChallenge(
//         'https://api.comick.io/v1.0/search?sort=user_follow_count&page=1');

//     // Check again if widget is still mounted after the async operation
//     if (!mounted) return;

//     // Now it's safe to use the BuildContext
//     if (success) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Challenge solved successfully! Refreshing data...'),
//           backgroundColor: Colors.green,
//         ),
//       );
//       _refreshMangaList();
//     }
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
// }
