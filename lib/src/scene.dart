/// The fixed backdrop seen through every glass panel, ported from
/// web/src/components/Scene.astro: a smoking volcano under the moon, a ruined
/// rumah panggung with something pale in its window, a banyan and two nisan
/// gravestones, and a camp with a tent and a campfire. Light mode is a misty
/// dusk and dark mode is night. Purely decorative.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

class SceneColors {
  const SceneColors({
    required this.sky1,
    required this.sky2,
    required this.moon,
    required this.moonShade,
    required this.cloud,
    required this.far,
    required this.volcano,
    required this.ridge,
    required this.smoke,
    required this.mid,
    required this.fog,
    required this.near,
    required this.ground,
    required this.ink,
    required this.inkLine,
    required this.stone,
    required this.window,
    required this.specter,
    required this.tent,
    required this.tentGlow,
    required this.log,
    required this.wisp,
    required this.stars,
  });

  final Color sky1, sky2, moon, moonShade, cloud, far, volcano, ridge, smoke;
  final Color mid, fog, near, ground, ink, inkLine, stone, window, specter;
  final Color tent, tentGlow, log, wisp;
  final double stars;

  static const dusk = SceneColors(
    sky1: Color(0xffb9aecb),
    sky2: Color(0xffece2d4),
    moon: Color(0xfffbf3df),
    moonShade: Color(0xffe6dcc4),
    cloud: Color(0xffd8cfdc),
    far: Color(0xffb0a5c2),
    volcano: Color(0xff9d90b3),
    ridge: Color(0xffb5aac7),
    smoke: Color(0xffe9e2ea),
    mid: Color(0xff7f7298),
    fog: Color(0xfff2ebe0),
    near: Color(0xff4f4569),
    ground: Color(0xff2e2840),
    ink: Color(0xff1f1a2e),
    inkLine: Color(0xff3a3150),
    stone: Color(0xff6d6385),
    window: Color(0xffd9c48a),
    specter: Color(0xfffbf8f1),
    tent: Color(0xff7a4a3a),
    tentGlow: Color(0xffffcf7a),
    log: Color(0xff4a3326),
    wisp: Color(0xffc7f0ff),
    stars: 0,
  );

  static const night = SceneColors(
    sky1: Color(0xff05040a),
    sky2: Color(0xff1f1838),
    moon: Color(0xfff4ecd6),
    moonShade: Color(0xffd9cfb6),
    cloud: Color(0xff2a2442),
    far: Color(0xff231d3a),
    volcano: Color(0xff2b2447),
    ridge: Color(0xff3a3358),
    smoke: Color(0xff4a426e),
    mid: Color(0xff1a152c),
    fog: Color(0xff3a3358),
    near: Color(0xff120f20),
    ground: Color(0xff0a0812),
    ink: Color(0xff06050b),
    inkLine: Color(0xff1c1830),
    stone: Color(0xff3a3358),
    window: Color(0xff3d3418),
    specter: Color(0xffe8e4f2),
    tent: Color(0xff4a2e26),
    tentGlow: Color(0xffffb347),
    log: Color(0xff2a1c14),
    wisp: Color(0xff9fe8ff),
    stars: 1,
  );
}

/// Full-window backdrop. Animates unless [animate] is false (the pause
/// control, or the platform's reduced-motion setting).
class Scene extends StatefulWidget {
  const Scene({super.key, required this.dark, required this.animate});

  final bool dark;
  final bool animate;

  @override
  State<Scene> createState() => _SceneState();
}

class _SceneState extends State<Scene> with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    // One long loop; every motion below is periodic within it.
    duration: const Duration(hours: 1),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _clock.repeat();
  }

  @override
  void didUpdateWidget(Scene old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_clock.isAnimating) _clock.repeat();
    if (!widget.animate && _clock.isAnimating) _clock.stop();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _clock,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _ScenePainter(
              widget.dark ? SceneColors.night : SceneColors.dusk,
              widget.animate ? _clock.value * 3600 : 0,
            ),
          ),
        ),
      ),
    );
  }
}

// ---- Geometry (deterministic, same seed as the site) ------------------------

class _Geometry {
  _Geometry() {
    var seed = 7;
    double rand() {
      seed = (seed * 16807) % 2147483647;
      return (seed - 1) / 2147483646;
    }

    String f(double v) => v.toStringAsFixed(0);

    String canopy(double x0, double x1, double y, double amp, double step) {
      final d = StringBuffer('M$x0 900 V$y');
      for (var x = x0; x < x1; x += step) {
        final w = step * (0.7 + rand() * 0.6);
        d.write(
          ' q${f(w / 2)} ${f(-amp * (0.5 + rand()))} ${f(w)} ${f(rand() * 8 - 4)}',
        );
      }
      d.write(' V900 Z');
      return d.toString();
    }

    String palm(double x, double base, double h, double lean) {
      final tx = x + lean;
      final ty = base - h;
      final trunk =
          'M${x - 4} $base Q${x + lean * 0.3} ${base - h * 0.5} ${tx - 2} $ty L${tx + 2} $ty Q${x + lean * 0.3 + 6} ${base - h * 0.5} ${x + 4} $base Z';
      final fronds = [-150, -115, -70, -35, -5, 20]
          .map((deg) {
            final a = deg * math.pi / 180;
            final ex = tx + math.cos(a) * 46;
            final ey = ty + math.sin(a) * 26 + 18;
            final cx = tx + math.cos(a) * 26;
            final cy = ty + math.sin(a) * 26 - 8;
            return 'M$tx $ty Q${f(cx)} ${f(cy)} ${f(ex)} ${f(ey)} Q${f(cx + 4)} ${f(cy + 8)} $tx ${ty + 3} Z';
          })
          .join(' ');
      return '$trunk $fronds';
    }

    stars = List.generate(
      90,
      (_) => (
        x: rand() * 1600,
        y: rand() * 420,
        r: 0.6 + rand() * 1.4,
        o: 0.3 + rand() * 0.7,
      ),
    );
    final g = StringBuffer();
    for (var i = 0; i < 140; i++) {
      final x = (i / 140) * 1600 + rand() * 10;
      final h = 14 + rand() * 26;
      final lean = rand() * 12 - 6;
      g.write(
        'M${f(x)} 900 Q${f(x + lean / 2)} ${f(880 - h / 2)} ${f(x + lean)} ${f(870 - h)} Q${f(x + 3)} ${f(880 - h / 2)} ${f(x + 5)} 900 Z ',
      );
    }
    grass = parseSvgPathData(g.toString());
    treeline = parseSvgPathData(canopy(0, 1600, 690, 26, 34));
    palms = parseSvgPathData(
      [
        palm(470, 700, 120, 18),
        palm(1010, 690, 140, -22),
        palm(1090, 700, 100, 14),
        palm(60, 720, 110, 10),
      ].join(' '),
    );
    sparks = List.generate(
      10,
      (i) => (x: 1200 + rand() * 30, y: 720 - rand() * 40, d: i * 0.37),
    );
  }

  late final List<({double x, double y, double r, double o})> stars;
  late final Path grass, treeline, palms;
  late final List<({double x, double y, double d})> sparks;
}

final _geo = _Geometry();
final _p = <String, Path>{};
Path _path(String d) => _p[d] ??= parseSvgPathData(d);

const _wisps = [
  (x: 560.0, y: 690.0, d: 0.0),
  (x: 640.0, y: 640.0, d: 3.0),
  (x: 880.0, y: 700.0, d: 6.0),
  (x: 300.0, y: 600.0, d: 2.0),
  (x: 1520.0, y: 640.0, d: 5.0),
];

double _ease(double x) => -(math.cos(math.pi * x) - 1) / 2;

/// 0→1→0 over [period] seconds, eased (CSS `alternate` with ease-in-out).
double _alternate(double t, double period) {
  final cycle = (t / period) % 2;
  return _ease(cycle < 1 ? cycle : 2 - cycle);
}

/// CSS `flicker` keyframes: 1, .82 at 45%, .6 at 50%, .9 at 55%, 1.
double _flicker(double t, double period) {
  final x = (t / period) % 1;
  const stops = [(0.0, 1.0), (0.45, 0.82), (0.5, 0.6), (0.55, 0.9), (1.0, 1.0)];
  for (var i = 1; i < stops.length; i++) {
    if (x <= stops[i].$1) {
      final (a, va) = stops[i - 1];
      final (b, vb) = stops[i];
      return va + (vb - va) * _ease((x - a) / (b - a));
    }
  }
  return 1;
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.c, this.t);

  final SceneColors c;
  final double t;

  Paint _fill(Color color, [double opacity = 1]) => Paint()
    ..color = color.withValues(alpha: color.a * opacity)
    ..isAntiAlias = true;

  Paint _stroke(Color color, double width, {bool round = false}) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = round ? StrokeCap.round : StrokeCap.butt;

  Paint _radial(
    Offset center,
    double r,
    List<Color> colors, [
    List<double>? stops,
  ]) => Paint()
    ..shader = RadialGradient(
      colors: colors,
      stops: stops,
    ).createShader(Rect.fromCircle(center: center, radius: r));

  @override
  void paint(Canvas canvas, Size size) {
    // preserveAspectRatio="xMidYMax slice" on a 1600×900 view box.
    final s = math.max(size.width / 1600, size.height / 900);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate((size.width - 1600 * s) / 2, size.height - 900 * s);
    canvas.scale(s);

    // Sky
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 1600, 900),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.sky1, c.sky2],
          stops: const [0, 0.7],
        ).createShader(const Rect.fromLTWH(0, 0, 1600, 900)),
    );
    if (c.stars > 0) {
      for (final st in _geo.stars) {
        canvas.drawCircle(
          Offset(st.x.roundToDouble(), st.y.roundToDouble()),
          st.r,
          _fill(c.moon, st.o * c.stars),
        );
      }
    }

    // Moon with drifting cloud
    const moon = Offset(1010, 170);
    canvas.drawCircle(
      moon,
      230,
      _radial(moon, 230, [
        c.moon.withValues(alpha: 0.55),
        c.moon.withValues(alpha: 0),
      ]),
    );
    canvas.drawCircle(moon, 62, _fill(c.moon));
    canvas.drawCircle(const Offset(990, 155), 10, _fill(c.moonShade));
    canvas.drawCircle(const Offset(1030, 190), 7, _fill(c.moonShade));
    _drift(canvas, 70, reverse: true, () {
      canvas.drawPath(
        _path(
          'M820 200 q60 -30 140 -10 q70 -26 150 4 q50 -10 90 14 q-120 22 -380 -8 Z',
        ),
        _fill(c.cloud),
      );
      canvas.drawPath(
        _path('M180 120 q80 -26 170 -6 q60 -20 120 6 q-130 22 -290 0 Z'),
        _fill(c.cloud),
      );
    });

    // Far ridges and the volcano
    canvas.drawPath(
      _path(
        'M0 560 L110 520 L250 480 L340 500 L460 450 L560 470 L640 440 V700 H0 Z',
      ),
      _fill(c.far),
    );
    canvas.drawPath(
      _path(
        'M330 660 C460 520 600 360 712 252 L732 238 L748 250 L764 236 L782 248 L800 256 C930 380 1080 520 1240 660 Z',
      ),
      _fill(c.volcano),
    );
    canvas.drawPath(
      _path(
        'M748 252 L720 330 L740 420 M770 250 L790 340 L776 430 M700 300 L660 380 M820 300 L870 380',
      ),
      _stroke(c.ridge, 3, round: true),
    );
    final rise = _alternate(t, 18);
    canvas.save();
    canvas.translate(24 * rise, -10 * rise);
    for (final (x, y, rx, ry, o) in const [
      (760.0, 214.0, 24.0, 16.0, 0.8),
      (786.0, 180.0, 34.0, 22.0, 0.65),
      (830.0, 142.0, 46.0, 26.0, 0.5),
      (900.0, 108.0, 62.0, 30.0, 0.35),
      (990.0, 84.0, 80.0, 30.0, 0.2),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: rx * 2, height: ry * 2),
        _fill(c.smoke, o),
      );
    }
    canvas.restore();
    canvas.drawPath(
      _path(
        'M880 700 L1080 470 L1190 520 L1320 400 L1440 480 L1600 420 V700 Z',
      ),
      _fill(c.mid),
    );
    canvas.drawPath(
      _path('M0 700 V600 L130 520 L250 580 L380 540 L470 600 V700 Z'),
      _fill(c.mid),
    );

    // Fog bank
    _drift(canvas, 40, () {
      const r = Rect.fromLTWH(-200, 540, 2000, 150);
      canvas.drawRect(
        r,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              c.fog.withValues(alpha: 0),
              c.fog,
              c.fog.withValues(alpha: 0),
            ],
          ).createShader(r),
      );
    });

    // Treeline, palms, ground
    canvas.drawPath(_geo.treeline, _fill(c.near));
    canvas.drawPath(_geo.palms, _fill(c.near));
    canvas.drawPath(
      _path(
        'M0 900 V772 C260 760 520 792 820 778 C1080 766 1300 742 1600 750 V900 Z',
      ),
      _fill(c.ground),
    );

    // Keep the ruined house on the left edge and the camp on the right edge
    // at any size, scaling both down on narrow screens.
    const groundY = 790.0;
    final aspect = size.width / size.height;
    final vw = aspect < 16 / 9 ? 900 * aspect : 1600.0;
    final x0 = 800 - vw / 2;
    final x1 = 800 + vw / 2;
    final k = math.min(1.0, math.max(0.36, vw / 1150));
    final ty = groundY * (1 - k);

    canvas.save();
    canvas.translate(x0 + 8 - 100 * k, ty);
    canvas.scale(k);
    _left(canvas);
    canvas.restore();

    canvas.save();
    canvas.translate(x1 - 8 - 1560 * k, ty);
    canvas.scale(k);
    _right(canvas);
    canvas.restore();

    // Will-o'-the-wisps
    for (final w in _wisps) {
      final x = ((t + w.d) / 9) % 1;
      final e = _ease(x < 0.5 ? x * 2 : 2 - x * 2);
      final center = Offset(w.x + 18 * e, w.y - 26 * e);
      canvas.saveLayer(
        Rect.fromCircle(center: center, radius: 10),
        Paint()..color = Colors.black.withValues(alpha: 0.2 + 0.7 * e),
      );
      canvas.drawCircle(
        center,
        9,
        _radial(center, 9, [
          c.wisp.withValues(alpha: 0.9),
          c.wisp.withValues(alpha: 0),
        ]),
      );
      canvas.restore();
    }

    canvas.drawPath(_geo.grass, _fill(c.ink));
    canvas.restore();
  }

  void _drift(
    Canvas canvas,
    double period,
    VoidCallback draw, {
    bool reverse = false,
  }) {
    var e = _alternate(t, period);
    if (reverse) e = 1 - e;
    canvas.save();
    canvas.translate(-40 + 80 * e, 0);
    draw();
    canvas.restore();
  }

  void _left(Canvas canvas) {
    final ink = _fill(c.ink);
    // Banyan and nisan gravestones
    canvas.drawPath(
      _path(
        'M560 784 C566 740 556 700 548 660 C530 650 500 640 470 646 C500 628 530 630 548 640 C540 610 520 590 500 584 C530 580 552 600 560 620 C566 590 580 570 610 562 C600 590 586 612 580 640 C600 630 630 628 656 640 C626 644 600 652 584 668 C580 710 586 750 594 784 Z',
      ),
      ink,
    );
    canvas.drawPath(
      _path(
        'M500 590 L498 700 M520 640 L516 740 M630 640 L634 730 M650 642 L652 700 M610 566 L612 650',
      ),
      _stroke(c.ink, 2),
    );
    canvas.drawPath(
      _path(
        'M640 790 V766 Q650 752 660 766 V790 Z M672 792 V774 Q680 764 688 774 V792 Z',
      ),
      _fill(c.stone),
    );

    // The ruined rumah panggung
    for (final d in const [
      'M150 662 h10 v118 h-10 Z M210 664 h10 v116 h-10 Z M270 666 h10 v112 h-10 Z M330 690 l10 2 l-4 50 l-9 -2 Z M392 690 l10 0 l14 92 h-10 Z',
      'M128 652 L300 660 L430 694 L428 708 L298 674 L128 666 Z',
      'M140 652 V560 L300 556 V660 Z',
      'M300 660 V600 L330 586 L352 610 L372 592 L400 640 L420 690 Z',
    ]) {
      canvas.drawPath(_path(d), ink);
    }
    canvas.drawPath(
      _path(
        'M156 570 V646 M172 568 V648 M188 568 V648 M204 566 V650 M250 564 V652 M266 562 V654 M282 562 V656',
      ),
      _stroke(c.inkLine, 1.6),
    );
    canvas.drawRect(const Rect.fromLTWH(214, 580, 28, 36), _fill(c.window));
    // Something pale in the window, now and then.
    final g = ((t / 11) % 1);
    final ghost = g < 0.6
        ? 0.0
        : g < 0.7
        ? (g - 0.6) / 0.1 * 0.85
        : g < 0.88
        ? 0.85
        : (1 - g) / 0.12 * 0.85;
    if (ghost > 0) {
      canvas.drawPath(
        _path(
          'M228 588 c-6 0 -8 6 -7 12 c-3 6 -4 12 -5 16 h24 c-1 -4 -2 -10 -5 -16 c1 -6 -1 -12 -7 -12 Z',
        ),
        _fill(c.specter, ghost),
      );
      canvas.drawPath(
        _path('M222 592 c-2 8 -2 16 -4 24 M234 592 c2 8 2 16 4 24'),
        _stroke(c.ink.withValues(alpha: ghost), 2.4),
      );
    }
    canvas.drawPath(_path('M214 598 h28 M228 580 v36'), _stroke(c.ink, 2));
    canvas.drawPath(
      _path('M160 600 L190 596 L196 650 L166 654 Z'),
      _fill(c.inkLine, 0.6),
    );
    canvas.drawPath(_path('M112 574 L232 446 L250 452 L150 584 Z'), ink);
    canvas.drawPath(
      _path(
        'M232 446 L262 470 L300 520 L326 516 L346 548 L372 538 L320 470 L250 452 Z',
      ),
      ink,
    );
    canvas.drawPath(
      _path('M262 470 L282 420 M300 520 L316 470 M346 548 L370 500'),
      _stroke(c.ink, 4, round: true),
    );
    canvas.drawPath(
      _path(
        'M120 580 l-2 14 M132 584 l0 16 M144 586 l2 12 M330 520 l-2 18 M352 548 l2 20 M362 544 l0 14',
      ),
      _stroke(c.ink, 1.6),
    );
    canvas.drawPath(
      _path(
        'M110 780 L136 664 M128 782 L152 668 M118 744 L140 748 M126 706 L146 710',
      ),
      _stroke(c.ink, 4, round: true),
    );
    canvas.drawPath(
      _path(
        'M200 786 l70 -10 l2 6 l-70 10 Z M300 790 l44 4 l-1 6 l-44 -4 Z M380 784 l30 -18 l4 4 l-30 18 Z',
      ),
      ink,
    );
  }

  void _right(Canvas canvas) {
    final flicker = _flicker(t, 3.2);
    Paint fireGlow(Offset center, double r) => _radial(
      center,
      r,
      [
        const Color(0xffffb347).withValues(alpha: 0.55 * flicker),
        const Color(0xffff7a2a).withValues(alpha: 0.18 * flicker),
        const Color(0x00ff7a2a),
      ],
      const [0, 0.45, 1],
    );
    const fire = Offset(1210, 756);
    canvas.drawCircle(fire, 200, fireGlow(fire, 200));
    canvas.drawPath(_path('M1300 758 L1384 636 L1478 758 Z'), _fill(c.tent));
    canvas.drawPath(
      _path('M1384 636 L1478 758 L1460 758 L1384 650 Z'),
      _fill(c.ink, 0.35),
    );
    canvas.drawPath(
      _path('M1364 758 L1386 692 L1406 758 Z'),
      _fill(c.tentGlow, flicker),
    );
    canvas.drawPath(
      _path('M1300 758 L1270 776 M1478 758 L1510 776 M1384 636 L1384 620'),
      _stroke(c.ink, 2),
    );
    canvas.drawPath(
      _path('M1100 772 h70 a6 6 0 0 1 0 12 h-70 a6 6 0 0 1 0 -12 Z'),
      _fill(c.ink),
    );
    canvas.drawPath(
      _path('M1186 770 L1236 754 M1188 754 L1234 772'),
      _stroke(c.log, 8, round: true),
    );
    // Flame, scaled from its base.
    final fl = _alternate(t, 0.9);
    canvas.save();
    canvas.translate(1212, 762);
    canvas.scale(1 - 0.08 * fl, 1 + 0.12 * fl);
    canvas.translate(-1212, -762);
    canvas.drawPath(
      _path(
        'M1210 762 C1190 746 1196 722 1206 708 C1208 724 1216 724 1214 700 C1232 716 1232 748 1210 762 Z',
      ),
      _fill(const Color(0xffff7a2a)),
    );
    canvas.drawPath(
      _path(
        'M1211 760 C1200 750 1202 736 1209 726 C1211 738 1218 738 1216 724 C1226 738 1224 752 1211 760 Z',
      ),
      _fill(const Color(0xffffb347)),
    );
    canvas.drawPath(
      _path(
        'M1211 758 C1206 752 1207 744 1211 738 C1214 746 1218 750 1211 758 Z',
      ),
      _fill(const Color(0xffffe08a)),
    );
    canvas.restore();
    for (final sp in _geo.sparks) {
      final x = ((t + sp.d) / 3.6) % 1;
      canvas.drawCircle(
        Offset(sp.x.roundToDouble() + 14 * x, sp.y.roundToDouble() - 120 * x),
        1.6,
        _fill(const Color(0xffffcf7a), 1 - x),
      );
    }
    _drift(canvas, 70, reverse: true, () {
      canvas.drawPath(
        _path(
          'M1212 700 C1200 660 1230 640 1214 600 C1200 570 1226 540 1214 500',
        ),
        _stroke(c.smoke.withValues(alpha: 0.35), 10, round: true),
      );
    });
    canvas.drawPath(_path('M1530 780 V690'), _stroke(c.ink, 4));
    const lamp = Offset(1530, 686);
    canvas.drawCircle(lamp, 30, fireGlow(lamp, 30));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(1523, 676, 14, 16),
        const Radius.circular(3),
      ),
      _fill(const Color(0xffffe08a)),
    );
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.t != t || old.c != c;
}
