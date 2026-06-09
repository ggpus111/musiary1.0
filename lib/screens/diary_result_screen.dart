import 'package:flutter/material.dart';
import '../models/diary_entry.dart';
import '../models/emotion.dart';
import '../utils/app_theme.dart';
import 'music_player_screen.dart';

class DiaryResultScreen extends StatelessWidget {
  final DiaryEntry entry;

  const DiaryResultScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final emotion = Emotion.fromType(entry.emotion);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, emotion)),
            SliverToBoxAdapter(child: _buildComfortSection(context, emotion)),
            SliverToBoxAdapter(child: _buildMusicSection(context, emotion)),
            SliverToBoxAdapter(child: _buildActionButtons(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Emotion emotion) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [emotion.color, emotion.color.withValues(alpha: 0.7)],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
              const Spacer(),
              const Text(
                '감정 분석 완료',
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 24),
          Text(emotion.emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          Text(
            emotion.label,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          if (entry.emotionScore > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '감정 강도 ${(entry.emotionScore * 100).toInt()}%',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComfortSection(BuildContext context, Emotion emotion) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: emotion.lightColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: emotion.color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite_rounded, color: emotion.color, size: 20),
                const SizedBox(width: 8),
                Text(
                  '뮤지어리의 위로',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: emotion.color),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              entry.comfortMessage,
              style: const TextStyle(fontSize: 16, height: 1.7, color: AppTheme.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMusicSection(BuildContext context, Emotion emotion) {
    if (entry.recommendedTracks.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.music_note_rounded, color: emotion.color, size: 20),
              const SizedBox(width: 8),
              Text('지금 이 감정에 맞는 음악', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          // 플레이어 바로 열기 버튼
          GestureDetector(
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [emotion.color, emotion.color.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      entry.recommendedTracks.first.thumbnailUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => Container(
                        width: 56, height: 56,
                        color: Colors.white24,
                        child: const Icon(Icons.music_note, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.recommendedTracks.first.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${entry.recommendedTracks.length}곡 추천됨',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // 트랙 목록 미리보기
          ...entry.recommendedTracks.asMap().entries.map(
            (e) => _buildMusicTile(context, e.value, emotion, e.key),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicTile(BuildContext context, MusicTrack track, Emotion emotion, int index) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MusicPlayerScreen(
            tracks: entry.recommendedTracks,
            emotionType: entry.emotion,
            initialIndex: index,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Text('${index + 1}',
                style: TextStyle(
                  color: emotion.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                )),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                track.thumbnailUrl,
                width: 44, height: 44, fit: BoxFit.cover,
                errorBuilder: (ctx, err, st) => Container(
                  width: 44, height: 44,
                  color: emotion.lightColor,
                  child: Icon(Icons.music_note, color: emotion.color),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    track.artist,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.play_circle_outline_rounded, color: emotion.color, size: 26),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
          child: const Text('홈으로 돌아가기'),
        ),
      ),
    );
  }

}
