import 'dart:async';

import 'package:flutter/material.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar>
    with SingleTickerProviderStateMixin {
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _searchResults = [];
  Timer? _debounceTimer;
  late AnimationController _animationController;
  late Animation<double> _animation;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _focusNode.addListener(_onFocusChanged);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    _animationController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _performSearch(_searchController.text);
    } else {
      _removeOverlay();
    }
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      _removeOverlay();
      return;
    }

    // Debounce search to avoid excessive API calls
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(_searchController.text);
    });
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      _removeOverlay();
      return;
    }

    // Simulate search results (replace this part with your API call)
    setState(() {
      _searchResults = List.generate(
        5,
        (index) => "$query result ${index + 1}",
      );
    });

    _showSearchResults();
  }

  void _showSearchResults() {
    _removeOverlay();

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    final Offset offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: offset.dy + size.height + 4, // 4px spacing di bawah AppBar
        left: 8,
        right: 8,
        child: Material(
          color: Colors.transparent,
          child: FadeTransition(
            opacity: _animation,
            child: SizeTransition(
              sizeFactor: _animation,
              axisAlignment: -1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: _searchResults.isEmpty
                        ? _buildNoResultsWidget()
                        : _buildResultsListWidget(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
  }

  Widget _buildNoResultsWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: Text(
          "No results found",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildResultsListWidget() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      shrinkWrap: true,
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return ListTile(
          leading: CircleAvatar(
            backgroundImage:
                NetworkImage('https://meo.comick.pictures/kRX7nW-m.jpg'),
          ),
          title: Text(
            _searchResults[index],
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            'Found in popular comics',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Handle selection (misal, navigasi ke detail komik)
            _removeOverlay();
            _exitSearchMode();
          },
        );
      },
    );
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _animationController.reverse().then((_) {
        _overlayEntry?.remove();
        _overlayEntry = null;
      });
    }
  }

  void _toggleSearchMode() {
    setState(() {
      _isSearchActive = !_isSearchActive;
      if (_isSearchActive) {
        _focusNode.requestFocus();
      } else {
        _searchController.clear();
        _focusNode.unfocus();
        _removeOverlay();
      }
    });
  }

  void _exitSearchMode() {
    if (_isSearchActive) {
      setState(() {
        _isSearchActive = false;
        _searchController.clear();
        _focusNode.unfocus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).primaryColor,
      centerTitle: false,
      title: _isSearchActive
          ? _buildSearchField()
          : const Text(
              "Home",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
      actions: [
        AnimatedOpacity(
          opacity: _isSearchActive ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: IconButton(
            icon: const Icon(Icons.search, size: 24),
            onPressed: _isSearchActive ? null : _toggleSearchMode,
          ),
        ),
        if (_isSearchActive)
          IconButton(
            icon: const Icon(Icons.close, size: 24),
            onPressed: _exitSearchMode,
          ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      focusNode: _focusNode,
      textAlignVertical:
          TextAlignVertical.center, // Membuat teks berada di tengah vertikal
      cursorColor: Colors.white,
      style: const TextStyle(
        color: Colors.white,
        fontFamily: 'Poppins',
        fontSize: 16,
      ),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
        hintText: 'Search comics...',
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontFamily: 'Poppins',
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        prefixIcon: const Icon(
          Icons.search,
          color: Colors.white,
          size: 20,
        ),
      ),
      textInputAction: TextInputAction.search,
      onSubmitted: (value) {
        _performSearch(value);
      },
    );
  }
}
