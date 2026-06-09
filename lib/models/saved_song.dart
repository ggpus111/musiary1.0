import 'emotion.dart';
import 'diary_entry.dart';

/// 뮤지의 앨범에 저장된 노래
/// 일기를 쓸 때마다 대표곡 1개가 자동으로 저장됩니다.
class SavedSong {
  final int? id;
  final String videoId;
  final String title;
  final String artist;
  final String thumbnailUrl;
  final String youtubeUrl;
  final EmotionType emotion;
  final DateTime savedAt;
  final int? diaryId;

  const SavedSong({
    this.id,
    required this.videoId,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    required this.youtubeUrl,
    required this.emotion,
    required this.savedAt,
    this.diaryId,
  });

  MusicTrack toMusicTrack() => MusicTrack(
    videoId: videoId,
    title: title,
    artist: artist,
    thumbnailUrl: thumbnailUrl,
    youtubeUrl: youtubeUrl,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'videoId': videoId,
    'title': title,
    'artist': artist,
    'thumbnailUrl': thumbnailUrl,
    'youtubeUrl': youtubeUrl,
    'emotion': emotion.name,
    'savedAt': savedAt.millisecondsSinceEpoch,
    'diaryId': diaryId,
  };

  factory SavedSong.fromMap(Map<String, dynamic> map) => SavedSong(
    id: map['id'] as int?,
    videoId: map['videoId'] as String,
    title: map['title'] as String,
    artist: map['artist'] as String,
    thumbnailUrl: map['thumbnailUrl'] as String,
    youtubeUrl: map['youtubeUrl'] as String,
    emotion: EmotionType.values.firstWhere(
      (e) => e.name == map['emotion'],
      orElse: () => EmotionType.happy,
    ),
    savedAt: DateTime.fromMillisecondsSinceEpoch(map['savedAt'] as int),
    diaryId: map['diaryId'] as int?,
  );

  SavedSong copyWith({int? id}) => SavedSong(
    id: id ?? this.id,
    videoId: videoId,
    title: title,
    artist: artist,
    thumbnailUrl: thumbnailUrl,
    youtubeUrl: youtubeUrl,
    emotion: emotion,
    savedAt: savedAt,
    diaryId: diaryId,
  );

  factory SavedSong.fromDiary({
    required MusicTrack track,
    required EmotionType emotion,
    required DateTime savedAt,
    int? diaryId,
  }) => SavedSong(
    videoId: track.videoId,
    title: track.title,
    artist: track.artist,
    thumbnailUrl: track.thumbnailUrl,
    youtubeUrl: track.youtubeUrl,
    emotion: emotion,
    savedAt: savedAt,
    diaryId: diaryId,
  );
}
