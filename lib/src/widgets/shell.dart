/// Page frame: the night scene behind everything, a sticky glass header with
/// navigation, language, motion, and theme controls, and a batik footer.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../i18n.dart';
import '../scene.dart';
import '../settings.dart';
import '../theme.dart';
import 'common.dart';

const sourceUrl = 'https://github.com/hhandika/ghost-phylogeny-indonesia';

const navItems = [
  ('/', 'navOverview'),
  ('/atlas', 'navAtlas'),
  ('/lantern', 'navLantern'),
  ('/bestiary', 'navBestiary'),
  ('/key', 'navKey'),
  ('/patterns', 'navPatterns'),
  ('/methods', 'navMethods'),
];

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    return Scaffold(
      backgroundColor: k.ground,
      body: Stack(
        children: [
          Positioned.fill(
            child: Scene(
              dark: k.dark,
              animate: context.settings.animate(context),
            ),
          ),
          Positioned.fill(child: child),
          const Positioned(left: 0, right: 0, top: 0, child: _Header()),
        ],
      ),
    );
  }
}

/// Scrollable page body under the header, with the footer at the end.
/// [wide] pages (the tree views) manage their own width.
class PageScroll extends StatelessWidget {
  const PageScroll({
    super.key,
    required this.children,
    this.wide = false,
    this.controller,
  });

  final List<Widget> children;
  final bool wide;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final side = wide
        ? (w >= 1024
              ? 32.0
              : w >= 640
              ? 16.0
              : 12.0)
        : (w >= 640 ? 24.0 : 12.0);
    return SingleChildScrollView(
      controller: controller,
      padding: EdgeInsets.fromLTRB(side, w >= 640 ? 84 : 76, side, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: wide ? 1280 : 1024),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [...children, const _Footer()],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final here = GoRouterState.of(context).uri.path;
    final showLinks = w >= 1280;
    final showName = w >= 640;
    final k = Tokens.of(context);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          w >= 640 ? 16 : 8,
          w >= 640 ? 16 : 12,
          w >= 640 ? 16 : 8,
          0,
        ),
        child: Glass(
          radius: 999,
          batik: true,
          padding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
          child: Row(
            children: [
              Semantics(
                link: true,
                label: context.t('siteName'),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => context.go('/'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Gunungan(),
                      if (showName) ...[
                        const SizedBox(width: 8),
                        ExcludeSemantics(
                          child: Text.rich(
                            TextSpan(
                              text: context.t('siteName'),
                              children: [
                                if (w >= 768) ...[
                                  const TextSpan(text: ', '),
                                  TextSpan(
                                    text: context.t('literally'),
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const TextSpan(text: '.'),
                                ],
                              ],
                            ),
                            style: serif(size: 18, color: k.ink),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (showLinks)
                for (final (path, label) in navItems)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: PillButton(
                      label: context.t(label),
                      selected: here == path,
                      bordered: false,
                      onPressed: () => context.go(path),
                    ),
                  ),
              if (showLinks) const SizedBox(width: 8),
              const _LangSwitch(),
              const SizedBox(width: 6),
              const _MotionToggle(),
              const SizedBox(width: 6),
              const _ThemeToggle(),
              if (!showLinks) ...[const SizedBox(width: 6), _Menu(here: here)],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: k.controlFill,
        shape: CircleBorder(side: BorderSide(color: k.controlBorder)),
        child: InkWell(
          customBorder: const CircleBorder(),
          hoverColor: k.hover,
          onTap: onPressed,
          child: SizedBox.square(dimension: 40, child: Center(child: child)),
        ),
      ),
    );
  }
}

class _LangSwitch extends StatelessWidget {
  const _LangSwitch();

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    final s = context.settings;
    return Semantics(
      label: context.t('language'),
      child: Container(
        height: 40,
        padding: const EdgeInsets.all(3),
        decoration: controlDecoration(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final l in Lang.values)
              Tooltip(
                message: langName[l]!,
                child: Semantics(
                  selected: s.lang == l,
                  button: true,
                  child: Material(
                    color: s.lang == l ? k.activeFill : Colors.transparent,
                    shape: const StadiumBorder(),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: () => s.setLang(l),
                      child: Container(
                        height: 32,
                        constraints: const BoxConstraints(minWidth: 36),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          l.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: s.lang == l ? k.activeText : k.ink,
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

class _MotionToggle extends StatelessWidget {
  const _MotionToggle();

  @override
  Widget build(BuildContext context) {
    final on = context.settings.animate(context);
    final k = Tokens.of(context);
    return _RoundControl(
      tooltip: context.t(on ? 'pauseMotion' : 'playMotion'),
      onPressed: () => context.settings.setMotion(!on),
      child: Icon(
        on ? Icons.pause_rounded : Icons.play_arrow_rounded,
        size: 20,
        color: k.ink,
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    // Sun shows in dark mode (switch to light); moon in light mode.
    return _RoundControl(
      tooltip: context.t(k.dark ? 'toLight' : 'toDark'),
      onPressed: () => context.settings.setDark(!k.dark),
      child: Icon(
        k.dark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
        size: 20,
        color: k.ink,
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({required this.here});

  final String here;

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    return PopupMenuButton<String>(
      tooltip: context.t('menu'),
      position: PopupMenuPosition.under,
      offset: const Offset(0, 12),
      color: k.glassSolid,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: k.glassBorder),
      ),
      onSelected: (path) => context.go(path),
      itemBuilder: (context) => [
        for (final (path, label) in navItems)
          PopupMenuItem(
            value: path,
            child: Container(
              width: 180,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: here == path ? k.activeFill : null,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                context.t(label),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: here == path ? k.activeText : k.ink,
                ),
              ),
            ),
          ),
      ],
      child: Container(
        width: 40,
        height: 40,
        decoration: controlDecoration(context)
            .copyWith(shape: BoxShape.circle, borderRadius: null),
        child: Icon(Icons.menu_rounded, size: 20, color: k.ink),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final k = Tokens.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 640;
    final title = Text.rich(
      TextSpan(
        text: '${context.t('siteName')}, ',
        children: [
          TextSpan(
            text: context.t('literally'),
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
          const TextSpan(text: '.'),
        ],
      ),
      style: serif(size: 16, color: k.ink),
    );
    final links = Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 4,
      children: [
        Text(
          '© ${DateTime.now().year} Heru Handika',
          style: TextStyle(color: k.muted, fontSize: 14),
        ),
        AccentLink(
          context.t('navMethods'),
          onTap: () => context.go('/methods'),
        ),
        AccentLink('GitHub', onTap: () => launchUrl(Uri.parse(sourceUrl))),
      ],
    );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1024),
        child: Padding(
          padding: const EdgeInsets.only(top: 80, bottom: 40),
          child: Glass(
            batik: true,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: wide
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [title, links],
                  )
                : Column(children: [title, const SizedBox(height: 12), links]),
          ),
        ),
      ),
    );
  }
}
