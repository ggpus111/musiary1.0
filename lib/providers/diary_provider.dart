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
  // 현재 음악 로딩 중인 일기 id
  int? _loadingMusicForId;
  int? get loadingMusicForId => _loadingMusicForId;

  /// 일기를 즉시 저장하고 바로 반환 — 음악은 백그라운드에서 탐색
  Future<DiaryEntry?> saveDiary({
    required String content,
    required EmotionType selectedEmotion,
    String? imagePath,
    Future<void> Function(int gems)? onGemsEarned,
    bool isPremium = false,
    void Function(DiaryEntry updated)? onMusicReady,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // ① 감정 분석 (빠름)
      final analysisResult = _emotionService.analyzeText(content);
      final finalEmotion = _emotionService.combineAnalysis(
        userSelected: selectedEmotion,
        text: content,
      );
      final emotionData = Emotion.fromType(finalEmotion);

      // ② 음악 없이 즉시 DB 저장
      final entry = DiaryEntry(
        content: content,
        imagePath: imagePath,
        emotion: finalEmotion,
        emotionScore: analysisResult.score,
        comfortMessage: emotionData.comfortMessage,
        recommendedTracks: [],
        createdAt: DateTime.now(),
      );

      final id = await _db.insertDiary(entry);
      final savedEntry = entry.copyWith(id: id);

      _entries.insert(0, savedEntry);
      final key = DateTime(savedEntry.createdAt.year, savedEntry.createdAt.month, savedEntry.createdAt.day);
      _entryByDate[key] = savedEntry;

      _error = null;
      _isLoading = false;
      _invalidateProfileCache();
      notifyListeners();

      // 💎 보석 즉시 지급
      if (onGemsEarned != null) {
        final gemsEarned = isPremium ? 6 : 3;
        await onGemsEarned(gemsEarned);
      }

      // ③ YouTube 음악 탐색은 백그라운드에서
      _fetchMusicInBackground(savedEntry, onMusicReady);

      return savedEntry;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// 음악 백그라운드 탐색 — 완료되면 entry 업데이트 후 콜백 호출
  void _fetchMusicInBackground(
    DiaryEntry entry,
    void Function(DiaryEntry updated)? onReady,
  ) async {
    _loadingMusicForId = entry.id;
    notifyListeners();
    try {
      final tracks = await _musicService.searchByEmotion(entry.emotion);
      if (tracks.isEmpty) return;

      final updated = entry.copyWith(recommendedTracks: tracks);

      // 리스트 업데이트
      final idx = _entries.indexWhere((e) => e.id == entry.id);
      if (idx >= 0) _entries[idx] = updated;
      final key = DateTime(updated.createdAt.year, updated.createdAt.month, updated.createdAt.day);
      _entryByDate[key] = updated;

      // 🎵 대표곡 앨범 저장
      final song = SavedSong.fromDiary(
        track: tracks.first,
        emotion: entry.emotion,
        savedAt: updated.createdAt,
        diaryId: updated.id,
      );
      final songId = await _db.saveSong(song);
      _savedSongs.insert(0, song.copyWith(id: songId));

      notifyListeners();
      onReady?.call(updated);
    } catch (_) {
      // 음악 탐색 실패 — 일기는 이미 저장됨
    } finally {
      _loadingMusicForId = null;
      notifyListeners();
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
