import 'dart:math';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/diary_entry.dart';
import '../models/emotion.dart';

/// AI 랜덤 음악 추천 서비스
/// youtube_explode_dart 사용 → API 키 불필요, 완전 무료
/// 매번 다른 키워드 조합으로 랜덤 한국 노래 추천
class YoutubeAudioService {
  static final YoutubeAudioService _instance = YoutubeAudioService._internal();
  factory YoutubeAudioService() => _instance;
  YoutubeAudioService._internal();

  final YoutubeExplode _yt = YoutubeExplode();
  final Random _rnd = Random();

  /// 감정별 다양한 검색 키워드 풀 (AI 랜덤 선택)
  static const Map<EmotionType, List<String>> _keywordPool = {
    EmotionType.excited: [
      '설레는 노래 케이팝', '두근두근 한국 노래 플레이리스트',
      '설레는 감성 발라드', '첫사랑 느낌 한국 노래',
      '두근거리는 케이팝 모음', '설렘 감성 노래 추천',
      'IU 설레는 노래', '케이팝 설레는 곡 모음',
    ],
    EmotionType.joyful: [
      '신나는 케이팝 2024', '기분 좋은 한국 노래 플레이리스트',
      '신나는 한국 댄스곡', '즐거운 노래 케이팝 모음',
      '신나는 K-POP 히트곡', '기분업 되는 한국 노래',
      '케이팝 신나는 곡 모음', '파티 기분 케이팝',
    ],
    EmotionType.happy: [
      '행복한 한국 노래 플레이리스트', '따뜻한 감성 발라드 모음',
      '행복 노래 케이팝', '기쁜 날 듣는 노래 한국',
      '따뜻한 한국 노래 추천', '행복할 때 듣는 케이팝',
      '좋은 날 노래 한국', '밝은 노래 케이팝 2024',
    ],
    EmotionType.nostalgic: [
      '그리운 한국 발라드 모음', '추억 소환 한국 노래',
      '옛날 감성 케이팝', '보고싶다 느낌 발라드',
      '그리움 노래 한국', '추억의 발라드 명곡 모음',
      '2010년대 감성 케이팝', '그리운 사람 떠오르는 노래',
    ],
    EmotionType.calm: [
      '잔잔한 한국 노래 플레이리스트', '힐링 음악 한국 감성',
      '편안한 발라드 모음', '카페 음악 한국 잔잔',
      '공부할 때 듣는 노래 한국', '잔잔한 어쿠스틱 한국',
      '새벽 감성 한국 노래', '힐링 케이팝 노래 모음',
    ],
    EmotionType.busy: [
      '집중력 향상 한국 음악', '공부 집중 케이팝',
      '카페 공부 음악 한국', '집중할 때 듣는 노래',
      '워크아웃 케이팝', '에너지 넘치는 한국 노래',
      '공부 플레이리스트 케이팝', '집중 BGM 한국',
    ],
    EmotionType.miserable: [
      '위로 노래 한국 감성', '슬플 때 듣는 발라드 모음',
      '눈물 노래 한국 2024', '힘들 때 위로되는 노래',
      '상처받은 마음 달래는 노래', '슬픈 감성 발라드',
      '혼자일 때 듣는 노래 한국', '위로 케이팝 플레이리스트',
    ],
    EmotionType.tired: [
      '지칠 때 듣는 노래 한국', '힐링 수면 음악 한국',
      '번아웃 위로 노래', '피곤할 때 듣는 잔잔한 노래',
      '편안한 수면 음악 한국', '지친 하루 끝 노래',
      '몽환적인 한국 노래', '쉬고 싶을 때 노래 한국',
    ],
    EmotionType.angry: [
      '화날 때 듣는 노래 한국', '스트레스 해소 케이팝',
      '강렬한 케이팝 모음', '카타르시스 한국 노래',
      '답답할 때 케이팝', '화날 때 신나는 노래',
      '격렬한 케이팝 히트곡', '울분 해소 노래 한국',
    ],
  };

  /// 감정 기반 AI 랜덤 음악 추천
  Future<List<MusicTrack>> searchByEmotion(EmotionType emotion) async {
    final pool = _keywordPool[emotion] ?? _keywordPool[EmotionType.calm]!;

    // 랜덤 키워드 2개 섞어서 검색 (매번 다른 결과)
    final shuffled = List<String>.from(pool)..shuffle(_rnd);
    final keyword = shuffled.first;

    return _search(keyword, emotion);
  }

  /// 특정 키워드로 재검색 (새로고침 기능용)
  Future<List<MusicTrack>> refreshRecommendations(EmotionType emotion) async {
    final pool = _keywordPool[emotion] ?? _keywordPool[EmotionType.calm]!;
    final shuffled = List<String>.from(pool)..shuffle(_rnd);
    // 두 번째 키워드 사용 (첫 번째와 다른 결과)
    final keyword = shuffled[_rnd.nextInt(shuffled.length)];
    return _search(keyword, emotion);
  }

  Future<List<MusicTrack>> _search(String query, EmotionType emotion) async {
    try {
      final results = await _yt.search.search(query);
      final allVideos = results.toList();

      // 결과 셔플 → 매번 다른 순서
      allVideos.shuffle(_rnd);

      final tracks = <MusicTrack>[];
      for (final video in allVideos) {
        if (video.duration == null) continue;
        final dur = video.duration!;
        if (dur.inSeconds < 60 || dur.inSeconds > 600) continue;

        tracks.add(MusicTrack(
          videoId: video.id.value,
          title: _cleanTitle(video.title),
          artist: video.author,
          thumbnailUrl: video.thumbnails.mediumResUrl,
          youtubeUrl: 'https://www.youtube.com/watch?v=${video.id.value}',
        ));
        if (tracks.length >= 5) break;
      }

      return tracks.isEmpty ? _getFallbackTracks(emotion) : tracks;
    } catch (e) {
      return _getFallbackTracks(emotion);
    }
  }

  /// 오디오 스트림 URL 가져오기
  Future<String?> getAudioStreamUrl(String videoId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final audioStreams = manifest.audioOnly.sortByBitrate();
      if (audioStreams.isEmpty) return null;
      final stream = audioStreams.length > 1
          ? audioStreams[audioStreams.length ~/ 2]
          : audioStreams.last;
      return stream.url.toString();
    } catch (e) {
      return null;
    }
  }

  String _cleanTitle(String title) {
    return title
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .replaceAll(RegExp(r'\(.*?MV.*?\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\(.*?Official.*?\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\(.*?Lyric.*?\)', caseSensitive: false), '')
        .trim();
  }

  /// 네트워크 오류 대비 폴백 목록
  List<MusicTrack> _getFallbackTracks(EmotionType emotion) {
    final fallbacks = {
      EmotionType.miserable: [
        MusicTrack(videoId: 'Km71Rr9K-Bw', title: '아이유 - 밤편지', artist: '아이유 IU',
            thumbnailUrl: 'https://i.ytimg.com/vi/Km71Rr9K-Bw/mqdefault.jpg',
            youtubeUrl: 'https://www.youtube.com/watch?v=Km71Rr9K-Bw'),
      ],
      EmotionType.happy: [
        MusicTrack(videoId: 'HQqEFd6e2Y8', title: '볼빨간사춘기 - 우주를 줄게', artist: '볼빨간사춘기',
            thumbnailUrl: 'https://i.ytimg.com/vi/HQqEFd6e2Y8/mqdefault.jpg',
            youtubeUrl: 'https://www.youtube.com/watch?v=HQqEFd6e2Y8'),
      ],
      EmotionType.nostalgic: [
        MusicTrack(videoId: 'IHNzOHi8sJs', title: 'BTS - Spring Day', artist: 'BTS',
            thumbnailUrl: 'https://i.ytimg.com/vi/IHNzOHi8sJs/mqdefault.jpg',
            youtubeUrl: 'https://www.youtube.com/watch?v=IHNzOHi8sJs'),
      ],
    };
    return fallbacks[emotion] ?? fallbacks[EmotionType.happy]!;
  }

  void dispose() => _yt.close();
}
