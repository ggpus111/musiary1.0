import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/diary_entry.dart';
import '../models/emotion.dart';
import '../providers/diary_provider.dart';
import '../utils/app_theme.dart';
import 'diary_result_screen.dart';

class DiaryDetailScreen extends StatelessWidget {
  final DiaryEntry entry;

  const DiaryDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final emotion = Emotion.fromType(entry.emotion);
    final dateStr = DateFormat('yyyy년 M월 d일 EEEE', 'ko_KR').format(entry.createdAt);

    return Scaffold(
      appBar: AppBar(
        title: Text(dateStr, style: const TextStyle(fontSize: 15)),
        actions: [
          IconButton(
            onPressed: () => _showDeleteDialog(context),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEmotionBadge(emotion),
            const SizedBox(height: 20),
            if (entry.imagePath != null) ...[
              _buildImage(),
              const SizedBox(height: 20),
            ],
            _buildContent(context),
            const SizedBox(height: 20),
            _buildComfortCard(emotion),
            if (entry.recommendedTracks.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildMusicButton(context, emotion),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionBadge(Emotion emotion) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: emotion.lightColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: emotion.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emotion.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(
            emotion.label,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: emotion.color),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.file(
        File(entry.imagePath!),
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(entry.content, style: Theme.of(context).textTheme.bodyLarge),
    );
  }

  Widget _buildComfortCard(Emotion emotion) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: emotion.lightColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💌', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.comfortMessage,
              style: const TextStyle(fontSize: 14, height: 1.6, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicButton(BuildContext context, Emotion emotion) {
    return OutlinedButton.icon(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DiaryResultScreen(entry: entry)),
      ),
      icon: Icon(Icons.music_note_rounded, color: emotion.color),
      label: Text(
        '추천 음악 보기',
        style: TextStyle(color: emotion.color, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: emotion.color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('일기 삭제'),
        content: const Text('이 일기를 삭제할까요? 삭제한 일기는 복구되지 않아요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () async {
              if (entry.id != null) {
                await context.read<DiaryProvider>().deleteDiary(entry.id!);
              }
              if (context.mounted) {
                Navigator.pop(ctx);
                Navigator.pop(context);
              }
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
