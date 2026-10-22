/// "Patterns": the whole dataset shown chart by chart, each in a different
/// form, ported from web/src/islands/Patterns.tsx. Hover, focus, or tap
/// updates a readout line under the chart (never a floating tooltip, so
/// nothing covers the marks), and every chart has a data table.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:path_drawing/path_drawing.dart';

import '../data.dart';
import '../i18n.dart' as i18n;
import '../settings.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/shell.dart';

const _landAsset = 'web/src/data/indonesia-land.json';
const _shelvesAsset = 'web/src/data/iaa-shelves.json';

List<Character> get _traits =>
    data.characters.take(18).where((c) => c.id != 'sex').toList();

int _pct(int n, int d) => d == 0 ? 0 : (n / d * 100).round();

List<Ghost> _where(bool Function(Ghost) f) => data.ghosts.where(f).toList();

/// Counts of each clade among [gs], most common first.
List<MapEntry<String, int>> _topClades(List<Ghost> gs) {
  final c = <String, int>{};
  for (final g in gs) {
    c[g.clade] = (c[g.clade] ?? 0) + 1;
  }
  return c.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
}

Color _surface(Tokens k) => k.dark ? Malam.c900 : Kafan.c100;

class PatternsPage extends StatefulWidget {
  const PatternsPage({super.key});

  @override
  State<PatternsPage> createState() => _PatternsPageState();
}

class _PatternsPageState extends State<PatternsPage> {
  final _keys = {for (final s in _sections) s.$1: GlobalKey(debugLabel: s.$1)};

  static const _sections = [
    ('where', 'secWhere'),
    ('traits', 'secTraits'),
    ('danger', 'secDanger'),
    ('bodies', 'secBodies'),
    ('support', 'secSupport'),
    ('twins', 'secTwins'),
    ('provenance', 'secProvenance'),
  ];

  void _jump(String id) {
    final c = _keys[id]?.currentContext;
    if (c == null) return;
    Scrollable.ensureVisible(
      c,
      duration: context.settings.animate(context)
          ? const Duration(milliseconds: 450)
          : Duration.zero,
      curve: Curves.easeInOut,
    );
  }

  /// A section with an invisible anchor above it, so a jump clears the header.
  Widget _anchored(String id, Widget child) => Stack(
    clipBehavior: Clip.none,
    children: [
      child,
      Positioned(
        top: -96,
        left: 0,
        child: SizedBox(key: _keys[id], width: 1, height: 1),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    final k = Tokens.of(context);

    // Data-driven leads, so the text always matches the charts.
    final regionCounts = [
      for (final r in data.regions)
        MapEntry(r, _where((g) => g.regionGroup == r).length),
    ]..sort((a, b) => b.value.compareTo(a.value));
    String rn(int i) => i18n.regionName(lang, regionCounts[i].key);
    final lethal = _where((g) => g.danger == 5).length;
    final dangerByClade = [
      for (final c in data.clades)
        () {
          final gs = _where((g) => g.clade == c);
          return MapEntry(c, gs.fold(0, (s, g) => s + g.danger) / gs.length);
        }(),
    ]..sort((a, b) => b.value.compareTo(a.value));
    final synth = _where((g) => g.coding != 'source').length;
    final twinSets = {
      for (final g in data.ghosts)
        if (g.twins.isNotEmpty) g.row,
    }.length;
    final blood = ([
      for (final c in data.clades)
        () {
          final gs = _where((g) => g.clade == c);
          return MapEntry(
            c,
            gs.where((g) => g.traits['predation_blood_organs'] == 1).length /
                gs.length,
          );
        }(),
    ]..sort((a, b) => b.value.compareTo(a.value))).first;
    final bloodPlans = [
      for (final b in data.bodyPlans)
        MapEntry(
          context.tr(b.label),
          _where((g) => g.bodyPlan == b.id && g.dietClass == 'Blood').length,
        ),
    ]..sort((a, b) => b.value.compareTo(a.value));
    final bloodTotal = _where((g) => g.dietClass == 'Blood').length;
    final supports = [
      for (final p in data.cladogram.all)
        if (!p.isTip && p.support != null) p.support!,
    ];

    Widget gap() => const SizedBox(height: 24);

    return PageScroll(
      wide: true,
      children: [
        PageTitle(
          title: context.t('patternsTitle'),
          kicker: context.t('patternsKicker'),
          lead: context.t('patternsLead'),
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1024),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  label: context.t('chartsOnPage'),
                  container: true,
                  child: Glass(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (id, label) in _sections)
                          Semantics(
                            link: true,
                            child: Material(
                              color: k.controlFill,
                              shape: StadiumBorder(
                                side: BorderSide(color: k.controlBorder),
                              ),
                              child: InkWell(
                                customBorder: const StadiumBorder(),
                                hoverColor: k.hover,
                                onTap: () => _jump(id),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  child: Text(
                                    context.t(label),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                gap(),
                _anchored(
                  'where',
                  GlassSection(
                    title: context.t('secWhere'),
                    lead: context.t('leadWhere', [
                      rn(0),
                      regionCounts[0].value,
                      rn(1),
                      regionCounts[1].value,
                      rn(2),
                      regionCounts[2].value,
                    ]),
                    child: const _ArchipelagoMap(),
                  ),
                ),
                gap(),
                _anchored(
                  'traits',
                  GlassSection(
                    title: context.t('secTraits'),
                    lead: context.t('leadTraits', [
                      context.tr(blood.key),
                      (blood.value * 100).round(),
                    ]),
                    child: const _TraitHeatmap(),
                  ),
                ),
                gap(),
                _anchored(
                  'danger',
                  GlassSection(
                    title: context.t('secDanger'),
                    lead: context.t('leadDanger', [
                      lethal,
                      context.tr(dangerByClade.first.key),
                      i18n.num(lang, dangerByClade.first.value, 1),
                    ]),
                    child: const _DangerUnits(),
                  ),
                ),
                gap(),
                _anchored(
                  'bodies',
                  GlassSection(
                    title: context.t('secBodies'),
                    lead: context.t('leadBodies', [
                      bloodTotal,
                      bloodPlans[0].value,
                      bloodPlans[0].key,
                      bloodPlans[1].value,
                      bloodPlans[1].key,
                    ]),
                    child: const _BodyDiet(),
                  ),
                ),
                gap(),
                _anchored(
                  'support',
                  GlassSection(
                    title: context.t('secSupport'),
                    lead: context.t('leadSupport', [
                      supports.length,
                      data.meta['strongNodes'],
                      data.meta['weakNodes'],
                    ]),
                    child: _SupportHistogram(supports: supports),
                  ),
                ),
                gap(),
                _anchored(
                  'twins',
                  GlassSection(
                    title: context.t('secTwins'),
                    lead: context.t('leadTwins', [twinSets]),
                    child: const _Twins(),
                  ),
                ),
                gap(),
                _anchored(
                  'provenance',
                  GlassSection(
                    title: context.t('secProvenance'),
                    lead: context.t('leadProvenance', [
                      synth,
                      data.ghosts.length,
                    ]),
                    child: const _Provenance(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---- Shared chart parts ------------------------------------------------------

/// Status line under a chart: the hovered mark, or a hint when idle.
class _Readout extends StatelessWidget {
  const _Readout({required this.text, required this.idle});

  final String? text;
  final String idle;

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: _surface(k),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text ?? idle,
          style: TextStyle(color: k.muted, fontSize: 14, height: 1.4),
        ),
      ),
    );
  }
}

/// Expandable data table behind every chart.
class _DataTable extends StatefulWidget {
  const _DataTable({
    required this.caption,
    required this.head,
    required this.rows,
  });

  final String caption;
  final List<String> head;
  final List<List<Object>> rows;

  @override
  State<_DataTable> createState() => _DataTableState();
}

class _DataTableState extends State<_DataTable> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    Widget cell(Object v, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Text(
        '$v',
        style: TextStyle(
          fontSize: 14,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            expanded: _open,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => setState(() => _open = !_open),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _open ? Icons.arrow_drop_down : Icons.arrow_right,
                    color: k.accent,
                    size: 20,
                  ),
                  Flexible(
                    child: Text(
                      context.t('showTable'),
                      style: TextStyle(
                        color: k.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: k.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: const BoxConstraints(maxHeight: 384),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: k.tileBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: Semantics(
                label: context.t('scrollable', [widget.caption]),
                child: SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Table(
                      defaultColumnWidth: const IntrinsicColumnWidth(),
                      border: TableBorder(
                        horizontalInside: BorderSide(
                          color: k.dark ? Malam.c800 : Kafan.c200,
                        ),
                      ),
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: _surface(k)),
                          children: [
                            for (final h in widget.head) cell(h, bold: true),
                          ],
                        ),
                        for (final r in widget.rows)
                          TableRow(
                            children: [
                              for (var j = 0; j < r.length; j++)
                                cell(r[j], bold: j == 0),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.color, this.label);

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: k.dark
                  ? Colors.white.withValues(alpha: 0.3)
                  : Malam.c950.withValues(alpha: 0.3),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(child: Text(label, style: const TextStyle(fontSize: 12))),
      ],
    );
  }
}

/// A fixed-size drawing scaled to the available width, scrolling sideways
/// when the width falls below [minWidth].
class _Canvas extends StatelessWidget {
  const _Canvas({
    required this.width,
    required this.height,
    required this.minWidth,
    required this.child,
    this.label,
  });

  final double width;
  final double height;
  final double minWidth;
  final Widget child;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = math.max(box.maxWidth, minWidth);
        final content = SizedBox(
          width: w,
          height: w * height / width,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(width: width, height: height, child: child),
          ),
        );
        return Semantics(
          label: label,
          container: true,
          child: w > box.maxWidth
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: content,
                )
              : content,
        );
      },
    );
  }
}

/// Text placed at an SVG-style anchor point.
Widget _label(
  String text, {
  required double x,
  required double y,
  TextStyle? style,
  TextAlign align = TextAlign.start,
  double angle = 0,
  double width = 260,
}) {
  // Anchor the baseline-ish centre line at (x, y), like SVG text.
  final dx = switch (align) {
    TextAlign.end => -width,
    TextAlign.center => -width / 2,
    _ => 0.0,
  };
  final child = SizedBox(
    width: width,
    child: Text(
      text,
      textAlign: align,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.visible,
      style: style,
    ),
  );
  return Positioned(
    left: x + dx,
    top: y - 12,
    child: angle == 0
        ? child
        : Transform.rotate(
            angle: angle,
            alignment: Alignment.centerLeft,
            child: child,
          ),
  );
}

// ---- 1. Archipelago map with Pleistocene sea levels --------------------------

const _west = 94.0, _east = 142.0, _south = -12.5, _north = 7.5;
const _scale = 20.0;
double _mx(double lon) => (lon - _west) * _scale;
double _my(double lat) => (_north - lat) * _scale;
const _mapW = (_east - _west) * _scale;
const _mapH = (_north - _south) * _scale;

const _levels = [
  (level: 0, label: 'today', note: 'lvlToday'),
  (level: -40, label: '−40 m', note: 'lvl40'),
  (level: -80, label: '−80 m', note: 'lvl80'),
  (level: -120, label: '−120 m', note: 'lvl120'),
];

// Approximate placements after Wallace (1863), Huxley (1868), Weber (1902),
// and Lydekker (1896), as on hhandika-com's speciation map.
const _lines = [
  (
    id: 'wallace',
    name: 'lineWallace',
    color: Color(0xffe67e14),
    points: [
      [115.8, -10.5], [115.75, -8.7], [116.4, -6.8], [117.25, -5.2], //
      [117.8, -3.8], [118.35, -2.5], [118.4, -1.0], [118.7, 0.2],
      [119.45, 1.1], [119.5, 2.2], [119.6, 3.2], [121.5, 4.6], [124.0, 5.3],
      [126.2, 5.4], [127.3, 5.9], [128.8, 6.6],
    ],
  ),
  (
    id: 'huxley',
    name: 'lineHuxley',
    color: Color(0xffe2b93b),
    points: [
      [119.5, 2.2], [119.5, 4.2], [119.6, 5.0], [119.4, 6.0], [119.0, 7.3], //
      [119.0, 8.6],
    ],
  ),
  (
    id: 'weber',
    name: 'lineWeber',
    color: Color(0xffc96fd8),
    points: [
      [129.2, 5.8], [127.8, 4.0], [127.1, 2.5], [126.9, 0.5], [126.9, -0.6], //
      [126.8, -1.8], [126.3, -2.8], [125.75, -3.3], [125.8, -4.1],
      [126.6, -4.3], [127.7, -4.3], [128.8, -5.2], [129.6, -6.3],
      [129.5, -7.4], [129.2, -8.6], [128.0, -9.2], [126.5, -10.2],
      [124.8, -11.2],
    ],
  ),
  (
    id: 'lydekker',
    name: 'lineLydekker',
    color: Color(0xff5f92cb),
    points: [
      [125.5, -11.6], [127.0, -10.4], [129.6, -9.2], [131.6, -8.7], //
      [132.2, -7.5], [133.3, -6.6], [133.7, -5.9], [133.65, -5.1],
      [132.2, -4.8], [131.4, -3.6], [129.6, -2.3], [129.3, -0.8],
      [129.5, 0.6], [130.5, 1.0], [131.8, 1.4],
    ],
  ),
];

// Bubble anchors. Widespread motifs and outgroups sit in open sea.
const _regionAt = {
  'Sumatra': (101.2, -0.6),
  'Java': (110.2, -7.3),
  'Bali': (115.2, -8.4),
  'Nusa Tenggara': (120.6, -8.7),
  'Kalimantan': (114.0, 0.6),
  'Sulawesi': (120.6, -2.2),
  'Maluku': (128.8, -3.2),
  'Papua': (138.0, -4.6),
  'Widespread': (98.4, -8.6),
  'Outgroup': (137.0, 3.6),
};

// Biogeographic regions, labelled once their shelves can be exposed.
const _zones = [
  (name: 'zoneSunda', lon: 106.5, lat: 4.2),
  (name: 'zoneWallacea', lon: 124.6, lat: -6.4),
  (name: 'zoneSahul', lon: 136.2, lat: -10.2),
];

/// Coastline and exposed shelves, loaded once from the website's data.
class _MapGeometry {
  _MapGeometry(this.land, this.shelves);

  final Path land;
  final Map<int, Path> shelves;

  static Future<_MapGeometry>? _future;

  static Future<_MapGeometry> load() => _future ??= () async {
    final land = Path();
    final landJson = jsonDecode(await rootBundle.loadString(_landAsset));
    for (final ring in landJson['rings'] as List) {
      final pts = [
        for (final p in ring as List)
          Offset(_mx((p[0] as num).toDouble()), _my((p[1] as num).toDouble())),
      ];
      if (pts.isNotEmpty) land.addPolygon(pts, true);
    }
    // The shelf paths come in the frame of hhandika-com's IAA map
    // (x = 33 + 11.647 (lon − 95.2), y = 175.3 + 11.6 (5.65 − lat)); this
    // matrix maps that frame onto ours.
    const a = _scale / 11.647;
    const d = _scale / 11.6;
    final m = Matrix4.identity()
      ..setEntry(0, 0, a)
      ..setEntry(1, 1, d)
      ..setEntry(0, 3, _mx(95.2) - 33 * a)
      ..setEntry(1, 3, _my(5.65) - 175.3 * d);
    final shelvesJson = jsonDecode(await rootBundle.loadString(_shelvesAsset));
    final shelves = <int, Path>{
      for (final s in shelvesJson['shelves'] as List)
        (s['level'] as num).toInt(): (parseSvgPathData(
          s['d'] as String,
        )..fillType = PathFillType.evenOdd).transform(m.storage),
    };
    return _MapGeometry(land, shelves);
  }();
}

class _ArchipelagoMap extends StatefulWidget {
  const _ArchipelagoMap();

  @override
  State<_ArchipelagoMap> createState() => _ArchipelagoMapState();
}

class _ArchipelagoMapState extends State<_ArchipelagoMap> {
  String _region = 'Java';
  String? _hover;
  int _level = 0;
  final Set<String> _shown = {for (final l in _lines) l.id};
  bool _playing = false;
  final List<Timer> _timers = [];

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  // Step from today down to the Last Glacial Maximum.
  void _play() {
    if (_playing) return;
    setState(() => _playing = true);
    for (var i = 0; i < _levels.length; i++) {
      _timers.add(
        Timer(Duration(milliseconds: i * 1100), () {
          if (!mounted) return;
          setState(() {
            _level = _levels[i].level;
            if (i == _levels.length - 1) _playing = false;
          });
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    final lang = context.lang;
    final animate = context.settings.animate(context);
    final fade = Duration(milliseconds: animate ? 700 : 0);
    final groups = {
      for (final r in data.regions) r: _where((g) => g.regionGroup == r),
    };
    final max = groups.values.map((g) => g.length).reduce(math.max);
    double radius(int n) => 8 + math.sqrt(n / max) * 32;
    String describe(String r) {
      final gs = groups[r]!;
      final top = _topClades(gs).first;
      return context.t('regionSays', [
        i18n.regionName(lang, r),
        gs.length,
        context.tr(top.key),
        top.value,
      ]);
    }

    String lvLabel(({int level, String label, String note}) l) =>
        l.label == 'today' ? context.t('today') : l.label;
    final lv = _levels.firstWhere((l) => l.level == _level);
    final shown = groups[_region]!;
    final halo = k.dark ? Malam.c950 : Kafan.c50;
    final ink = k.dark ? Kafan.c100 : Malam.c950;

    Widget haloText(String s, double x, double y, TextStyle style) => Stack(
      clipBehavior: Clip.none,
      children: [
        _label(
          s,
          x: x,
          y: y,
          align: TextAlign.center,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 6
              ..strokeJoin = StrokeJoin.round
              ..color = halo,
          ),
        ),
        _label(
          s,
          x: x,
          y: y,
          align: TextAlign.center,
          style: style.copyWith(color: ink),
        ),
      ],
    );

    final placed = [
      for (final r in data.regions)
        (
          r: r,
          gs: groups[r]!,
          x: _mx(_regionAt[r]!.$1),
          y: _my(_regionAt[r]!.$2),
          rad: radius(groups[r]!.length),
        ),
    ];

    final controls = Wrap(
      spacing: 16,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Semantics(
          label: context.t('seaLevel'),
          container: true,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: controlDecoration(context),
            child: Wrap(
              spacing: 2,
              children: [
                for (final l in _levels)
                  PillButton(
                    label: lvLabel(l),
                    selected: _level == l.level,
                    bordered: false,
                    small: true,
                    onPressed: () => setState(() => _level = l.level),
                  ),
                Semantics(
                  label: context.t('animateSea'),
                  child: Opacity(
                    opacity: _playing ? 0.6 : 1,
                    child: PillButton(
                      label: context.t('play'),
                      selected: false,
                      bordered: false,
                      small: true,
                      leading: Icon(Icons.play_arrow, size: 14, color: k.ink),
                      onPressed: _play,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Semantics(
          label: context.t('bioLines'),
          container: true,
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final l in _lines)
                Opacity(
                  opacity: _shown.contains(l.id) ? 1 : 0.7,
                  child: Semantics(
                    toggled: _shown.contains(l.id),
                    child: Material(
                      color: k.controlFill,
                      shape: StadiumBorder(
                        side: BorderSide(color: k.controlBorder),
                      ),
                      child: InkWell(
                        customBorder: const StadiumBorder(),
                        hoverColor: k.hover,
                        onTap: () => setState(
                          () => _shown.contains(l.id)
                              ? _shown.remove(l.id)
                              : _shown.add(l.id),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomPaint(
                                size: const Size(18, 6),
                                painter: _LineSwatch(l.color),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                context.t(l.name),
                                style: TextStyle(
                                  fontSize: 14,
                                  decoration: _shown.contains(l.id)
                                      ? null
                                      : TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    final map = FutureBuilder<_MapGeometry>(
      future: _MapGeometry.load(),
      builder: (context, snap) => Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _MapPainter(
                geometry: snap.data,
                dark: k.dark,
                lines: [
                  for (final l in _lines)
                    if (_shown.contains(l.id)) (l.color, l.points),
                ],
                boxes: [
                  for (final p in placed)
                    if (p.r == 'Widespread' || p.r == 'Outgroup')
                      Rect.fromLTWH(
                        p.x - 64,
                        p.y - p.rad - 10,
                        128,
                        p.rad * 2 + 42,
                      ),
                ],
                boxColor: k.dark ? Kemenyan.c300 : Kafan.c800,
              ),
            ),
          ),
          // Exposed shelves (ETOPO1), faded in under today's land.
          if (snap.data != null)
            for (final e in snap.data!.shelves.entries)
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: e.key == _level ? 1 : 0,
                  duration: fade,
                  child: CustomPaint(
                    painter: _ShelfPainter(e.value, snap.data!.land, k.dark),
                  ),
                ),
              ),
          // Zone names appear once the sea has fallen.
          Positioned.fill(
            child: ExcludeSemantics(
              child: AnimatedOpacity(
                opacity: _level <= -80 ? 1 : 0,
                duration: fade,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final z in _zones)
                      haloText(
                        context.t(z.name).toUpperCase(),
                        _mx(z.lon),
                        _my(z.lat) - 4,
                        const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.5,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          for (final p in placed)
            Positioned(
              left: p.x - p.rad - 5,
              top: p.y - p.rad - 5,
              child: Semantics(
                button: true,
                selected: p.r == _region,
                label: '${describe(p.r)} ${context.t('showThem')}',
                excludeSemantics: true,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => _hover = p.r),
                  onExit: (_) => setState(() => _hover = null),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _region = p.r;
                      _hover = p.r;
                    }),
                    child: Container(
                      width: (p.rad + 5) * 2,
                      height: (p.rad + 5) * 2,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: 3,
                          color: p.r == _region || p.r == _hover
                              ? (k.dark ? Prada.c200 : Malam.c950)
                              : Colors.transparent,
                        ),
                      ),
                      child: Container(
                        width: p.rad * 2,
                        height: p.rad * 2,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: k.dark ? Darah.c600 : Darah.c700,
                          border: Border.all(
                            width: 2,
                            color: k.dark ? Malam.c950 : Kafan.c50,
                          ),
                        ),
                        child: Text(
                          '${p.gs.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Labels above the bubbles so nothing is covered.
          for (final p in placed)
            IgnorePointer(
              child: ExcludeSemantics(
                child: haloText(
                  i18n.regionName(lang, p.r),
                  p.x,
                  p.y + p.rad + 14,
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        controls,
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _Canvas(
            width: _mapW,
            height: _mapH,
            minWidth: 600,
            label: context.t('mapSvg', [lvLabel(lv), context.t(lv.note)]),
            child: map,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _surface(k),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Semantics(
            liveRegion: true,
            child: Text(
              context.t('seaStatus', [
                    _level == 0 ? context.t('seaToday') : lv.label,
                    context.t(lv.note),
                  ]) +
                  (_level <= -80 ? context.t('seaLowNote') : ''),
              style: TextStyle(color: k.muted, fontSize: 14, height: 1.4),
            ),
          ),
        ),
        _Readout(
          text: _hover == null ? null : describe(_hover!),
          idle: context.t('mapIdle'),
        ),
        const SizedBox(height: 16),
        Text.rich(
          TextSpan(
            text: i18n.regionName(lang, _region),
            children: [
              TextSpan(
                text: ' · ${context.t('ghosts', [shown.length])}',
                style: TextStyle(color: k.muted, fontWeight: FontWeight.w400),
              ),
            ],
          ),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final g in shown)
              Material(
                color: k.controlFill,
                shape: StadiumBorder(side: BorderSide(color: k.controlBorder)),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  hoverColor: k.hover,
                  onTap: () => context.go('/ghosts/${g.id}'),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(2, 2, 12, 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Plate(g.id, size: 26),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            g.name,
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        _DataTable(
          caption: context.t('regionTableCap'),
          head: [
            context.t('region'),
            context.t('ghostsWord'),
            context.t('mostCommonClade'),
          ],
          rows: [
            for (final r in data.regions)
              () {
                final top = _topClades(groups[r]!).first;
                return <Object>[
                  i18n.regionName(lang, r),
                  groups[r]!.length,
                  '${context.tr(top.key)} (${top.value})',
                ];
              }(),
          ],
        ),
      ],
    );
  }
}

Path _dashed(Path p, List<double> pattern) =>
    dashPath(p, dashArray: CircularIntervalList<double>(pattern));

class _LineSwatch extends CustomPainter {
  _LineSwatch(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = _dashed(
      Path()
        ..moveTo(1, size.height / 2)
        ..lineTo(size.width - 1, size.height / 2),
      [5, 3],
    );
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.4
        ..color = Malam.c900,
    );
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_LineSwatch old) => old.color != color;
}

/// Sea, today's land, biogeographic lines, and the off-map boxes.
class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.geometry,
    required this.dark,
    required this.lines,
    required this.boxes,
    required this.boxColor,
  });

  final _MapGeometry? geometry;
  final bool dark;
  final List<(Color, List<List<double>>)> lines;
  final List<Rect> boxes;
  final Color boxColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = dark ? const Color(0xff141022) : const Color(0xffdfe3ec),
    );
    // Land is drawn by _ShelfPainter too (over the shelves); draw it here as
    // well so the coast shows when no shelf is visible.
    final g = geometry;
    if (g != null) _drawLand(canvas, g.land, dark);
    for (final (color, pts) in lines) {
      final path = Path()..moveTo(_mx(pts[0][0]), _my(pts[0][1]));
      for (final p in pts.skip(1)) {
        path.lineTo(_mx(p[0]), _my(p[1]));
      }
      final dashed = _dashed(path, [8, 5]);
      Paint stroke(Color c, double w) => Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = c;
      // A dark casing keeps 3:1 against both land and sea.
      canvas.drawPath(dashed, stroke(Malam.c900, 4.6));
      canvas.drawPath(dashed, stroke(color, 2.2));
    }
    for (final r in boxes) {
      canvas.drawPath(
        _dashed(
          Path()
            ..addRRect(RRect.fromRectAndRadius(r, const Radius.circular(14))),
          [4, 4],
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..color = boxColor,
      );
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      old.geometry != geometry ||
      old.dark != dark ||
      old.lines.length != lines.length ||
      old.boxColor != boxColor;
}

void _drawLand(Canvas canvas, Path land, bool dark) {
  canvas.drawPath(
    land,
    Paint()..color = dark ? const Color(0xff3a3358) : const Color(0xffd6c7a6),
  );
  canvas.drawPath(
    land,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = dark ? const Color(0xff7d73a6) : const Color(0xff8a7253),
  );
}

/// One exposed shelf, with today's land redrawn on top of it.
class _ShelfPainter extends CustomPainter {
  _ShelfPainter(this.shelf, this.land, this.dark);

  final Path shelf;
  final Path land;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      shelf,
      Paint()..color = dark ? const Color(0xff22382c) : const Color(0xffc4d6bd),
    );
    canvas.drawPath(
      shelf,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = dark ? const Color(0xff7fb08a) : const Color(0xff4f7a4a),
    );
    _drawLand(canvas, land, dark);
  }

  @override
  bool shouldRepaint(_ShelfPainter old) =>
      old.shelf != shelf || old.dark != dark;
}

// ---- 2. Clade × trait heatmap -----------------------------------------------

int _seqIndex(int p) => math.min(5, (p / 20).floor() + (p == 0 ? 0 : 1));

class _TraitHeatmap extends StatefulWidget {
  const _TraitHeatmap();

  @override
  State<_TraitHeatmap> createState() => _TraitHeatmapState();
}

class _TraitHeatmapState extends State<_TraitHeatmap> {
  String? _hover;

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    final traits = _traits;
    final rows = [
      for (final c in data.clades)
        (key: c, label: context.tr(c), ghosts: _where((g) => g.clade == c)),
      (key: '', label: context.t('allGhosts'), ghosts: data.ghosts),
    ];
    const cell = 30.0;
    final left = math.max(
      210.0,
      30 +
          rows
                  .map((r) => '${r.label} (${r.ghosts.length})'.length)
                  .reduce(math.max) *
              7.0,
    );
    final top = math.max(
      118.0,
      20 + traits.map((x) => context.tr(x.label).length).reduce(math.max) * 5.6,
    );
    const rot = 55 * math.pi / 180;
    // Headers are rotated −55°; leave room for the last ones to lean right.
    final lean = [
      for (var j = 0; j < 4; j++)
        context.tr(traits[traits.length - 4 + j].label).length *
                6.6 *
                math.cos(rot) -
            (3 - j) * cell,
    ].reduce(math.max);
    final w = left + traits.length * cell + math.max(4, lean + 8);
    final h = top + rows.length * cell + 8;
    final ink = TextStyle(color: k.ink, fontSize: 12);
    final seq = k.seq;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Canvas(
          width: w,
          height: h,
          minWidth: 640,
          label: context.t('heatmapSvg'),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var j = 0; j < traits.length; j++)
                _label(
                  context.tr(traits[j].label),
                  x: left + j * cell + cell / 2 + 4,
                  y: top - 8,
                  angle: -rot,
                  style: ink,
                ),
              for (var i = 0; i < rows.length; i++) ...[
                if (i < rows.length - 1)
                  Positioned(
                    left: 5,
                    top: top + i * cell + cell / 2 - 5,
                    child: CladeDot(rows[i].key),
                  ),
                _label(
                  '${rows[i].label} (${rows[i].ghosts.length})',
                  x: i == rows.length - 1 ? 4 : 20,
                  y: top + i * cell + cell / 2 + (i == rows.length - 1 ? 4 : 0),
                  style: ink.copyWith(
                    fontSize: 12.5,
                    fontWeight: i == rows.length - 1 ? FontWeight.w700 : null,
                  ),
                ),
                for (var j = 0; j < traits.length; j++)
                  () {
                    final r = rows[i];
                    final n = r.ghosts
                        .where((g) => g.traits[traits[j].id] == 1)
                        .length;
                    final p = _pct(n, r.ghosts.length);
                    final msg = context.t('heatSays', [
                      r.label,
                      p,
                      context.tr(traits[j].label),
                      n,
                      r.ghosts.length,
                    ]);
                    return Positioned(
                      left: left + j * cell + 1,
                      top: top + i * cell + 1 + (i == rows.length - 1 ? 4 : 0),
                      child: MouseRegion(
                        onEnter: (_) => setState(() => _hover = msg),
                        onExit: (_) => setState(() => _hover = null),
                        child: GestureDetector(
                          onTap: () => setState(() => _hover = msg),
                          child: Container(
                            width: cell - 2,
                            height: cell - 2,
                            decoration: BoxDecoration(
                              color: seq[_seqIndex(p)],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: k.dark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Malam.c950.withValues(alpha: 0.1),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }(),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          label: context.t('colorScale'),
          container: true,
          child: Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                context.t('heatScale'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              for (final (i, l) in const [
                '0%',
                '1–20%',
                '21–40%',
                '41–60%',
                '61–80%',
                '81–100%',
              ].indexed)
                _Swatch(seq[i], l),
            ],
          ),
        ),
        _Readout(text: _hover, idle: context.t('heatIdle')),
        _DataTable(
          caption: context.t('heatTableCap'),
          head: [
            context.t('clade'),
            for (final x in traits) context.tr(x.label),
          ],
          rows: [
            for (final r in rows)
              [
                r.label,
                for (final x in traits)
                  '${_pct(r.ghosts.where((g) => g.traits[x.id] == 1).length, r.ghosts.length)}%',
              ],
          ],
        ),
      ],
    );
  }
}

// ---- 3. Danger unit chart -----------------------------------------------------

class _DangerUnits extends StatefulWidget {
  const _DangerUnits();

  @override
  State<_DangerUnits> createState() => _DangerUnitsState();
}

class _DangerUnitsState extends State<_DangerUnits> {
  Ghost? _hover;

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    final lang = context.lang;
    final table = Table(
      columnWidths: const {0: FixedColumnWidth(176)},
      defaultColumnWidth: const FlexColumnWidth(),
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      children: [
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                context.t('clade'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            for (var d = 1; d <= 5; d++)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                child: Text(
                  '$d · ${i18n.dangerLabel(lang, d)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
        for (final c in data.clades)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 6, 8, 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: CladeDot(c),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        context.tr(c),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              for (var d = 1; d <= 5; d++)
                () {
                  final gs = _where((g) => g.clade == c && g.danger == d);
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 2,
                    ),
                    child: Semantics(
                      label:
                          '${context.tr(c)}, ${i18n.dangerLabel(lang, d)}: ${gs.isEmpty ? context.t('none') : gs.map((g) => g.name).join(', ')}',
                      excludeSemantics: true,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 30),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _surface(k).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Wrap(
                          spacing: 2,
                          runSpacing: 2,
                          children: [
                            for (final g in gs)
                              MouseRegion(
                                onEnter: (_) => setState(() => _hover = g),
                                onExit: (_) => setState(() => _hover = null),
                                child: GestureDetector(
                                  onTap: () => setState(() => _hover = g),
                                  child: Plate(g.id, size: 22),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }(),
            ],
          ),
      ],
    );
    final h = _hover;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: context.t('dangerCap'),
          container: true,
          child: LayoutBuilder(
            builder: (context, box) => box.maxWidth >= 640
                ? table
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(width: 640, child: table),
                  ),
          ),
        ),
        _Readout(
          text: h == null
              ? null
              : context.t('dangerSays', [
                  h.name,
                  context.tr(h.clade),
                  h.danger,
                  i18n.dangerLabel(lang, h.danger),
                ]),
          idle: context.t('dangerIdle'),
        ),
      ],
    );
  }
}

// ---- 4. Body plan × diet bubble matrix ---------------------------------------

class _BodyDiet extends StatefulWidget {
  const _BodyDiet();

  @override
  State<_BodyDiet> createState() => _BodyDietState();
}

class _BodyDietState extends State<_BodyDiet> {
  String? _hover;

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    final diets = [...data.characters[19].states, 'Unknown'];
    final plans = data.bodyPlans
        .where((b) => data.ghosts.any((g) => g.bodyPlan == b.id))
        .toList();
    List<Ghost> count(String plan, String diet) =>
        _where((g) => g.bodyPlan == plan && (g.dietClass ?? 'Unknown') == diet);
    final max = [
      for (final p in plans)
        for (final d in diets) count(p.id, d).length,
    ].reduce(math.max);
    const cell = 56.0;
    const row = 30.0;
    const rot = 25 * math.pi / 180;
    final left = math.max(
      200.0,
      20 + plans.map((p) => context.tr(p.label).length).reduce(math.max) * 7.0,
    );
    final headerLen = diets.map((d) => context.tr(d).length).reduce(math.max);
    final top = math.max(
      70.0,
      (22 + headerLen * 6.6 * math.sin(rot)).ceilToDouble(),
    );
    // Diet headers are rotated −25°; leave room for the last ones to lean right.
    final lean = [
      for (var j = 0; j < 3; j++)
        context.tr(diets[diets.length - 3 + j]).length * 6.6 * math.cos(rot) -
            (2 - j) * cell -
            cell / 2,
    ].reduce(math.max);
    final w = left + diets.length * cell + math.max(0, lean + 8);
    final h = top + plans.length * row + 6;
    final ink = TextStyle(color: k.ink, fontSize: 12.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Canvas(
          width: w,
          height: h,
          minWidth: 560,
          label: context.t('bodySvg'),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var j = 0; j < diets.length; j++)
                _label(
                  context.tr(diets[j]),
                  x: left + j * cell + cell / 2,
                  y: top - 10,
                  angle: -rot,
                  style: ink.copyWith(fontSize: 12),
                ),
              for (var i = 0; i < plans.length; i++) ...[
                Positioned(
                  left: left,
                  right: 0,
                  top: top + i * row + row / 2,
                  child: Container(
                    height: 1,
                    color: k.dark ? Malam.c800 : Kafan.c300,
                  ),
                ),
                _label(
                  context.tr(plans[i].label),
                  x: left - 10,
                  y: top + i * row + row / 2 + 2,
                  align: TextAlign.end,
                  style: ink,
                ),
                for (var j = 0; j < diets.length; j++)
                  () {
                    final gs = count(plans[i].id, diets[j]);
                    if (gs.isEmpty) return const SizedBox.shrink();
                    final r = 3 + math.sqrt(gs.length / max) * 12;
                    final msg = context.t('bodySays', [
                      context.tr(plans[i].label),
                      context.tr(diets[j]),
                      gs.map((g) => g.name).join(', '),
                    ]);
                    return Positioned(
                      left: left + j * cell + cell / 2 - r - 1,
                      top: top + i * row + row / 2 - r - 1,
                      child: MouseRegion(
                        onEnter: (_) => setState(() => _hover = msg),
                        onExit: (_) => setState(() => _hover = null),
                        child: GestureDetector(
                          onTap: () => setState(() => _hover = msg),
                          child: Container(
                            width: r * 2 + 2,
                            height: r * 2 + 2,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: k.dark ? Prada.c300 : Malam.c700,
                              border: Border.all(
                                width: 2,
                                color: k.dark ? Malam.c950 : Kafan.c50,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }(),
              ],
            ],
          ),
        ),
        _Readout(text: _hover, idle: context.t('bodyIdle')),
        _DataTable(
          caption: context.t('bodyTableCap'),
          head: [context.t('bodyPlan'), for (final d in diets) context.tr(d)],
          rows: [
            for (final p in plans)
              [
                context.tr(p.label),
                for (final d in diets) count(p.id, d).length,
              ],
          ],
        ),
      ],
    );
  }
}

// ---- 5. Coding provenance bars -----------------------------------------------

const _coding = [
  (key: 'source', label: 'provSource', seq: 5),
  (key: 'filled', label: 'provFilled', seq: 2),
  (key: 'new', label: 'provNew', seq: 1),
];

class _Provenance extends StatefulWidget {
  const _Provenance();

  @override
  State<_Provenance> createState() => _ProvenanceState();
}

class _ProvenanceState extends State<_Provenance> {
  String? _hover;

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    final seq = k.seq;
    final max = data.clades
        .map((c) => _where((g) => g.clade == c).length)
        .reduce(math.max);
    final narrow = MediaQuery.sizeOf(context).width < 480;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: context.t('legend'),
          container: true,
          child: Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              for (final c in _coding) _Swatch(seq[c.seq], context.t(c.label)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final c in data.clades)
          () {
            final gs = _where((g) => g.clade == c);
            final name = Row(
              children: [
                CladeDot(c),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    context.tr(c),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            );
            final bar = Semantics(
              label:
                  '${context.tr(c)}: ${_coding.map((k) => '${gs.where((g) => g.coding == k.key).length} ${context.t(k.label).toLowerCase()}').join(', ')}',
              excludeSemantics: true,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: gs.length / max,
                child: SizedBox(
                  height: 24,
                  child: Row(
                    children: [
                      for (final kd in _coding)
                        () {
                          final n = gs.where((g) => g.coding == kd.key).length;
                          if (n == 0) return const SizedBox.shrink();
                          final msg = context.t('provSays', [
                            context.tr(c),
                            n,
                            gs.length,
                            context.t(kd.label),
                          ]);
                          return Expanded(
                            flex: n,
                            child: MouseRegion(
                              onEnter: (_) => setState(() => _hover = msg),
                              onExit: (_) => setState(() => _hover = null),
                              child: GestureDetector(
                                onTap: () => setState(() => _hover = msg),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 2),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: seq[kd.seq],
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    '$n',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: kd.key == 'source'
                                          ? seq[0]
                                          : seq[5],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }(),
                    ],
                  ),
                ),
              ),
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: narrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [name, const SizedBox(height: 4), bar],
                    )
                  : Row(
                      children: [
                        SizedBox(width: 176, child: name),
                        const SizedBox(width: 12),
                        Expanded(child: bar),
                      ],
                    ),
            );
          }(),
        _Readout(text: _hover, idle: context.t('provIdle')),
      ],
    );
  }
}

// ---- 6. Support histogram ------------------------------------------------------

class _SupportHistogram extends StatefulWidget {
  const _SupportHistogram({required this.supports});

  final List<int> supports;

  @override
  State<_SupportHistogram> createState() => _SupportHistogramState();
}

class _SupportHistogramState extends State<_SupportHistogram> {
  String? _hover;

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    final bins = [
      for (var i = 0; i < 10; i++) [i * 10, i == 9 ? 100 : i * 10 + 9, 0],
    ];
    for (final s in widget.supports) {
      bins[math.min(9, s ~/ 10)][2]++;
    }
    final max = bins.map((b) => b[2]).reduce(math.max);
    const w = 640.0, h = 220.0, b = 30.0;
    const plotH = h - b - 16;
    const bw = (w - 40) / 10;
    final ink = TextStyle(color: k.ink, fontSize: 11);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Canvas(
          width: w,
          height: h,
          minWidth: 0,
          label: context.t('supportSvg', [widget.supports.length]),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final tick in {0, (max / 2).ceil(), max}) ...[
                Positioned(
                  left: 36,
                  right: 0,
                  top: 8 + plotH - tick / max * plotH,
                  child: Container(
                    height: 1,
                    color: k.dark ? Malam.c800 : Kafan.c300,
                  ),
                ),
                _label(
                  '$tick',
                  x: 30,
                  y: 8 + plotH - tick / max * plotH + 4,
                  align: TextAlign.end,
                  width: 30,
                  style: ink,
                ),
              ],
              for (var i = 0; i < 10; i++) ...[
                Positioned(
                  left: 40 + i * bw,
                  top: 8,
                  width: bw,
                  height: plotH,
                  child: MouseRegion(
                    onEnter: (_) => setState(
                      () => _hover = context.t('supportSays', [
                        bins[i][2],
                        bins[i][0],
                        bins[i][1],
                      ]),
                    ),
                    onExit: (_) => setState(() => _hover = null),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(
                        () => _hover = context.t('supportSays', [
                          bins[i][2],
                          bins[i][0],
                          bins[i][1],
                        ]),
                      ),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: bins[i][2] / max * plotH,
                          decoration: BoxDecoration(
                            color: bins[i][0] >= 90
                                ? (k.dark ? Prada.c300 : Darah.c700)
                                : (k.dark ? Kemenyan.c400 : Malam.c600),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _label(
                  '${bins[i][0]}',
                  x: 40 + i * bw + bw / 2,
                  y: h - 12,
                  align: TextAlign.center,
                  width: 40,
                  style: ink,
                ),
              ],
            ],
          ),
        ),
        _Readout(text: _hover, idle: context.t('supportIdle')),
        _DataTable(
          caption: context.t('supportCap'),
          head: [context.t('support'), context.t('nodes')],
          rows: [
            for (final b in bins) ['${b[0]}–${b[1]}', b[2]],
          ],
        ),
      ],
    );
  }
}

// ---- 7. Twins -----------------------------------------------------------------

class _Twins extends StatelessWidget {
  const _Twins();

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    final seen = <String>{};
    final sets = <List<Ghost>>[];
    for (final g in data.ghosts) {
      if (g.twins.isEmpty || seen.contains(g.id)) continue;
      final set = [g, for (final t in g.twins) data.byId[t]!];
      seen.addAll(set.map((s) => s.id));
      sets.add(set);
    }
    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth >= 900
            ? 3
            : box.maxWidth >= 560
            ? 2
            : 1;
        final tileW = (box.maxWidth - 12 * (cols - 1)) / cols;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final set in sets)
              SizedBox(
                width: tileW,
                child: Tile(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [for (final g in set) Plate(g.id, size: 36)],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          for (final (j, g) in set.indexed) ...[
                            if (j > 0)
                              Text(
                                j == set.length - 1
                                    ? ' ${context.t('and')} '
                                    : ', ',
                                style: const TextStyle(fontSize: 14),
                              ),
                            Semantics(
                              link: true,
                              child: InkWell(
                                onTap: () => context.go('/ghosts/${g.id}'),
                                child: Text(
                                  g.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                    decorationColor: k.dark
                                        ? Kafan.c500
                                        : Kafan.c500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
