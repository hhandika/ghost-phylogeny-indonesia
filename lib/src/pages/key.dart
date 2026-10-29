/// Key: the dichotomous key to the ghosts, ported from key.astro.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data.dart';
import '../i18n.dart';
import '../settings.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/shell.dart';

class KeyPage extends StatefulWidget {
  const KeyPage({super.key});

  @override
  State<KeyPage> createState() => _KeyPageState();
}

class _KeyPageState extends State<KeyPage> {
  final _scroll = ScrollController();
  late final _anchors = {for (final c in data.key.couplets) c.n: GlobalKey()};
  int? _target;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Scroll a couplet into view and light it, like the site's :target.
  void _jump(int n) {
    setState(() => _target = n);
    final ctx = _anchors[n]!.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.15,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final key = data.key;
    final depth = <int, int>{};
    for (final c in key.couplets) {
      depth[c.n] = c.from == null ? 0 : depth[c.from]! + 1;
    }
    final wide = MediaQuery.sizeOf(context).width >= 640;
    final byName = [...data.ghosts]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final k = Tokens.of(context);

    return PageScroll(
      controller: _scroll,
      children: [
        PageTitle(
          title: context.t('keyTitle'),
          kicker: context.t('keyKicker'),
          lead: context.t('keyLead', [data.ghosts.length, key.couplets.length]),
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 896),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassSection(
                  title: context.t('keyCouplets'),
                  lead: context.t('keyHowTo'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final c in key.couplets)
                        _CoupletRow(
                          key: _anchors[c.n],
                          couplet: c,
                          indent: wide ? (depth[c.n]!.clamp(0, 10)) * 16.0 : 0,
                          lit: _target == c.n,
                          onJump: _jump,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GlassSection(
                  title: context.t('keyIndex'),
                  lead: context.t('keyIndexLead'),
                  child: Wrap(
                    spacing: 24,
                    runSpacing: 2,
                    children: [
                      for (final g in byName)
                        SizedBox(
                          width: wide ? 260 : double.infinity,
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => context.go('/ghosts/${g.id}'),
                                  child: Text(
                                    g.name,
                                    style: serif(
                                      size: 15,
                                      weight: FontWeight.w400,
                                      color: k.ink,
                                    ).copyWith(fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ),
                              for (final (i, n)
                                  in key.index[g.id]!.indexed) ...[
                                if (i > 0)
                                  Text(', ', style: TextStyle(color: k.muted)),
                                AccentLink('$n', onTap: () => _jump(n)),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CoupletRow extends StatelessWidget {
  const _CoupletRow({
    super.key,
    required this.couplet,
    required this.indent,
    required this.lit,
    required this.onJump,
  });

  final Couplet couplet;
  final double indent;
  final bool lit;
  final void Function(int) onJump;

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    final c = couplet;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.fromLTRB(indent, 8, 4, 8),
      decoration: BoxDecoration(
        color: lit
            ? (k.dark
                  ? Prada.c300.withValues(alpha: 0.15)
                  : Prada.c200.withValues(alpha: 0.5))
            : null,
        borderRadius: lit ? BorderRadius.circular(8) : null,
        border: lit ? null : Border(top: BorderSide(color: k.tileBorder)),
      ),
      child: Column(
        children: [
          for (final (i, lead) in c.leads.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 64,
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.end,
                      spacing: 3,
                      children: [
                        if (i == 0) ...[
                          Text(
                            '${c.n}',
                            style: TextStyle(
                              color: k.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (c.from != null)
                            Semantics(
                              label: context.t('keyBack', [c.from]),
                              button: true,
                              excludeSemantics: true,
                              child: InkWell(
                                onTap: () => onJump(c.from!),
                                child: Text(
                                  '(${c.from})',
                                  style: TextStyle(
                                    color: k.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                        Text(
                          i == 0 ? 'a' : 'b',
                          style: TextStyle(color: k.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _LeadBody(lead: lead, onJump: onJump),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LeadBody extends StatelessWidget {
  const _LeadBody({required this.lead, required this.onJump});

  final KeyLead lead;
  final void Function(int) onJump;

  String _describe(BuildContext context) {
    final states = lead.states
        .map(
          (s) => lead.char == 'region'
              ? regionName(context.lang, s)
              : context.tr(s),
        )
        .join(' ${context.t('keyOr')} ');
    if (!lead.negate) return states;
    // Region names are proper nouns; other states read lowercase after "not".
    final rest = lead.char == 'region'
        ? states
        : states[0].toLowerCase() + states.substring(1);
    return '${context.t('keyNot')} $rest';
  }

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    final text = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${context.tr(data.key.labels[lead.char])}: ',
            style: TextStyle(color: k.muted),
          ),
          TextSpan(text: _describe(context)),
        ],
      ),
      style: TextStyle(color: k.ink, fontSize: 15, height: 1.35),
    );
    final Widget end = lead.to != null
        ? Semantics(
            label: context.t('keyGoTo', [lead.to]),
            excludeSemantics: true,
            child: AccentLink('${lead.to}', onTap: () => onJump(lead.to!)),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final id in lead.ghosts!) _GhostEnd(data.byId[id]!),
            ],
          );
    // Ghost names wrap below the lead on narrow screens.
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.start,
      spacing: 12,
      runSpacing: 4,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 180, maxWidth: 460),
          child: text,
        ),
        end,
      ],
    );
  }
}

class _GhostEnd extends StatelessWidget {
  const _GhostEnd(this.g);

  final Ghost g;

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    return InkWell(
      onTap: () => context.go('/ghosts/${g.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                g.outgroup ? '${g.name} †' : g.name,
                textAlign: TextAlign.right,
                style: serif(
                  size: 16,
                  weight: FontWeight.w400,
                  color: k.ink,
                ).copyWith(fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cladeColor(context, g.clade),
              ),
              child: Plate(g.id, size: 26),
            ),
          ],
        ),
      ),
    );
  }
}
