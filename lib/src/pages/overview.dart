/// Overview: the hero with its two letter-ghosts, the four ways in, the
/// strongest kinships on the tree, and how the tree is built.
library;

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../i18n.dart';
import '../settings.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/marks.dart';
import '../widgets/shell.dart';

const _heroIds = [
  'kuntilanak_indonesian_archipelago',
  'pocong_java_indonesia',
  'banaspati_java_indonesia',
  'nyi_roro_kidul_java_bali',
  'rangda_bali_indonesia',
  'genderuwo_java_indonesia',
  'toyol_tuyul_indonesian_archipelago',
];

const _bestiaryIds = [
  'kuntilanak_merah_java_indonesia',
  'babi_ngepet_java_indonesia',
  'orang_bati_seram_indonesia',
  'naga_besukih_bali_indonesia',
  'preta_indonesian_archipelago',
  'lampor_java_indonesia',
];

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return PageScroll(
      children: [
        SizedBox(height: w >= 640 ? 40 : 24),
        const _Hero(),
        const SizedBox(height: 40),
        const _Views(),
        const SizedBox(height: 40),
        const _Kinships(),
        const SizedBox(height: 40),
        const _HowBuilt(),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    final w = MediaQuery.sizeOf(context).width;
    final meta = data.meta;
    final em = w >= 640 ? 60.0 : 46.0;
    final style = serif(size: em, color: k.ink, height: 1.15);
    final italic = style.copyWith(fontStyle: FontStyle.italic);
    final lang = context.lang;

    // Kuyang sits on the baseline with its descender below it.
    InlineSpan kuyang(String letter) {
      final bottom = letter == 'y' ? 250.0 : 40.0;
      return WidgetSpan(
        alignment: PlaceholderAlignment.aboveBaseline,
        baseline: TextBaseline.alphabetic,
        child: Transform.translate(
          offset: Offset(0, em * bottom / 1000),
          child: KuyangMark(letter: letter, fontSize: em, ink: k.ink),
        ),
      );
    }

    final o = WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: GhostSitO(style: style),
    );
    final title = lang == Lang.id
        ? [
            const TextSpan(text: 'Fil'),
            o,
            const TextSpan(text: 'gen'),
            kuyang('i'),
            const TextSpan(text: ' hantu, '),
            TextSpan(text: context.t('literally'), style: italic),
            const TextSpan(text: '.'),
          ]
        : [
            const TextSpan(text: 'Gh'),
            o,
            const TextSpan(text: 'st phylogen'),
            kuyang('y'),
            const TextSpan(text: ', '),
            TextSpan(text: context.t('literally'), style: italic),
            const TextSpan(text: '.'),
          ];

    final stats = [
      (meta['taxa'] - meta['outgroups'], context.t('statGhosts')),
      (meta['outgroups'], context.t('statOutgroups')),
      (meta['characters'], context.t('statChars')),
      (
        data.regions.where((r) => r != 'Outgroup' && r != 'Widespread').length,
        context.t('statIslands'),
      ),
    ];

    final lead = context.t('heroLead', [meta['taxa'] - 3, meta['characters']]);
    final at = lead.indexOf('IQ-TREE');

    return Glass(
      padding: EdgeInsets.symmetric(
        horizontal: w >= 640 ? 40 : 20,
        vertical: w >= 640 ? 56 : 40,
      ),
      child: Column(
        children: [
          Kicker(context.t('heroKicker'), center: true, spacing: 4),
          const SizedBox(height: 40),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 768),
            child: Semantics(
              header: true,
              label: '${context.t('siteName')}, ${context.t('literally')}.',
              child: ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text.rich(
                    TextSpan(children: title),
                    style: style,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 672),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: lead.substring(0, at)),
                  TextSpan(
                    text: 'IQ-TREE',
                    style: TextStyle(
                      color: k.accent,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: k.accent,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () =>
                          launchUrl(Uri.parse('https://iqtree.github.io/')),
                  ),
                  TextSpan(text: lead.substring(at + 'IQ-TREE'.length)),
                ],
              ),
              textAlign: TextAlign.center,
              style: TextStyle(color: k.muted, fontSize: 18, height: 1.6),
            ),
          ),
          const SizedBox(height: 40),
          Semantics(
            label: context.t('aFewGhosts'),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: w >= 640 ? 20 : 12,
              runSpacing: 12,
              children: [
                for (final (i, id) in _heroIds.indexed)
                  if (data.byId[id] != null)
                    Semantics(
                      link: true,
                      label: data.byId[id]!.name,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => context.go('/ghosts/$id'),
                        child: Drift(
                          delay: i * -0.7,
                          child: Plate(
                            id,
                            size: i == 3 ? 132 : 92,
                            shadow: true,
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 768),
            child: _Grid(
              columns: w >= 640 ? 4 : 2,
              spacing: 12,
              children: [
                for (final (value, label) in stats)
                  Tile(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$value', style: serif(size: 30, color: k.accent)),
                        Text(
                          label,
                          style: TextStyle(color: k.muted, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Equal-width grid whose rows size to their tallest cell.
class _Grid extends StatelessWidget {
  const _Grid({
    required this.columns,
    required this.children,
    this.spacing = 16,
  });

  final int columns;
  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final cells = children.sublist(i, math.min(i + columns, children.length));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < columns; j++) ...[
                if (j > 0) SizedBox(width: spacing),
                Expanded(child: j < cells.length ? cells[j] : const SizedBox()),
              ],
            ],
          ),
        ),
      );
      if (i + columns < children.length) rows.add(SizedBox(height: spacing));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

class _Views extends StatelessWidget {
  const _Views();

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    final w = MediaQuery.sizeOf(context).width;
    const views = [
      ('/atlas', 'navAtlas', 'kindAtlas', 'blurbAtlas'),
      ('/lantern', 'navLantern', 'kindLantern', 'blurbLantern'),
      ('/bestiary', 'navBestiary', 'kindBestiary', 'blurbBestiary'),
      ('/patterns', 'navPatterns', 'kindPatterns', 'blurbPatterns'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Glass(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Semantics(
                header: true,
                child: Text(
                  context.t('fourWays'),
                  style: serif(size: 30, color: k.ink),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.t('fourWaysLead'),
                textAlign: TextAlign.center,
                style: TextStyle(color: k.muted, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Grid(
          columns: w >= 640 ? 2 : 1,
          children: [
            for (final (path, name, kind, blurb) in views)
              _ViewCard(path, name, kind, blurb),
          ],
        ),
      ],
    );
  }
}

class _ViewCard extends StatefulWidget {
  const _ViewCard(this.path, this.name, this.kind, this.blurb);

  final String path, name, kind, blurb;

  @override
  State<_ViewCard> createState() => _ViewCardState();
}

class _ViewCardState extends State<_ViewCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    final lantern = widget.path == '/lantern';
    final art = switch (widget.path) {
      '/atlas' => CustomPaint(
        size: const Size(213, 128),
        painter: _AtlasArt(k),
      ),
      '/lantern' => CustomPaint(
        size: const Size(128, 128),
        painter: _LanternArt(k),
      ),
      '/bestiary' => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final id in _bestiaryIds)
            if (data.byId[id] != null)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: k.dark
                      ? Malam.c900.withValues(alpha: 0.8)
                      : Kafan.c50.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Plate(id, size: 40),
              ),
        ],
      ),
      _ => CustomPaint(size: const Size(233, 128), painter: _PatternsArt(k)),
    };
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedSlide(
        offset: Offset(0, _hover ? -0.02 : 0),
        duration: const Duration(milliseconds: 150),
        child: Semantics(
          link: true,
          child: GestureDetector(
            onTap: () => context.go(widget.path),
            child: Glass(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ExcludeSemantics(
                    child: Container(
                      height: 160,
                      alignment: Alignment.center,
                      color: lantern
                          ? night.withValues(alpha: 0.9)
                          : (k.dark ? Malam.c900 : Kafan.c200).withValues(
                              alpha: 0.5,
                            ),
                      child: SizedBox(width: 240, child: Center(child: art)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Kicker(context.t(widget.kind), spacing: 1.5),
                        const SizedBox(height: 4),
                        Text(
                          context.t(widget.name),
                          style: serif(size: 24, color: k.ink),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.t(widget.blurb),
                          style: TextStyle(
                            color: k.muted,
                            fontSize: 14,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${context.t('open', [context.t(widget.name)])} →',
                          style: TextStyle(
                            color: k.accent,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            decoration: _hover
                                ? TextDecoration.underline
                                : null,
                            decorationColor: k.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Paint _line(Color c, [double w = 2]) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round;

class _AtlasArt extends CustomPainter {
  _AtlasArt(this.k);

  final Tokens k;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 200, size.height / 120);
    void seg(List<double> pts, Color c) {
      for (var i = 0; i < pts.length; i += 4) {
        canvas.drawLine(
          Offset(pts[i], pts[i + 1]),
          Offset(pts[i + 2], pts[i + 3]),
          _line(c),
        );
      }
    }

    seg([
      10,
      60,
      30,
      60,
      30,
      25,
      30,
      95,
      30,
      25,
      55,
      25,
      55,
      15,
      55,
      35,
      30,
      95,
      50,
      95,
      50,
      55,
      50,
      110,
    ], k.neutralBranch);
    seg([55, 15, 80, 15, 55, 35, 80, 35], k.cladeColors[0]);
    seg([50, 55, 80, 55, 50, 80, 80, 80], k.cladeColors[2]);
    seg([50, 110, 80, 110], k.cladeColors[7]);
    final on = Paint()..color = k.dark ? Prada.c300 : Malam.c800;
    final off = _line(k.dark ? Kemenyan.c400 : Kafan.c700, 1);
    for (final (r, y) in [15.0, 35.0, 55.0, 80.0, 110.0].indexed) {
      canvas.drawCircle(Offset(88, y), 5, Paint()..color = Malam.c900);
      for (var c = 0; c < 8; c++) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(128 + c * 9.0, y - 4, 7, 7),
          const Radius.circular(1.5),
        );
        canvas.drawRRect(rect, (r * 3 + c * 5) % 3 == 0 ? on : off);
      }
    }
  }

  @override
  bool shouldRepaint(_AtlasArt old) => old.k != k;
}

class _LanternArt extends CustomPainter {
  _LanternArt(this.k);

  final Tokens k;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(size.width / 120);
    canvas.drawCircle(
      Offset.zero,
      54,
      _line(Prada.c400.withValues(alpha: 0.3), 1),
    );
    for (var i = 0; i < 28; i++) {
      final a = i / 28 * math.pi * 2;
      canvas.drawLine(
        Offset(math.cos(a) * 22, math.sin(a) * 22),
        Offset(math.cos(a) * 44, math.sin(a) * 44),
        _line(Tokens.darkTokens.cladeColors[i % 9], 1.6)
          ..strokeCap = StrokeCap.butt,
      );
    }
    canvas.drawCircle(Offset.zero, 18, Paint()..color = night);
    canvas.drawCircle(Offset.zero, 18, _line(Prada.c400, 1));
    canvas.drawCircle(Offset.zero, 9, Paint()..color = const Color(0xfff1e9d8));
  }

  @override
  bool shouldRepaint(_LanternArt old) => false;
}

class _PatternsArt extends CustomPainter {
  _PatternsArt(this.k);

  final Tokens k;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 200, size.height / 110);
    for (var r = 0; r < 6; r++) {
      for (var c = 0; c < 8; c++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(20 + c * 20.0, 8 + r * 16.0, 18, 14),
            const Radius.circular(3),
          ),
          Paint()..color = k.seq[(r * 7 + c * 3) % 6],
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PatternsArt old) => old.k != k;
}

class _Kinships extends StatelessWidget {
  const _Kinships();

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    final w = MediaQuery.sizeOf(context).width;
    final lang = context.lang;
    // Well-supported small clades, read straight from the tree.
    final pairs =
        data.cladogram.all
            .where(
              (p) => !p.isTip && p.tips.length <= 3 && (p.support ?? 0) >= 90,
            )
            .toList()
          ..sort((a, b) => (b.support ?? 0).compareTo(a.support ?? 0));
    return GlassSection(
      title: context.t('kinships'),
      lead: context.t('kinshipsLead', [
        data.meta['strongNodes'],
        data.meta['nodes'],
      ]),
      center: true,
      child: _Grid(
        columns: w >= 1024
            ? 3
            : w >= 640
            ? 2
            : 1,
        spacing: 12,
        children: [
          for (final p in pairs.take(6))
            Builder(
              builder: (context) {
                final ghosts = [for (final id in p.tips) data.byId[id]!];
                return Tile(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 52 + (ghosts.length - 1) * 36,
                        height: 52,
                        child: Stack(
                          children: [
                            for (final (i, g) in ghosts.indexed)
                              Positioned(
                                left: i * 36.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: k.dark ? Malam.c900 : Kafan.c50,
                                      width: 2,
                                    ),
                                  ),
                                  child: Plate(g.id, size: 48),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              children: [
                                for (final (i, g) in ghosts.indexed) ...[
                                  if (i > 0)
                                    Text(
                                      ' + ',
                                      style: TextStyle(color: k.muted),
                                    ),
                                  InkWell(
                                    onTap: () => context.go('/ghosts/${g.id}'),
                                    child: Text(
                                      g.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                        decorationColor: Kafan.c500,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              'UFBoot ${p.support} · ${{for (final g in ghosts) regionName(lang, g.regionGroup)}.join(', ')}',
                              style: TextStyle(color: k.muted, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _HowBuilt extends StatelessWidget {
  const _HowBuilt();

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    final w = MediaQuery.sizeOf(context).width;
    final meta = data.meta;
    final a = data.analysis;
    final steps = [
      (context.t('stepParse'), context.t('stepParseText', [meta['taxa']])),
      (
        context.t('stepEncode'),
        context.t('stepEncodeText', [meta['taxa'], meta['characters']]),
      ),
      (
        context.t('stepInfer'),
        context.t('stepInferText', [a['software'], a['model'] ?? '?']),
      ),
      (context.t('stepPublish'), context.t('stepPublishText')),
    ];
    return GlassSection(
      title: context.t('howBuilt'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Grid(
            columns: w >= 1024
                ? 4
                : w >= 640
                ? 2
                : 1,
            children: [
              for (final (i, (step, text)) in steps.indexed)
                Tile(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExcludeSemantics(
                        child: Text(
                          '${i + 1}',
                          style: serif(size: 24, color: k.accent),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        text,
                        style: TextStyle(
                          color: k.muted,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${context.t('workflowNote')} ',
                style: const TextStyle(fontSize: 14),
              ),
              AccentLink(
                context.t('readMethods'),
                onTap: () => context.go('/methods'),
              ),
              const Text('.', style: TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
