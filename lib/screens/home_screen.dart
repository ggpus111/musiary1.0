import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/diary_provider.dart';
import '../providers/auth_provider.dart';
import '../models/diary_entry.dart';
import '../models/emotion.dart';
import '../models/muzi_music_profile.dart';
import '../models/saved_song.dart';
import '../utils/app_theme.dart';
import '../widgets/muzi_character.dart';
import 'diary_write_screen.dart';
import 'diary_detail_screen.dart';
import 'muzi_playlist_screen.dart';
import 'music_player_screen.dart';
import 'muzi_shop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final _headerDateFmt = DateFormat('M월 d일 EEEE', 'ko_KR');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiaryProvider>().loadEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FF),
      body: SafeArea(
        child: Consumer2<DiaryProvider, AuthProvider>(
          builder: (context, diary, auth, _) {
            final todayEntry = diary.todayEntry;
            final profile = diary.muziProfile;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(auth, diary)),
                SliverToBoxAdapter(
                  child: _buildMuziHero(diary, todayEntry, profile, auth),
                ),
                if (todayEntry != null && todayEntry.recommendedTracks.isNotEmpty)
                  SliverToBoxAdapter(child: _buildTodaySongCard(todayEntry)),
                SliverToBoxAdapter(child: _buildTasteProfileCard(profile, diary)),
                SliverToBoxAdapter(child: _buildMiniAlbum(diary)),
                SliverToBoxAdapter(child: _buildRecentEntries(diary)),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DiaryWriteScreen()),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        label: const Text('일기 쓰기', style: TextStyle(fontWeight: FontWeight.w700)),
        icon: const Icon(Icons.edit_rounded),
      ),
    );
  }

  // ── 상단 헤더 ─────────────────────────────────────────
  Widget _buildHeader(AuthProvider auth, DiaryProvider diary) {
    final now = DateTime.now();
    final dateStr = _headerDateFmt.format(now);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '뮤지어리',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppTheme.primary, fontSize: 24, fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                dateStr,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MuziShopScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EBFF),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  const Text('💎', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 5),
                  Text(
                    '${auth.gems}',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 뮤지 히어로 ── 캐릭터 중앙 배치 + 옷장 ─────────────
  Widget _buildMuziHero(
    DiaryProvider diary,
    DiaryEntry? todayEntry,
    MuziMusicProfile profile,
    AuthProvider auth,
  ) {
    final emotion = todayEntry?.emotion;
    final emotionData = emotion != null ? Emotion.fromType(emotion) : null;
    final accentColor = emotionData?.color ?? const Color(0xFFBB86FC);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── 캐릭터 영역 (파스텔 그라디언트 배경) ──────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accentColor.withValues(alpha: 0.14),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                // 감정 뱃지
                if (emotion != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: emotionData!.color.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(emotionData.emoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 5),
                        Text(
                          '오늘 기분: ${emotionData.label}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: emotionData.color,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    '안녕! 나는 뮤지야 🎵',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: accentColor.withValues(alpha: 0.85),
                    ),
                  ),

                // 뮤지 캐릭터 — 크게, 중앙
                RepaintBoundary(
                  child: Consumer<AuthProvider>(
                    builder: (context, auth, _) => MuziCharacter(
                      emotion: emotion,
                      size: 160,
                      showSpeechBubble: false,
                      outfit: auth.user?.equippedOutfit ?? 'none',
                      accessory: auth.user?.equippedAccessory ?? 'none',
                      background: 'default',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── 하단: 스탯 + 옷장 + 버튼 ────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Consumer2<AuthProvider, DiaryProvider>(
              builder: (context, auth, diary, _) => Column(
                children: [
                  // 핵심 스탯 3개
                  _buildHeroStats(auth, diary),
                  const SizedBox(height: 10),

                  // 옷장
                  _buildWardrobeRow(auth),
                  const SizedBox(height: 14),

                  // 액션 버튼
                  GestureDetector(
                    onTap: () {
                      if (emotion != null && todayEntry!.recommendedTracks.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MusicPlayerScreen(
                              tracks: todayEntry.recommendedTracks,
                              emotionType: emotion,
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DiaryWriteScreen()),
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            emotion != null ? Icons.music_note_rounded : Icons.edit_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            emotion != null ? '오늘 노래 듣기' : '일기 쓰기',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 핵심 스탯 (히어로 내부) ───────────────────────────
  Widget _buildHeroStats(AuthProvider auth, DiaryProvider diary) {
    final level = diary.muziProfile.level;
    final totalEntries = diary.entries.length;
    final streak = _calcStreak(diary.entries);

    return Row(
      children: [
        _statChip(Icons.auto_awesome_rounded, 'Lv.$level', '레벨', const Color(0xFFBB86FC)),
        const SizedBox(width: 8),
        _statChip(Icons.book_rounded, '$totalEntries', '일기', const Color(0xFF82B8F8)),
        const SizedBox(width: 8),
        _statChip(Icons.local_fire_department_rounded, '$streak일', '연속', const Color(0xFFFF8C6B)),
      ],
    );
  }

  Widget _statChip(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.75)),
            ),
          ],
        ),
      ),
    );
  }

  int _calcStreak(List<DiaryEntry> entries) {
    if (entries.isEmpty) return 0;
    final sorted = [...entries]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final today = DateTime.now();
    int streak = 0;
    DateTime check = DateTime(today.year, today.month, today.day);
    for (final e in sorted) {
      final d = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
      if (d == check) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      } else if (d.isBefore(check)) {
        break;
      }
    }
    return streak;
  }

  // ── 옷장 위젯 ─────────────────────────────────────────
  Widget _buildWardrobeRow(AuthProvider auth) {
    final outfit = auth.user?.equippedOutfit ?? 'none';
    final accessory = auth.user?.equippedAccessory ?? 'none';
    final skin = auth.user?.muziSkin ?? 'default';
    final hasOutfit = outfit != 'none';
    final hasAccessory = accessory != 'none';
    final hasSpecialSkin = skin != 'default';
    final hasAnything = hasOutfit || hasAccessory || hasSpecialSkin;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MuziShopScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F0FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0D0FF)),
        ),
        child: Row(
          children: [
            const Icon(Icons.checkroom_rounded, size: 15, color: Color(0xFF9B59B6)),
            const SizedBox(width: 7),
            if (!hasAnything) ...[
              const Text(
                '꾸미기 아이템을 장착해봐요',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9B59B6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else ...[
              if (hasSpecialSkin) _wardrobeBadge(_skinEmoji(skin), _skinLabel(skin)),
              if (hasSpecialSkin && (hasOutfit || hasAccessory)) _wardrobeDivider(),
              if (hasOutfit) _wardrobeBadge(_outfitEmoji(outfit), _outfitLabel(outfit)),
              if (hasOutfit && hasAccessory) _wardrobeDivider(),
              if (hasAccessory) _wardrobeBadge(_accessoryEmoji(accessory), _accessoryLabel(accessory)),
            ],
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFFCBB4E8)),
          ],
        ),
      ),
    );
  }

  Widget _wardrobeBadge(String emoji, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 15)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF7D4F9E),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _wardrobeDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Text('·', style: TextStyle(color: Color(0xFFCBB4E8), fontSize: 14)),
    );
  }

  String _outfitEmoji(String id) {
    switch (id) {
      case 'ribbon': return '🎀';
      case 'music_hat': return '🎩';
      case 'crown': return '👑';
      case 'star_clip': return '⭐';
      case 'headphones': return '🎧';
      default: return '✨';
    }
  }

  String _outfitLabel(String id) {
    switch (id) {
      case 'ribbon': return '핑크 리본';
      case 'music_hat': return '뮤직 모자';
      case 'crown': return '황금 왕관';
      case 'star_clip': return '별 머리핀';
      case 'headphones': return '헤드폰';
      default: return id;
    }
  }

  String _accessoryEmoji(String id) {
    switch (id) {
      case 'glasses': return '👓';
      case 'heart_glasses': return '🕶️';
      case 'sparkle': return '✨';
      default: return '💫';
    }
  }

  String _accessoryLabel(String id) {
    switch (id) {
      case 'glasses': return '동그란 안경';
      case 'heart_glasses': return '하트 선글라스';
      case 'sparkle': return '반짝이';
      default: return id;
    }
  }

  String _skinEmoji(String id) {
    switch (id) {
      case 'gold': return '🌟';
      case 'pink': return '🌸';
      case 'sky': return '☁️';
      default: return '✨';
    }
  }

  String _skinLabel(String id) {
    switch (id) {
      case 'gold': return '황금 뮤지';
      case 'pink': return '핑크 뮤지';
      case 'sky': return '하늘 뮤지';
      default: return id;
    }
  }

  // ── 오늘의 노래 카드 ──────────────────────────────────
  Widget _buildTodaySongCard(DiaryEntry entry) {
    final emotion = Emotion.fromType(entry.emotion);
    final track = entry.recommendedTracks.first;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MusicPlayerScreen(
            tracks: entry.recommendedTracks,
            emotionType: entry.emotion,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [emotion.color, emotion.color.withValues(alpha: 0.75)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: emotion.color.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(child: Text('🎵', style: TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '뮤지가 고른 오늘의 노래',
                    style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    track.title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    track.artist,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  // ── 뮤지 취향 프로필 카드 ─────────────────────────────
  Widget _buildTasteProfileCard(MuziMusicProfile profile, DiaryProvider diary) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(profile.tasteEmoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '뮤지의 음악 취향',
                      style: TextStyle(fontSize: 11, color: AppTheme.textHint, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      profile.tasteLabel,
                      style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: profile.tasteColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Lv.${profile.level}',
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w900, color: profile.tasteColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            profile.tasteDescription,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
          ),
          if (profile.totalEntries > 0) ...[
            const SizedBox(height: 12),
            _buildEmotionBar(profile),
          ],
        ],
      ),
    );
  }

  Widget _buildEmotionBar(MuziMusicProfile profile) {
    final top3 = profile.topEmotions.take(3).toList();
    if (top3.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('자주 느끼는 감정', style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Row(
            children: top3.map((type) {
              final count = profile.emotionCounts[type] ?? 0;
              final ratio = count / profile.totalEntries;
              final em = Emotion.fromType(type);
              return Expanded(
                flex: (ratio * 100).round().clamp(1, 100),
                child: Container(height: 8, color: em.color),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: top3.map((type) {
            final em = Emotion.fromType(type);
            final count = profile.emotionCounts[type] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: em.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${em.label} $count',
                    style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── 뮤지의 미니 앨범 ──────────────────────────────────
  Widget _buildMiniAlbum(DiaryProvider diary) {
    final recent = diary.recentSongs(limit: 3);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('🎵', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '뮤지의 앨범',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MuziPlaylistScreen()),
                ),
                child: Row(
                  children: [
                    Text(
                      '${diary.savedSongs.length}곡 전체보기',
                      style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppTheme.primary, size: 16),
                  ],
                ),
              ),
            ],
          ),
          if (recent.isEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Text('🎶', style: TextStyle(fontSize: 32, color: Colors.grey.shade300)),
                  const SizedBox(height: 8),
                  const Text(
                    '일기를 쓰면 여기에\n노래가 쌓여요!',
                    style: TextStyle(fontSize: 13, color: AppTheme.textHint, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            ...recent.map((song) => _MiniSongRow(song: song)),
          ],
        ],
      ),
    );
  }

  // ── 최근 일기 ─────────────────────────────────────────
  Widget _buildRecentEntries(DiaryProvider diary) {
    if (diary.entries.isEmpty) return const SizedBox.shrink();
    final recent = diary.entries.take(3).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              '최근 일기',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
          ),
          ...recent.map((entry) => _DiaryEntryItem(entry: entry)),
        ],
      ),
    );
  }
}

// ── StatelessWidget 분리 ──────────────────────────────────

class _MiniSongRow extends StatelessWidget {
  final SavedSong song;
  const _MiniSongRow({required this.song});

  @override
  Widget build(BuildContext context) {
    final emotion = Emotion.fromType(song.emotion);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MusicPlayerScreen(
            tracks: [song.toMusicTrack()],
            emotionType: song.emotion,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [emotion.color, emotion.color.withValues(alpha: 0.6)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(emotion.emoji, style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    song.artist,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.play_circle_outline_rounded, color: emotion.color, size: 28),
          ],
        ),
      ),
    );
  }
}

class _DiaryEntryItem extends StatelessWidget {
  final DiaryEntry entry;
  static final _dateFmt = DateFormat('M월 d일', 'ko_KR');
  const _DiaryEntryItem({required this.entry});

  @override
  Widget build(BuildContext context) {
    final emotion = Emotion.fromType(entry.emotion);
    final dateStr = _dateFmt.format(entry.createdAt);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DiaryDetailScreen(entry: entry)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: emotion.lightColor, borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(emotion.emoji, style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        emotion.label,
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: emotion.color,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        dateStr,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textHint),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.content.length > 50
                        ? '${entry.content.substring(0, 50)}...'
                        : entry.content,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
