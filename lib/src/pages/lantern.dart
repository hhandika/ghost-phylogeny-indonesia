/// "Lantern": a circular tree on a night canvas, the selected ghost held in
/// the center like a lamp, ported from web/src/islands/Lantern.tsx. Hovering
/// a tip lights its path to the root; island chips dim everything else. The
/// canvas uses the dark palette in either theme.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data.dart';
import '../i18n.dart' as i18n;
import '../settings.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ghost_card.dart';
import '../widgets/shell.dart';

const _half = 560.0;
const _inner = 120.0;
const _outer = 330.0;
// Radians left open at the top.
const _gap = 0.22;
// Space between the label start and the clade ring.
const _labelRoom = 150.0;
const _ringR = 522.0;

final _darkTheme = buildTheme(Brightness.dark);

class LanternPage extends StatefulWidget {
  const LanternPage({super.key});

  @override
  State<LanternPage> createState() => _LanternPageState();
}

class _LanternPageState extends State<LanternPage>
    with SingleTickerProviderStateMixin {
  String selected = data.ghosts.first.id;
  String? hover;
  String region = '';
  late final _flicker = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  TreeLayout get L => data.cladogram;

  double angleOf(double y) =>
      -math.pi / 2 + _gap / 2 + (y / (L.nTips - 1)) * (2 * math.pi - _gap);
  double radiusOf(double x) => _inner + (x / L.maxX) * (_outer - _inner);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.settings.animate(context)) {
      if (!_flicker.isAnimating) _flicker.repeat();
    } else {
      _flicker.stop();
      _flicker.value = 0;
    }
  }

  @override
  void dispose() {
    _flicker.dispose();
    super.dispose();
  }

  /// The tip under a point in view-box coordinates (origin at the center).
  String? tipAt(Offset p) {
    final r = p.distance;
    if (r < _inner || r > _ringR) return null;
    var a = math.atan2(p.dy, p.dx);
    if (a < -math.pi / 2) a += 2 * math.pi;
    final y =
        ((a + math.pi / 2 - _gap / 2) / (2 * math.pi - _gap) * (L.nTips - 1))
            .round();
    if (y < 0 || y >= L.nTips) return null;
    return L.tips.firstWhere((t) => t.y == y).id;
  }

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final g in data.ghosts) {
      counts[g.regionGroup] = (counts[g.regionGroup] ?? 0) + 1;
    }
    final ghost = data.byId[selected]!;
    return PageScroll(
      wide: true,
      children: [
        PageTitle(
          kicker: context.t('lanternKicker'),
          title: context.t('lanternTitle'),
          lead: context.t('lanternLead'),
        ),
        const CladeLegend(),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1024),
            child: Glass(
              padding: const EdgeInsets.all(12),
              child: Semantics(
                label: context.t('filterIsland'),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final r in ['', ...data.regions])
                      PillButton(
                        label: r.isEmpty
                            ? context.t('allIslands')
                            : '${i18n.regionName(context.lang, r)} ${counts[r] ?? 0}',
                        selected: region == r,
                        small: true,
                        onPressed: () => setState(() => region = r),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, c) {
            final figure = _figure(context);
            final card = GhostCard(
              ghost: ghost,
              onSelect: (id) => setState(() => selected = id),
            );
            if (c.maxWidth >= 1024) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: figure),
                  const SizedBox(width: 24),
                  SizedBox(width: 384, child: card),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [figure, const SizedBox(height: 24), card],
            );
          },
        ),
      ],
    );
  }

  Widget _figure(BuildContext context) {
    final lang = context.lang;
    final focus = data.byId[hover ?? selected]!;
    final ghost = data.byId[selected]!;
    final labels = {for (final tip in L.tips) tip.id!: data.byId[tip.id]!.name};
    final canvas = SizedBox.square(
      dimension: _half * 2,
      child: MouseRegion(
        onHover: (e) {
          final id = tipAt(e.localPosition - const Offset(_half, _half));
          if (id != hover) setState(() => hover = id);
        },
        onExit: (_) => setState(() => hover = null),
        child: GestureDetector(
          onTapUp: (e) {
            final id = tipAt(e.localPosition - const Offset(_half, _half));
            if (id != null) setState(() => selected = id);
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _LanternPainter(
                    layout: L,
                    angleOf: angleOf,
                    radiusOf: radiusOf,
                    selected: selected,
                    hover: hover,
                    region: region,
                    labels: labels,
                    focusName: focus.name,
                    focusRegion: i18n.regionName(lang, focus.regionGroup),
                    focusClade: context.tr(focus.clade).split(' / '),
                  ),
                ),
              ),
              for (final tip in L.tips)
                Builder(
                  builder: (context) {
                    final a = angleOf(tip.y);
                    final g = data.byId[tip.id]!;
                    final dim = region.isNotEmpty && g.regionGroup != region;
                    return Positioned(
                      left: _half + math.cos(a) * (_outer + 13) - 9,
                      top: _half + math.sin(a) * (_outer + 13) - 9,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: dim ? 0.25 : 1,
                          child: Plate(g.id, size: 18),
                        ),
                      ),
                    );
                  },
                ),
              // The lantern: the focused ghost in the center.
              Positioned(
                left: _half - 55,
                top: _half - 96,
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _flicker,
                    builder: (context, child) => Opacity(
                      opacity: _flickerAt(_flicker.value),
                      child: child,
                    ),
                    child: Plate(focus.id, size: 110),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Theme(
      data: _darkTheme,
      child: Glass(
        radius: 40,
        padding: const EdgeInsets.all(8),
        color: Malam.c950.withValues(alpha: 0.85),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0x33d9ab3c), Color(0x00d9ab3c)],
              stops: [0, 0.45],
            ),
          ),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, c) => Semantics(
                  label: context.t('lanternSvg', [L.nTips, ghost.name]),
                  child: SizedBox.square(
                    dimension: c.maxWidth,
                    child: FittedBox(child: canvas),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  context.t('lanternCaption'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Kemenyan.c200,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// CSS `flicker` keyframes: 1, .82 at 45%, .6 at 50%, .9 at 55%, 1.
double _flickerAt(double x) {
  const stops = [(0.0, 1.0), (0.45, 0.82), (0.5, 0.6), (0.55, 0.9), (1.0, 1.0)];
  for (var i = 1; i < stops.length; i++) {
    if (x <= stops[i].$1) {
      final (a, va) = stops[i - 1];
      final (b, vb) = stops[i];
      return va + (vb - va) * ((x - a) / (b - a));
    }
  }
  return 1;
}

class _LanternPainter extends CustomPainter {
  _LanternPainter({
    required this.layout,
    required this.angleOf,
    required this.radiusOf,
    required this.selected,
    required this.hover,
    required this.region,
    required this.labels,
    required this.focusName,
    required this.focusRegion,
    required this.focusClade,
  });

  final TreeLayout layout;
  final double Function(double) angleOf;
  final double Function(double) radiusOf;
  final String selected;
  final String? hover;
  final String region;
  final Map<String, String> labels;
  final String focusName;
  final String focusRegion;
  final List<String> focusClade;

  static Offset polar(double a, double r) =>
      Offset(r * math.cos(a), r * math.sin(a));

  Color clade(String? c) {
    final colors = Tokens.darkTokens.cladeColors;
    final i = c == null ? -1 : data.clades.indexOf(c);
    return i < 0 ? Tokens.darkTokens.neutralBranch : colors[i];
  }

  Paint stroke(Color c, double w, {StrokeCap cap = StrokeCap.round}) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = cap;

  /// Draws [s] centered on (or starting at) a baseline point.
  void text(Canvas canvas, String s, double y, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final ascent = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    tp.paint(canvas, Offset(-tp.width / 2, y - ascent));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final font = GoogleFonts.figtree().fontFamily;
    canvas.translate(_half, _half);

    // Stars
    for (var i = 0; i < 70; i++) {
      final a = i * 137.5 * math.pi / 180;
      final r = 360.0 + (i * 53) % 190;
      canvas.drawCircle(
        polar(a, r),
        0.8 + (i % 3) * 0.5,
        Paint()..color = Kafan.c100.withValues(alpha: 0.15 + (i % 5) * 0.08),
      );
    }

    // Clade ring: contiguous runs of one clade around the rim.
    final runs = <(String, double, double)>[];
    for (final tip in layout.tips) {
      final c = data.byId[tip.id]!.clade;
      if (runs.isNotEmpty && runs.last.$1 == c && runs.last.$3 == tip.y - 1) {
        runs.last = (c, runs.last.$2, tip.y);
      } else {
        runs.add((c, tip.y, tip.y));
      }
    }
    final ring = Rect.fromCircle(center: Offset.zero, radius: _ringR);
    for (final (c, from, to) in runs) {
      final a0 = angleOf(from - 0.45);
      final a1 = angleOf(to + 0.45);
      canvas.drawArc(
        ring,
        a0,
        a1 - a0,
        false,
        stroke(clade(c).withValues(alpha: 0.9), 10, cap: StrokeCap.butt),
      );
    }

    // Branches, the lit lineage in gold
    final lit = TreeLayout.ancestry(layout.tipById[hover ?? selected]).toSet();
    for (final p in layout.all) {
      final on = lit.contains(p);
      final color = clade(p.clade);
      final alpha = on ? 1.0 : 0.75;
      if (p.parent != null) {
        final a = angleOf(p.y);
        canvas.drawLine(
          polar(a, radiusOf(p.parent!.x)),
          polar(a, radiusOf(p.x)),
          on
              ? stroke(const Color(0xfff4dc8e), 3.6)
              : stroke(color.withValues(alpha: alpha), 1.5),
        );
      }
      if (!p.isTip) {
        final r = radiusOf(p.x);
        final a0 = angleOf(p.children.first.y);
        final a1 = angleOf(p.children.last.y);
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: r),
          a0,
          a1 - a0,
          false,
          stroke(color.withValues(alpha: alpha), 1.5),
        );
      }
    }
    for (final p in lit) {
      if (p.parent == null) continue;
      final a = angleOf(p.y);
      canvas.drawLine(
        polar(a, radiusOf(p.parent!.x)),
        polar(a, radiusOf(p.x)),
        stroke(const Color(0xffe0b03e).withValues(alpha: 0.15), 10),
      );
    }

    // Strong nodes
    for (final p in layout.all) {
      if (p.isTip || (p.support ?? 0) < 95) continue;
      canvas.drawCircle(
        polar(angleOf(p.y), radiusOf(p.x)),
        3.6,
        Paint()..color = Prada.c300,
      );
    }

    // Tips: highlight rings and rotated labels (plates are widgets on top).
    for (final tip in layout.tips) {
      final g = data.byId[tip.id]!;
      final a = angleOf(tip.y);
      final flip = math.cos(a) < 0;
      final at = polar(a, _outer + 13);
      final isSel = g.id == selected;
      final isHover = g.id == hover;
      final dim = region.isNotEmpty && g.regionGroup != region;
      if (isSel) {
        canvas.drawCircle(
          at,
          13,
          Paint()..color = Prada.c300.withValues(alpha: 0.45),
        );
      }
      if (isHover) canvas.drawCircle(at, 13, stroke(Prada.c200, 2));
      final name = labels[g.id]!;
      final tp = TextPainter(
        text: TextSpan(
          text: name,
          style: TextStyle(
            fontFamily: font,
            fontSize: math.min(12.5, _labelRoom / (name.length * 0.56)),
            fontWeight: isSel || isHover || (region.isNotEmpty && !dim)
                ? FontWeight.bold
                : FontWeight.normal,
            color: isSel || isHover
                ? Prada.c200
                : dim
                ? Kemenyan.c300
                : region.isNotEmpty
                ? Kafan.c50
                : Kafan.c200,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      final l = polar(a, _outer + 26);
      canvas.translate(l.dx, l.dy);
      canvas.rotate(flip ? a + math.pi : a);
      tp.paint(canvas, Offset(flip ? -tp.width : 0, -tp.height / 2));
      canvas.restore();
    }

    // The lantern: text sized to the circle's width at its height.
    canvas.drawCircle(Offset.zero, _inner - 14, Paint()..color = Malam.c950);
    canvas.drawCircle(
      Offset.zero,
      _inner - 14,
      stroke(const Color(0xffe0b03e).withValues(alpha: 0.5), 1.5),
    );
    text(
      canvas,
      focusName,
      34,
      serif(
        size: math.min(18, 185 / (focusName.length * 0.52)),
        color: Prada.c200,
      ),
    );
    text(
      canvas,
      focusRegion,
      52,
      TextStyle(
        fontFamily: font,
        color: Kemenyan.c200,
        fontSize: math.min(11.5, 170 / (focusRegion.length * 0.56)),
      ),
    );
    for (var i = 0; i < focusClade.length; i++) {
      final line = focusClade[i];
      text(
        canvas,
        i < focusClade.length - 1 ? '$line /' : line,
        68 + i * 14.0,
        TextStyle(
          fontFamily: font,
          color: Kemenyan.c200,
          fontSize: math.min(11.5, (i > 0 ? 120 : 150) / (line.length * 0.56)),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_LanternPainter old) => true;
}
