/// Shared building blocks that mirror the site's components: frosted glass
/// panels, the batik header texture, page titles, plates, clade pills, the
/// danger meter, and the pill-shaped form controls.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_drawing/path_drawing.dart';

import '../data.dart';
import '../settings.dart';
import '../theme.dart';

Dataset get data => Dataset.instance;

/// Frosted glass: a window onto the scene.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.solid = false,
    this.batik = false,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool solid;
  final bool batik;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    final shape = BorderRadius.circular(radius);
    Widget content = Padding(padding: padding, child: child);
    if (batik) {
      content = CustomPaint(painter: BatikPainter(k.batik), child: content);
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: [
          BoxShadow(
            color: k.dark
                ? Colors.black.withValues(alpha: 0.6)
                : const Color(0xff110e1b).withValues(alpha: 0.35),
            offset: const Offset(0, 20),
            blurRadius: 40,
            spreadRadius: -20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color ?? (solid ? k.glassSolid : k.glass),
              borderRadius: shape,
              border: Border.all(color: k.glassBorder),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Kawung: the four-petal batik motif, for the header and footer only.
class BatikPainter extends CustomPainter {
  BatikPainter(this.color);

  final Color color;
  static final _tile = parseSvgPathData(
    'M30 12 A6 11 0 1 0 18 12 A6 11 0 1 0 30 12 Z '
    'M30 36 A6 11 0 1 0 18 36 A6 11 0 1 0 30 36 Z '
    'M23 24 A11 6 0 1 0 1 24 A11 6 0 1 0 23 24 Z '
    'M47 24 A11 6 0 1 0 25 24 A11 6 0 1 0 47 24 Z',
  );

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke;
    final dot = Paint()..color = color;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (double y = 0; y < size.height + 48; y += 48) {
      for (double x = 0; x < size.width + 48; x += 48) {
        canvas.save();
        canvas.translate(x, y);
        canvas.drawPath(_tile, stroke);
        canvas.drawCircle(const Offset(24, 24), 1.6, dot);
        canvas.drawCircle(Offset.zero, 1.6, dot);
        canvas.restore();
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(BatikPainter old) => old.color != color;
}

/// The gunungan (kayon): the wayang puppet that opens a shadow play, used as
/// the site mark.
class Gunungan extends StatelessWidget {
  const Gunungan({super.key, this.height = 36});

  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: height * 40 / 48,
    height: height,
    child: CustomPaint(painter: _GununganPainter(Tokens.of(context).dark)),
  );
}

class _GununganPainter extends CustomPainter {
  _GununganPainter(this.dark);

  final bool dark;
  static final _leaf = parseSvgPathData(
    'M20 2 C27 10 35 20 36 30 C37 38 31 44 20 46 C9 44 3 38 4 30 C5 20 13 10 20 2 Z',
  );
  static final _tree = parseSvgPathData(
    'M20 40 V14 M20 22 C16 20 13 22 10 26 M20 22 C24 20 27 22 30 26 M20 30 C15 28 11 31 9 34 M20 30 C25 28 29 31 31 34 M20 16 C17 15 15 16 14 18 M20 16 C23 15 25 16 26 18',
  );
  static final _gate = parseSvgPathData('M15 46 V39 H25 V46');

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 40, size.height / 48);
    Paint stroke(Color c, double w) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(_leaf, Paint()..color = dark ? Prada.c300 : Prada.c400);
    canvas.drawPath(_leaf, stroke(dark ? Prada.c100 : Malam.c900, 1.6));
    canvas.drawPath(_tree, stroke(Malam.c900, 1.4));
    canvas.drawPath(_gate, Paint()..color = Darah.c600);
    canvas.drawPath(_gate, stroke(Malam.c900, 1.4));
    canvas.drawCircle(const Offset(20, 9), 1.6, Paint()..color = Darah.c600);
  }

  @override
  bool shouldRepaint(_GununganPainter old) => old.dark != dark;
}

/// Small caps kicker above a title.
class Kicker extends StatelessWidget {
  const Kicker(this.text, {super.key, this.center = false, this.spacing = 3});

  final String text;
  final bool center;
  final double spacing;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    textAlign: center ? TextAlign.center : null,
    style: TextStyle(
      color: Tokens.of(context).accent,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: spacing,
    ),
  );
}

/// Centered glass card with a kicker, a serif title, and a lead paragraph.
class PageTitle extends StatelessWidget {
  const PageTitle({super.key, required this.title, this.kicker, this.lead});

  final String title;
  final String? kicker;
  final String? lead;

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 640;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 768),
        child: Padding(
          padding: EdgeInsets.only(top: wide ? 40 : 24, bottom: 24),
          child: Glass(
            padding: EdgeInsets.symmetric(
              horizontal: wide ? 40 : 24,
              vertical: 32,
            ),
            child: Column(
              children: [
                if (kicker != null) Kicker(kicker!, center: true),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: serif(size: wide ? 48 : 36, color: k.ink, height: 1.1),
                ),
                if (lead != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    lead!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: k.muted, fontSize: 16, height: 1.6),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A glass section with a serif heading and optional lead.
class GlassSection extends StatelessWidget {
  const GlassSection({
    super.key,
    required this.title,
    this.lead,
    required this.child,
    this.center = false,
  });

  final String title;
  final String? lead;
  final Widget child;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 640;
    return Glass(
      padding: EdgeInsets.all(wide ? 28 : 20),
      child: Column(
        crossAxisAlignment: center
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: center ? TextAlign.center : null,
              style: serif(size: center ? 30 : 24, color: k.ink),
            ),
          ),
          if (lead != null) ...[
            const SizedBox(height: 4),
            Text(
              lead!,
              textAlign: center ? TextAlign.center : null,
              style: TextStyle(color: k.muted, height: 1.5),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Inset tile inside glass (stats, fields, steps).
class Tile extends StatelessWidget {
  const Tile({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: k.tile,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: k.tileBorder),
      ),
      child: child,
    );
  }
}

/// Field label in small caps.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      color: Tokens.of(context).muted,
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
      letterSpacing: 1,
    ),
  );
}

/// One ghost's plate, drawn by the pipeline.
class Plate extends StatelessWidget {
  const Plate(
    this.id, {
    super.key,
    this.size = 40,
    this.semanticLabel,
    this.shadow = false,
  });

  final String id;
  final double size;
  final String? semanticLabel;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final img = ClipOval(
      child: SvgPicture.asset(
        plateAsset(id),
        width: size,
        height: size,
        semanticsLabel: semanticLabel,
        excludeFromSemantics: semanticLabel == null,
      ),
    );
    if (!shadow) return SizedBox.square(dimension: size, child: img);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Malam.c950.withValues(alpha: 0.3),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: img,
    );
  }
}

/// A gentle vertical bob, like the site's `animate-drift`.
class Drift extends StatefulWidget {
  const Drift({
    super.key,
    required this.child,
    this.delay = 0,
    this.amount = 6,
  });

  final Widget child;
  final double delay;
  final double amount;

  @override
  State<Drift> createState() => _DriftState();
}

class _DriftState extends State<Drift> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.settings.animate(context)) {
      if (!_c.isAnimating) {
        _c.value = (widget.delay / 5) % 1;
        _c.repeat();
      }
    } else {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) {
      final x = _c.value;
      final e = (1 - (x * 2 - 1).abs());
      final eased = -(math.cos(math.pi * e) - 1) / 2;
      return Transform.translate(
        offset: Offset(0, -widget.amount * eased),
        child: child,
      );
    },
    child: widget.child,
  );
}

Color cladeColor(BuildContext context, String? clade) {
  final k = Tokens.of(context);
  if (clade == null) return k.neutralBranch;
  final i = data.clades.indexOf(clade);
  return i < 0 ? k.neutralBranch : k.cladeColors[i];
}

class CladeDot extends StatelessWidget {
  const CladeDot(this.clade, {super.key, this.size = 10, this.border = false});

  final String clade;
  final double size;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cladeColor(context, clade),
        shape: BoxShape.circle,
        border: border
            ? Border.all(
                color: k.dark
                    ? Colors.white.withValues(alpha: 0.3)
                    : Malam.c950.withValues(alpha: 0.3),
              )
            : null,
      ),
    );
  }
}

class CladePill extends StatelessWidget {
  const CladePill(this.clade, {super.key, this.large = false});

  final String clade;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 10,
        vertical: large ? 4 : 2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: k.controlBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CladeDot(clade),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              context.tr(clade),
              style: TextStyle(
                fontSize: large ? 14 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DangerMeter extends StatelessWidget {
  const DangerMeter(this.level, {super.key});

  final int level;

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    final label = context.t('danger$level');
    return Semantics(
      label: '${context.t('dangerOf', [level])} $label',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.rotate(
                angle: 0.785398,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i <= level ? k.dangerOn : null,
                    border: Border.all(
                      color: i <= level ? k.dangerOn : k.controlBorder,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: k.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Small rounded chip for coded traits.
class TraitChip extends StatelessWidget {
  const TraitChip(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: Tokens.of(context).chip,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(text, style: const TextStyle(fontSize: 12)),
  );
}

// ---- Controls -------------------------------------------------------------

/// Pill outline with a 3:1 boundary, used by every control.
BoxDecoration controlDecoration(BuildContext context) {
  final k = Tokens.of(context);
  return BoxDecoration(
    color: k.controlFill,
    borderRadius: BorderRadius.circular(999),
    border: Border.all(color: k.controlBorder),
  );
}

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.hint,
    required this.label,
    required this.onChanged,
    this.onSubmitted,
    this.controller,
  });

  final String hint;
  final String label;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: controlDecoration(context),
      child: Row(
        children: [
          Icon(Icons.search, size: 18, color: k.ink.withValues(alpha: 0.6)),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              label: label,
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                style: TextStyle(fontSize: 14, color: k.ink),
                cursorColor: k.accent,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(color: k.muted),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PillDropdown<T> extends StatelessWidget {
  const PillDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.label,
  });

  final T value;
  final List<(T, String)> items;
  final ValueChanged<T> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    return Semantics(
      label: label,
      child: Container(
        height: 40,
        padding: const EdgeInsets.only(left: 14, right: 8),
        decoration: controlDecoration(context),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isDense: true,
            borderRadius: BorderRadius.circular(16),
            dropdownColor: k.glassSolid,
            style: TextStyle(fontSize: 14, color: k.ink),
            iconEnabledColor: k.ink,
            items: [
              for (final (v, text) in items)
                DropdownMenuItem(value: v, child: Text(text)),
            ],
            onChanged: (v) => v == null ? null : onChanged(v),
          ),
        ),
      ),
    );
  }
}

/// A pressable pill: filled when [selected].
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.leading,
    this.small = false,
    this.bordered = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final Widget? leading;
  final bool small;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? k.activeFill : Colors.transparent,
        shape: StadiumBorder(
          side: bordered
              ? BorderSide(color: selected ? k.activeFill : k.controlBorder)
              : BorderSide.none,
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          hoverColor: k.hover,
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: small ? 12 : 14,
              vertical: small ? 5 : 7,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 6)],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: small ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    color: selected ? k.activeText : k.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Underlined accent link.
class AccentLink extends StatelessWidget {
  const AccentLink(
    this.text, {
    super.key,
    required this.onTap,
    this.arrow = false,
  });

  final String text;
  final VoidCallback onTap;
  final bool arrow;

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    return Semantics(
      link: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Text(
          arrow ? '$text →' : text,
          style: TextStyle(
            color: k.accent,
            fontWeight: FontWeight.w600,
            decoration: arrow ? null : TextDecoration.underline,
            decorationColor: k.accent,
          ),
        ),
      ),
    );
  }
}

/// Clade colors with their counts, shown above the trees.
class CladeLegend extends StatelessWidget {
  const CladeLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    final counts = <String, int>{};
    for (final g in data.ghosts) {
      counts[g.clade] = (counts[g.clade] ?? 0) + 1;
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1024),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Glass(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 6,
              children: [
                for (final c in data.clades)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CladeDot(c, size: 12, border: true),
                      const SizedBox(width: 6),
                      Text(context.tr(c), style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        '${counts[c]}',
                        style: TextStyle(fontSize: 14, color: k.muted),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
