// import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsModel extends ChangeNotifier {
  String _language = 'system';
  String _theme = 'system';
  String _syncFrequency = 'manual';
  int _dailyStepGoal = 6000;
  bool _showCumulative = true;
  bool _showDailyStepGoal = false;

  // late SharedPreferences _prefs;
  // late SharedPreferencesWithCache _prefs;
  late SharedPreferencesAsync _prefs;

  SettingsModel() {
    _loadPreferences();
  }

  String get language => _language;
  String get theme => _theme;
  String get syncFrequency => _syncFrequency;
  int get dailyStepGoal => _dailyStepGoal;
  bool get showCumulative => _showCumulative;
  bool get showDailyStepGoal => _showDailyStepGoal;

  Future<void> _loadPreferences() async {
    // _prefs = await SharedPreferences.getInstance();
    // _prefs = await SharedPreferencesWithCache.create(
    //   cacheOptions: const SharedPreferencesWithCacheOptions(
    //     // When an allowlist is included, any keys that aren't included cannot be used.
    //     // allowList: <String>{'repeat', 'action'},
    //   ),
    // );

    // _language = _prefs.getString('language') ?? 'system';
    // _theme = _prefs.getString('theme') ?? 'system';
    // _syncFrequency = _prefs.getString('syncFrequency') ?? 'manual';

    _prefs = SharedPreferencesAsync();
    _language = await _prefs.getString('language') ?? 'system';
    _theme = await _prefs.getString('theme') ?? 'system';
    _syncFrequency = await _prefs.getString('syncFrequency') ?? 'manual';
    _dailyStepGoal = await _prefs.getInt('dailyStepGoal') ?? 6000;
    _showCumulative = await _prefs.getBool('showCumulative') ?? true;
    _showDailyStepGoal = await _prefs.getBool('showDailyStepGoal') ?? false;

    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    _language = language;
    await _prefs.setString('language', language);
    notifyListeners();
  }

  Future<void> setTheme(String theme) async {
    _theme = theme;
    await _prefs.setString('theme', theme);
    notifyListeners();
  }

  Future<void> setSyncFrequency(String frequency) async {
    _syncFrequency = frequency;
    await _prefs.setString('syncFrequency', frequency);
    notifyListeners();
  }

  Future<void> setDailyStepGoal(int dailyStepGoal) async {
    _dailyStepGoal = dailyStepGoal;
    await _prefs.setInt('dailyStepGoal', dailyStepGoal);
    notifyListeners();
  }

  Future<void> setShowCumulative(bool showCumulative) async {
    _showCumulative = showCumulative;
    await _prefs.setBool('showCumulative', showCumulative);
    notifyListeners();
  }

  Future<void> setShowDailyStepGoal(bool showDailyStepGoal) async {
    _showDailyStepGoal = showCumulative;
    await _prefs.setBool('showDailyStepGoal', showDailyStepGoal);
    notifyListeners();
  }

  Locale? getLocale() {
    switch (_language) {
      case 'en':
        return const Locale('en', '');
      case 'zh_Hant':
        return const Locale('zh', 'Hant');
      case 'zh_Hans':
        return const Locale('zh', 'Hans');
      case 'system':
      default:
        return null;
    }
  }

  ThemeMode getThemeMode() {
    switch (_theme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}
