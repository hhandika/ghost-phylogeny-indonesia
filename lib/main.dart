/// Ghost phylogeny, literally: the Flutter app. Reads the same pipeline
/// output as the website (web/src/data/phylogeny.json and the plates in
/// web/public/ghosts/) and follows the same design.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'src/data.dart';
import 'src/pages/atlas.dart';
import 'src/pages/bestiary.dart';
import 'src/pages/lantern.dart';
import 'src/pages/methods.dart';
import 'src/pages/overview.dart';
import 'src/pages/patterns.dart';
import 'src/pages/specimen.dart';
import 'src/settings.dart';
import 'src/theme.dart';
import 'src/widgets/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Dataset.load();
  final settings = await AppSettings.load();
  runApp(GhostPhylogenyApp(settings: settings));
}

Page<void> _fade(GoRouterState state, Widget child) => CustomTransitionPage(
  key: state.pageKey,
  child: child,
  transitionsBuilder: (context, animation, _, child) =>
      FadeTransition(opacity: animation, child: child),
);

final router = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (_, s) => _fade(s, const OverviewPage()),
        ),
        GoRoute(
          path: '/atlas',
          pageBuilder: (_, s) => _fade(s, const AtlasPage()),
        ),
        GoRoute(
          path: '/lantern',
          pageBuilder: (_, s) => _fade(s, const LanternPage()),
        ),
        GoRoute(
          path: '/bestiary',
          pageBuilder: (_, s) => _fade(s, const BestiaryPage()),
        ),
        GoRoute(
          path: '/patterns',
          pageBuilder: (_, s) => _fade(s, const PatternsPage()),
        ),
        GoRoute(
          path: '/methods',
          pageBuilder: (_, s) => _fade(s, const MethodsPage()),
        ),
        GoRoute(
          path: '/ghosts/:id',
          redirect: (_, s) =>
              Dataset.instance.byId.containsKey(s.pathParameters['id'])
              ? null
              : '/',
          pageBuilder: (_, s) =>
              _fade(s, SpecimenPage(id: s.pathParameters['id']!)),
        ),
      ],
    ),
  ],
);

class GhostPhylogenyApp extends StatelessWidget {
  const GhostPhylogenyApp({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      settings: settings,
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => MaterialApp.router(
          title: settings.lang.name == 'id'
              ? 'Filogeni hantu, secara harfiah'
              : 'Ghost phylogeny, literally',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: settings.themeMode,
          locale: Locale(settings.lang.name),
          supportedLocales: const [Locale('en'), Locale('id')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          routerConfig: router,
        ),
      ),
    );
  }
}
