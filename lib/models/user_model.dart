/// 뮤지어리 사용자 모델
class MusiaryUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;     // 전화번호 (이메일 찾기에 활용)
  final bool isPremium;
  final DateTime? premiumUntil;
  final String muziSkin;         // 현재 뮤지 스킨
  final List<String> ownedSkins; // 보유한 스킨 목록
  final String equippedOutfit;       // 머리 장식 ID
  final String equippedAccessory;    // 얼굴 악세사리 ID
  final String equippedBackground;   // 배경 테마 ID
  final List<String> ownedItems;     // 보유한 꾸미기 아이템 목록
  final int gems;                // 💎 보석 (악세사리 구매에 사용)
  final DateTime createdAt;
  final int diaryCount;

  const MusiaryUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.isPremium = false,
    this.premiumUntil,
    this.muziSkin = 'default',
    this.ownedSkins = const ['default'],
    this.equippedOutfit = 'none',
    this.equippedAccessory = 'none',
    this.equippedBackground = 'default',
    this.ownedItems = const ['ribbon'],  // 리본은 기본 무료 제공
    this.gems = 10,                      // 신규 가입 시 10 💎 지급
    required this.createdAt,
    this.diaryCount = 0,
  });

  bool get isPremiumActive {
    if (!isPremium) return false;
    if (premiumUntil == null) return false;
    return premiumUntil!.isAfter(DateTime.now());
  }

  String get displayNameOrEmail {
    if (displayName != null && displayName!.isNotEmpty) return displayName!;
    return email.split('@').first;
  }

  factory MusiaryUser.fromMap(Map<String, dynamic> map) {
    return MusiaryUser(
      uid: map['uid'] as String,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      isPremium: map['isPremium'] as bool? ?? false,
      premiumUntil: map['premiumUntil'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['premiumUntil'] as int)
          : null,
      muziSkin: map['muziSkin'] as String? ?? 'default',
      ownedSkins: List<String>.from(map['ownedSkins'] as List? ?? ['default']),
      equippedOutfit: map['equippedOutfit'] as String? ?? 'none',
      equippedAccessory: map['equippedAccessory'] as String? ?? 'none',
      equippedBackground: map['equippedBackground'] as String? ?? 'default',
      ownedItems: List<String>.from(map['ownedItems'] as List? ?? ['ribbon']),
      gems: map['gems'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      diaryCount: map['diaryCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'phoneNumber': phoneNumber,
    'isPremium': isPremium,
    'premiumUntil': premiumUntil?.millisecondsSinceEpoch,
    'muziSkin': muziSkin,
    'ownedSkins': ownedSkins,
    'equippedOutfit': equippedOutfit,
    'equippedAccessory': equippedAccessory,
    'equippedBackground': equippedBackground,
    'ownedItems': ownedItems,
    'gems': gems,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'diaryCount': diaryCount,
  };

  MusiaryUser copyWith({
    bool? isPremium,
    DateTime? premiumUntil,
    String? muziSkin,
    List<String>? ownedSkins,
    String? equippedOutfit,
    String? equippedAccessory,
    String? equippedBackground,
    List<String>? ownedItems,
    String? phoneNumber,
    int? gems,
    int? diaryCount,
  }) => MusiaryUser(
    uid: uid,
    email: email,
    displayName: displayName,
    photoUrl: photoUrl,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    isPremium: isPremium ?? this.isPremium,
    premiumUntil: premiumUntil ?? this.premiumUntil,
    muziSkin: muziSkin ?? this.muziSkin,
    ownedSkins: ownedSkins ?? this.ownedSkins,
    equippedOutfit: equippedOutfit ?? this.equippedOutfit,
    equippedAccessory: equippedAccessory ?? this.equippedAccessory,
    equippedBackground: equippedBackground ?? this.equippedBackground,
    ownedItems: ownedItems ?? this.ownedItems,
    gems: gems ?? this.gems,
    createdAt: createdAt,
    diaryCount: diaryCount ?? this.diaryCount,
  );
}

/// 뮤지 스킨 정보
class MuziSkin {
  final String id;
  final String name;
  final String emoji;
  final int colorValue;
  final int price;         // 원 단위, 0이면 무료
  final bool isPremiumOnly;
  final String description;

  const MuziSkin({
    required this.id,
    required this.name,
    required this.emoji,
    required this.colorValue,
    required this.price,
    this.isPremiumOnly = false,
    required this.description,
  });

  static const List<MuziSkin> all = [
    MuziSkin(
      id: 'default',
      name: '기본 뮤지',
      emoji: '🎵',
      colorValue: 0xFFC4966A,
      price: 0,
      description: '언제나 함께하는 뮤지!',
    ),
    MuziSkin(
      id: 'pink',
      name: '핑크 뮤지',
      emoji: '🌸',
      colorValue: 0xFFFF6B9D,
      price: 1900,
      description: '사랑스럽고 달콤한 핑크 뮤지',
    ),
    MuziSkin(
      id: 'sky',
      name: '하늘 뮤지',
      emoji: '☁️',
      colorValue: 0xFF74B9FF,
      price: 1900,
      description: '맑고 시원한 하늘빛 뮤지',
    ),
    MuziSkin(
      id: 'mint',
      name: '민트 뮤지',
      emoji: '🍃',
      colorValue: 0xFF00B894,
      price: 1900,
      description: '상쾌하고 활기찬 민트 뮤지',
    ),
    MuziSkin(
      id: 'gold',
      name: '골드 뮤지',
      emoji: '✨',
      colorValue: 0xFFFDCB6E,
      price: 0,
      isPremiumOnly: true,
      description: '프리미엄 전용 황금빛 뮤지',
    ),
    MuziSkin(
      id: 'night',
      name: '밤하늘 뮤지',
      emoji: '🌙',
      colorValue: 0xFF2D3436,
      price: 2900,
      description: '신비롭고 몽환적인 밤하늘 뮤지',
    ),
    MuziSkin(
      id: 'rainbow',
      name: '레인보우 뮤지',
      emoji: '🌈',
      colorValue: 0xFFE17055,
      price: 0,
      isPremiumOnly: true,
      description: '프리미엄 전용 무지개빛 뮤지',
    ),
  ];
}
