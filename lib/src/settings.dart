/// Reader choices that persist between visits: language, theme, and motion.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'i18n.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs)
    : lang = _prefs?.getString('lang') == 'id' ? Lang.id : Lang.en,
      themeMode = switch (_prefs?.getString('theme')) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.system,
      },
      motionOff = switch (_prefs?.getString('motion')) {
        'off' => true,
        'on' => false,
        _ => null,
      };

  static Future<AppSettings> load() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      // Storage can be unavailable (private windows); defaults still work.
    }
    return AppSettings._(prefs);
  }

  final SharedPreferences? _prefs;
  Lang lang;
  ThemeMode themeMode;

  /// Null follows the platform's reduced-motion setting.
  bool? motionOff;

  void setLang(Lang l) {
    lang = l;
    _prefs?.setString('lang', l.name);
    notifyListeners();
  }

  void setDark(bool dark) {
    themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    _prefs?.setString('theme', dark ? 'dark' : 'light');
    notifyListeners();
  }

  void setMotion(bool on) {
    motionOff = !on;
    _prefs?.setString('motion', on ? 'on' : 'off');
    notifyListeners();
  }

  /// Whether decorative motion should run in this context.
  bool animate(BuildContext context) =>
      !(motionOff ?? MediaQuery.of(context).disableAnimations);

  static AppSettings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsScope>()!.notifier!;
}

class SettingsScope extends InheritedNotifier<AppSettings> {
  const SettingsScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);
}

extension SettingsContext on BuildContext {
  AppSettings get settings => AppSettings.of(this);
  Lang get lang => AppSettings.of(this).lang;

  /// Interface string in the current language.
  String t(String key, [List<Object?> args = const []]) =>
      i18nT(lang, key, args);

  /// Data string in the current language.
  String tr(String? s) => i18nTr(lang, s);
}

// Aliases so the extension can call the top-level functions it shadows.
const i18nT = t;
const i18nTr = tr;
