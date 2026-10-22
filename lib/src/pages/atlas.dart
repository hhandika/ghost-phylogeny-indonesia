/// "Atlas": the classic phylogenetics figure, ported from
/// web/src/islands/Atlas.tsx. A rectangular tree on the left, tip plates and
/// names, and the coded trait matrix aligned to the tips, with the selected
/// ghost's card beside it. Scrolls sideways on phones.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data.dart';
import '../settings.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ghost_card.dart';
import '../widgets/shell.dart';

const _row = 22.0;
const _treeW = 330.0;
const _labelW = 196.0;
const _cell = 13.0;
const _minWidth = 680.0;

class AtlasPage extends StatefulWidget {
  const AtlasPage({super.key});

  @override
  State<AtlasPage> createState() => _AtlasPageState();
}

class _AtlasPageState extends State<AtlasPage> {
  TreeMode mode = TreeMode.cladogram;
  String selected = data.ghosts.first.id;
  String query = '';
  String trait = '';
  String? hover;
  final _layouts = <TreeMode, TreeLayout>{TreeMode.cladogram: data.cladogram};

  TreeLayout get layout => _layouts[mode] ??= TreeLayout(
    data.tree,
    (id) => data.byId[id]!.clade,
    mode,
  );

  bool matches(String id) {
    final g = data.byId[id]!;
    final q = query.trim().toLowerCase();
    final okQuery =
        q.isEmpty ||
        [
          g.name,
          g.region,
          context.tr(g.region),
        ].any((s) => s.toLowerCase().contains(q));
    final okTrait = trait.isEmpty || g.traits[trait] == 1;
    return okQuery && okTrait;
  }

  @override
  Widget build(BuildContext context) {
    final L = layout;
    final nMatch = L.tips.where((t) => matches(t.id!)).length;
    final ghost = data.byId[selected]!;
    return PageScroll(
      wide: true,
      children: [
        PageTitle(
          kicker: context.t('atlasKicker'),
          title: context.t('atlasTitle'),
          lead: context.t('atlasLead', [data.meta['characters']]),
        ),
        const CladeLegend(),
        _toolbar(context, L, nMatch),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, c) {
            final figure = _figure(context, L);
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

  Widget _toolbar(BuildContext context, TreeLayout L, int nMatch) {
    final k = Tokens.of(context);
    return Glass(
      radius: 16,
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 192, maxWidth: 360),
            child: SearchField(
              hint: context.t('searchNameIsland'),
              label: context.t('searchGhosts'),
              onChanged: (v) => setState(() => query = v),
              onSubmitted: (_) {
                for (final tip in L.tips) {
                  if (matches(tip.id!)) {
                    setState(() => selected = tip.id!);
                    break;
                  }
                }
              },
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.t('highlight'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              PillDropdown<String>(
                value: trait,
                label: context.t('highlight'),
                items: [
                  ('', context.t('noTrait')),
                  for (final c
                      in data.characters.take(18).where((c) => c.id != 'sex'))
                    (c.id, context.tr(c.label)),
                ],
                onChanged: (v) => setState(() => trait = v),
              ),
            ],
          ),
          Semantics(
            label: context.t('branchLengths'),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: controlDecoration(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final m in TreeMode.values)
                    PillButton(
                      label: context.t(m.name),
                      selected: mode == m,
                      bordered: false,
                      small: true,
                      onPressed: () => setState(() => mode = m),
                    ),
                ],
              ),
            ),
          ),
          Semantics(
            liveRegion: true,
            child: Text(
              context.t('nMatch', [nMatch, L.nTips]),
              style: TextStyle(color: k.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _figure(BuildContext context, TreeLayout L) {
    final k = Tokens.of(context);
    final labels = [for (final c in data.characters) context.tr(c.label)];
    // Room for the rotated matrix headers, sized to the longest label.
    final top = math.max(
      124.0,
      (24 + labels.map((s) => s.length).reduce(math.max) * 4.9).ceilToDouble(),
    );
    const matrixX = _treeW + _labelW;
    // Rotated headers lean right; leave room for the last ones.
    final n = labels.length;
    var lean = -double.infinity;
    for (var j = 0; j < 4; j++) {
      lean = math.max(
        lean,
        labels[n - 4 + j].length * 5.6 * 0.5 - (3 - j) * _cell,
      );
    }
    final w = matrixX + n * _cell + math.max(8, lean + 8);
    final h = top + L.nTips * _row + 8;
    const labelX = _treeW + 4;
    double sy(double y) => top + y * _row + _row / 2;
    String? rowAt(Offset p) {
      final i = ((p.dy - top) / _row).floor();
      if (i < 0 || i >= L.nTips) return null;
      return L.tips.firstWhere((t) => t.y == i).id;
    }

    final filtering = query.trim().isNotEmpty || trait.isNotEmpty;
    final ghost = data.byId[selected]!;

    final canvas = SizedBox(
      width: w,
      height: h,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onHover: (e) {
          final id = rowAt(e.localPosition);
          if (id != hover) setState(() => hover = id);
        },
        onExit: (_) => setState(() => hover = null),
        child: GestureDetector(
          onTapUp: (e) {
            final id = rowAt(e.localPosition);
            if (id != null) setState(() => selected = id);
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _AtlasPainter(
                    layout: L,
                    tokens: k,
                    labels: labels,
                    top: top,
                    width: w,
                    selected: selected,
                    hover: hover,
                    trait: trait,
                    filtering: filtering,
                    matches: matches,
                  ),
                ),
              ),
              for (final tip in L.tips)
                Positioned(
                  left: labelX,
                  top: sy(tip.y) - 9,
                  child: Opacity(
                    opacity: matches(tip.id!) ? 1 : 0.3,
                    child: Plate(tip.id!, size: 18),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return Glass(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final display = math.max(c.maxWidth, _minWidth);
              final figure = Semantics(
                label: context.t('atlasSvg', [L.nTips, ghost.name]),
                child: SizedBox(
                  width: display,
                  height: h * display / w,
                  child: FittedBox(fit: BoxFit.fill, child: canvas),
                ),
              );
              if (display <= c.maxWidth) return figure;
              return Semantics(
                label: context.t('atlasFigure'),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: figure,
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Text(
              context.t('atlasCaption'),
              style: TextStyle(color: k.muted, fontSize: 12, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _AtlasPainter extends CustomPainter {
  _AtlasPainter({
    required this.layout,
    required this.tokens,
    required this.labels,
    required this.top,
    required this.width,
    required this.selected,
    required this.hover,
    required this.trait,
    required this.filtering,
    required this.matches,
  });

  final TreeLayout layout;
  final Tokens tokens;
  final List<String> labels;
  final double top;
  final double width;
  final String selected;
  final String? hover;
  final String trait;
  final bool filtering;
  final bool Function(String) matches;

  double sx(double x) => 8 + (x / layout.maxX) * (_treeW - 16);
  double sy(double y) => top + y * _row + _row / 2;

  Color clade(String? c) {
    if (c == null) return tokens.neutralBranch;
    final i = data.clades.indexOf(c);
    return i < 0 ? tokens.neutralBranch : tokens.cladeColors[i];
  }

  void text(
    Canvas canvas,
    String s,
    Offset baseline,
    TextStyle style, {
    double rotate = 0,
    bool center = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final ascent = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    canvas.save();
    canvas.translate(baseline.dx, baseline.dy);
    if (rotate != 0) canvas.rotate(rotate);
    tp.paint(canvas, Offset(center ? -tp.width / 2 : 0, -ascent));
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final k = tokens;
    final dark = k.dark;
    final font = GoogleFonts.figtree().fontFamily;
    const matrixX = _treeW + _labelW;
    const labelX = _treeW + 4;
    final on = dark ? Prada.c300 : Malam.c800;

    // Matrix headers
    for (var i = 0; i < labels.length; i++) {
      final hit = trait == data.characters[i].id;
      text(
        canvas,
        labels[i],
        Offset(matrixX + i * _cell + _cell / 2 + 3, top - 6),
        TextStyle(
          fontFamily: font,
          fontSize: 10,
          color: hit ? k.accent : k.muted,
          fontWeight: hit ? FontWeight.bold : FontWeight.normal,
        ),
        rotate: -math.pi / 3,
      );
    }

    // Row bands for selected and hovered tips
    for (final tip in layout.tips) {
      if (tip.id != selected && tip.id != hover) continue;
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, sy(tip.y) - _row / 2, width, _row),
        const Radius.circular(6),
      );
      if (tip.id == selected) {
        canvas.drawRRect(
          r,
          Paint()
            ..color = dark ? Malam.c800 : Prada.c200.withValues(alpha: 0.8),
        );
      } else {
        canvas.drawRRect(
          r,
          Paint()
            ..color = dark ? Malam.c900 : Kafan.c200.withValues(alpha: 0.7),
        );
        canvas.drawRRect(
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = dark ? Prada.c300 : Darah.c700,
        );
      }
    }

    // Branches, the selected lineage thick
    final path = TreeLayout.ancestry(layout.tipById[selected]).toSet();
    Paint branch(Color c, double w) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    for (final p in layout.all) {
      final color = clade(p.clade);
      if (p.parent != null) {
        canvas.drawLine(
          Offset(sx(p.parent!.x), sy(p.y)),
          Offset(sx(p.x), sy(p.y)),
          branch(color, path.contains(p) ? 3.5 : 1.6),
        );
      }
      if (!p.isTip) {
        canvas.drawLine(
          Offset(sx(p.x), sy(p.children.first.y)),
          Offset(sx(p.x), sy(p.children.last.y)),
          branch(color, 1.6),
        );
      }
    }

    // Node support: filled ≥ 95, open 80–94
    for (final p in layout.all) {
      final s = p.support;
      if (p.isTip || s == null || s < 80) continue;
      final strong = s >= 95;
      final c = Offset(sx(p.x), sy(p.y));
      final fill = strong
          ? (dark ? Kafan.c100 : Malam.c900)
          : (dark ? Malam.c950 : Kafan.c50);
      final stroke = strong
          ? (dark ? Malam.c950 : Kafan.c50)
          : (dark ? Kafan.c100 : Malam.c900);
      canvas.drawCircle(c, 3.4, Paint()..color = fill);
      canvas.drawCircle(c, 3.4, branch(stroke, 1.4));
    }

    // Tips: leader, name, matrix row
    for (final tip in layout.tips) {
      final g = data.byId[tip.id]!;
      final y = sy(tip.y);
      final hit = matches(g.id);
      if (layout.mode == TreeMode.phylogram) {
        final leader = branch(dark ? Malam.c600 : Kafan.c400, 1)
          ..strokeCap = StrokeCap.butt;
        for (var x = sx(tip.x) + 2; x < labelX; x += 4) {
          canvas.drawLine(
            Offset(x, y),
            Offset(math.min(x + 1, labelX), y),
            leader,
          );
        }
      }
      final isSel = g.id == selected;
      text(
        canvas,
        '${g.name}${g.outgroup ? ' †' : ''}${g.coding != 'source' ? ' ◆' : ''}',
        Offset(labelX + 23, y + 4),
        TextStyle(
          fontFamily: font,
          fontSize: 12,
          fontWeight: isSel || (hit && filtering)
              ? FontWeight.bold
              : FontWeight.normal,
          color: isSel
              ? (dark ? Prada.c200 : Darah.c800)
              : !hit
              ? k.muted
              : (dark ? (filtering ? Kafan.c50 : Kafan.c100) : Malam.c950),
        ),
      );

      // States differ in shape as well as color: filled square = present,
      // outlined = absent, half-filled = variable, dot = unknown, letter =
      // multistate code. Filtered-out rows fade their shapes.
      final op = hit ? 1.0 : 0.3;
      const s = _cell - 3;
      for (var i = 0; i < g.row.length; i++) {
        final state = g.row[i];
        final x = matrixX + i * _cell;
        final box = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y - s / 2, s, s),
          const Radius.circular(2),
        );
        if (state == '?') {
          canvas.drawCircle(
            Offset(x + s / 2, y),
            1.6,
            Paint()..color = k.muted.withValues(alpha: op),
          );
        } else if (i >= 18) {
          canvas.drawRRect(
            box,
            Paint()
              ..color = (dark ? Malam.c800 : Kafan.c200).withValues(alpha: op),
          );
          canvas.drawRRect(
            box,
            branch(k.controlBorder.withValues(alpha: op), 0.8),
          );
          text(
            canvas,
            state,
            Offset(x + s / 2, y + 3),
            TextStyle(
              fontFamily: font,
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: dark ? Kafan.c100 : Malam.c950,
            ),
            center: true,
          );
        } else if (state == '1') {
          canvas.drawRRect(box, Paint()..color = on.withValues(alpha: op));
        } else if (state == '2') {
          canvas.drawRRect(box, branch(on, 1));
          canvas.drawPath(
            Path()
              ..moveTo(x, y + s / 2)
              ..lineTo(x + s, y - s / 2)
              ..lineTo(x + s, y + s / 2)
              ..close(),
            Paint()..color = on.withValues(alpha: op),
          );
        } else {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x + 0.5, y - s / 2 + 0.5, s - 1, s - 1),
              const Radius.circular(2),
            ),
            branch(k.controlBorder.withValues(alpha: op), 1),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_AtlasPainter old) => true;
}
