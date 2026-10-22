/// Specimen page: every field and coded character for one ghost, with its
/// neighbors on the tree.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../i18n.dart';
import '../settings.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/shell.dart';

class SpecimenPage extends StatelessWidget {
  const SpecimenPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    final lang = context.lang;
    final w = MediaQuery.sizeOf(context).width;
    final ghost = data.byId[id]!;
    final order = [for (final t in data.cladogram.tips) t.id!];
    final at = order.indexOf(id);
    final prev = data.byId[order[(at - 1 + order.length) % order.length]]!;
    final next = data.byId[order[(at + 1) % order.length]]!;
    final fields = [
      (context.t('form'), context.tr(ghost.morphology)),
      (context.t('origin'), context.tr(ghost.origin)),
      (context.t('behavior'), context.tr(ghost.behavior)),
      (context.t('deterrentsLong'), context.tr(ghost.deterrents)),
      (context.t('diet'), context.tr(ghost.diet)),
      (context.t('culture'), context.tr(ghost.culture)),
      (context.t('region'), context.tr(ghost.region)),
      (
        context.t('sampling'),
        ghost.inSourceTree ? context.t('inBothTrees') : context.t('newOnTree'),
      ),
    ].where((f) => f.$2.isNotEmpty).toList();

    Widget neighbor(String gid, String name, String srLabel, bool before) =>
        Flexible(
          child: Semantics(
            link: true,
            label: '$srLabel $name',
            child: GestureDetector(
              onTap: () => context.go('/ghosts/$gid'),
              child: Glass(
                radius: 999,
                padding: EdgeInsets.fromLTRB(
                  before ? 4 : 12,
                  4,
                  before ? 12 : 4,
                  4,
                ),
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (before) ...[
                        Plate(gid, size: 30),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          before ? '← $name' : '$name →',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      if (!before) ...[
                        const SizedBox(width: 8),
                        Plate(gid, size: 30),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

    final plateCard = Glass(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Drift(
          child: Plate(
            id,
            size: 240,
            shadow: true,
            semanticLabel: context.t('drawnAs', [
              ghost.name,
              context.tr(ghost.morphology),
            ]),
          ),
        ),
      ),
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Glass(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Kicker(
                ghost.outgroup
                    ? context.t('outgroup')
                    : regionName(lang, ghost.regionGroup),
              ),
              const SizedBox(height: 4),
              Semantics(
                header: true,
                child: Text(
                  ghost.name,
                  style: serif(size: 48, color: k.ink, height: 1.1),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  CladePill(ghost.clade, large: true),
                  Text(
                    context.t('dangerLine', [
                      ghost.danger,
                      dangerLabel(lang, ghost.danger),
                    ]),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, c) {
                  final two = c.maxWidth >= 480;
                  final cellW = two ? (c.maxWidth - 12) / 2 : c.maxWidth;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final (label, value) in fields)
                        SizedBox(
                          width: cellW,
                          child: Tile(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FieldLabel(label),
                                const SizedBox(height: 4),
                                Text(
                                  value,
                                  style: const TextStyle(height: 1.45),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        GlassSection(
          title: context.t('codedCharacters'),
          lead:
              '${ghost.coding != 'source' ? '◆ ' : ''}${codingLabel(lang, ghost.coding)}. ${context.t('sexIs', [sexLabel(lang, ghost)])}',
          child: Table(
            columnWidths: const {0: FractionColumnWidth(1 / 3)},
            children: [
              for (final (i, c) in data.characters.indexed)
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: k.tileBorder)),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 6, 12, 6),
                      child: Text(
                        context.tr(c.label),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        '${ghost.row[i] == '1' && i < 18 ? '● ' : ''}${data.stateOf(ghost, i, context.tr, context.t('unknown'))}',
                        style: TextStyle(
                          fontSize: 14,
                          color: ghost.row[i] == '1' && i < 18
                              ? k.accent
                              : k.ink,
                          fontWeight: ghost.row[i] == '1' && i < 18
                              ? FontWeight.w600
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        GlassSection(
          title: context.t('nearest'),
          lead: ghost.twins.isEmpty
              ? null
              : context.t('twinsPage', [
                  ghost.twins.map((x) => data.byId[x]!.name).join(', '),
                ]),
          child: LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth >= 640
                  ? 5
                  : c.maxWidth >= 400
                  ? 3
                  : 2;
              final cellW = (c.maxWidth - 12 * (cols - 1)) / cols;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final rid in ghost.relatives)
                    if (data.byId[rid] case final r?)
                      SizedBox(
                        width: cellW,
                        child: Semantics(
                          link: true,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => context.go('/ghosts/${r.id}'),
                            child: Tile(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  Plate(r.id, size: 64),
                                  const SizedBox(height: 4),
                                  Text(
                                    r.name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      height: 1.2,
                                    ),
                                  ),
                                  Text(
                                    regionName(lang, r.regionGroup),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: k.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                ],
              );
            },
          ),
        ),
      ],
    );

    return PageScroll(
      children: [
        const SizedBox(height: 24),
        Semantics(
          label: context.t('neighbors'),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              neighbor(prev.id, prev.name, context.t('previous'), true),
              const SizedBox(width: 8),
              neighbor(next.id, next.name, context.t('next'), false),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (w >= 768)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 288, child: plateCard),
              const SizedBox(width: 24),
              Expanded(child: details),
            ],
          )
        else ...[
          plateCard,
          const SizedBox(height: 24),
          details,
        ],
      ],
    );
  }
}
