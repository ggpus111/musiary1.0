import 'package:flutter/material.dart';

enum EmotionType {
  excited,    // 설렘
  joyful,     // 즐거움
  happy,      // 행복
  nostalgic,  // 그리움
  calm,       // 편안함
  busy,       // 바쁨
  miserable,  // 비참
  tired,      // 지침
  angry,      // 화남
}

class Emotion {
  final EmotionType type;
  final String label;
  final String emoji;
  final Color color;
  final Color lightColor;
  final List<String> keywords;
  final String comfortMessage;
  final List<String> musicKeywords; // YouTube 검색 키워드 (한국어)

  const Emotion({
    required this.type,
    required this.label,
    required this.emoji,
    required this.color,
    required this.lightColor,
    required this.keywords,
    required this.comfortMessage,
    required this.musicKeywords,
  });

  static const List<Emotion> all = [
    Emotion(
      type: EmotionType.excited,
      label: '설렘',
      emoji: '💓',
      color: Color(0xFFE0909C),   // 소프트 로즈
      lightColor: Color(0xFFFAECEE),
      keywords: ['설레', '두근', '기대', '떨려', '흥분', '새로운', '시작'],
      comfortMessage: '두근거리는 마음이 느껴져요 ✨\n그 설렘을 소중히 간직하세요.',
      musicKeywords: ['설레는 노래 한국', '두근두근 케이팝', '설레는 감성 플레이리스트'],
    ),
    Emotion(
      type: EmotionType.joyful,
      label: '즐거움',
      emoji: '😄',
      color: Color(0xFFE8A87C),   // 따뜻한 피치
      lightColor: Color(0xFFFAF0E6),
      keywords: ['즐거', '재미', '신나', '웃음', '유쾌', '활기', '좋아'],
      comfortMessage: '오늘 하루가 즐거웠군요 😄\n이 기쁨이 내일까지 이어지길!',
      musicKeywords: ['신나는 한국 노래', '기분 좋은 케이팝', '즐거운 플레이리스트 kpop'],
    ),
    Emotion(
      type: EmotionType.happy,
      label: '행복',
      emoji: '😊',
      color: Color(0xFFE8C87A),   // 허니 옐로우
      lightColor: Color(0xFFFAF4E1),
      keywords: ['행복', '감사', '좋은', '완벽', '최고', '사랑', '따뜻'],
      comfortMessage: '행복한 하루를 보내셨군요 🌟\n이런 날들이 더 많아지길 바라요.',
      musicKeywords: ['행복한 한국 노래', '따뜻한 감성 발라드', '행복 플레이리스트 한국'],
    ),
    Emotion(
      type: EmotionType.nostalgic,
      label: '그리움',
      emoji: '🥺',
      color: Color(0xFFAA90C8),   // 더스티 모브
      lightColor: Color(0xFFF2EDF8),
      keywords: ['그립', '보고싶', '추억', '옛날', '그때', '생각나', '기억'],
      comfortMessage: '누군가 혹은 무언가가 그리운가요 🥺\n소중한 기억은 마음속에 영원해요.',
      musicKeywords: ['그리운 한국 발라드', '추억의 노래 감성', '보고싶다 노래 한국'],
    ),
    Emotion(
      type: EmotionType.calm,
      label: '편안함',
      emoji: '😌',
      color: Color(0xFF8EBD98),   // 세이지 그린
      lightColor: Color(0xFFEAF4EC),
      keywords: ['편안', '안정', '여유', '잔잔', '고요', '평화', '쉬고'],
      comfortMessage: '마음이 편안한 하루였군요 🌿\n이 평화로운 기분을 즐기세요.',
      musicKeywords: ['잔잔한 한국 노래', '힐링 음악 한국', '편안한 감성 플레이리스트'],
    ),
    Emotion(
      type: EmotionType.busy,
      label: '바쁨',
      emoji: '😤',
      color: Color(0xFF8AADCC),   // 더스티 블루
      lightColor: Color(0xFFE8F0F6),
      keywords: ['바쁘', '정신없', '할일', '스트레스', '힘들', '많은', '빠듯'],
      comfortMessage: '바쁜 하루를 보내느라 수고했어요 💪\n잠시 쉬어가는 것도 중요해요.',
      musicKeywords: ['집중력 향상 한국 음악', '공부할 때 듣는 노래', '카페 음악 한국'],
    ),
    Emotion(
      type: EmotionType.miserable,
      label: '비참',
      emoji: '😢',
      color: Color(0xFF8E90BC),   // 소프트 인디고
      lightColor: Color(0xFFEEEEF6),
      keywords: ['슬프', '우울', '눈물', '힘들', '괴롭', '외로', '비참', '상처'],
      comfortMessage: '많이 힘드셨군요 💙\n괜찮아요, 이 감정도 지나갈 거예요. 당신 곁에 있을게요.',
      musicKeywords: ['위로 노래 한국', '슬플 때 듣는 발라드', '눈물 노래 한국 감성'],
    ),
    Emotion(
      type: EmotionType.tired,
      label: '지침',
      emoji: '😮‍💨',
      color: Color(0xFFAA9688),   // 따뜻한 그레이-브라운
      lightColor: Color(0xFFF2EDEA),
      keywords: ['지쳐', '피곤', '힘없', '무기력', '귀찮', '쉬고싶', '번아웃'],
      comfortMessage: '많이 지쳤군요 🌙\n오늘은 푹 쉬어도 돼요. 내일의 나에게 맡겨요.',
      musicKeywords: ['편안한 수면 음악 한국', '지칠 때 듣는 노래', '힐링 발라드 잔잔'],
    ),
    Emotion(
      type: EmotionType.angry,
      label: '화남',
      emoji: '😠',
      color: Color(0xFFD07868),   // 더스티 테라코타
      lightColor: Color(0xFFF8ECEA),
      keywords: ['화나', '짜증', '열받', '분노', '억울', '불공평', '싫어'],
      comfortMessage: '많이 화가 났군요 🔥\n깊게 숨을 들이쉬어 보세요. 이 감정도 괜찮아요.',
      musicKeywords: ['화날 때 듣는 노래', '스트레스 해소 한국 음악', '강렬한 케이팝'],
    ),
  ];

  static Emotion fromType(EmotionType type) {
    return all.firstWhere((e) => e.type == type);
  }

  static Emotion fromString(String label) {
    return all.firstWhere(
      (e) => e.label == label,
      orElse: () => all[2],
    );
  }

  String get typeString => type.name;
}
