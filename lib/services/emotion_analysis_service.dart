import '../models/emotion.dart';

class EmotionAnalysisService {
  static final EmotionAnalysisService _instance = EmotionAnalysisService._internal();
  factory EmotionAnalysisService() => _instance;
  EmotionAnalysisService._internal();

  EmotionAnalysisResult analyzeText(String text) {
    if (text.trim().isEmpty) {
      return const EmotionAnalysisResult(
        emotion: EmotionType.calm,
        score: 0.5,
        detectedKeywords: [],
      );
    }

    final Map<EmotionType, double> scores = {};
    final List<String> detectedKeywords = [];

    for (final emotion in Emotion.all) {
      double score = 0.0;
      for (final keyword in emotion.keywords) {
        if (text.contains(keyword)) {
          score += 1.0;
          if (!detectedKeywords.contains(keyword)) {
            detectedKeywords.add(keyword);
          }
        }
      }
      if (score > 0) {
        scores[emotion.type] = score / emotion.keywords.length;
      }
    }

    if (scores.isEmpty) {
      return const EmotionAnalysisResult(
        emotion: EmotionType.calm,
        score: 0.3,
        detectedKeywords: [],
      );
    }

    final topEmotion = scores.entries.reduce((a, b) => a.value > b.value ? a : b);

    return EmotionAnalysisResult(
      emotion: topEmotion.key,
      score: topEmotion.value.clamp(0.0, 1.0),
      detectedKeywords: detectedKeywords,
    );
  }

  double calculateIntensity(String text) {
    if (text.isEmpty) return 0.0;

    double intensity = 0.0;
    intensity += (text.length / 500).clamp(0.0, 0.4);

    final exclamationCount = '!'.allMatches(text).length;
    final questionCount = '?'.allMatches(text).length;
    final ellipsisCount = '...'.allMatches(text).length;

    intensity += (exclamationCount * 0.05).clamp(0.0, 0.2);
    intensity += (ellipsisCount * 0.03).clamp(0.0, 0.15);
    intensity += (questionCount * 0.02).clamp(0.0, 0.1);

    // ㅠㅠ, ㅋㅋ 등 반복 표현 감지
    final sadPattern = RegExp(r'[ㅠ-ㅡ]{2,}');
    final laughPattern = RegExp(r'[ㅋㅇ]{2,}');
    if (sadPattern.hasMatch(text)) intensity += 0.15;
    if (laughPattern.hasMatch(text)) intensity += 0.1;

    return intensity.clamp(0.0, 1.0);
  }

  EmotionType combineAnalysis({
    required EmotionType userSelected,
    required String text,
  }) {
    final textResult = analyzeText(text);
    if (textResult.score > 0.6) return textResult.emotion;
    return userSelected;
  }
}

class EmotionAnalysisResult {
  final EmotionType emotion;
  final double score;
  final List<String> detectedKeywords;

  const EmotionAnalysisResult({
    required this.emotion,
    required this.score,
    required this.detectedKeywords,
  });
}
