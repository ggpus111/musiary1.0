import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/diary_entry.dart';
import '../models/emotion.dart';
import '../services/youtube_audio_service.dart';

class MusicPlayerScreen extends StatefulWidget {
  final List<MusicTrack> tracks;
  final EmotionType emotionType;
  final int initialIndex;

  const MusicPlayerScreen({
    super.key,
    required this.tracks,
    required this.emotionType,
    this.initialIndex = 0,
  });

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen>
    with SingleTickerProviderStateMixin {
  late AudioPlayer _player;
  late AnimationController _albumAnim;
  final YoutubeAudioService _ytService = YoutubeAudioService();

  late List<MusicTrack> _tracks;
  int _currentIndex = 0;
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _tracks = List.from(widget.tracks);
    _currentIndex = widget.initialIndex;
    _player = AudioPlayer();
    _albumAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _setupPlayerListeners();
    _loadTrack(_currentIndex);
  }

  void _setupPlayerListeners() {
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      final playing = state.playing;
      setState(() => _isPlaying = playing);
      if (playing) {
        _albumAnim.repeat();
      } else {
        _albumAnim.stop();
      }
      // 곡 끝나면 다음 곡 자동 재생
      if (state.processingState == ProcessingState.completed) {
        _nextTrack();
      }
    });

    _player.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });

    _player.durationStream.listen((dur) {
      if (mounted && dur != null) setState(() => _duration = dur);
    });
  }

  Future<void> _refreshTracks() async {
    setState(() => _isRefreshing = true);
    await _player.stop();
    try {
      final newTracks = await _ytService.refreshRecommendations(widget.emotionType);
      if (mounted) {
        setState(() {
          _tracks = newTracks;
          _currentIndex = 0;
          _isRefreshing = false;
        });
        _loadTrack(0);
      }
    } catch (e) {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _loadTrack(int index) async {
    if (index < 0 || index >= _tracks.length) return;
    setState(() {
      _isLoading = true;
      _errorMsg = null;
      _position = Duration.zero;
      _duration = Duration.zero;
    });

    final track = _tracks[index];
    try {
      final url = await _ytService.getAudioStreamUrl(track.videoId);
      if (url == null) throw Exception('스트림 URL을 가져올 수 없습니다.');
      await _player.setUrl(url);
      await _player.play();
      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMsg = '이 곡은 재생할 수 없어요 😢\n다음 곡을 눌러보세요.';
        });
      }
    }
  }

  void _togglePlay() {
    if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void _nextTrack() {
    if (_currentIndex < _tracks.length - 1) {
      setState(() => _currentIndex++);
      _loadTrack(_currentIndex);
    }
  }

  void _prevTrack() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _loadTrack(_currentIndex);
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _player.dispose();
    _albumAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emotion = Emotion.fromType(widget.emotionType);
    final track = _tracks[_currentIndex];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              emotion.color,
              emotion.color.withValues(alpha: 0.7),
              Colors.black87,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context, emotion),
              const Spacer(),
              _buildAlbumArt(track, emotion),
              const SizedBox(height: 32),
              _buildTrackInfo(track),
              const SizedBox(height: 24),
              if (_errorMsg != null) _buildErrorMsg(),
              _buildProgressBar(),
              const SizedBox(height: 8),
              _buildControls(emotion),
              const Spacer(),
              _buildPlaylist(emotion),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, Emotion emotion) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.white, size: 32),
          ),
          const Spacer(),
          Column(
            children: [
              const Text('지금 듣는 중',
                  style: TextStyle(color: Colors.white60, fontSize: 11)),
              Text(emotion.label,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
          const Spacer(),
          // AI 새로고침 버튼
          _isRefreshing
              ? const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white,
                  ),
                )
              : IconButton(
                  onPressed: _refreshTracks,
                  tooltip: 'AI 새 노래 추천',
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 24),
                ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(MusicTrack track, Emotion emotion) {
    return AnimatedBuilder(
      animation: _albumAnim,
      builder: (context, child) => Transform.rotate(
        angle: _isPlaying ? _albumAnim.value * 2 * 3.14159 : 0,
        child: child,
      ),
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: emotion.color.withValues(alpha: 0.5),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: track.thumbnailUrl,
            fit: BoxFit.cover,
            placeholder: (ctx, url) => Container(
              color: emotion.lightColor,
              child: Icon(Icons.music_note_rounded,
                  color: emotion.color, size: 64),
            ),
            errorWidget: (ctx, url, err) => Container(
              color: emotion.lightColor,
              child: Icon(Icons.music_note_rounded,
                  color: emotion.color, size: 64),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackInfo(MusicTrack track) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(
            track.title,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            track.artist,
            style: const TextStyle(color: Colors.white60, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMsg() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          _errorMsg!,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final total = _duration.inSeconds > 0 ? _duration.inSeconds.toDouble() : 1.0;
    final current = _position.inSeconds.clamp(0, _duration.inSeconds).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white30,
              thumbColor: Colors.white,
              overlayColor: Colors.white24,
            ),
            child: Slider(
              value: current,
              max: total,
              onChanged: (val) {
                _player.seek(Duration(seconds: val.toInt()));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(_position),
                    style: const TextStyle(color: Colors.white60, fontSize: 12)),
                Text(_formatDuration(_duration),
                    style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(Emotion emotion) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 이전 곡
          IconButton(
            onPressed: _currentIndex > 0 ? _prevTrack : null,
            icon: Icon(Icons.skip_previous_rounded,
                color: _currentIndex > 0 ? Colors.white : Colors.white30,
                size: 40),
          ),
          // 재생/일시정지
          GestureDetector(
            onTap: _isLoading ? null : _togglePlay,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: emotion.color,
                      ),
                    )
                  : Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: emotion.color,
                      size: 40,
                    ),
            ),
          ),
          // 다음 곡
          IconButton(
            onPressed:
                _currentIndex < _tracks.length - 1 ? _nextTrack : null,
            icon: Icon(Icons.skip_next_rounded,
                color: _currentIndex < _tracks.length - 1
                    ? Colors.white
                    : Colors.white30,
                size: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylist(Emotion emotion) {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _tracks.length,
        itemBuilder: (context, index) {
          final t = _tracks[index];
          final isCurrent = index == _currentIndex;
          return GestureDetector(
            onTap: () {
              if (!isCurrent) {
                setState(() => _currentIndex = index);
                _loadTrack(index);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrent ? Colors.white : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: t.thumbnailUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorWidget: (ctx, url, err) => Container(
                        width: 64,
                        height: 64,
                        color: emotion.lightColor,
                        child: Icon(Icons.music_note,
                            color: emotion.color, size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.title,
                    style: TextStyle(
                      color: isCurrent ? Colors.white : Colors.white60,
                      fontSize: 10,
                      fontWeight: isCurrent
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
