// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comick_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ComicModelAdapter extends TypeAdapter<ComicModel> {
  @override
  final int typeId = 0;

  @override
  ComicModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ComicModel(
      slug: fields[0] as String,
      name: fields[1] as String,
      imageUrl: fields[2] as String,
      description: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ComicModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.slug)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.imageUrl)
      ..writeByte(3)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComicModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReadingHistoryModelAdapter extends TypeAdapter<ReadingHistoryModel> {
  @override
  final int typeId = 1;

  @override
  ReadingHistoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReadingHistoryModel(
      comicSlug: fields[0] as String,
      comicName: fields[1] as String,
      imageUrl: fields[2] as String,
      chapterId: fields[3] as String,
      chapterTitle: fields[4] as String,
      lastReadDate: fields[5] as DateTime,
      lastReadPage: fields[6] as int,
      readingProgress: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ReadingHistoryModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.comicSlug)
      ..writeByte(1)
      ..write(obj.comicName)
      ..writeByte(2)
      ..write(obj.imageUrl)
      ..writeByte(3)
      ..write(obj.chapterId)
      ..writeByte(4)
      ..write(obj.chapterTitle)
      ..writeByte(5)
      ..write(obj.lastReadDate)
      ..writeByte(6)
      ..write(obj.lastReadPage)
      ..writeByte(7)
      ..write(obj.readingProgress);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingHistoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
