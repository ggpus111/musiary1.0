import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/diary_entry.dart';
import '../models/emotion.dart';
import '../utils/app_theme.dart';

class MusicMiniPlayer extends StatelessWidget {
  final MusicTrack track;
  final EmotionType emotionType;

  const MusicMiniPlayer({
    super.key,
    required this.track,
    required this.emotionType,
  });

  @override
  Widget build(BuildContext context) {
    final emotion = Emotion.fromType(emotionType);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: emotion.lightColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: emotion.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              track.thumbnailUrl,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, st) => Container(
                width: 44,
                height: 44,
                color: emotion.color.withValues(alpha: 0.2),
                child: Icon(Icons.music_note, color: emotion.color, size: 20),
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
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
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
          IconButton(
            onPressed: () async {
              final uri = Uri.parse(track.youtubeUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: Icon(Icons.play_circle_filled_rounded, color: emotion.color, size: 36),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
