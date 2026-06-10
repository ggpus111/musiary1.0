import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
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

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  late YoutubePlayerController _controller;
  final YoutubeAudioService _ytService = YoutubeAudioService();

  late List<MusicTrack> _tracks;
  int _currentIndex = 0;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tracks = List.from(widget.tracks);
    _currentIndex = widget.initialIndex;
    _controller = YoutubePlayerController(
      initialVideoId: _tracks[_currentIndex].videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        loop: false,
        isLive: false,
        enableCaption: false,
        hideControls: true,
        hideThumbnail: false,
        disableDragSeek: false,
        forceHD: false,
      ),
    );
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    if (_controller.value.playerState == PlayerState.ended) {
      _nextTrack();
      return;
    }
    setState(() {});
  }

  void _loadTrack(int index) {
    if (index < 0 || index >= _tracks.length) return;
    _controller.load(_tracks[index].videoId);
  }

  void _togglePlay() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
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

  Future<void> _refreshTracks() async {
    setState(() => _isRefreshing = true);
    _controller.pause();
    try {
      final newTracks = await _ytService.refreshRecommendations(widget.emotionType);
      if (mounted) {
        setState(() {
          _tracks = newTracks;
          _currentIndex = 0;
          _isRefreshing = false;
        });
        _controller.load(newTracks.first.videoId);
      }
    } catch (e) {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emotion = Emotion.fromType(widget.emotionType);
    final track = _tracks[_currentIndex];
    final isPlaying = _controller.value.isPlaying;
    final playerState = _controller.value.playerState;
    final isLoading = playerState == PlayerState.buffering ||
        playerState == PlayerState.unknown ||
        playerState == PlayerState.cued;

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: false,
      ),
      builder: (context, player) {
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
                  _buildAlbumArt(track, emotion, player, isPlaying),
                  const SizedBox(height: 32),
                  _buildTrackInfo(track),
                  const SizedBox(height: 24),
                  _buildProgressBar(),
                  const SizedBox(height: 8),
                  _buildControls(emotion, isPlaying, isLoading),
                  const Spacer(),
                  _buildPlaylist(emotion),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, Emotion emotion) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
          ),
          const Spacer(),
          Column(
            children: [
              const Text('지금 듣는 중', style: TextStyle(color: Colors.white60, fontSize: 11)),
              Text(emotion.label,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
          const Spacer(),
          _isRefreshing
              ? const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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

  Widget _buildAlbumArt(MusicTrack track, Emotion emotion, Widget player, bool isPlaying) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isPlaying ? Colors.white.withValues(alpha: 0.6) : Colors.transparent,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: emotion.color.withValues(alpha: 0.5),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          children: [
            // 썸네일 배경 (플레이어 로딩 전 표시)
            CachedNetworkImage(
              imageUrl: track.thumbnailUrl,
              width: 220,
              height: 220,
              fit: BoxFit.cover,
              errorWidget: (ctx, url, err) => Container(
                color: emotion.lightColor,
                child: Icon(Icons.music_note_rounded, color: emotion.color, size: 64),
              ),
            ),
            // YouTube 플레이어 (동영상 + 오디오)
            Positioned.fill(child: player),
          ],
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
          Text(track.artist, style: const TextStyle(color: Colors.white60, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final position = _controller.value.position;
    final duration = _controller.value.metaData.duration;
    final totalSec = duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0;
    final currentSec =
        position.inSeconds.clamp(0, duration.inSeconds > 0 ? duration.inSeconds : 1).toDouble();

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
              value: currentSec,
              max: totalSec,
              onChanged: (val) => _controller.seekTo(Duration(seconds: val.toInt())),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(position),
                    style: const TextStyle(color: Colors.white60, fontSize: 12)),
                Text(_formatDuration(duration),
                    style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(Emotion emotion, bool isPlaying, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: _currentIndex > 0 ? _prevTrack : null,
            icon: Icon(Icons.skip_previous_rounded,
                color: _currentIndex > 0 ? Colors.white : Colors.white30,
                size: 40),
          ),
          GestureDetector(
            onTap: isLoading ? null : _togglePlay,
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
              child: isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: emotion.color),
                    )
                  : Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: emotion.color,
                      size: 40,
                    ),
            ),
          ),
          IconButton(
            onPressed: _currentIndex < _tracks.length - 1 ? _nextTrack : null,
            icon: Icon(Icons.skip_next_rounded,
                color: _currentIndex < _tracks.length - 1 ? Colors.white : Colors.white30,
                size: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylist(Emotion emotion) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        width: 64, height: 64,
                        color: emotion.lightColor,
                        child: Icon(Icons.music_note, color: emotion.color, size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.title,
                    style: TextStyle(
                      color: isCurrent ? Colors.white : Colors.white60,
                      fontSize: 10,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
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
