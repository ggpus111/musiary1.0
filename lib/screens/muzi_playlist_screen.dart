import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/diary_provider.dart';
import '../models/saved_song.dart';
import '../models/emotion.dart';
import '../utils/app_theme.dart';
import '../widgets/muzi_character.dart';
import 'music_player_screen.dart';

/// 🎵 뮤지의 앨범 — 일기에서 쌓인 노래 컬렉션
class MuziPlaylistScreen extends StatefulWidget {
  const MuziPlaylistScreen({super.key});

  @override
  State<MuziPlaylistScreen> createState() => _MuziPlaylistScreenState();
}

class _MuziPlaylistScreenState extends State<MuziPlaylistScreen> {
  EmotionType? _filterEmotion; // null = 전체

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Consumer<DiaryProvider>(
        builder: (context, diary, _) {
          final profile = diary.muziProfile;
          final allSongs = diary.savedSongs;
          final filtered = _filterEmotion == null
              ? allSongs
              : allSongs.where((s) => s.emotion == _filterEmotion).toList();

          return CustomScrollView(
            slivers: [
              // ── 헤더 ──────────────────────────────────
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: profile.tasteColor,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeader(profile, allSongs.length),
                ),
              ),

              // ── 감정 필터 ──────────────────────────────
              SliverToBoxAdapter(
                child: _buildEmotionFilter(allSongs),
              ),

              // ── 노래 목록 ──────────────────────────────
              filtered.isEmpty
                  ? SliverFillRemaining(child: _buildEmpty(allSongs.isEmpty))
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => _buildSongCard(filtered[i], i),
                          childCount: filtered.length,
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(dynamic profile, int songCount) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            profile.tasteColor,
            profile.tasteColor.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${profile.tasteEmoji} 뮤지의 앨범',
                      style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.tasteLabel,
                      style: const TextStyle(
                        fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _headerChip('🎵 $songCount곡'),
                        const SizedBox(width: 8),
                        _headerChip('Lv.${profile.level} ${profile.levelLabel}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              MuziCharacter(
                size: 70,
                showSpeechBubble: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: const TextStyle(
        fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600,
      )),
    );
  }

  Widget _buildEmotionFilter(List<SavedSong> allSongs) {
    // 실제로 노래가 있는 감정만 필터로 표시
    final emotions = allSongs.map((s) => s.emotion).toSet().toList();
    if (emotions.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 52,
      margin: const EdgeInsets.only(top: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // 전체
          _filterChip(null, '전체 🎵', allSongs.length),
          const SizedBox(width: 8),
          ...emotions.map((e) {
            final count = allSongs.where((s) => s.emotion == e).length;
            final em = Emotion.fromType(e);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _filterChip(e, '${em.emoji} ${em.label}', count),
            );
          }),
        ],
      ),
    );
  }

  Widget _filterChip(EmotionType? emotion, String label, int count) {
    final selected = _filterEmotion == emotion;
    Color chipColor;
    if (emotion == null) {
      chipColor = AppTheme.primary;
    } else {
      chipColor = Emotion.fromType(emotion).color;
    }

    return GestureDetector(
      onTap: () => setState(() => _filterEmotion = emotion),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? chipColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? chipColor : Colors.grey.shade200,
            width: selected ? 0 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: chipColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                color: selected ? Colors.white70 : AppTheme.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongCard(SavedSong song, int index) {
    final emotion = Emotion.fromType(song.emotion);
    final dateStr = DateFormat('M월 d일', 'ko_KR').format(song.savedAt);

    return Container(
      margin: EdgeInsets.only(bottom: 10, top: index == 0 ? 12 : 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadow,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
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
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // 앨범 아트 (감정 색상 원)
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [emotion.color, emotion.color.withValues(alpha: 0.6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(emotion.emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),
              // 곡 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      song.artist,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: emotion.lightColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            emotion.label,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: emotion.color),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(dateStr, style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
                      ],
                    ),
                  ],
                ),
              ),
              // 재생 버튼
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: emotion.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.play_arrow_rounded, color: emotion.color, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(bool noSongsAtAll) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MuziCharacter(
              size: 110,
              showSpeechBubble: true,
              overrideMessage: noSongsAtAll
                  ? '일기를 쓰면 노래가\n여기에 쌓여요! 🎵'
                  : '이 감정의 노래는\n아직 없어요 🥺',
            ),
            const SizedBox(height: 20),
            if (noSongsAtAll)
              Text(
                '일기를 쓸 때마다 뮤지가\n그날의 감정에 맞는 노래를 골라드려요.',
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.6),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
