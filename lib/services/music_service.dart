import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/diary_entry.dart';
import '../models/emotion.dart';

class MusicService {
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal();

  static const String _apiKey = 'YOUR_YOUTUBE_API_KEY';
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';

  Future<List<MusicTrack>> getRecommendations(EmotionType emotion) async {
    final emotionData = Emotion.fromType(emotion);
    final query = emotionData.musicKeywords.first;

    try {
      final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
        'part': 'snippet',
        'q': '$query playlist',
        'type': 'video',
        'videoCategoryId': '10',
        'maxResults': '5',
        'key': _apiKey,
      });

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List;

        return items.map((item) {
          final videoId = item['id']['videoId'] as String;
          final snippet = item['snippet'];
          return MusicTrack(
            videoId: videoId,
            title: snippet['title'] as String,
            artist: snippet['channelTitle'] as String,
            thumbnailUrl: snippet['thumbnails']['medium']['url'] as String,
            youtubeUrl: 'https://www.youtube.com/watch?v=$videoId',
          );
        }).toList();
      }
    } catch (_) {
      // API 키 없을 때 샘플 데이터 반환
    }

    return _getSampleTracks(emotion);
  }

  List<MusicTrack> _getSampleTracks(EmotionType emotion) {
    final samples = {
      EmotionType.excited: [
        const MusicTrack(
          videoId: 'dQw4w9WgXcQ',
          title: '설레는 마음 - 봄날의 시작',
          artist: '감성 뮤직',
          thumbnailUrl: 'https://i.ytimg.com/vi/dQw4w9WgXcQ/mqdefault.jpg',
          youtubeUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        ),
      ],
      EmotionType.joyful: [
        const MusicTrack(
          videoId: 'ZbZSe6N_BXs',
          title: '오늘도 신나게',
          artist: '유쾌한 밴드',
          thumbnailUrl: 'https://i.ytimg.com/vi/ZbZSe6N_BXs/mqdefault.jpg',
          youtubeUrl: 'https://www.youtube.com/watch?v=ZbZSe6N_BXs',
        ),
      ],
      EmotionType.happy: [
        const MusicTrack(
          videoId: 'y6Sxv-sUYtM',
          title: '행복한 하루',
          artist: '따뜻한 음악',
          thumbnailUrl: 'https://i.ytimg.com/vi/y6Sxv-sUYtM/mqdefault.jpg',
          youtubeUrl: 'https://www.youtube.com/watch?v=y6Sxv-sUYtM',
        ),
      ],
      EmotionType.nostalgic: [
        const MusicTrack(
          videoId: 'fJ9rUzIMcZQ',
          title: '그리운 날들',
          artist: '추억의 선율',
          thumbnailUrl: 'https://i.ytimg.com/vi/fJ9rUzIMcZQ/mqdefault.jpg',
          youtubeUrl: 'https://www.youtube.com/watch?v=fJ9rUzIMcZQ',
        ),
      ],
      EmotionType.calm: [
        const MusicTrack(
          videoId: '5qap5aO4i9A',
          title: 'lofi hip hop - 집중을 위한 음악',
          artist: 'ChilledCow',
          thumbnailUrl: 'https://i.ytimg.com/vi/5qap5aO4i9A/mqdefault.jpg',
          youtubeUrl: 'https://www.youtube.com/watch?v=5qap5aO4i9A',
        ),
      ],
      EmotionType.busy: [
        const MusicTrack(
          videoId: 'DWcJFNfaw9c',
          title: '집중력 향상 음악',
          artist: '스터디 뮤직',
          thumbnailUrl: 'https://i.ytimg.com/vi/DWcJFNfaw9c/mqdefault.jpg',
          youtubeUrl: 'https://www.youtube.com/watch?v=DWcJFNfaw9c',
        ),
      ],
      EmotionType.miserable: [
        const MusicTrack(
          videoId: 'WNIPqafd4As',
          title: '위로가 되는 음악',
          artist: '힐링 뮤직',
          thumbnailUrl: 'https://i.ytimg.com/vi/WNIPqafd4As/mqdefault.jpg',
          youtubeUrl: 'https://www.youtube.com/watch?v=WNIPqafd4As',
        ),
      ],
      EmotionType.tired: [
        const MusicTrack(
          videoId: 'lTRiuFIWV54',
          title: '편안한 수면 음악',
          artist: '릴렉스 뮤직',
          thumbnailUrl: 'https://i.ytimg.com/vi/lTRiuFIWV54/mqdefault.jpg',
          youtubeUrl: 'https://www.youtube.com/watch?v=lTRiuFIWV54',
        ),
      ],
      EmotionType.angry: [
        const MusicTrack(
          videoId: 'TboBaVE7GhI',
          title: '감정 해소 플레이리스트',
          artist: '카타르시스',
          thumbnailUrl: 'https://i.ytimg.com/vi/TboBaVE7GhI/mqdefault.jpg',
          youtubeUrl: 'https://www.youtube.com/watch?v=TboBaVE7GhI',
        ),
      ],
    };

    return samples[emotion] ?? samples[EmotionType.calm]!;
  }
}
