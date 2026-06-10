import 'dart:math';
import 'package:flutter/material.dart';
import '../models/emotion.dart';
import '../models/muzi_item.dart';

/// 뮤지어리 마스코트 캐릭터 "뮤지 (Muzi)"
/// 9가지 감정에 따라 완전히 다른 표정과 이펙트를 보여줍니다.
class MuziCharacter extends StatefulWidget {
  final EmotionType? emotion;
  final double size;
  final bool showSpeechBubble;
  final String? overrideMessage;
  final String outfit;
  final String accessory;
  final String background;

  const MuziCharacter({
    super.key,
    this.emotion,
    this.size = 120,
    this.showSpeechBubble = true,
    this.overrideMessage,
    this.outfit = 'none',
    this.accessory = 'none',
    this.background = 'default',
  });

  @override
  State<MuziCharacter> createState() => _MuziCharacterState();
}

class _MuziCharacterState extends State<MuziCharacter>
    with TickerProviderStateMixin {
  late AnimationController _bounceCtrl;
  late AnimationController _blinkCtrl;
  late AnimationController _particleCtrl;
  late Animation<double> _bounceAnim;
  late Animation<double> _blinkAnim;
  late Animation<double> _particleAnim;

  @override
  void initState() {
    super.initState();

    _bounceCtrl = AnimationController(
      vsync: this,
      duration: _bounceDuration(),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0, end: _bounceAmount()).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
    );

    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _blinkAnim = Tween<double>(begin: 1.0, end: 0.05).animate(_blinkCtrl);
    _startBlinking();

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _particleAnim = CurvedAnimation(parent: _particleCtrl, curve: Curves.linear);
  }

  Duration _bounceDuration() {
    switch (widget.emotion) {
      case EmotionType.joyful:
      case EmotionType.excited:
        return const Duration(milliseconds: 500);
      case EmotionType.tired:
      case EmotionType.miserable:
        return const Duration(milliseconds: 1600);
      case EmotionType.calm:
        return const Duration(milliseconds: 1400);
      default:
        return const Duration(milliseconds: 900);
    }
  }

  double _bounceAmount() {
    switch (widget.emotion) {
      case EmotionType.joyful:
      case EmotionType.excited:
        return -16.0;
      case EmotionType.tired:
      case EmotionType.miserable:
        return -3.0;
      case EmotionType.angry:
        return -6.0;
      default:
        return -10.0;
    }
  }

  void _startBlinking() async {
    // 졸린/비참한 감정은 눈을 거의 안 깜빡임 (이미 눈이 처져있으므로)
    final skipBlink = widget.emotion == EmotionType.tired ||
        widget.emotion == EmotionType.miserable;
    while (mounted) {
      await Future.delayed(Duration(seconds: skipBlink ? 8 : 3));
      if (!mounted) break;
      await _blinkCtrl.forward();
      await _blinkCtrl.reverse();
      if (!skipBlink) {
        await Future.delayed(const Duration(milliseconds: 80));
        if (!mounted) break;
        await _blinkCtrl.forward();
        await _blinkCtrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _blinkCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showSpeechBubble) _buildSpeechBubble(),
        if (widget.showSpeechBubble) const SizedBox(height: 6),
        AnimatedBuilder(
          animation: _bounceAnim,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, _bounceAnim.value),
            child: child,
          ),
          child: _buildBody(),
        ),
      ],
    );
  }

  Widget _buildSpeechBubble() {
    final emotion = widget.emotion != null ? Emotion.fromType(widget.emotion!) : null;
    final msg = widget.overrideMessage ?? _getGreeting(emotion);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: const BoxConstraints(maxWidth: 220),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(18),
          bottomLeft: Radius.circular(4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        msg,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF2D3436),
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBody() {
    final emotion = widget.emotion != null ? Emotion.fromType(widget.emotion!) : null;
    final bodyColor = emotion?.color ?? const Color(0xFFC4966A);
    final s = widget.size;
    final bgColors = getBackgroundGradient(widget.background);
    final hasBackground = widget.background != 'default';

    return SizedBox(
      width: s * 1.4,
      height: s * 1.4,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 배경 원
          if (hasBackground)
            Positioned(
              top: s * 0.1,
              child: Container(
                width: s * 1.1,
                height: s * 1.05,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [bgColors[0], bgColors.length > 1 ? bgColors[1] : bgColors[0]],
                  ),
                ),
              ),
            ),
          if (hasBackground) _buildBackgroundDecoration(bgColors, s),

          // 그림자
          Positioned(
            bottom: s * 0.04,
            child: Container(
              width: s * 0.7,
              height: s * 0.1,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(s * 0.4),
              ),
            ),
          ),

          // 파티클 효과 (감정별)
          AnimatedBuilder(
            animation: _particleAnim,
            builder: (ctx, _) => CustomPaint(
              size: Size(s * 1.4, s * 1.4),
              painter: _EmotionParticlePainter(
                emotion: widget.emotion,
                progress: _particleAnim.value,
                bodyColor: bodyColor,
              ),
            ),
          ),

          // 몸통
          Positioned(
            top: s * 0.18,
            child: AnimatedBuilder(
              animation: _blinkAnim,
              builder: (ctx, _) => CustomPaint(
                size: Size(s, s),
                painter: _MuziBodyPainter(
                  bodyColor: bodyColor,
                  emotion: widget.emotion,
                  blinkAnim: _blinkAnim,
                  outfit: widget.outfit,
                  accessory: widget.accessory,
                  particleValue: _particleAnim.value,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecoration(List<Color> colors, double s) {
    switch (widget.background) {
      case 'night_sky':
        return Positioned(
          top: s * 0.05,
          child: SizedBox(
            width: s * 1.1, height: s * 1.0,
            child: CustomPaint(painter: _StarsPainter()),
          ),
        );
      case 'sakura':
        return Positioned(
          top: s * 0.05,
          child: SizedBox(
            width: s * 1.1, height: s * 1.0,
            child: CustomPaint(painter: _PetalsPainter()),
          ),
        );
      case 'galaxy':
        return Positioned(
          top: s * 0.05,
          child: AnimatedBuilder(
            animation: _particleAnim,
            builder: (ctx, _) => SizedBox(
              width: s * 1.1, height: s * 1.0,
              child: CustomPaint(
                painter: _GalaxyPainter(progress: _particleAnim.value),
              ),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _getGreeting(Emotion? emotion) {
    if (emotion == null) {
      final greetings = [
        '오늘 기분은 어때? 🎵',
        '나는 뮤지야! 같이 음악 들어요 🎶',
        '일기 써봐요! 노래 골라줄게 💿',
        '안녕! 오늘 하루 어땠어? 🌟',
      ];
      return greetings[DateTime.now().second % greetings.length];
    }
    switch (emotion.type) {
      case EmotionType.excited:   return '설레는 마음이 느껴져! 💓\n딱 맞는 노래 찾았어!';
      case EmotionType.joyful:    return '같이 신나자! 😄\n기분 좋은 노래 가져왔어!';
      case EmotionType.happy:     return '행복해 보여서 나도 기뻐! 🌟\n따뜻한 노래 준비했어!';
      case EmotionType.nostalgic: return '그리운 마음 알아... 🥺\n추억 떠올리게 하는 노래야!';
      case EmotionType.calm:      return '편안한 거 좋아~ 😌\n잔잔한 노래 가져왔어!';
      case EmotionType.busy:      return '수고했어! 💪\n집중에 도움되는 노래야!';
      case EmotionType.miserable: return '많이 힘들지... 💙\n같이 있어줄게. 위로 노래야!';
      case EmotionType.tired:     return '푹 쉬어도 돼요 🌙\n편안한 노래 틀어줄게!';
      case EmotionType.angry:     return '화풀어! 🔥\n시원하게 들을 노래 가져왔어!';
    }
  }
}

// ══════════════════════════════════════════════════════
/// 감정별 파티클 이펙트 (하트, 눈물, Zzz, 스팀, 음표)
// ══════════════════════════════════════════════════════
class _EmotionParticlePainter extends CustomPainter {
  final EmotionType? emotion;
  final double progress;
  final Color bodyColor;

  const _EmotionParticlePainter({
    required this.emotion,
    required this.progress,
    required this.bodyColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    switch (emotion) {
      case EmotionType.excited:
        _drawFloatingHearts(canvas, cx, cy, size);
        break;
      case EmotionType.joyful:
        _drawMusicNotes(canvas, cx, cy, size);
        break;
      case EmotionType.miserable:
        _drawFallingTears(canvas, cx, cy, size);
        break;
      case EmotionType.tired:
        _drawZzz(canvas, cx, cy, size);
        break;
      case EmotionType.angry:
        _drawSteam(canvas, cx, cy, size);
        break;
      case EmotionType.nostalgic:
        _drawSparkles(canvas, cx, cy, size);
        break;
      default:
        break;
    }
  }

  void _drawFloatingHearts(Canvas canvas, double cx, double cy, Size size) {
    final positions = [
      Offset(cx - size.width * 0.3, cy - size.height * 0.1),
      Offset(cx + size.width * 0.28, cy - size.height * 0.05),
      Offset(cx - size.width * 0.2, cy + size.height * 0.1),
    ];
    for (int i = 0; i < positions.length; i++) {
      final phase = (progress + i * 0.33) % 1.0;
      final dy = -phase * size.height * 0.35;
      final alpha = (sin(phase * pi)).clamp(0.0, 1.0);
      final scale = 0.6 + phase * 0.4;
      final paint = Paint()..color = const Color(0xFFE0909C).withValues(alpha: alpha * 0.85);
      canvas.save();
      canvas.translate(positions[i].dx, positions[i].dy + dy);
      canvas.scale(scale, scale);
      _drawHeart(canvas, Offset.zero, size.width * 0.055, paint);
      canvas.restore();
    }
  }

  void _drawMusicNotes(Canvas canvas, double cx, double cy, Size size) {
    final notes = ['♪', '♫', '♩'];
    final offsets = [
      Offset(cx - size.width * 0.3, cy),
      Offset(cx + size.width * 0.3, cy - size.height * 0.05),
      Offset(cx - size.width * 0.1, cy - size.height * 0.15),
    ];
    for (int i = 0; i < offsets.length; i++) {
      final phase = (progress + i * 0.33) % 1.0;
      final dy = -phase * size.height * 0.3;
      final alpha = (sin(phase * pi)).clamp(0.0, 1.0);
      final tp = TextPainter(
        text: TextSpan(
          text: notes[i],
          style: TextStyle(
            fontSize: size.width * 0.13,
            color: bodyColor.withValues(alpha: alpha * 0.9),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(offsets[i].dx - tp.width / 2, offsets[i].dy + dy));
    }
  }

  void _drawFallingTears(Canvas canvas, double cx, double cy, Size size) {
    final xPositions = [cx - size.width * 0.18, cx + size.width * 0.18, cx - size.width * 0.05];
    for (int i = 0; i < xPositions.length; i++) {
      final phase = (progress + i * 0.33) % 1.0;
      final dy = phase * size.height * 0.4;
      final alpha = (1.0 - phase * 0.7).clamp(0.0, 1.0);
      final paint = Paint()..color = const Color(0xFF9EC4E8).withValues(alpha: alpha * 0.8);
      final tearX = xPositions[i];
      final tearY = cy + size.height * 0.05 + dy;
      // 물방울 모양
      final path = Path()
        ..moveTo(tearX, tearY - size.width * 0.06)
        ..quadraticBezierTo(tearX + size.width * 0.035, tearY, tearX, tearY + size.width * 0.05)
        ..quadraticBezierTo(tearX - size.width * 0.035, tearY, tearX, tearY - size.width * 0.06);
      canvas.drawPath(path, paint);
    }
  }

  void _drawZzz(Canvas canvas, double cx, double cy, Size size) {
    final zOffsets = [
      Offset(cx + size.width * 0.25, cy - size.height * 0.05),
      Offset(cx + size.width * 0.32, cy - size.height * 0.15),
      Offset(cx + size.width * 0.38, cy - size.height * 0.25),
    ];
    for (int i = 0; i < zOffsets.length; i++) {
      final phase = (progress + i * 0.33) % 1.0;
      final alpha = (sin(phase * pi) * 0.8).clamp(0.0, 0.9);
      final fontSize = size.width * (0.08 + i * 0.03);
      final tp = TextPainter(
        text: TextSpan(
          text: 'z',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: const Color(0xFFAA90C8).withValues(alpha: alpha),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(zOffsets[i].dx, zOffsets[i].dy - phase * size.height * 0.1));
    }
  }

  void _drawSteam(Canvas canvas, double cx, double cy, Size size) {
    final steamPaint = Paint()
      ..color = const Color(0xFFD07868).withValues(alpha: 0.5)
      ..strokeWidth = size.width * 0.025
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int side = -1; side <= 1; side += 2) {
      final baseX = cx + side * size.width * 0.38;
      final baseY = cy - size.height * 0.05;
      for (int i = 0; i < 2; i++) {
        final phase = (progress + i * 0.5) % 1.0;
        final alpha = (1.0 - phase).clamp(0.0, 1.0);
        steamPaint.color = const Color(0xFFD07868).withValues(alpha: alpha * 0.6);
        final dy = -phase * size.height * 0.25;
        final dx = sin(phase * pi * 2) * size.width * 0.04;
        final path = Path()
          ..moveTo(baseX + dx, baseY + dy)
          ..quadraticBezierTo(
            baseX + dx + side * size.width * 0.05, baseY + dy - size.height * 0.08,
            baseX + dx, baseY + dy - size.height * 0.16,
          );
        canvas.drawPath(path, steamPaint);
      }
    }
  }

  void _drawSparkles(Canvas canvas, double cx, double cy, Size size) {
    final positions = [
      Offset(cx - size.width * 0.35, cy - size.height * 0.1),
      Offset(cx + size.width * 0.35, cy - size.height * 0.05),
      Offset(cx + size.width * 0.15, cy + size.height * 0.15),
    ];
    for (int i = 0; i < positions.length; i++) {
      final phase = (progress + i * 0.33) % 1.0;
      final alpha = (sin(phase * pi)).clamp(0.0, 1.0);
      final paint = Paint()..color = const Color(0xFFE8C87A).withValues(alpha: alpha * 0.85);
      _drawStar(canvas, positions[i], size.width * 0.045, paint);
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy + r * 0.4);
    path.cubicTo(center.dx, center.dy, center.dx - r, center.dy, center.dx - r, center.dy - r * 0.3);
    path.arcToPoint(Offset(center.dx, center.dy - r * 0.1), radius: Radius.circular(r * 0.5));
    path.arcToPoint(Offset(center.dx + r, center.dy - r * 0.3), radius: Radius.circular(r * 0.5));
    path.cubicTo(center.dx + r, center.dy, center.dx, center.dy, center.dx, center.dy + r * 0.4);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawStar(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outer = Offset(
        center.dx + r * cos((i * 72 - 90) * pi / 180),
        center.dy + r * sin((i * 72 - 90) * pi / 180),
      );
      final inner = Offset(
        center.dx + r * 0.4 * cos(((i * 72 + 36) - 90) * pi / 180),
        center.dy + r * 0.4 * sin(((i * 72 + 36) - 90) * pi / 180),
      );
      if (i == 0) {
        path.moveTo(outer.dx, outer.dy);
      } else {
        path.lineTo(outer.dx, outer.dy);
      }
      path.lineTo(inner.dx, inner.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_EmotionParticlePainter old) =>
      old.progress != progress || old.emotion != emotion;
}

// ══════════════════════════════════════════════════════
/// 뮤지 몸통 그리기 — 9가지 감정 표정 완전 차별화
// ══════════════════════════════════════════════════════
class _MuziBodyPainter extends CustomPainter {
  final Color bodyColor;
  final EmotionType? emotion;
  final Animation<double> blinkAnim;
  final String outfit;
  final String accessory;
  final double particleValue;

  _MuziBodyPainter({
    required this.bodyColor,
    required this.emotion,
    required this.blinkAnim,
    this.outfit = 'none',
    this.accessory = 'none',
    this.particleValue = 0,
  }) : super(repaint: blinkAnim);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // 몸통
    final bodyPaint = Paint()..color = bodyColor;
    canvas.drawCircle(
      Offset(cx, h * 0.45),
      w * 0.44,
      Paint()
        ..color = bodyColor.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.drawCircle(Offset(cx, h * 0.45), w * 0.42, bodyPaint);

    // 귀
    canvas.drawCircle(Offset(cx - w * 0.28, h * 0.14), w * 0.12, bodyPaint);
    canvas.drawCircle(Offset(cx + w * 0.28, h * 0.14), w * 0.12, bodyPaint);
    canvas.drawCircle(Offset(cx - w * 0.28, h * 0.14), w * 0.07,
        Paint()..color = Colors.white.withValues(alpha: 0.4));
    canvas.drawCircle(Offset(cx + w * 0.28, h * 0.14), w * 0.07,
        Paint()..color = Colors.white.withValues(alpha: 0.4));

    final eyeY = h * 0.38;

    // 감정별 눈 그리기
    _drawEyes(canvas, size, cx, eyeY);

    // 감정별 특수 눈썹/이마 장식
    _drawBrowsAndExtra(canvas, size, cx, eyeY);

    // 입
    _drawMouth(canvas, size, cx);

    // 볼터치
    _drawBlush(canvas, size, cx);

    // 악세사리
    if (accessory != 'none') {
      _drawAccessory(canvas, size, cx, eyeY);
    }

    // 머리 장식
    if (outfit != 'none') {
      _drawOutfit(canvas, size, cx);
    }
  }

  // ── 감정별 눈 ────────────────────────────────────────
  void _drawEyes(Canvas canvas, Size size, double cx, double eyeY) {
    final w = size.width;

    switch (emotion) {
      // 설렘: 하트 동공
      case EmotionType.excited:
        _drawHeartEye(canvas, Offset(cx - w * 0.16, eyeY), w, false);
        _drawHeartEye(canvas, Offset(cx + w * 0.16, eyeY), w, true);
        break;

      // 즐거움: 초승달 모양 웃는 눈 (∪)
      case EmotionType.joyful:
        _drawCrescentEye(canvas, Offset(cx - w * 0.16, eyeY), w);
        _drawCrescentEye(canvas, Offset(cx + w * 0.16, eyeY), w);
        break;

      // 행복: 반달 모양 눈 (기분 좋게 살짝 찡긋)
      case EmotionType.happy:
        _drawHappyEye(canvas, Offset(cx - w * 0.16, eyeY), w);
        _drawHappyEye(canvas, Offset(cx + w * 0.16, eyeY), w);
        break;

      // 그리움: 반짝이는 촉촉한 눈
      case EmotionType.nostalgic:
        _drawNostalgicEye(canvas, Offset(cx - w * 0.16, eyeY), w, true);
        _drawNostalgicEye(canvas, Offset(cx + w * 0.16, eyeY), w, false);
        break;

      // 편안함: 실눈 (— 모양)
      case EmotionType.calm:
        _drawCalmEye(canvas, Offset(cx - w * 0.16, eyeY), w);
        _drawCalmEye(canvas, Offset(cx + w * 0.16, eyeY), w);
        break;

      // 바쁨: 결의에 찬 눈 (살짝 찡그림)
      case EmotionType.busy:
        _drawDeterminedEye(canvas, Offset(cx - w * 0.16, eyeY), w, true);
        _drawDeterminedEye(canvas, Offset(cx + w * 0.16, eyeY), w, false);
        break;

      // 비참함: 눈물 가득한 눈
      case EmotionType.miserable:
        _drawMiserableEye(canvas, Offset(cx - w * 0.16, eyeY), w, true);
        _drawMiserableEye(canvas, Offset(cx + w * 0.16, eyeY), w, false);
        break;

      // 지침: 무거운 눈꺼풀 (반쯤 감긴)
      case EmotionType.tired:
        _drawTiredEye(canvas, Offset(cx - w * 0.16, eyeY), w);
        _drawTiredEye(canvas, Offset(cx + w * 0.16, eyeY), w);
        break;

      // 화남: 날카로운 눈
      case EmotionType.angry:
        _drawAngryEye(canvas, Offset(cx - w * 0.16, eyeY), w, true);
        _drawAngryEye(canvas, Offset(cx + w * 0.16, eyeY), w, false);
        break;

      // 기본 눈
      default:
        _drawDefaultEye(canvas, Offset(cx - w * 0.16, eyeY), w);
        _drawDefaultEye(canvas, Offset(cx + w * 0.16, eyeY), w);
        break;
    }
  }

  void _drawDefaultEye(Canvas canvas, Offset center, double w) {
    final blink = blinkAnim.value;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1.0, blink);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 0.14, height: w * 0.16),
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(Offset(0, w * 0.02), w * 0.07, Paint()..color = const Color(0xFF5C3D2E));
    canvas.drawCircle(Offset(w * 0.02, -w * 0.01), w * 0.025, Paint()..color = Colors.white);
    canvas.restore();
  }

  // 하트 동공 (설렘)
  void _drawHeartEye(Canvas canvas, Offset center, double w, bool flip) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 0.15, height: w * 0.17),
      Paint()..color = Colors.white,
    );
    final heartPaint = Paint()..color = const Color(0xFFE0909C);
    if (flip) canvas.scale(-1, 1);
    _drawHeart(canvas, Offset(0, w * 0.01), w * 0.055, heartPaint);
    canvas.restore();
    // 반짝임
    canvas.drawCircle(Offset(center.dx + w * 0.03, center.dy - w * 0.04),
        w * 0.02, Paint()..color = Colors.white.withValues(alpha: 0.9));
  }

  // 초승달 눈 (즐거움) — ∪ 모양, 웃을 때 눈이 굽어짐
  void _drawCrescentEye(Canvas canvas, Offset center, double w) {
    final paint = Paint()
      ..color = const Color(0xFF5C3D2E)
      ..strokeWidth = w * 0.035
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(center.dx - w * 0.075, center.dy - w * 0.02)
      ..quadraticBezierTo(center.dx, center.dy + w * 0.07, center.dx + w * 0.075, center.dy - w * 0.02);
    canvas.drawPath(path, paint);
  }

  // 반짝이는 행복한 눈 (행복) — 별 반짝임 있는 눈
  void _drawHappyEye(Canvas canvas, Offset center, double w) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    // 흰 눈 전체
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 0.15, height: w * 0.16),
      Paint()..color = Colors.white,
    );
    // 위 절반을 덮어 반달처럼 (찡긋)
    canvas.drawRect(
      Rect.fromLTWH(-w * 0.09, -w * 0.1, w * 0.18, w * 0.08),
      Paint()..color = bodyColor,
    );
    canvas.drawCircle(Offset(0, w * 0.03), w * 0.062, Paint()..color = const Color(0xFF5C3D2E));
    // 반짝임 큰 것 + 작은 것
    canvas.drawCircle(Offset(w * 0.02, -w * 0.01), w * 0.025, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(-w * 0.02, w * 0.025), w * 0.014, Paint()..color = Colors.white);
    canvas.restore();
  }

  // 그리움 눈: 왼쪽=촉촉한 눈, 오른쪽=살짝 윙크 (꿈꾸는 표정)
  void _drawNostalgicEye(Canvas canvas, Offset center, double w, bool isLeft) {
    if (!isLeft) {
      // 오른쪽: 살짝 윙크 (∪ 모양)
      final paint = Paint()
        ..color = const Color(0xFF5C3D2E)
        ..strokeWidth = w * 0.038
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final path = Path()
        ..moveTo(center.dx - w * 0.07, center.dy - w * 0.015)
        ..quadraticBezierTo(center.dx, center.dy + w * 0.065, center.dx + w * 0.07, center.dy - w * 0.015);
      canvas.drawPath(path, paint);
      return;
    }

    // 왼쪽: 촉촉하게 반짝이는 눈
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 0.15, height: w * 0.17),
      Paint()..color = Colors.white,
    );
    // 파란 눈물 기운
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, w * 0.02), width: w * 0.11, height: w * 0.09),
      Paint()..color = const Color(0xFFDFEFFF),
    );
    canvas.drawCircle(Offset(0, w * 0.02), w * 0.065, Paint()..color = const Color(0xFF5C3D2E));
    // 큰 반짝임 (촉촉한 눈)
    canvas.drawCircle(Offset(w * 0.025, -w * 0.025), w * 0.038,
        Paint()..color = Colors.white.withValues(alpha: 0.95));
    canvas.drawCircle(Offset(-w * 0.02, w * 0.02), w * 0.018,
        Paint()..color = Colors.white.withValues(alpha: 0.7));
    canvas.restore();

    // 눈물 한 방울
    final tearPaint = Paint()..color = const Color(0xFF9EC4E8).withValues(alpha: 0.8);
    final tearPath = Path()
      ..moveTo(center.dx, center.dy + w * 0.09)
      ..quadraticBezierTo(center.dx + w * 0.028, center.dy + w * 0.14, center.dx, center.dy + w * 0.18)
      ..quadraticBezierTo(center.dx - w * 0.028, center.dy + w * 0.14, center.dx, center.dy + w * 0.09);
    canvas.drawPath(tearPath, tearPaint);
  }

  // 작은 점 눈 (편안함) — ･ω･ 느낌의 귀여운 점 눈
  void _drawCalmEye(Canvas canvas, Offset center, double w) {
    // 흰 눈 배경
    canvas.drawOval(
      Rect.fromCenter(center: center, width: w * 0.12, height: w * 0.13),
      Paint()..color = Colors.white,
    );
    // 작고 동그란 동공
    canvas.drawCircle(center, w * 0.05, Paint()..color = const Color(0xFF5C3D2E));
    // 작은 반짝임
    canvas.drawCircle(
      Offset(center.dx + w * 0.01, center.dy - w * 0.01),
      w * 0.018,
      Paint()..color = Colors.white,
    );
  }

  // 결의 찬 눈 (바쁨)
  void _drawDeterminedEye(Canvas canvas, Offset center, double w, bool isLeft) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 0.13, height: w * 0.13),
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(Offset(0, 0), w * 0.058, Paint()..color = const Color(0xFF5C3D2E));
    canvas.drawCircle(Offset(w * 0.015, -w * 0.015), w * 0.018, Paint()..color = Colors.white);
    // 위 절반 살짝 잘라서 찡그린 효과
    canvas.drawRect(
      Rect.fromLTWH(-w * 0.09, -w * 0.09, w * 0.18, w * 0.04),
      Paint()..color = bodyColor,
    );
    canvas.restore();
  }

  // 눈물 가득 눈 (비참함)
  void _drawMiserableEye(Canvas canvas, Offset center, double w, bool isLeft) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 0.15, height: w * 0.18),
      Paint()..color = Colors.white,
    );
    // 파란 눈물색 배경 (눈이 촉촉)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, w * 0.03), width: w * 0.12, height: w * 0.1),
      Paint()..color = const Color(0xFFDFEFFF),
    );
    canvas.drawCircle(Offset(0, w * 0.01), w * 0.065, Paint()..color = const Color(0xFF5C3D2E));
    canvas.drawCircle(Offset(w * 0.02, -w * 0.02), w * 0.022, Paint()..color = Colors.white);
    canvas.restore();

    // 눈물 줄기
    final tearPaint = Paint()..color = const Color(0xFF9EC4E8).withValues(alpha: 0.8);
    final tearPath = Path()
      ..moveTo(center.dx, center.dy + w * 0.1)
      ..quadraticBezierTo(center.dx + w * 0.03, center.dy + w * 0.17, center.dx, center.dy + w * 0.23)
      ..quadraticBezierTo(center.dx - w * 0.03, center.dy + w * 0.17, center.dx, center.dy + w * 0.1);
    canvas.drawPath(tearPath, tearPaint);
  }

  // 무거운 눈꺼풀 (지침)
  void _drawTiredEye(Canvas canvas, Offset center, double w) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 0.14, height: w * 0.14),
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(Offset(0, w * 0.02), w * 0.055, Paint()..color = const Color(0xFF5C3D2E));
    // 무거운 눈꺼풀 (눈 위 60% 덮기)
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(-w * 0.09, -w * 0.09, w * 0.18, w * 0.1),
        topLeft: const Radius.circular(0),
        topRight: const Radius.circular(0),
        bottomLeft: const Radius.circular(6),
        bottomRight: const Radius.circular(6),
      ),
      Paint()..color = bodyColor,
    );
    canvas.restore();
  }

  // 날카로운 화난 눈 (화남)
  void _drawAngryEye(Canvas canvas, Offset center, double w, bool isLeft) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 0.13, height: w * 0.13),
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(Offset(0, 0), w * 0.058, Paint()..color = const Color(0xFF5C3D2E));
    canvas.drawCircle(Offset(w * 0.015, -w * 0.01), w * 0.018, Paint()..color = Colors.white);
    // 날카로운 눈썹선이 눈 안쪽에 걸침
    final browPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;
    // 삼각형 눈꺼풀 — 안쪽이 더 내려온 각도
    final lidPath = Path();
    if (isLeft) {
      lidPath
        ..moveTo(-w * 0.09, -w * 0.09)
        ..lineTo(w * 0.07, -w * 0.09)
        ..lineTo(w * 0.07, -w * 0.02)
        ..lineTo(-w * 0.09, -w * 0.07)
        ..close();
    } else {
      lidPath
        ..moveTo(-w * 0.07, -w * 0.09)
        ..lineTo(w * 0.09, -w * 0.09)
        ..lineTo(w * 0.09, -w * 0.07)
        ..lineTo(-w * 0.07, -w * 0.02)
        ..close();
    }
    canvas.drawPath(lidPath, browPaint);
    canvas.restore();
  }

  // ── 눈썹 / 이마 특수 효과 ────────────────────────────
  void _drawBrowsAndExtra(Canvas canvas, Size size, double cx, double eyeY) {
    final w = size.width;

    switch (emotion) {
      case EmotionType.angry:
        // 굵고 V자 눈썹
        final browPaint = Paint()
          ..color = const Color(0xFF5C3D2E)
          ..strokeWidth = w * 0.038
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(cx - w * 0.28, eyeY - w * 0.12),
          Offset(cx - w * 0.1, eyeY - w * 0.06),
          browPaint,
        );
        canvas.drawLine(
          Offset(cx + w * 0.28, eyeY - w * 0.12),
          Offset(cx + w * 0.1, eyeY - w * 0.06),
          browPaint,
        );
        break;

      case EmotionType.busy:
        // 결의에 찬 눈썹
        final browPaint = Paint()
          ..color = const Color(0xFF5C3D2E)
          ..strokeWidth = w * 0.03
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(cx - w * 0.25, eyeY - w * 0.1),
          Offset(cx - w * 0.09, eyeY - w * 0.07),
          browPaint,
        );
        canvas.drawLine(
          Offset(cx + w * 0.25, eyeY - w * 0.1),
          Offset(cx + w * 0.09, eyeY - w * 0.07),
          browPaint,
        );
        // 땀방울
        final sweatPaint = Paint()..color = const Color(0xFF9EC4E8).withValues(alpha: 0.85);
        final sweatPath = Path()
          ..moveTo(cx + w * 0.32, eyeY - w * 0.15)
          ..quadraticBezierTo(cx + w * 0.36, eyeY - w * 0.09, cx + w * 0.32, eyeY - w * 0.05)
          ..quadraticBezierTo(cx + w * 0.28, eyeY - w * 0.09, cx + w * 0.32, eyeY - w * 0.15);
        canvas.drawPath(sweatPath, sweatPaint);
        break;

      case EmotionType.miserable:
        // 처진 눈썹
        final browPaint = Paint()
          ..color = const Color(0xFF5C3D2E).withValues(alpha: 0.7)
          ..strokeWidth = w * 0.028
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(cx - w * 0.27, eyeY - w * 0.07),
          Offset(cx - w * 0.1, eyeY - w * 0.12),
          browPaint,
        );
        canvas.drawLine(
          Offset(cx + w * 0.27, eyeY - w * 0.07),
          Offset(cx + w * 0.1, eyeY - w * 0.12),
          browPaint,
        );
        break;

      case EmotionType.tired:
        // 처진 눈썹
        final browPaint = Paint()
          ..color = const Color(0xFF5C3D2E).withValues(alpha: 0.55)
          ..strokeWidth = w * 0.025
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(cx - w * 0.26, eyeY - w * 0.09),
          Offset(cx - w * 0.1, eyeY - w * 0.08),
          browPaint,
        );
        canvas.drawLine(
          Offset(cx + w * 0.26, eyeY - w * 0.09),
          Offset(cx + w * 0.1, eyeY - w * 0.08),
          browPaint,
        );
        break;

      case EmotionType.excited:
        // 올라간 눈썹 (설렘)
        final browPaint = Paint()
          ..color = const Color(0xFF5C3D2E).withValues(alpha: 0.6)
          ..strokeWidth = w * 0.025
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        final eyeBrowPath1 = Path()
          ..moveTo(cx - w * 0.25, eyeY - w * 0.14)
          ..quadraticBezierTo(cx - w * 0.17, eyeY - w * 0.18, cx - w * 0.1, eyeY - w * 0.14);
        final eyeBrowPath2 = Path()
          ..moveTo(cx + w * 0.1, eyeY - w * 0.14)
          ..quadraticBezierTo(cx + w * 0.17, eyeY - w * 0.18, cx + w * 0.25, eyeY - w * 0.14);
        canvas.drawPath(eyeBrowPath1, browPaint);
        canvas.drawPath(eyeBrowPath2, browPaint);
        break;

      default:
        break;
    }
  }

  // ── 감정별 입 ────────────────────────────────────────
  void _drawMouth(Canvas canvas, Size size, double cx) {
    final w = size.width;
    final h = size.height;
    final mouthY = h * 0.56;

    final strokePaint = Paint()
      ..color = const Color(0xFF5C3D2E)
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    switch (emotion) {

      // 설렘: 활짝 웃음 + 치아
      case EmotionType.excited:
        final path = Path()
          ..moveTo(cx - w * 0.2, mouthY - w * 0.01)
          ..quadraticBezierTo(cx, mouthY + w * 0.14, cx + w * 0.2, mouthY - w * 0.01);
        canvas.drawPath(path, strokePaint);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, mouthY + w * 0.05), width: w * 0.28, height: w * 0.09),
            const Radius.circular(5),
          ),
          Paint()..color = Colors.white,
        );
        // 치아 선
        canvas.drawLine(Offset(cx, mouthY + w * 0.01), Offset(cx, mouthY + w * 0.1),
            Paint()..color = Colors.grey.shade200..strokeWidth = w * 0.015..style = PaintingStyle.stroke);
        break;

      // 즐거움: 얼굴 절반 웃는 입 + 치아 확실히 보임
      case EmotionType.joyful:
        final outerPath = Path()
          ..moveTo(cx - w * 0.25, mouthY - w * 0.01)
          ..quadraticBezierTo(cx, mouthY + w * 0.21, cx + w * 0.25, mouthY - w * 0.01);
        canvas.drawPath(outerPath, strokePaint..strokeWidth = w * 0.038);
        // 치아 칸 (더 넓게)
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, mouthY + w * 0.07), width: w * 0.34, height: w * 0.13),
            const Radius.circular(5),
          ),
          Paint()..color = Colors.white,
        );
        // 치아 구분선 3개
        final tLinePaint = Paint()
          ..color = Colors.grey.shade300
          ..strokeWidth = w * 0.012
          ..style = PaintingStyle.stroke;
        for (final dx in [-w * 0.09, 0.0, w * 0.09]) {
          canvas.drawLine(
            Offset(cx + dx, mouthY + w * 0.01),
            Offset(cx + dx, mouthY + w * 0.13),
            tLinePaint,
          );
        }
        break;

      // 행복: 따뜻한 미소
      case EmotionType.happy:
        final path = Path()
          ..moveTo(cx - w * 0.17, mouthY)
          ..quadraticBezierTo(cx, mouthY + w * 0.11, cx + w * 0.17, mouthY);
        canvas.drawPath(path, strokePaint);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, mouthY + w * 0.04), width: w * 0.22, height: w * 0.08),
            const Radius.circular(4),
          ),
          Paint()..color = Colors.white,
        );
        break;

      // 그리움: 씁쓸한 미소 (한쪽이 살짝 올라간)
      case EmotionType.nostalgic:
        final path = Path()
          ..moveTo(cx - w * 0.14, mouthY + w * 0.02)
          ..quadraticBezierTo(cx - w * 0.02, mouthY + w * 0.08, cx + w * 0.14, mouthY - w * 0.01);
        canvas.drawPath(path, strokePaint);
        break;

      // 편안함: ω 모양 (고양이 미소) — 귀엽고 평온한 느낌
      case EmotionType.calm:
        final calmPaint = Paint()
          ..color = const Color(0xFF5C3D2E)
          ..strokeWidth = w * 0.028
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        // 왼쪽 ω 곡선
        final leftCurve = Path()
          ..moveTo(cx - w * 0.14, mouthY - w * 0.01)
          ..quadraticBezierTo(cx - w * 0.07, mouthY + w * 0.07, cx, mouthY - w * 0.01);
        // 오른쪽 ω 곡선
        final rightCurve = Path()
          ..moveTo(cx, mouthY - w * 0.01)
          ..quadraticBezierTo(cx + w * 0.07, mouthY + w * 0.07, cx + w * 0.14, mouthY - w * 0.01);
        canvas.drawPath(leftCurve, calmPaint);
        canvas.drawPath(rightCurve, calmPaint);
        break;

      // 바쁨: 일자 입 (긴장)
      case EmotionType.busy:
        canvas.drawLine(
          Offset(cx - w * 0.13, mouthY),
          Offset(cx + w * 0.13, mouthY),
          strokePaint,
        );
        break;

      // 비참함: 뒤집힌 U (엉엉 우는 입)
      case EmotionType.miserable:
        final path = Path()
          ..moveTo(cx - w * 0.2, mouthY + w * 0.06)
          ..quadraticBezierTo(cx, mouthY - w * 0.06, cx + w * 0.2, mouthY + w * 0.06);
        canvas.drawPath(path, strokePaint..strokeWidth = w * 0.035);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, mouthY + w * 0.02), width: w * 0.26, height: w * 0.1),
            const Radius.circular(5),
          ),
          Paint()..color = Colors.white.withValues(alpha: 0.5),
        );
        break;

      // 지침: 지그재그 물결 입
      case EmotionType.tired:
        final path = Path()..moveTo(cx - w * 0.17, mouthY);
        final steps = 4;
        for (int i = 0; i < steps; i++) {
          final x = cx - w * 0.17 + (w * 0.34 / steps) * (i + 0.5);
          final y = mouthY + (i % 2 == 0 ? w * 0.04 : -w * 0.04);
          path.lineTo(x, y);
        }
        path.lineTo(cx + w * 0.17, mouthY);
        canvas.drawPath(path, strokePaint..strokeWidth = w * 0.025);
        break;

      // 화남: 이 악문 입
      case EmotionType.angry:
        final path = Path()
          ..moveTo(cx - w * 0.16, mouthY - w * 0.01)
          ..lineTo(cx + w * 0.16, mouthY - w * 0.01);
        canvas.drawPath(path, strokePaint..strokeWidth = w * 0.03);
        // 이빨 격자
        final teethPaint = Paint()..color = Colors.white;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, mouthY + w * 0.02), width: w * 0.22, height: w * 0.065),
            const Radius.circular(3),
          ),
          teethPaint,
        );
        final linePaint = Paint()
          ..color = Colors.grey.shade300
          ..strokeWidth = w * 0.01
          ..style = PaintingStyle.stroke;
        for (int i = -1; i <= 1; i++) {
          canvas.drawLine(
            Offset(cx + i * w * 0.07, mouthY - w * 0.01),
            Offset(cx + i * w * 0.07, mouthY + w * 0.05),
            linePaint,
          );
        }
        break;

      default:
        final path = Path()
          ..moveTo(cx - w * 0.14, mouthY - w * 0.01)
          ..quadraticBezierTo(cx, mouthY + w * 0.09, cx + w * 0.14, mouthY - w * 0.01);
        canvas.drawPath(path, strokePaint);
    }
  }

  // 볼터치 (감정별 강도 다름)
  void _drawBlush(Canvas canvas, Size size, double cx) {
    final w = size.width;
    final h = size.height;
    double alpha;
    Color blushColor;

    switch (emotion) {
      case EmotionType.excited:
      case EmotionType.joyful:
        alpha = 0.38;
        blushColor = const Color(0xFFE8A0A8);
        break;
      case EmotionType.happy:
        alpha = 0.30;
        blushColor = const Color(0xFFE8C87A);
        break;
      case EmotionType.angry:
        alpha = 0.35;
        blushColor = const Color(0xFFD07868);
        break;
      case EmotionType.tired:
      case EmotionType.miserable:
        alpha = 0.15;
        blushColor = const Color(0xFFAA9688);
        break;
      case EmotionType.calm:
        alpha = 0.22;
        blushColor = const Color(0xFF8EBD98);
        break;
      default:
        alpha = 0.25;
        blushColor = const Color(0xFFE8A0A8);
    }

    // 바깥 볼터치 (더 크고 부드럽게)
    final blushPaint = Paint()..color = blushColor.withValues(alpha: alpha * 0.55);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - w * 0.29, h * 0.51), width: w * 0.25, height: w * 0.14),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + w * 0.29, h * 0.51), width: w * 0.25, height: w * 0.14),
      blushPaint,
    );
    // 안쪽 볼터치 (진한 포인트)
    final innerBlushPaint = Paint()..color = blushColor.withValues(alpha: alpha);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - w * 0.28, h * 0.51), width: w * 0.14, height: w * 0.08),
      innerBlushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + w * 0.28, h * 0.51), width: w * 0.14, height: w * 0.08),
      innerBlushPaint,
    );
  }

  // ── 머리 장식 ────────────────────────────────────────
  void _drawOutfit(Canvas canvas, Size size, double cx) {
    final w = size.width;
    final h = size.height;
    final topOfHead = h * 0.04;

    switch (outfit) {
      case 'ribbon':    _drawRibbon(canvas, cx, topOfHead, w); break;
      case 'music_hat': _drawMusicHat(canvas, cx, topOfHead, w, h); break;
      case 'crown':     _drawCrown(canvas, cx, topOfHead, w); break;
      case 'star_clip': _drawStarClip(canvas, cx, h * 0.06, w); break;
      case 'headphones': _drawHeadphones(canvas, cx, h * 0.1, w); break;
    }
  }

  void _drawRibbon(Canvas canvas, double cx, double y, double w) {
    final ribbonPaint = Paint()..color = const Color(0xFFE0909C);
    final darkPaint = Paint()..color = const Color(0xFFE84393);
    final leftWing = Path()
      ..moveTo(cx - w * 0.02, y + w * 0.04)
      ..lineTo(cx - w * 0.16, y)
      ..lineTo(cx - w * 0.14, y + w * 0.1)
      ..close();
    final rightWing = Path()
      ..moveTo(cx + w * 0.02, y + w * 0.04)
      ..lineTo(cx + w * 0.16, y)
      ..lineTo(cx + w * 0.14, y + w * 0.1)
      ..close();
    canvas.drawPath(leftWing, ribbonPaint);
    canvas.drawPath(rightWing, ribbonPaint);
    canvas.drawCircle(Offset(cx, y + w * 0.04), w * 0.04, darkPaint);
  }

  void _drawMusicHat(Canvas canvas, double cx, double topY, double w, double h) {
    final hatPaint = Paint()..color = const Color(0xFF5C3D2E);
    final brimPaint = Paint()..color = const Color(0xFF1E1E2E);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, topY + w * 0.12), width: w * 0.52, height: w * 0.08),
        const Radius.circular(4),
      ),
      brimPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, topY + w * 0.04), width: w * 0.38, height: w * 0.14),
        const Radius.circular(6),
      ),
      hatPaint,
    );
    final notePt = Paint()
      ..color = const Color(0xFFE8C87A)
      ..strokeWidth = w * 0.025
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx + w * 0.02, topY - w * 0.01), Offset(cx + w * 0.02, topY + w * 0.07), notePt);
    canvas.drawCircle(Offset(cx - w * 0.01, topY + w * 0.07), w * 0.025, Paint()..color = const Color(0xFFE8C87A));
  }

  void _drawCrown(Canvas canvas, double cx, double topY, double w) {
    final goldPaint = Paint()..color = const Color(0xFFE8C87A);
    final darkGoldPaint = Paint()
      ..color = const Color(0xFFE6B800)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.015;
    final crownPath = Path()
      ..moveTo(cx - w * 0.2, topY + w * 0.1)
      ..lineTo(cx - w * 0.2, topY + w * 0.02)
      ..lineTo(cx - w * 0.12, topY + w * 0.07)
      ..lineTo(cx, topY - w * 0.02)
      ..lineTo(cx + w * 0.12, topY + w * 0.07)
      ..lineTo(cx + w * 0.2, topY + w * 0.02)
      ..lineTo(cx + w * 0.2, topY + w * 0.1)
      ..close();
    canvas.drawPath(crownPath, goldPaint);
    canvas.drawPath(crownPath, darkGoldPaint);
    canvas.drawCircle(Offset(cx, topY + w * 0.03), w * 0.03, Paint()..color = const Color(0xFFE0909C));
  }

  void _drawStarClip(Canvas canvas, double cx, double y, double w) {
    _drawStar(canvas, Offset(cx + w * 0.22, y), w * 0.07, Paint()..color = const Color(0xFFE8C87A));
    _drawStar(canvas, Offset(cx - w * 0.18, y + w * 0.04), w * 0.05, Paint()..color = const Color(0xFFE0909C));
  }

  void _drawStar(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outer = Offset(
        center.dx + r * cos((i * 72 - 90) * pi / 180),
        center.dy + r * sin((i * 72 - 90) * pi / 180),
      );
      final inner = Offset(
        center.dx + r * 0.4 * cos(((i * 72 + 36) - 90) * pi / 180),
        center.dy + r * 0.4 * sin(((i * 72 + 36) - 90) * pi / 180),
      );
      if (i == 0) {
        path.moveTo(outer.dx, outer.dy);
      } else {
        path.lineTo(outer.dx, outer.dy);
      }
      path.lineTo(inner.dx, inner.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawHeadphones(Canvas canvas, double cx, double y, double w) {
    final hpPaint = Paint()
      ..color = const Color(0xFFC4966A)
      ..strokeWidth = w * 0.06
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, y + w * 0.1), width: w * 0.6, height: w * 0.3),
      pi, pi, false, hpPaint,
    );
    final cupPaint = Paint()..color = const Color(0xFFC4966A);
    canvas.drawCircle(Offset(cx - w * 0.3, y + w * 0.1), w * 0.07, cupPaint);
    canvas.drawCircle(Offset(cx + w * 0.3, y + w * 0.1), w * 0.07, cupPaint);
  }

  // ── 악세사리 ─────────────────────────────────────────
  void _drawAccessory(Canvas canvas, Size size, double cx, double eyeY) {
    final w = size.width;
    switch (accessory) {
      case 'glasses':      _drawGlasses(canvas, cx, eyeY, w); break;
      case 'heart_glasses': _drawHeartGlasses(canvas, cx, eyeY, w); break;
      case 'sparkle':      _drawSparkleEffect(canvas, cx, eyeY, w); break;
    }
  }

  void _drawGlasses(Canvas canvas, double cx, double eyeY, double w) {
    final paint = Paint()
      ..color = const Color(0xFF5C3D2E)
      ..strokeWidth = w * 0.02
      ..style = PaintingStyle.stroke;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - w * 0.16, eyeY), width: w * 0.17, height: w * 0.15), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + w * 0.16, eyeY), width: w * 0.17, height: w * 0.15), paint);
    canvas.drawLine(Offset(cx - w * 0.075, eyeY), Offset(cx + w * 0.075, eyeY), paint);
    canvas.drawLine(Offset(cx - w * 0.245, eyeY), Offset(cx - w * 0.32, eyeY + w * 0.04), paint);
    canvas.drawLine(Offset(cx + w * 0.245, eyeY), Offset(cx + w * 0.32, eyeY + w * 0.04), paint);
  }

  void _drawHeartGlasses(Canvas canvas, double cx, double eyeY, double w) {
    final paint = Paint()..color = const Color(0xFFE0909C);
    _drawHeart(canvas, Offset(cx - w * 0.16, eyeY - w * 0.01), w * 0.09, paint);
    _drawHeart(canvas, Offset(cx + w * 0.16, eyeY - w * 0.01), w * 0.09, paint);
    canvas.drawLine(
      Offset(cx - w * 0.075, eyeY + w * 0.02),
      Offset(cx + w * 0.075, eyeY + w * 0.02),
      Paint()..color = const Color(0xFFE0909C)..strokeWidth = w * 0.02..style = PaintingStyle.stroke,
    );
  }

  void _drawHeart(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy + r * 0.4);
    path.cubicTo(center.dx, center.dy, center.dx - r, center.dy, center.dx - r, center.dy - r * 0.3);
    path.arcToPoint(Offset(center.dx, center.dy - r * 0.1), radius: Radius.circular(r * 0.5));
    path.arcToPoint(Offset(center.dx + r, center.dy - r * 0.3), radius: Radius.circular(r * 0.5));
    path.cubicTo(center.dx + r, center.dy, center.dx, center.dy, center.dx, center.dy + r * 0.4);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawSparkleEffect(Canvas canvas, double cx, double eyeY, double w) {
    final positions = [
      Offset(cx - w * 0.3, eyeY - w * 0.1),
      Offset(cx + w * 0.3, eyeY - w * 0.08),
      Offset(cx - w * 0.22, eyeY + w * 0.18),
      Offset(cx + w * 0.25, eyeY + w * 0.2),
    ];
    for (int i = 0; i < positions.length; i++) {
      final phase = (particleValue + i * 0.25) % 1.0;
      final alpha = (sin(phase * pi)).clamp(0.0, 1.0);
      final sp = Paint()..color = const Color(0xFFE8C87A).withValues(alpha: alpha);
      _drawStar(canvas, positions[i], w * 0.04, sp);
    }
  }

  @override
  bool shouldRepaint(_MuziBodyPainter old) =>
      old.bodyColor != bodyColor ||
      old.emotion != emotion ||
      old.outfit != outfit ||
      old.accessory != accessory ||
      old.particleValue != particleValue;
}

// ── 배경 장식 페인터 ───────────────────────────────────

class _StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.8);
    final rnd = Random(42);
    for (int i = 0; i < 20; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        rnd.nextDouble() * 2 + 1, paint,
      );
    }
  }
  @override bool shouldRepaint(_StarsPainter old) => false;
}

class _PetalsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFFB3C6).withValues(alpha: 0.7);
    final rnd = Random(7);
    for (int i = 0; i < 10; i++) {
      canvas.save();
      canvas.translate(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      canvas.rotate(rnd.nextDouble() * pi);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 10, height: 6), paint);
      canvas.restore();
    }
  }
  @override bool shouldRepaint(_PetalsPainter old) => false;
}

class _GalaxyPainter extends CustomPainter {
  final double progress;
  const _GalaxyPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(13);
    for (int i = 0; i < 25; i++) {
      final phase = (progress + i / 25) % 1.0;
      final alpha = (sin(phase * pi) * 0.8 + 0.2).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        rnd.nextDouble() * 2 + 0.5,
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
    }
  }
  @override bool shouldRepaint(_GalaxyPainter old) => old.progress != progress;
}
