import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/diary_entry.dart';
import '../models/emotion.dart';
import '../models/saved_song.dart';

class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'musiary.db'),
      version: 2,
      onCreate: (db, version) async {
        await _createDiaryTable(db);
        await _createSongsTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createSongsTable(db);
        }
      },
    );
  }

  Future<void> _createDiaryTable(Database db) async {
    await db.execute('''
      CREATE TABLE diary_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content TEXT NOT NULL,
        imagePath TEXT,
        emotion TEXT NOT NULL,
        emotionScore REAL NOT NULL DEFAULT 0.0,
        comfortMessage TEXT NOT NULL,
        recommendedTracks TEXT,
        createdAt INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createSongsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS saved_songs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        videoId TEXT NOT NULL,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        thumbnailUrl TEXT NOT NULL,
        youtubeUrl TEXT NOT NULL,
        emotion TEXT NOT NULL,
        savedAt INTEGER NOT NULL,
        diaryId INTEGER
      )
    ''');
  }

  Future<int> insertDiary(DiaryEntry entry) async {
    final db = await database;
    return db.insert('diary_entries', entry.toMap());
  }

  Future<List<DiaryEntry>> getAllDiaries() async {
    final db = await database;
    final maps = await db.query('diary_entries', orderBy: 'createdAt DESC');
    return maps.map((m) => DiaryEntry.fromMap(m)).toList();
  }

  Future<List<DiaryEntry>> getDiariesByMonth(int year, int month) async {
    final db = await database;
    final start = DateTime(year, month, 1).millisecondsSinceEpoch;
    final end = DateTime(year, month + 1, 1).millisecondsSinceEpoch;
    final maps = await db.query(
      'diary_entries',
      where: 'createdAt >= ? AND createdAt < ?',
      whereArgs: [start, end],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => DiaryEntry.fromMap(m)).toList();
  }

  Future<DiaryEntry?> getDiaryByDate(DateTime date) async {
    final db = await database;
    final start = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final end = DateTime(date.year, date.month, date.day + 1).millisecondsSinceEpoch;
    final maps = await db.query(
      'diary_entries',
      where: 'createdAt >= ? AND createdAt < ?',
      whereArgs: [start, end],
      orderBy: 'createdAt DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return DiaryEntry.fromMap(maps.first);
  }

  Future<int> updateDiary(DiaryEntry entry) async {
    final db = await database;
    return db.update(
      'diary_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteDiary(int id) async {
    final db = await database;
    return db.delete('diary_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<EmotionType, int>> getEmotionStats(int year, int month) async {
    final db = await database;
    final start = DateTime(year, month, 1).millisecondsSinceEpoch;
    final end = DateTime(year, month + 1, 1).millisecondsSinceEpoch;
    // 전체 row 로드 없이 DB에서 바로 집계
    final rows = await db.rawQuery(
      'SELECT emotion, COUNT(*) as cnt FROM diary_entries '
      'WHERE createdAt >= ? AND createdAt < ? GROUP BY emotion',
      [start, end],
    );
    final Map<EmotionType, int> stats = {};
    for (final row in rows) {
      final type = EmotionType.values.firstWhere(
        (e) => e.name == row['emotion'],
        orElse: () => EmotionType.happy,
      );
      stats[type] = row['cnt'] as int;
    }
    return stats;
  }

  Future<int> getTotalCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM diary_entries');
    return result.first['count'] as int;
  }

  // ── 뮤지의 앨범 (저장된 노래) ──────────────────────────

  Future<int> saveSong(SavedSong song) async {
    final db = await database;
    // 같은 diaryId가 이미 있으면 중복 저장 안 함
    if (song.diaryId != null) {
      final existing = await db.query(
        'saved_songs',
        where: 'diaryId = ?',
        whereArgs: [song.diaryId],
        limit: 1,
      );
      if (existing.isNotEmpty) return existing.first['id'] as int;
    }
    return db.insert('saved_songs', song.toMap()..remove('id'));
  }

  Future<List<SavedSong>> getSavedSongs({int limit = 100}) async {
    final db = await database;
    final maps = await db.query(
      'saved_songs',
      orderBy: 'savedAt DESC',
      limit: limit,
    );
    return maps.map((m) => SavedSong.fromMap(m)).toList();
  }

  Future<List<SavedSong>> getSongsByEmotion(EmotionType emotion) async {
    final db = await database;
    final maps = await db.query(
      'saved_songs',
      where: 'emotion = ?',
      whereArgs: [emotion.name],
      orderBy: 'savedAt DESC',
    );
    return maps.map((m) => SavedSong.fromMap(m)).toList();
  }

  Future<int> getSongCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM saved_songs');
    return result.first['count'] as int;
  }

  Future<Map<EmotionType, int>> getSongEmotionStats() async {
    final db = await database;
    final maps = await db.rawQuery(
      'SELECT emotion, COUNT(*) as count FROM saved_songs GROUP BY emotion',
    );
    final stats = <EmotionType, int>{};
    for (final row in maps) {
      final type = EmotionType.values.firstWhere(
        (e) => e.name == row['emotion'],
        orElse: () => EmotionType.happy,
      );
      stats[type] = row['count'] as int;
    }
    return stats;
  }
}

