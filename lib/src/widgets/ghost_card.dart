/// Detail card for one ghost, shared by the Atlas, Lantern, and Bestiary.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data.dart';
import '../i18n.dart' as i18n;
import '../settings.dart';
import '../theme.dart';
import 'common.dart';

class GhostCard extends StatelessWidget {
  const GhostCard({
    super.key,
    required this.ghost,
    this.onSelect,
    this.compact = false,
    this.solid = false,
  });

  final Ghost ghost;
  final ValueChanged<String>? onSelect;
  final bool compact;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    final lang = context.lang;
    final relatives = [
      for (final id in ghost.relatives)
        if (data.byId[id] != null) data.byId[id]!,
    ];
    Widget field(String label, String? value) {
      if (value == null || value.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FieldLabel(label),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 14, height: 1.5)),
          ],
        ),
      );
    }

    final plateSize = compact ? 96.0 : 128.0;
    return Semantics(
      container: true,
      label: context.t('cardOf', [ghost.name]),
      child: Glass(
        solid: solid,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Drift(
                  child: Plate(
                    ghost.id,
                    size: plateSize,
                    shadow: true,
                    semanticLabel: context.t('drawnAs', [
                      ghost.name,
                      context.tr(ghost.morphology),
                    ]),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          ghost.name,
                          style: serif(size: 24, color: k.ink, height: 1.15),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          context.tr(ghost.region),
                          if (ghost.culture != null) context.tr(ghost.culture),
                        ].join(' · '),
                        style: TextStyle(color: k.muted, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          CladePill(ghost.clade),
                          if (ghost.outgroup)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: k.dark ? Malam.c800 : Malam.c100,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                context.t('outgroup'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: k.dark ? Malam.c100 : Malam.c800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DangerMeter(ghost.danger),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            field(context.t('form'), context.tr(ghost.morphology)),
            field(context.t('origin'), context.tr(ghost.origin)),
            field(context.t('behavior'), context.tr(ghost.behavior)),
            field(context.t('deterrents'), context.tr(ghost.deterrents)),
            field(context.t('diet'), context.tr(ghost.diet)),
            const SizedBox(height: 16),
            FieldLabel(context.t('codedTraits')),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                TraitChip(i18n.sexLabel(lang, ghost)),
                for (final x in i18n.presentTraits(lang, ghost)) TraitChip(x),
              ],
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                children: [
                  if (ghost.coding != 'source')
                    TextSpan(
                      text: '◆ ',
                      style: TextStyle(color: k.dangerOn),
                    ),
                  TextSpan(text: '${i18n.codingLabel(lang, ghost.coding)}.'),
                  if (ghost.twins.isNotEmpty)
                    TextSpan(
                      text: context.t('twinsCard', [
                        ghost.twins.map((x) => data.byId[x]?.name).join(', '),
                      ]),
                    ),
                ],
              ),
              style: TextStyle(color: k.muted, fontSize: 12, height: 1.5),
            ),
            if (!compact && relatives.isNotEmpty) ...[
              const SizedBox(height: 16),
              FieldLabel(context.t('nearest')),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in relatives)
                    Material(
                      color: k.controlFill,
                      shape: StadiumBorder(
                        side: BorderSide(color: k.controlBorder),
                      ),
                      child: InkWell(
                        customBorder: const StadiumBorder(),
                        hoverColor: k.hover,
                        onTap: () => onSelect != null
                            ? onSelect!(r.id)
                            : context.go('/ghosts/${r.id}'),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(2, 2, 10, 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Plate(r.id, size: 22),
                              const SizedBox(width: 6),
                              Text(
                                r.name,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            AccentLink(
              context.t('fullPage'),
              arrow: true,
              onTap: () => context.go('/ghosts/${ghost.id}'),
            ),
          ],
        ),
      ),
    );
  }
}
