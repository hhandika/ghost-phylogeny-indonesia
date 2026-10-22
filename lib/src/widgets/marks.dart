/// The hero title's two ghosts, ported from web/src/components/KuyangMark.astro
/// and GhostSit.astro: a Kuyang drawn as a letter ("y" of phylogeny or "i" of
/// Filogeni) and a Kuntilanak sitting on a letter "o". Both are sized in em
/// and use the title ink for outlines. Decorative.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import '../settings.dart';

Paint _fill(Color c, [double o = 1]) =>
    Paint()..color = c.withValues(alpha: c.a * o);

Paint _stroke(Color c, double w, {bool round = true}) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = round ? StrokeCap.round : StrokeCap.butt
  ..strokeJoin = StrokeJoin.round;

/// Repeating 0→1 clock for the marks; still when motion is off.
class _Clock extends StatefulWidget {
  const _Clock({required this.builder});

  final Widget Function(double t) builder;

  @override
  State<_Clock> createState() => _ClockState();
}

class _ClockState extends State<_Clock> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.settings.animate(context)) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, _) => widget.builder(_c.value * 60),
    ),
  );
}

double _wave(double t, double period) =>
    (1 - math.cos(2 * math.pi * t / period)) / 2;

// ---- Kuyang --------------------------------------------------------------

/// A Kuyang letter at [fontSize]; sits on the baseline like real type.
class KuyangMark extends StatelessWidget {
  const KuyangMark({
    super.key,
    required this.letter,
    required this.fontSize,
    required this.ink,
  });

  final String letter;
  final double fontSize;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final y = letter == 'y';
    final w = y ? 600.0 : 330.0;
    final top = y ? 650.0 : 900.0;
    final bottom = y ? 250.0 : 40.0;
    return SizedBox(
      width: fontSize * w / 1000,
      height: fontSize * (top + bottom) / 1000,
      child: _Clock(
        builder: (t) =>
            CustomPaint(painter: _KuyangPainter(y, ink, t, w, top, bottom)),
      ),
    );
  }
}

class _KuyangPainter extends CustomPainter {
  _KuyangPainter(this.y, this.ink, this.t, this.w, this.top, this.bottom);

  final bool y;
  final Color ink;
  final double t, w, top, bottom;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / w, size.height / (top + bottom));
    final b = top;
    final x = b - 512;
    Path p(String d) => parseSvgPathData(d);
    final bob = -26 * _wave(t, 3.2);
    final sway = (_wave(t, 4.8) * 2 - 1) * 4 * math.pi / 180;
    final stare = 0.2 + 0.65 * _wave(t, 2.4);
    final pulse = 0.88 + 0.18 * _wave(t, 3.5);
    const blood = Color(0xffa3172d);
    const pale = Color(0xfff1e9d8);
    const eye = Color(0xffff4a4a);

    void aura(Offset c, double r) {
      canvas.drawCircle(
        c,
        r * pulse,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xffff6a3a)
                  .withValues(alpha: 0.5 * (0.7 + 0.3 * pulse)),
              blood.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: r * pulse)),
      );
    }

    void swaying(Offset origin, VoidCallback draw) {
      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      canvas.rotate(sway);
      canvas.translate(-origin.dx, -origin.dy);
      draw();
      canvas.restore();
    }

    if (y) {
      aura(Offset(300, x + 250), 230);
      final gut = p(
        'M300 ${x + 330} C282 ${x + 420} 322 ${b - 40} 300 ${b + 60} C284 ${b + 140} 290 ${b + 190} 220 ${b + 215} C180 ${b + 228} 140 ${b + 222} 118 ${b + 205}',
      );
      swaying(Offset(300, x + 330), () {
        canvas.drawPath(gut, _stroke(ink, 96));
        canvas.drawPath(gut, _stroke(const Color(0xffc45a6a), 58));
        final lungs = p(
          'M296 ${x + 400} C236 ${x + 400} 216 ${x + 470} 240 ${x + 500} C270 ${x + 512} 288 ${x + 460} 296 ${x + 430} Z M304 ${x + 400} C364 ${x + 400} 384 ${x + 470} 360 ${x + 500} C330 ${x + 512} 312 ${x + 460} 304 ${x + 430} Z',
        );
        canvas.drawPath(lungs, _fill(const Color(0xffb5485a)));
        canvas.drawPath(lungs, _stroke(ink, 12));
        final heart = p(
          'M300 ${x + 450} C262 ${x + 462} 262 ${x + 516} 300 ${x + 540} C338 ${x + 516} 338 ${x + 462} 300 ${x + 450} Z',
        );
        canvas.drawPath(heart, _fill(const Color(0xff8f1028)));
        canvas.drawPath(heart, _stroke(ink, 12));
        final drip = (t / 2.4) % 1;
        canvas.drawCircle(
          Offset(112, b + 236 + (drip < 0.4 ? 0 : (drip - 0.4) / 0.6 * 60)),
          14,
          _fill(blood, drip < 0.4 ? 1 : 1 - (drip - 0.4) / 0.6),
        );
      });
      // Hair: the arms of a serif y.
      canvas.drawPath(
        p('M60 ${x + 22} L150 ${x + 22} L272 ${x + 250} L222 ${x + 290} Z'),
        _fill(ink),
      );
      canvas.drawPath(p('M22 ${x + 14} H188'), _stroke(ink, 30));
      canvas.drawPath(
        p(
          'M70 ${x + 10} C56 ${x - 40} 30 ${x - 70} 6 ${x - 86} M110 ${x + 8} C110 ${x - 50} 92 ${x - 90} 70 ${x - 112}',
        ),
        _stroke(ink, 12),
      );
      canvas.drawPath(
        p('M488 ${x + 22} L524 ${x + 22} L350 ${x + 280} L322 ${x + 262} Z'),
        _fill(ink),
      );
      canvas.drawPath(p('M430 ${x + 14} H580'), _stroke(ink, 28));
      canvas.drawPath(
        p(
          'M520 ${x + 8} C534 ${x - 44} 560 ${x - 74} 590 ${x - 88} M484 ${x + 8} C486 ${x - 50} 504 ${x - 92} 528 ${x - 112}',
        ),
        _stroke(ink, 12),
      );
      // Head at the junction.
      canvas.save();
      canvas.translate(0, bob);
      final face = Rect.fromCenter(
        center: Offset(300, x + 290),
        width: 184,
        height: 204,
      );
      canvas.drawOval(face, _fill(pale));
      canvas.drawOval(face, _stroke(ink, 18));
      canvas.drawPath(
        p(
          'M222 ${x + 262} C222 ${x + 180} 378 ${x + 180} 378 ${x + 262} C352 ${x + 222} 248 ${x + 222} 222 ${x + 262} Z',
        ),
        _fill(ink),
      );
      for (final ex in [270.0, 330.0]) {
        canvas.drawCircle(Offset(ex, x + 292), 24, _fill(eye, stare));
        canvas.drawCircle(Offset(ex, x + 292), 12, _fill(eye));
      }
      final mouth = p(
        'M266 ${x + 338} Q300 ${x + 368} 334 ${x + 338} Q300 ${x + 386} 266 ${x + 338} Z',
      );
      canvas.drawPath(mouth, _fill(blood));
      canvas.drawPath(mouth, _stroke(const Color(0xff15111f), 6));
      canvas.drawPath(
        p('M278 ${x + 342} l8 16 l8 -16 M306 ${x + 342} l8 16 l8 -16'),
        _fill(Colors.white),
      );
      canvas.restore();
    } else {
      aura(Offset(165, b - 690), 190);
      final stem = p(
        'M165 ${x + 40} C150 ${x + 160} 182 ${x + 300} 165 ${b - 30}',
      );
      swaying(Offset(165, x + 40), () {
        canvas.drawPath(stem, _stroke(ink, 100));
        canvas.drawPath(stem, _stroke(const Color(0xffc45a6a), 62));
        canvas.drawPath(p('M60 ${b - 8} H270'), _stroke(ink, 40));
        final lungs = p(
          'M160 ${x + 10} C100 ${x + 10} 84 ${x + 80} 108 ${x + 112} C138 ${x + 124} 156 ${x + 70} 160 ${x + 40} Z M170 ${x + 10} C230 ${x + 10} 246 ${x + 80} 222 ${x + 112} C192 ${x + 124} 174 ${x + 70} 170 ${x + 40} Z',
        );
        canvas.drawPath(lungs, _fill(const Color(0xffb5485a)));
        canvas.drawPath(lungs, _stroke(ink, 12));
        final heart = p(
          'M165 ${x + 60} C128 ${x + 72} 128 ${x + 126} 165 ${x + 150} C202 ${x + 126} 202 ${x + 72} 165 ${x + 60} Z',
        );
        canvas.drawPath(heart, _fill(const Color(0xff8f1028)));
        canvas.drawPath(heart, _stroke(ink, 12));
      });
      // A thread of blood between the dot and the stem, dripping.
      final thread = p(
        'M165 ${b - 610} C158 ${b - 580} 172 ${b - 556} 165 ${x + 12}',
      );
      final dash = dashPath(
        thread,
        dashArray: CircularIntervalList([18.0, 14.0]),
        dashOffset: DashOffset.absolute(-64 * ((t / 1.2) % 1)),
      );
      canvas.drawPath(dash, _stroke(blood, 10));
      canvas.save();
      canvas.translate(0, bob);
      for (final d in [
        'M130 ${b - 720} C100 ${b - 780} 60 ${b - 830} 10 ${b - 850} C46 ${b - 820} 70 ${b - 790} 84 ${b - 760} C56 ${b - 770} 30 ${b - 768} 6 ${b - 752} C60 ${b - 744} 100 ${b - 722} 128 ${b - 690} Z',
        'M200 ${b - 720} C230 ${b - 780} 270 ${b - 830} 320 ${b - 850} C284 ${b - 820} 260 ${b - 790} 246 ${b - 760} C274 ${b - 770} 300 ${b - 768} 324 ${b - 752} C270 ${b - 744} 230 ${b - 722} 202 ${b - 690} Z',
      ]) {
        canvas.drawPath(p(d), _fill(ink));
      }
      final face = Rect.fromCenter(
        center: Offset(165, b - 680),
        width: 144,
        height: 160,
      );
      canvas.drawOval(face, _fill(pale));
      canvas.drawOval(face, _stroke(ink, 14));
      canvas.drawPath(
        p(
          'M96 ${b - 704} C96 ${b - 780} 234 ${b - 780} 234 ${b - 704} C212 ${b - 740} 118 ${b - 740} 96 ${b - 704} Z',
        ),
        _fill(ink),
      );
      for (final ex in [139.0, 191.0]) {
        canvas.drawCircle(Offset(ex, b - 678), 20, _fill(eye, stare));
        canvas.drawCircle(Offset(ex, b - 678), 10, _fill(eye));
      }
      final mouth = p(
        'M138 ${b - 640} Q165 ${b - 616} 192 ${b - 640} Q165 ${b - 602} 138 ${b - 640} Z',
      );
      canvas.drawPath(mouth, _fill(blood));
      canvas.drawPath(mouth, _stroke(const Color(0xff15111f), 5));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_KuyangPainter old) => old.t != t || old.ink != ink;
}

// ---- Kuntilanak on the "o" -------------------------------------------------

/// An "o" with a Kuntilanak sitting on it, her gown draped over its top.
class GhostSitO extends StatelessWidget {
  const GhostSitO({super.key, required this.style});

  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final em = style.fontSize ?? 48;
    final ink = style.color ?? Colors.black;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Text('o', style: style),
        Positioned(
          // The gown's hem rests on the top of the letter.
          bottom: em * 0.545 + (style.height ?? 1.2) * em * 0.12,
          child: SizedBox(
            width: em * 0.58,
            height: em * 0.692,
            child: _Clock(
              builder: (t) => CustomPaint(painter: _GhostSitPainter(ink, t)),
            ),
          ),
        ),
      ],
    );
  }
}

class _GhostSitPainter extends CustomPainter {
  _GhostSitPainter(this.ink, this.t);

  final Color ink;
  final double t;
  static final _cache = <String, Path>{};
  static Path p(String d) => _cache[d] ??= parseSvgPathData(d);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 120);
    const skin = Color(0xffefe6d6);
    const hair = Color(0xff0b0910);
    // Rocking from the base; legs kick.
    final rock = (_wave(t, 5) * 2 - 1) * 2 * math.pi / 180;
    canvas.translate(50, 120);
    canvas.rotate(rock);
    canvas.translate(-50, -120);

    for (final (leg, foot, dir) in [
      (
        'M42 92 C41 101 40 107 37 113',
        'M31 115 C31 111 39 110 41 113 C41 116 33 118 31 115 Z',
        1.0,
      ),
      (
        'M58 92 C59 101 60 107 63 113',
        'M69 115 C69 111 61 110 59 113 C59 116 67 118 69 115 Z',
        -1.0,
      ),
    ]) {
      final kick =
          (_wave(t + (dir < 0 ? 0.55 : 0), 2.2) * 2 - 1) * 8 * math.pi / 180;
      canvas.save();
      canvas.translate(dir > 0 ? 42 : 58, 92);
      canvas.rotate(kick * dir);
      canvas.translate(dir > 0 ? -42 : -58, -92);
      canvas.drawPath(p(leg), _stroke(ink, 7.5));
      canvas.drawPath(p(leg), _stroke(skin, 4));
      canvas.drawPath(p(foot), _fill(skin));
      canvas.drawPath(p(foot), _stroke(ink, 2.4));
      canvas.restore();
    }
    final hairPath = p(
      'M33 16 C22 34 20 62 24 86 C28 82 32 86 34 80 L66 80 C68 86 72 82 76 86 C80 62 78 34 67 16 Z',
    );
    canvas.drawPath(hairPath, _fill(hair));
    canvas.drawPath(hairPath, _stroke(ink, 2.5));
    final gown = p(
      'M40 38 C36 46 34 56 26 66 C20 76 14 84 13 92 Q16.5 88 20 94 Q26 88 32 95 Q38 89 44 95 Q50 89 56 95 Q62 89 68 95 Q74 88 80 94 Q83.5 88 87 92 C86 84 80 76 74 66 C66 56 64 46 60 38 Z',
    );
    canvas.drawPath(gown, _fill(const Color(0xfff6f1e6)));
    canvas.drawPath(gown, _stroke(ink, 3.5));
    canvas.drawPath(
      p('M30 76 C34 82 36 88 34 93 M50 70 V93 M70 76 C66 82 64 88 66 93'),
      _stroke(const Color(0xffd4c6aa), 2.4),
    );
    for (final arm in [
      'M40 42 C32 52 30 62 36 70',
      'M60 42 C68 52 70 62 64 70',
    ]) {
      canvas.drawPath(p(arm), _stroke(ink, 6.5));
      canvas.drawPath(p(arm), _stroke(skin, 3.5));
    }
    canvas.drawPath(
      p('M36 70 l3 5 M36 70 l0.5 6 M64 70 l-3 5 M64 70 l-0.5 6'),
      _stroke(ink, 1.4),
    );
    final face = Rect.fromCenter(
      center: const Offset(50, 26),
      width: 22,
      height: 26,
    );
    canvas.drawOval(face, _fill(skin));
    canvas.drawOval(face, _stroke(ink, 3));
    final fringe = p(
      'M37 22 C38 8 62 8 63 22 C64 34 66 44 68 54 C64 46 61 34 59 24 C56 18 44 18 41 24 C39 34 36 46 32 54 C34 44 36 34 37 22 Z',
    );
    canvas.drawPath(fringe, _fill(hair));
    canvas.drawPath(fringe, _stroke(ink, 1.6));
    final glow = 0.2 + 0.5 * _wave(t, 2.4);
    for (final ex in [46.0, 54.0]) {
      canvas.drawCircle(
        Offset(ex, 27),
        3.4,
        _fill(const Color(0xffff4a4a), glow),
      );
      canvas.drawCircle(Offset(ex, 27), 1.7, _fill(const Color(0xffd1182e)));
    }
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(50, 34), width: 3.2, height: 4.8),
      _fill(const Color(0xff15111f)),
    );
    // A frangipani in her hair.
    canvas.save();
    canvas.translate(62, 16);
    for (final a in [0.0, 72.0, -72.0]) {
      canvas.save();
      canvas.rotate(a * math.pi / 180);
      final petal = Rect.fromCenter(
        center: const Offset(0, -2.6),
        width: 3.6,
        height: 5.2,
      );
      canvas.drawOval(petal, _fill(const Color(0xfffff8ec)));
      canvas.drawOval(petal, _stroke(ink, 0.6));
      canvas.restore();
    }
    canvas.drawCircle(Offset.zero, 1, _fill(const Color(0xfff2c14e)));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GhostSitPainter old) => old.t != t || old.ink != ink;
}
