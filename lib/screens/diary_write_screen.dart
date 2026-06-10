import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/diary_provider.dart';
import '../models/emotion.dart';
import '../utils/app_theme.dart';
import 'diary_result_screen.dart';

class DiaryWriteScreen extends StatefulWidget {
  const DiaryWriteScreen({super.key});

  @override
  State<DiaryWriteScreen> createState() => _DiaryWriteScreenState();
}

class _DiaryWriteScreenState extends State<DiaryWriteScreen> {
  final TextEditingController _controller = TextEditingController();
  EmotionType? _selectedEmotion;
  String? _imagePath;
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 일기'),
        actions: [
          TextButton(
            onPressed: _canSave() ? _saveDiary : null,
            child: Text(
              '저장',
              style: TextStyle(
                color: _canSave() ? AppTheme.primary : AppTheme.textHint,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEmotionSelector(),
                  const SizedBox(height: 24),
                  _buildDiaryInput(),
                  const SizedBox(height: 24),
                  _buildImageSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          // 저장 중 오버레이 (폼 유지, 반투명 덮개)
          if (_isSaving)
            Container(
              color: Colors.black.withValues(alpha: 0.45),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 36, height: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '일기 저장 중...',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '잠시 후 음악을 추천해 드려요 🎵',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmotionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('지금 기분이 어때요?', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('감정을 선택하면 맞춤 음악을 추천해 드려요', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.1,
          ),
          itemCount: Emotion.all.length,
          itemBuilder: (context, index) {
            final emotion = Emotion.all[index];
            final isSelected = _selectedEmotion == emotion.type;
            return GestureDetector(
              onTap: () => setState(() => _selectedEmotion = emotion.type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? emotion.color : emotion.lightColor,
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected
                      ? Border.all(color: emotion.color, width: 2)
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: emotion.color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(emotion.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 4),
                    Text(
                      emotion.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDiaryInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('오늘 하루는 어땠나요?', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          maxLines: 8,
          maxLength: 1000,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: '오늘의 감정, 있었던 일, 생각들을 자유롭게 적어보세요...',
            hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('사진 추가 (선택)', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (_imagePath != null) ...[
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(_imagePath!),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => setState(() => _imagePath = null),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.divider),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, color: AppTheme.textHint, size: 36),
                  SizedBox(height: 8),
                  Text('사진을 추가해 보세요', style: TextStyle(color: AppTheme.textHint, fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  bool _canSave() => _selectedEmotion != null && _controller.text.trim().isNotEmpty;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 80,
    );
    if (result != null) setState(() => _imagePath = result.path);
  }

  Future<void> _saveDiary() async {
    if (!_canSave()) return;
    setState(() => _isSaving = true);

    // 결과 화면에서 음악을 업데이트하기 위한 콜백
    final resultKey = GlobalKey<DiaryResultScreenState>();

    final entry = await context.read<DiaryProvider>().saveDiary(
      content: _controller.text.trim(),
      selectedEmotion: _selectedEmotion!,
      imagePath: _imagePath,
      onMusicReady: (updated) {
        resultKey.currentState?.updateMusic(updated.recommendedTracks);
      },
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (entry != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DiaryResultScreen(key: resultKey, entry: entry),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장에 실패했습니다. 다시 시도해 주세요.')),
      );
    }
  }
}
