import 'package:flutter/material.dart';

/// 뮤지 꾸미기 아이템 카테고리
enum MuziItemCategory {
  outfit,     // 머리 장식 (모자, 리본 등)
  accessory,  // 얼굴 악세사리 (안경 등)
  background, // 배경 테마
}

/// 뮤지 꾸미기 아이템
/// price = 0 (실제 현금 없음), gemCost = 보석 비용
class MuziItem {
  final String id;
  final String name;
  final String emoji;
  final MuziItemCategory category;
  final int gemCost;        // 💎 보석 비용 (0 = 무료 or 프리미엄 전용)
  final bool isPremiumOnly;
  final String description;
  final int? colorValue;    // 배경 대표 색상

  const MuziItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.gemCost,
    this.isPremiumOnly = false,
    required this.description,
    this.colorValue,
  });

  static const List<MuziItem> all = [
    // ── 머리 장식 ───────────────────────────────────
    MuziItem(
      id: 'ribbon',
      name: '핑크 리본',
      emoji: '🎀',
      category: MuziItemCategory.outfit,
      gemCost: 0,
      description: '처음부터 뮤지와 함께한 귀여운 리본',
      colorValue: 0xFFFF6B9D,
    ),
    MuziItem(
      id: 'music_hat',
      name: '뮤직 모자',
      emoji: '🎩',
      category: MuziItemCategory.outfit,
      gemCost: 40,
      description: '음표가 그려진 멋진 모자예요',
      colorValue: 0xFF2D3436,
    ),
    MuziItem(
      id: 'crown',
      name: '황금 왕관',
      emoji: '👑',
      category: MuziItemCategory.outfit,
      gemCost: 80,
      description: '반짝이는 황금 왕관이에요',
      colorValue: 0xFFFDCB6E,
    ),
    MuziItem(
      id: 'star_clip',
      name: '별 머리핀',
      emoji: '⭐',
      category: MuziItemCategory.outfit,
      gemCost: 40,
      description: '반짝이는 별 모양 머리핀이에요',
      colorValue: 0xFFFDCB6E,
    ),
    MuziItem(
      id: 'headphones',
      name: '헤드폰',
      emoji: '🎧',
      category: MuziItemCategory.outfit,
      gemCost: 0,
      isPremiumOnly: true,
      description: '프리미엄 전용 뮤지 헤드폰이에요',
      colorValue: 0xFFC4966A,
    ),

    // ── 얼굴 악세사리 ────────────────────────────────
    MuziItem(
      id: 'glasses',
      name: '동그란 안경',
      emoji: '👓',
      category: MuziItemCategory.accessory,
      gemCost: 30,
      description: '지적인 느낌의 동그란 안경이에요',
      colorValue: 0xFF2D3436,
    ),
    MuziItem(
      id: 'heart_glasses',
      name: '하트 선글라스',
      emoji: '🕶️',
      category: MuziItemCategory.accessory,
      gemCost: 60,
      description: '사랑스러운 하트 모양 선글라스예요',
      colorValue: 0xFFFF6B9D,
    ),
    MuziItem(
      id: 'sparkle',
      name: '반짝 이펙트',
      emoji: '✨',
      category: MuziItemCategory.accessory,
      gemCost: 0,
      isPremiumOnly: true,
      description: '프리미엄 전용 반짝이 이펙트예요',
      colorValue: 0xFFFDCB6E,
    ),

    // ── 배경 테마 ────────────────────────────────────
    MuziItem(
      id: 'sunset',
      name: '노을 배경',
      emoji: '🌅',
      category: MuziItemCategory.background,
      gemCost: 50,
      description: '따뜻한 노을빛 배경이에요',
      colorValue: 0xFFFF7675,
    ),
    MuziItem(
      id: 'night_sky',
      name: '밤하늘 배경',
      emoji: '🌙',
      category: MuziItemCategory.background,
      gemCost: 50,
      description: '별이 빛나는 밤하늘 배경이에요',
      colorValue: 0xFF2D3436,
    ),
    MuziItem(
      id: 'sakura',
      name: '벚꽃 배경',
      emoji: '🌸',
      category: MuziItemCategory.background,
      gemCost: 80,
      description: '흩날리는 벚꽃잎 배경이에요',
      colorValue: 0xFFFFB3C6,
    ),
    MuziItem(
      id: 'galaxy',
      name: '은하수 배경',
      emoji: '🌌',
      category: MuziItemCategory.background,
      gemCost: 0,
      isPremiumOnly: true,
      description: '프리미엄 전용 신비로운 은하수 배경이에요',
      colorValue: 0xFF2D3A5C,
    ),
  ];

  /// 카테고리별 필터
  static List<MuziItem> byCategory(MuziItemCategory cat) =>
      all.where((i) => i.category == cat).toList();
}

/// 보석 팩 상품 정보
class GemPack {
  final String productId;
  final int gemAmount;      // 기본 보석 수
  final int bonusGems;      // 보너스 보석 (0이면 없음)
  final int price;          // 원 단위
  final String label;       // 화면 표시용
  final bool isBestValue;

  const GemPack({
    required this.productId,
    required this.gemAmount,
    this.bonusGems = 0,
    required this.price,
    required this.label,
    this.isBestValue = false,
  });

  /// 실제 지급 총량
  int get totalGems => gemAmount + bonusGems;

  /// 기준 단가(100원/개) 대비 할인율
  int get discountPercent {
    const baseUnitPrice = 100;
    final normalPrice = gemAmount * baseUnitPrice;
    if (normalPrice <= 0) return 0;
    return ((normalPrice - price) / normalPrice * 100).round();
  }

  static const List<GemPack> all = [
    GemPack(
      productId: 'musiary_gems_10',
      gemAmount: 10,
      price: 1000,
      label: '보석 소량',
    ),
    GemPack(
      productId: 'musiary_gems_30',
      gemAmount: 30,
      price: 2500,
      label: '보석 중량',
    ),
    GemPack(
      productId: 'musiary_gems_50',
      gemAmount: 50,
      bonusGems: 10,
      price: 4000,
      label: '보석 상자',
      isBestValue: true,
    ),
    GemPack(
      productId: 'musiary_gems_100',
      gemAmount: 100,
      bonusGems: 20,
      price: 7000,
      label: '보석 금고',
    ),
  ];
}

/// 배경 테마 그라디언트 색상 반환
List<Color> getBackgroundGradient(String backgroundId) {
  switch (backgroundId) {
    case 'sunset':
      return [const Color(0xFFFF9A9E), const Color(0xFFFECFEF), const Color(0xFFFECFEF)];
    case 'night_sky':
      return [const Color(0xFF0F0C29), const Color(0xFF302B63), const Color(0xFF24243E)];
    case 'sakura':
      return [const Color(0xFFFFE4E8), const Color(0xFFFFB3C6), const Color(0xFFFF8FAB)];
    case 'galaxy':
      return [const Color(0xFF1A1A2E), const Color(0xFF16213E), const Color(0xFF2D3A5C)];
    default:
      return [const Color(0xFFFAF7F2), const Color(0xFFF5EFE6)];
  }
}
