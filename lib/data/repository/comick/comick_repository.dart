import 'package:hive/hive.dart';
import 'package:boilerplate/data/models/comick_model.dart';

class ComicRepository {
  static const String _followedComicsBox = 'followedComics';
  static const String _readingHistoryBox = 'readingHistory';

  // Followed Comics Methods

  Future<Box<ComicModel>> _getFollowedComicsBox() async {
    return await Hive.openBox<ComicModel>(_followedComicsBox);
  }

  Future<List<ComicModel>> getAllFollowedComics() async {
    final box = await _getFollowedComicsBox();
    return box.values.toList();
  }

  Future<void> followComic(ComicModel comic) async {
    final box = await _getFollowedComicsBox();
    await box.put(comic.slug, comic);
  }

  Future<void> unfollowComic(String comicSlug) async {
    final box = await _getFollowedComicsBox();
    await box.delete(comicSlug);
  }

  Future<bool> isComicFollowed(String comicSlug) async {
    final box = await _getFollowedComicsBox();
    return box.containsKey(comicSlug);
  }

  // Reading History Methods

  Future<Box<ReadingHistoryModel>> _getReadingHistoryBox() async {
    return await Hive.openBox<ReadingHistoryModel>(_readingHistoryBox);
  }

  Future<List<ReadingHistoryModel>> getReadingHistory() async {
    final box = await _getReadingHistoryBox();

    // Sort by lastReadDate to get most recent first
    final history = box.values.toList();
    history.sort((a, b) => b.lastReadDate.compareTo(a.lastReadDate));

    return history;
  }

  Future<void> saveReadingProgress(ReadingHistoryModel historyEntry) async {
    final box = await _getReadingHistoryBox();

    // Create a unique key using comic slug + chapter ID
    final key = '${historyEntry.comicSlug}_${historyEntry.chapterId}';
    await box.put(key, historyEntry);
  }

  Future<ReadingHistoryModel?> getChapterProgress(
      String comicSlug, String chapterId) async {
    final box = await _getReadingHistoryBox();
    final key = '${comicSlug}_$chapterId';

    return box.get(key);
  }

  Future<void> deleteReadingHistory(String comicSlug, String chapterId) async {
    final box = await _getReadingHistoryBox();
    final key = '${comicSlug}_$chapterId';

    await box.delete(key);
  }

  Future<void> clearAllReadingHistory() async {
    final box = await _getReadingHistoryBox();
    await box.clear();
  }
}
