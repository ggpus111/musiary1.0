import 'package:flutter/material.dart';
import 'emotion.dart';

/// 뮤지의 음악 취향 타입
enum MusicTasteType {
  bright,    // 밝고 에너지 넘치는
  emotional, // 감성적이고 잔잔한
  healing,   // 편안하고 힐링하는
  intense,   // 강렬하고 다이나믹한
  mixed,     // 다양한 취향
}

/// 뮤지의 음악 취향 프로필
/// 일기의 감정 기록을 기반으로 자동 계산됩니다.
class MuziMusicProfile {
  final Map<EmotionType, int> emotionCounts;
  final int totalEntries;

  const MuziMusicProfile({
    required this.emotionCounts,
    required this.totalEntries,
  });

  factory MuziMusicProfile.empty() => const MuziMusicProfile(
    emotionCounts: {},
    totalEntries: 0,
  );

  factory MuziMusicProfile.fromEntries(List<MapEntry<EmotionType, int>> counts) {
    final map = Map.fromEntries(counts);
    final total = map.values.fold(0, (a, b) => a + b);
    return MuziMusicProfile(emotionCounts: map, totalEntries: total);
  }

  /// 상위 3개 감정
  List<EmotionType> get topEmotions {
    final sorted = emotionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).map((e) => e.key).toList();
  }

  /// 취향 타입 계산
  MusicTasteType get tasteType {
    if (totalEntries == 0) return MusicTasteType.mixed;

    // 각 취향 그룹 점수 계산
    final bright = _score([EmotionType.excited, EmotionType.joyful, EmotionType.happy]);
    final emotional = _score([EmotionType.nostalgic, EmotionType.calm, EmotionType.miserable]);
    final healing = _score([EmotionType.tired, EmotionType.calm]);
    final intense = _score([EmotionType.angry, EmotionType.busy]);

    final maxScore = [bright, emotional, healing, intense].reduce((a, b) => a > b ? a : b);
    if (maxScore < 0.25) return MusicTasteType.mixed;

    if (maxScore == bright)    return MusicTasteType.bright;
    if (maxScore == emotional) return MusicTasteType.emotional;
    if (maxScore == healing)   return MusicTasteType.healing;
    return MusicTasteType.intense;
  }

  double _score(List<EmotionType> types) {
    if (totalEntries == 0) return 0;
    final count = types.fold(0, (sum, t) => sum + (emotionCounts[t] ?? 0));
    return count / totalEntries;
  }

  /// 취향 강도 (0.0 ~ 1.0) — 진행바 표시용
  double get tasteStrength {
    if (totalEntries == 0) return 0;
    final top = topEmotions.isEmpty ? 0 : (emotionCounts[topEmotions.first] ?? 0);
    return (top / totalEntries).clamp(0.0, 1.0);
  }

  // ── UI용 정보 ────────────────────────────────────────

  String get tasteEmoji {
    switch (tasteType) {
      case MusicTasteType.bright:    return '☀️';
      case MusicTasteType.emotional: return '🌙';
      case MusicTasteType.healing:   return '🍃';
      case MusicTasteType.intense:   return '🔥';
      case MusicTasteType.mixed:     return '🌈';
    }
  }

  String get tasteLabel {
    switch (tasteType) {
      case MusicTasteType.bright:    return '밝고 에너지 넘치는';
      case MusicTasteType.emotional: return '감성적이고 잔잔한';
      case MusicTasteType.healing:   return '편안하고 힐링하는';
      case MusicTasteType.intense:   return '강렬하고 다이나믹한';
      case MusicTasteType.mixed:     return '다양한 음악';
    }
  }

  String get tasteDescription {
    if (totalEntries == 0) {
      return '일기를 쓰면 뮤지의 취향이 생겨요!\n어떤 음악을 좋아할지 함께 찾아봐요 🎵';
    }
    switch (tasteType) {
      case MusicTasteType.bright:
        return '신나고 밝은 에너지의 노래를\n좋아하는 것 같아요 ✨';
      case MusicTasteType.emotional:
        return '감성적이고 서정적인 멜로디에\n마음이 움직이나봐요 🥺';
      case MusicTasteType.healing:
        return '편안하고 잔잔한 힐링 음악으로\n마음을 달래고 싶어해요 🌿';
      case MusicTasteType.intense:
        return '강렬하고 박진감 넘치는 음악으로\n에너지를 발산하고 싶어해요 💪';
      case MusicTasteType.mixed:
        return '어떤 장르든 가리지 않는\n넓은 음악 취향을 가졌어요 🌈';
    }
  }

  Color get tasteColor {
    switch (tasteType) {
      case MusicTasteType.bright:    return const Color(0xFFE8C87A);  // 허니 옐로우
      case MusicTasteType.emotional: return const Color(0xFFAA90C8);  // 더스티 모브
      case MusicTasteType.healing:   return const Color(0xFF8EBD98);  // 세이지 그린
      case MusicTasteType.intense:   return const Color(0xFFD07868);  // 더스티 테라코타
      case MusicTasteType.mixed:     return const Color(0xFFC4966A);  // 카라멜 브라운 (기본)
    }
  }

  Color get tasteLightColor {
    switch (tasteType) {
      case MusicTasteType.bright:    return const Color(0xFFFAF4E1);
      case MusicTasteType.emotional: return const Color(0xFFF2EDF8);
      case MusicTasteType.healing:   return const Color(0xFFEAF4EC);
      case MusicTasteType.intense:   return const Color(0xFFF8ECEA);
      case MusicTasteType.mixed:     return const Color(0xFFF5EFE6);  // 따뜻한 베이지
    }
  }

  /// 뮤지 레벨 (일기 수 기반)
  int get level {
    if (totalEntries >= 100) return 5;
    if (totalEntries >= 50)  return 4;
    if (totalEntries >= 20)  return 3;
    if (totalEntries >= 7)   return 2;
    if (totalEntries >= 1)   return 1;
    return 0;
  }

  String get levelLabel {
    switch (level) {
      case 0: return '아직 음악을 몰라요';
      case 1: return '음악에 눈을 뜨는 중';
      case 2: return '음악을 즐기기 시작했어요';
      case 3: return '음악을 사랑하게 됐어요';
      case 4: return '음악 없이는 못 살아요';
      case 5: return '진정한 음악 마니아';
      default: return '음악 마니아';
    }
  }
}
