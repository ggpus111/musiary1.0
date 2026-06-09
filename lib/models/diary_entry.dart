import 'dart:convert';
import 'emotion.dart';

class DiaryEntry {
  final int? id;
  final String content;
  final String? imagePath;
  final EmotionType emotion;
  final double emotionScore;
  final String comfortMessage;
  final List<MusicTrack> recommendedTracks;
  final DateTime createdAt;

  DiaryEntry({
    this.id,
    required this.content,
    this.imagePath,
    required this.emotion,
    this.emotionScore = 0.0,
    required this.comfortMessage,
    this.recommendedTracks = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'imagePath': imagePath,
      'emotion': emotion.name,
      'emotionScore': emotionScore,
      'comfortMessage': comfortMessage,
      'recommendedTracks': jsonEncode(recommendedTracks.map((t) => t.toJson()).toList()),
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'] as int?,
      content: map['content'] as String,
      imagePath: map['imagePath'] as String?,
      emotion: EmotionType.values.firstWhere(
        (e) => e.name == map['emotion'],
        orElse: () => EmotionType.happy,
      ),
      emotionScore: (map['emotionScore'] as num).toDouble(),
      comfortMessage: map['comfortMessage'] as String,
      recommendedTracks: _parseTracks(map['recommendedTracks'] as String?),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  static List<MusicTrack> _parseTracks(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((j) => MusicTrack.fromJson(j as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  DiaryEntry copyWith({
    int? id,
    String? content,
    String? imagePath,
    EmotionType? emotion,
    double? emotionScore,
    String? comfortMessage,
    List<MusicTrack>? recommendedTracks,
    DateTime? createdAt,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      content: content ?? this.content,
      imagePath: imagePath ?? this.imagePath,
      emotion: emotion ?? this.emotion,
      emotionScore: emotionScore ?? this.emotionScore,
      comfortMessage: comfortMessage ?? this.comfortMessage,
      recommendedTracks: recommendedTracks ?? this.recommendedTracks,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class MusicTrack {
  final String videoId;
  final String title;
  final String artist;
  final String thumbnailUrl;
  final String youtubeUrl;

  const MusicTrack({
    required this.videoId,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    required this.youtubeUrl,
  });

  Map<String, dynamic> toJson() => {
    'videoId': videoId,
    'title': title,
    'artist': artist,
    'thumbnailUrl': thumbnailUrl,
    'youtubeUrl': youtubeUrl,
  };

  factory MusicTrack.fromJson(Map<String, dynamic> json) => MusicTrack(
    videoId: json['videoId'] as String,
    title: json['title'] as String,
    artist: json['artist'] as String,
    thumbnailUrl: json['thumbnailUrl'] as String,
    youtubeUrl: json['youtubeUrl'] as String,
  );
}

