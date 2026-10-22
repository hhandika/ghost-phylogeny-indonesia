/// Bestiary: a field guide. Specimen cards in tree order, filters for clade,
/// island, danger, and traits, a detail dialog, and a side-by-side comparison
/// of two ghosts that names their common ancestor's support.
library;

import 'package:flutter/material.dart';

import '../data.dart';
import '../i18n.dart';
import '../settings.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ghost_card.dart';
import '../widgets/shell.dart';

enum _Sort { tree, name, danger }

class BestiaryPage extends StatefulWidget {
  const BestiaryPage({super.key});

  @override
  State<BestiaryPage> createState() => _BestiaryPageState();
}

class _BestiaryPageState extends State<BestiaryPage> {
  final _query = TextEditingController();
  final _clades = <String>{};
  final _traits = <String>{};
  String _region = '';
  int _minDanger = 1;
  _Sort _sort = _Sort.tree;
  final _compare = <String>[];

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _toggle(Set<String> set, String v) =>
      setState(() => set.contains(v) ? set.remove(v) : set.add(v));

  void _pick(String id) => setState(() {
    if (!_compare.remove(id)) {
      if (_compare.length == 2) _compare.removeAt(0);
      _compare.add(id);
    }
  });

  void _reset() => setState(() {
    _query.clear();
    _clades.clear();
    _traits.clear();
    _region = '';
    _minDanger = 1;
  });

  List<Ghost> _list(Lang lang) {
    final q = _query.text.trim().toLowerCase();
    final order = {for (final t in data.cladogram.tips) t.id!: t.y};
    final list = data.ghosts.where((g) {
      final text = [
        g.name,
        g.region,
        g.culture,
        g.behavior,
        tr(lang, g.region),
        tr(lang, g.culture),
        tr(lang, g.behavior),
      ];
      return (q.isEmpty ||
              text.any((s) => (s ?? '').toLowerCase().contains(q))) &&
          (_clades.isEmpty || _clades.contains(g.clade)) &&
          (_region.isEmpty || g.regionGroup == _region) &&
          g.danger >= _minDanger &&
          _traits.every((k) => g.traits[k] == 1);
    }).toList();
    list.sort(
      (a, b) => switch (_sort) {
        _Sort.name => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        _Sort.danger =>
          b.danger != a.danger ? b.danger - a.danger : a.name.compareTo(b.name),
        _Sort.tree => order[a.id]!.compareTo(order[b.id]!),
      },
    );
    return list;
  }

  void _open(String id) {
    showDialog<void>(
      context: context,
      barrierColor: Malam.c950.withValues(alpha: 0.6),
      barrierLabel: context.t('close'),
      builder: (_) => _Dialog(
        maxWidth: 576,
        child: GhostCard(
          ghost: data.byId[id]!,
          solid: true,
          onSelect: (other) {
            Navigator.of(context).pop();
            _open(other);
          },
        ),
      ),
    );
  }

  void _showCompare() {
    showDialog<void>(
      context: context,
      barrierColor: Malam.c950.withValues(alpha: 0.6),
      barrierLabel: context.t('close'),
      builder: (_) => _Dialog(
        maxWidth: 768,
        child: _Compare(a: data.byId[_compare[0]]!, b: data.byId[_compare[1]]!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    final lang = context.lang;
    final w = MediaQuery.sizeOf(context).width;
    final list = _list(lang);
    final columns = w >= 1280
        ? 5
        : w >= 1024
        ? 4
        : w >= 640
        ? 3
        : 2;

    return Stack(
      children: [
        PageScroll(
          wide: true,
          children: [
            PageTitle(
              title: context.t('bestiaryTitle'),
              kicker: context.t('bestiaryKicker'),
              lead: context.t('bestiaryLead', [data.ghosts.length]),
            ),
            const CladeLegend(),
            Semantics(
              label: context.t('filters'),
              child: Glass(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: w >= 640 ? 320 : double.infinity,
                          child: SearchField(
                            controller: _query,
                            hint: context.t('searchBestiary'),
                            label: context.t('search'),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        PillDropdown<String>(
                          label: context.t('island'),
                          value: _region,
                          items: [
                            ('', context.t('allIslands')),
                            for (final r in data.regions)
                              (r, regionName(lang, r)),
                          ],
                          onChanged: (v) => setState(() => _region = v),
                        ),
                        PillDropdown<int>(
                          label: context.t('minDanger'),
                          value: _minDanger,
                          items: [
                            for (var d = 1; d <= 5; d++)
                              (
                                d,
                                d == 1
                                    ? context.t('anyDanger')
                                    : context.t('orWorse', [
                                        dangerLabel(lang, d),
                                      ]),
                              ),
                          ],
                          onChanged: (v) => setState(() => _minDanger = v),
                        ),
                        PillDropdown<_Sort>(
                          label: context.t('sort'),
                          value: _sort,
                          items: [
                            (_Sort.tree, context.t('sortTree')),
                            (_Sort.name, context.t('sortName')),
                            (_Sort.danger, context.t('sortDanger')),
                          ],
                          onChanged: (v) => setState(() => _sort = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Semantics(
                      label: context.t('clades'),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final c in data.clades)
                            PillButton(
                              small: true,
                              label: context.tr(c),
                              selected: _clades.contains(c),
                              leading: CladeDot(c, size: 8),
                              onPressed: () => _toggle(_clades, c),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: context.t('traitsAll'),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final c
                              in data.characters
                                  .take(18)
                                  .where((c) => c.id != 'sex'))
                            PillButton(
                              small: true,
                              label: context.tr(c.label),
                              selected: _traits.contains(c.id),
                              onPressed: () => _toggle(_traits, c.id),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '${context.t('nSpecimens', [list.length, data.ghosts.length])} ',
                            style: TextStyle(color: k.muted, fontSize: 12),
                          ),
                          if (list.length < data.ghosts.length)
                            AccentLink(
                              context.t('clearFilters'),
                              onTap: _reset,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 300,
              ),
              itemBuilder: (context, i) => _SpecimenCard(
                ghost: list[i],
                picked: _compare.contains(list[i].id),
                onOpen: () => _open(list[i].id),
                onPick: () => _pick(list[i].id),
              ),
            ),
            const SizedBox(height: 64),
          ],
        ),
        if (_compare.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Center(
              child: Glass(
                solid: true,
                radius: 999,
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final id in _compare)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Plate(
                          id,
                          size: 36,
                          semanticLabel: data.byId[id]!.name,
                        ),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      context.t(_compare.length == 1 ? 'pickOneMore' : 'ready'),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _compare.length < 2 ? null : _showCompare,
                      style: FilledButton.styleFrom(
                        backgroundColor: k.activeFill,
                        foregroundColor: k.activeText,
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      child: Text(context.t('compare')),
                    ),
                    TextButton(
                      onPressed: () => setState(_compare.clear),
                      child: Text(
                        context.t('clear'),
                        style: TextStyle(
                          color: k.ink,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SpecimenCard extends StatefulWidget {
  const _SpecimenCard({
    required this.ghost,
    required this.picked,
    required this.onOpen,
    required this.onPick,
  });

  final Ghost ghost;
  final bool picked;
  final VoidCallback onOpen;
  final VoidCallback onPick;

  @override
  State<_SpecimenCard> createState() => _SpecimenCardState();
}

class _SpecimenCardState extends State<_SpecimenCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    final g = widget.ghost;
    final place = g.regionGroup == 'Outgroup'
        ? context
              .tr(g.region)
              .replaceAll(RegExp(r' \((Outgroup|kelompok luar)\)'), '')
        : context.tr(g.regionGroup);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 150),
        offset: Offset(0, _hover ? -0.008 : 0),
        child: Stack(
          children: [
            Positioned.fill(
              child: Glass(
                padding: EdgeInsets.zero,
                child: const SizedBox.expand(),
              ),
            ),
            if (_hover)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: k.dark ? Prada.c400 : Darah.c600,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: widget.onOpen,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 40),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 4,
                          decoration: BoxDecoration(
                            color: cladeColor(context, g.clade),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedScale(
                          scale: _hover ? 1.05 : 1,
                          duration: const Duration(milliseconds: 500),
                          child: Plate(g.id, size: 112),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          g.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: serif(size: 18, color: k.ink, height: 1.15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          place,
                          style: TextStyle(color: k.muted, fontSize: 12),
                        ),
                        Text(
                          context.tr(g.clade),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: k.muted, fontSize: 12),
                        ),
                        const Spacer(),
                        DangerMeter(g.danger),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 6,
              child: Center(
                child: Semantics(
                  label: '${context.t('compare')} ${g.name}',
                  checked: widget.picked,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: widget.onPick,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ExcludeSemantics(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox.square(
                              dimension: 18,
                              child: Checkbox(
                                value: widget.picked,
                                activeColor: Darah.c700,
                                side: BorderSide(color: k.controlBorder),
                                onChanged: (_) => widget.onPick(),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              context.t('compare'),
                              style: TextStyle(color: k.muted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal over a dimmed scene with a round close button.
class _Dialog extends StatelessWidget {
  const _Dialog({required this.child, required this.maxWidth});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 14, right: 4),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              child,
              Positioned(
                top: -12,
                right: -8,
                child: Tooltip(
                  message: context.t('close'),
                  child: Material(
                    color: k.controlFill,
                    shape: CircleBorder(
                      side: BorderSide(color: k.controlBorder),
                    ),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).pop(),
                      child: SizedBox.square(
                        dimension: 40,
                        child: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: k.ink,
                        ),
                      ),
                    ),
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

class _Compare extends StatelessWidget {
  const _Compare({required this.a, required this.b});

  final Ghost a, b;

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    final L = data.cladogram;
    final pa = TreeLayout.ancestry(L.tipById[a.id]);
    final pb = TreeLayout.ancestry(L.tipById[b.id]);
    final mrca = pa.firstWhere(pb.contains);
    final steps = pa.indexOf(mrca) + pb.indexOf(mrca);
    final n = data.characters.length;
    final diffs = [for (var i = 0; i < n; i++) i]
        .where((i) => a.row[i] != b.row[i])
        .length;
    String state(Ghost g, int i) =>
        data.stateOf(g, i, context.tr, context.t('unknown'));
    final head = TextStyle(
      color: k.muted,
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
      letterSpacing: 1,
    );

    return Glass(
      solid: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (final g in [a, b])
                Expanded(
                  child: Column(
                    children: [
                      Plate(g.id, size: 112),
                      const SizedBox(height: 8),
                      Text(
                        g.name,
                        textAlign: TextAlign.center,
                        style: serif(size: 20, color: k.ink),
                      ),
                      const SizedBox(height: 4),
                      CladePill(g.clade),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: k.dark ? Malam.c800 : Kafan.c200.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              context.t('compareSummary', [
                diffs,
                n,
                steps,
                '${mrca.tips.length}',
                mrca.support != null ? '${mrca.support}' : '',
              ]),
              style: const TextStyle(fontSize: 14, height: 1.45),
            ),
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.1),
              1: FlexColumnWidth(),
              2: FlexColumnWidth(),
            },
            children: [
              TableRow(
                children: [
                  for (final s in [context.t('character'), a.name, b.name])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(s.toUpperCase(), style: head),
                    ),
                ],
              ),
              for (var i = 0; i < n; i++)
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: k.dark ? Malam.c800 : Kafan.c200),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 4, 8, 4),
                      child: Text(
                        context.tr(data.characters[i].label),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: a.row[i] == b.row[i] ? k.muted : k.ink,
                        ),
                      ),
                    ),
                    for (final g in [a, b])
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 4, 8, 4),
                        child: Text(
                          state(g, i),
                          style: TextStyle(
                            fontSize: 14,
                            color: a.row[i] == b.row[i] ? k.muted : k.accent,
                            fontWeight: a.row[i] == b.row[i]
                                ? null
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
