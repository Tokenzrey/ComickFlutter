import 'package:hive/hive.dart';

part 'comick_model.g.dart';

@HiveType(typeId: 0)
class ComicModel extends HiveObject {
  @HiveField(0)
  late String slug;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String imageUrl;

  @HiveField(3)
  String? description;

  // Constructor for creating new comic instances
  ComicModel({
    required this.slug,
    required this.name,
    required this.imageUrl,
    this.description,
  });
}

@HiveType(typeId: 1)
class ReadingHistoryModel extends HiveObject {
  @HiveField(0)
  late String comicSlug;

  @HiveField(1)
  late String comicName;

  @HiveField(2)
  late String imageUrl;

  @HiveField(3)
  late String chapterId;

  @HiveField(4)
  late String chapterTitle;

  @HiveField(5)
  late DateTime lastReadDate;

  @HiveField(6)
  late int lastReadPage;

  // Progress percentage 0-100
  @HiveField(7)
  late int readingProgress;

  ReadingHistoryModel({
    required this.comicSlug,
    required this.comicName,
    required this.imageUrl,
    required this.chapterId,
    required this.chapterTitle,
    required this.lastReadDate,
    this.lastReadPage = 0,
    this.readingProgress = 0,
  });
}
