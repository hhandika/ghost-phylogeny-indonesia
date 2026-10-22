/// Palette and type, matching web/tailwind.config.mjs and
/// web/src/styles/tailwind.css. Light mode is a misty dusk; dark mode is
/// night.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ramps named after the site's Tailwind colors.
abstract final class Malam {
  static const c50 = Color(0xfff1f0f7);
  static const c100 = Color(0xffe2dfee);
  static const c200 = Color(0xffc6c0dd);
  static const c300 = Color(0xffa29ac4);
  static const c400 = Color(0xff7d73a6);
  static const c500 = Color(0xff5f5689);
  static const c600 = Color(0xff4a426e);
  static const c700 = Color(0xff3a3358);
  static const c800 = Color(0xff2a2442);
  static const c900 = Color(0xff1c1830);
  static const c950 = Color(0xff110e1b);
}

abstract final class Kafan {
  static const c50 = Color(0xfffbf8f1);
  static const c100 = Color(0xfff5efe2);
  static const c200 = Color(0xffebe1cc);
  static const c300 = Color(0xffdccdb0);
  static const c400 = Color(0xffc4ae88);
  static const c500 = Color(0xffa88f68);
  static const c600 = Color(0xff8a7253);
  static const c700 = Color(0xff6c5842);
  static const c800 = Color(0xff4f4033);
  static const c900 = Color(0xff352b24);
}

abstract final class Prada {
  static const c100 = Color(0xfffaefc8);
  static const c200 = Color(0xfff4dc8e);
  static const c300 = Color(0xffedc556);
  static const c400 = Color(0xffe0b03e);
  static const c600 = Color(0xffa87622);
  static const c800 = Color(0xff6e4a20);
  static const c950 = Color(0xff36210e);
}

abstract final class Darah {
  static const c300 = Color(0xffee9ea7);
  static const c600 = Color(0xffb3243a);
  static const c700 = Color(0xff961b30);
  static const c800 = Color(0xff7d1a2d);
}

abstract final class Kemenyan {
  static const c200 = Color(0xffd6d1e0);
  static const c300 = Color(0xffb7afc8);
  static const c400 = Color(0xff958aab);
}

const paper = Color(0xfff5efe2);
const night = Color(0xff110e1b);

/// Clade colors, in the fixed categorical order of the pipeline
/// (pipeline/ghostphylo/config.py CLADES).
const _cladeLight = [
  Color(0xffc0283f),
  Color(0xff00998a),
  Color(0xffc98a12),
  Color(0xff5b4fd0),
  Color(0xffd0602a),
  Color(0xff2c7fc0),
  Color(0xffb8348f),
  Color(0xff4f8a1e),
  Color(0xff8b5cf6),
];
const _cladeDark = [
  Color(0xffe04a62),
  Color(0xff16a08c),
  Color(0xffbf8a1f),
  Color(0xff7d74e6),
  Color(0xffd8703c),
  Color(0xff3f8fd0),
  Color(0xffcc5aa6),
  Color(0xff6aa23a),
  Color(0xff9d7cf0),
];
const _seqLight = [
  Color(0xfff1f0f7),
  Color(0xffc6c0dd),
  Color(0xffa29ac4),
  Color(0xff7d73a6),
  Color(0xff4a426e),
  Color(0xff1c1830),
];
const _seqDark = [
  Color(0xff1c1830),
  Color(0xff36210e),
  Color(0xff6e4a20),
  Color(0xffa87622),
  Color(0xffe0b03e),
  Color(0xfffaefc8),
];

/// Semantic tokens for one theme, read with `Tokens.of(context)`.
class Tokens extends ThemeExtension<Tokens> {
  const Tokens._(this.dark);

  static const light = Tokens._(false);
  static const darkTokens = Tokens._(true);

  final bool dark;

  static Tokens of(BuildContext context) =>
      Theme.of(context).extension<Tokens>() ?? light;

  List<Color> get cladeColors => dark ? _cladeDark : _cladeLight;
  List<Color> get seq => dark ? _seqDark : _seqLight;
  Color get neutralBranch => dark ? Kemenyan.c400 : Kafan.c600;

  Color get ink => dark ? Kafan.c100 : Malam.c950;
  Color get muted => dark ? Kemenyan.c200 : Kafan.c800;
  Color get accent => dark ? Prada.c300 : Darah.c700;
  Color get ground => dark ? night : paper;

  /// Frosted glass: 82% keeps AA text contrast over the brightest scene parts.
  Color get glass => dark
      ? Malam.c950.withValues(alpha: 0.82)
      : Kafan.c50.withValues(alpha: 0.82);
  Color get glassSolid => dark
      ? Malam.c950.withValues(alpha: 0.97)
      : Kafan.c50.withValues(alpha: 0.97);
  Color get glassBorder => dark
      ? Colors.white.withValues(alpha: 0.10)
      : Colors.white.withValues(alpha: 0.60);

  /// Inset tiles inside glass (stats, fields, steps).
  Color get tile => dark
      ? Malam.c900.withValues(alpha: 0.70)
      : Kafan.c100.withValues(alpha: 0.70);
  Color get tileBorder => dark ? Malam.c700 : Kafan.c300;

  /// Form controls need a 3:1 boundary (WCAG 1.4.11).
  Color get controlBorder => dark ? Kemenyan.c400 : Kafan.c700;
  Color get controlFill => dark ? Malam.c900 : Kafan.c50;
  Color get hover => dark ? Malam.c800 : Kafan.c200;
  Color get chip => dark ? Malam.c800 : Kafan.c200;

  /// Pressed or current: night ink on gold in dark mode, gold on ink in light.
  Color get activeFill => dark ? Prada.c300 : Malam.c900;
  Color get activeText => dark ? Malam.c950 : Prada.c200;

  Color get dangerOn => dark ? Darah.c300 : Darah.c700;
  Color get focus => dark ? Prada.c300 : Darah.c700;

  Color get batik => dark
      ? Prada.c400.withValues(alpha: 0.16)
      : Kafan.c600.withValues(alpha: 0.32);

  @override
  Tokens copyWith() => this;

  @override
  Tokens lerp(Tokens? other, double t) => t < 0.5 ? this : (other ?? this);
}

TextStyle serif({
  double size = 16,
  FontWeight weight = FontWeight.w600,
  Color? color,
  FontStyle? style,
  double? height,
}) => GoogleFonts.newsreader(
  fontSize: size,
  fontWeight: weight,
  color: color,
  fontStyle: style,
  height: height,
  letterSpacing: -0.4,
);

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final tokens = dark ? Tokens.darkTokens : Tokens.light;
  final base = ThemeData(
    brightness: brightness,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: dark ? Prada.c300 : Malam.c900,
      brightness: brightness,
      primary: tokens.activeFill,
      onPrimary: tokens.activeText,
      surface: tokens.ground,
      onSurface: tokens.ink,
    ),
    scaffoldBackgroundColor: tokens.ground,
    extensions: [tokens],
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: GoogleFonts.figtree().fontFamily,
      bodyColor: tokens.ink,
      displayColor: tokens.ink,
    ),
    focusColor: tokens.focus.withValues(alpha: 0.2),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: tokens.glassSolid,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.controlBorder),
      ),
      textStyle: TextStyle(color: tokens.ink, fontSize: 12),
    ),
  );
}
