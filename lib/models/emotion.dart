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
  shy,        // 부끄러움
  anxious,    // 불안
  moved,      // 감동
  lonely,     // 외로움
  bored,      // 지루함
  hopeful,    // 희망
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
    Emotion(
      type: EmotionType.shy,
      label: '부끄러움',
      emoji: '🫣',
      color: Color(0xFFE8A0B8),   // 소프트 핑크
      lightColor: Color(0xFFFAEDF2),
      keywords: ['부끄', '쑥스럽', '창피', '수줍', '민망', '얼굴빨개', '어색'],
      comfortMessage: '그 수줍음, 사실 정말 귀여워요 🌸\n설레는 마음 아닌가요?',
      musicKeywords: ['수줍은 감성 한국 노래', '설레는 잔잔한 발라드', '부끄러운 느낌 케이팝'],
    ),
    Emotion(
      type: EmotionType.anxious,
      label: '불안',
      emoji: '😟',
      color: Color(0xFF94A8C0),   // 스틸 블루-그레이
      lightColor: Color(0xFFECEFF4),
      keywords: ['불안', '걱정', '긴장', '두려', '떨려', '무서', '초조'],
      comfortMessage: '지금 많이 불안한가요 💙\n괜찮아요, 이 순간도 지나가요. 천천히 숨을 쉬어요.',
      musicKeywords: ['불안할 때 듣는 노래', '마음 안정되는 한국 음악', '긴장 풀리는 힐링 노래'],
    ),
    Emotion(
      type: EmotionType.moved,
      label: '감동',
      emoji: '🥹',
      color: Color(0xFF98C0A8),   // 민트 그레이
      lightColor: Color(0xFFEAF4EE),
      keywords: ['감동', '뭉클', '눈물날것', '감사', '벅차', '울컥', '감격'],
      comfortMessage: '마음이 벅차오르는 하루였군요 🥹\n그 감동을 오래 간직하세요.',
      musicKeywords: ['감동적인 한국 노래', '뭉클한 발라드 명곡', '눈물 나는 감성 케이팝'],
    ),
    Emotion(
      type: EmotionType.lonely,
      label: '외로움',
      emoji: '😔',
      color: Color(0xFF8898B8),   // 더스티 코른플라워
      lightColor: Color(0xFFEBEEF4),
      keywords: ['외롭', '혼자', '쓸쓸', '심심', '고독', '아무도', '소외'],
      comfortMessage: '지금 조금 혼자인 기분이군요 🌙\n뮤지가 옆에 있을게요. 음악 들으면서 같이 있어요.',
      musicKeywords: ['혼자일 때 듣는 노래 한국', '외로울 때 감성 발라드', '쓸쓸한 새벽 노래'],
    ),
    Emotion(
      type: EmotionType.bored,
      label: '지루함',
      emoji: '😑',
      color: Color(0xFFB0A8A0),   // 웜 그레이
      lightColor: Color(0xFFF0EEEC),
      keywords: ['지루', '심심', '무료', '따분', '별로', '흥미없', '할게없'],
      comfortMessage: '지루한 하루였나요 😑\n뮤지가 분위기 바꿔줄 노래 찾았어요!',
      musicKeywords: ['기분 전환 한국 노래', '활기찬 케이팝 추천', '심심할 때 신나는 노래'],
    ),
    Emotion(
      type: EmotionType.hopeful,
      label: '희망',
      emoji: '✨',
      color: Color(0xFF78B8D0),   // 스카이 틸
      lightColor: Color(0xFFE4F2F6),
      keywords: ['희망', '기대', '꿈', '할수있', '잘될', '좋아질', '파이팅'],
      comfortMessage: '희망찬 마음이 느껴져요 ✨\n그 긍정 에너지, 정말 멋져요!',
      musicKeywords: ['희망적인 한국 노래', '기분 좋아지는 케이팝', '응원 노래 한국 감성'],
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
