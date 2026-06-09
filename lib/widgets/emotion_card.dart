import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/diary_entry.dart';
import '../models/emotion.dart';

class EmotionCard extends StatelessWidget {
  final DiaryEntry entry;

  const EmotionCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final emotion = Emotion.fromType(entry.emotion);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            emotion.color.withValues(alpha: 0.9),
            emotion.color.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: emotion.color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '오늘의 감정',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('HH:mm').format(entry.createdAt),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(emotion.emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 12),
              Text(
                emotion.label,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            entry.content.length > 80
                ? '${entry.content.substring(0, 80)}...'
                : entry.content,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.music_note_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text(
                '음악 ${entry.recommendedTracks.length}곡 추천됨',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
