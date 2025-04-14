class Comic {
  final String name;
  final String imageUrl;
  final String? chapter;
  final String? description;
  final String? updateDate;
  final String? slug; // Add slug field for navigation

  Comic({
    required this.name,
    required this.imageUrl,
    this.chapter,
    this.description,
    this.updateDate,
    this.slug,
  });
}
