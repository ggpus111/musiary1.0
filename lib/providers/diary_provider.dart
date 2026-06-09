import 'package:flutter/material.dart';
import '../models/diary_entry.dart';
import '../models/emotion.dart';
import '../models/saved_song.dart';
import '../models/muzi_music_profile.dart';
import '../services/local_db_service.dart';
import '../services/emotion_analysis_service.dart';
import '../services/youtube_audio_service.dart';

class DiaryProvider extends ChangeNotifier {
  final LocalDbService _db = LocalDbService();
  final EmotionAnalysisService _emotionService = EmotionAnalysisService();
  final YoutubeAudioService _musicService = YoutubeAudioService();

  List<DiaryEntry> _entries = [];
  Map<DateTime, DiaryEntry> _entryByDate = {};
  List<SavedSong> _savedSongs = [];
  bool _isLoading = false;
  String? _error;
  MuziMusicProfile? _cachedProfile; // 캐시: entries 변경 시만 재계산

  List<DiaryEntry> get entries => _entries;
  Map<DateTime, DiaryEntry> get entryByDate => _entryByDate;
  List<SavedSong> get savedSongs => _savedSongs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 뮤지의 음악 취향 프로필 — entries 변경 시만 재계산 (캐시)
  MuziMusicProfile get muziProfile => _cachedProfile ??= _computeProfile();

  MuziMusicProfile _computeProfile() {
    final counts = <EmotionType, int>{};
    for (final e in _entries) {
      counts[e.emotion] = (counts[e.emotion] ?? 0) + 1;
    }
    return MuziMusicProfile(
      emotionCounts: counts,
      totalEntries: _entries.length,
    );
  }

  void _invalidateProfileCache() => _cachedProfile = null;

  /// 최근 저장된 노래 N개
  List<SavedSong> recentSongs({int limit = 5}) =>
      _savedSongs.take(limit).toList();

  DiaryEntry? get todayEntry {
    final today = DateTime.now();
    final key = DateTime(today.year, today.month, today.day);
    return _entryByDate[key];
  }

  Future<void> loadEntries() async {
    if (_isLoading) return; // 중복 호출 방어
    _isLoading = true;
    notifyListeners();
    try {
      _entries = await _db.getAllDiaries();
      _savedSongs = await _db.getSavedSongs();
      _buildDateMap();
      _invalidateProfileCache();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSavedSongs() async {
    _savedSongs = await _db.getSavedSongs();
    notifyListeners();
  }

  Future<void> loadMonthEntries(int year, int month) async {
    try {
      final monthEntries = await _db.getDiariesByMonth(year, month);
      for (final entry in monthEntries) {
        final key = DateTime(entry.createdAt.year, entry.createdAt.month, entry.createdAt.day);
        _entryByDate[key] = entry;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  /// 일기 저장 후 보석 지급 콜백 (+3💎 기본, 프리미엄 x2)
  Future<DiaryEntry?> saveDiary({
    required String content,
    required EmotionType selectedEmotion,
    String? imagePath,
    Future<void> Function(int gems)? onGemsEarned,
    bool isPremium = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 감정 분석
      final analysisResult = _emotionService.analyzeText(content);
      final finalEmotion = _emotionService.combineAnalysis(
        userSelected: selectedEmotion,
        text: content,
      );
      final emotionData = Emotion.fromType(finalEmotion);

      // YouTube에서 한국 음악 검색 (API 키 불필요)
      final tracks = await _musicService.searchByEmotion(finalEmotion);

      final entry = DiaryEntry(
        content: content,
        imagePath: imagePath,
        emotion: finalEmotion,
        emotionScore: analysisResult.score,
        comfortMessage: emotionData.comfortMessage,
        recommendedTracks: tracks,
        createdAt: DateTime.now(),
      );

      final id = await _db.insertDiary(entry);
      final savedEntry = entry.copyWith(id: id);

      _entries.insert(0, savedEntry);
      final key = DateTime(savedEntry.createdAt.year, savedEntry.createdAt.month, savedEntry.createdAt.day);
      _entryByDate[key] = savedEntry;

      // 🎵 대표곡 자동 저장 (뮤지의 앨범)
      if (tracks.isNotEmpty) {
        final song = SavedSong.fromDiary(
          track: tracks.first,
          emotion: finalEmotion,
          savedAt: savedEntry.createdAt,
          diaryId: savedEntry.id,
        );
        final songId = await _db.saveSong(song);
        _savedSongs.insert(0, song.copyWith(id: songId));
      }

      _error = null;
      _isLoading = false;
      _invalidateProfileCache();
      notifyListeners();

      // 💎 보석 지급: 기본 3개, 프리미엄 2배
      if (onGemsEarned != null) {
        final gemsEarned = isPremium ? 6 : 3;
        await onGemsEarned(gemsEarned);
      }

      return savedEntry;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> deleteDiary(int id) async {
    await _db.deleteDiary(id);
    _entries.removeWhere((e) => e.id == id);
    _entryByDate.removeWhere((_, e) => e.id == id);
    _invalidateProfileCache();
    notifyListeners();
  }

  Future<Map<EmotionType, int>> getMonthlyStats(int year, int month) async {
    return _db.getEmotionStats(year, month);
  }

  void _buildDateMap() {
    _entryByDate = {};
    for (final entry in _entries) {
      final key = DateTime(entry.createdAt.year, entry.createdAt.month, entry.createdAt.day);
      _entryByDate[key] = entry;
    }
  }

  DiaryEntry? getEntryForDate(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    return _entryByDate[key];
  }
}
