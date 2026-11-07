import 'dart:async';

import 'package:dhealth/services/background_service.dart';
import 'package:dhealth/settings_keys.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'utils/log.dart';

/// 使用者設定。唯一寫 prefs 的地方；背景 isolate 只讀（見 BackgroundService）。
///
/// 建立方式一律用 [SettingsModel.load]，不要直接 new ——
/// 舊版在 ctor 裡 unawaited 呼叫 `_loadPreferences()`，後果不只是「設定頁先跳一下」：
/// 前幾幀的 setter 會被之後才完成的載入用**舊值**蓋掉。
class SettingsModel extends ChangeNotifier {
  final SharedPreferencesAsync _prefs;

  SettingsModel._(this._prefs);

  /// 載入完成才交回控制权：首幀就是正確的值，也不會有寫入被載入蓋掉的競態。
  static Future<SettingsModel> load() async {
    final model = SettingsModel._(SharedPreferencesAsync());
    await model._loadPreferences();
    return model;
  }

  // Inferface
  String _language = PrefsDefaults.language;
  String _theme = PrefsDefaults.theme;

  // Health Data Sync
  bool _healthSyncEnabled = PrefsDefaults.healthSyncEnabled;
  int _syncFrequency = PrefsDefaults.syncFrequencyMinutes;
  final List<int> _predefinedSyncFrequency = const [15, 30, 60]; // 15m, 30m, 1hr in minutes
  int _activeStartHour = PrefsDefaults.activeStartHour;
  int _activeEndHour = PrefsDefaults.activeEndHour;

  // Settings
  bool _showCumulative = PrefsDefaults.showCumulative;
  bool _showDailyStepGoal = PrefsDefaults.showDailyStepGoal;
  int _dailyStepGoal = PrefsDefaults.dailyStepGoal;
  String _dailyChartRange = PrefsDefaults.dailyChartRange;

  // Notification settings
  bool _notificationsEnabled = PrefsDefaults.notificationsEnabled;
  int _notificationFrequency = PrefsDefaults.notificationFrequencyMinutes;
  bool _reachGoal = PrefsDefaults.reachGoal;
  bool _motivation = PrefsDefaults.motivation;
  int _motivationTimeLimit = PrefsDefaults.motivationTimeLimitHours;
  bool _exception = PrefsDefaults.exception;
  bool _soundEnabled = PrefsDefaults.soundEnabled;
  bool _vibrationEnabled = PrefsDefaults.vibrationEnabled;
  String _priority = PrefsDefaults.priority; // low, default, high

  // Getters - Inferface
  String get language => _language;
  String get theme => _theme;

  // Getters - Health Data Sync
  bool get healthSyncEnabled => _healthSyncEnabled;
  int get syncFrequency => _syncFrequency;
  List<int> get predefinedSyncFrequency => _predefinedSyncFrequency;
  int get activeStartHour => _activeStartHour;
  int get activeEndHour => _activeEndHour;

  // Getters - Settings
  bool get showCumulative => _showCumulative;
  bool get showDailyStepGoal => _showDailyStepGoal;
  int get dailyStepGoal => _dailyStepGoal;
  String get dailyChartRange => _dailyChartRange;

  // Getters - Notification
  bool get notificationsEnabled => _notificationsEnabled;
  int get notificationFrequency => _notificationFrequency;
  bool get reachGoal => _reachGoal;
  bool get motivation => _motivation;
  int get motivationTimeLimit => _motivationTimeLimit;
  bool get exception => _exception;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  String get priority => _priority;

  Future<void> _loadPreferences() async {
    _language = await _prefs.getString(Prefs.language) ?? PrefsDefaults.language;
    _theme = await _prefs.getString(Prefs.theme) ?? PrefsDefaults.theme;

    // Health Data Sync
    _healthSyncEnabled = await _prefs.getBool(Prefs.healthSyncEnabled) ?? PrefsDefaults.healthSyncEnabled;
    _syncFrequency = _clampMinutes(await _prefs.getInt(Prefs.syncFrequency), PrefsDefaults.syncFrequencyMinutes);
    _activeStartHour = _clampHour(await _prefs.getInt(Prefs.activeStartHour), PrefsDefaults.activeStartHour);
    _activeEndHour = _clampHour(await _prefs.getInt(Prefs.activeEndHour), PrefsDefaults.activeEndHour);

    // Settings
    _showCumulative = await _prefs.getBool(Prefs.showCumulative) ?? PrefsDefaults.showCumulative;
    _showDailyStepGoal = await _prefs.getBool(Prefs.showDailyStepGoal) ?? PrefsDefaults.showDailyStepGoal;
    _dailyStepGoal = _clampGoal(await _prefs.getInt(Prefs.dailyStepGoal));
    _dailyChartRange = await _prefs.getString(Prefs.dailyChartRange) ?? PrefsDefaults.dailyChartRange;

    // Notification
    _notificationsEnabled = await _prefs.getBool(Prefs.notificationsEnabled) ?? PrefsDefaults.notificationsEnabled;
    _notificationFrequency = _clampMinutes(await _prefs.getInt(Prefs.notificationFrequency), PrefsDefaults.notificationFrequencyMinutes);
    _reachGoal = await _prefs.getBool(Prefs.reachGoal) ?? PrefsDefaults.reachGoal;
    _motivation = await _prefs.getBool(Prefs.motivation) ?? PrefsDefaults.motivation;
    _motivationTimeLimit = _clampRange(await _prefs.getInt(Prefs.motivationTimeLimit), PrefsDefaults.motivationTimeLimitHours, 0, 24);
    _exception = await _prefs.getBool(Prefs.exception) ?? PrefsDefaults.exception;
    _soundEnabled = await _prefs.getBool(Prefs.soundEnabled) ?? PrefsDefaults.soundEnabled;
    _vibrationEnabled = await _prefs.getBool(Prefs.vibrationEnabled) ?? PrefsDefaults.vibrationEnabled;
    _priority = await _prefs.getString(Prefs.priority) ?? PrefsDefaults.priority;
  }

  // 髒值（舊版寫入的、手工改過的、被備份還原回來的）不能直通 WorkManager 的排程間隔：
  // WorkManager 對 < 15 分鐘的 periodic 間隔會直接丟例外，於是大半夜的排程整個不見。
  // 一律夾到合法範圍，而不是讓它炸在背景。
  static int _clampMinutes(int? value, int fallback) => _clampRange(value, fallback, 15, 24 * 60);
  static int _clampHour(int? value, int fallback) => _clampRange(value, fallback, 0, 23);
  static int _clampGoal(int? value) => _clampRange(value, PrefsDefaults.dailyStepGoal, 1, 200000);
  static int _clampRange(int? value, int fallback, int min, int max) => (value ?? fallback).clamp(min, max);

  /// 會動到 WorkManager 排程的三個 setter 共用：重排即可，不要重新 initialize。
  void _rescheduleBackground() {
    unawaited(BackgroundService.scheduleTask().catchError((Object e) => appError('重新排程背景同步失敗', e)));
  }

  // Setters
  Future<void> setLanguage(String language) async {
    _language = language;
    await _prefs.setString(Prefs.language, language);
    notifyListeners();
  }

  Future<void> setTheme(String theme) async {
    _theme = theme;
    await _prefs.setString(Prefs.theme, theme);
    notifyListeners();
  }

  Future<void> setHealthSyncEnabled(bool healthSyncEnabled) async {
    _healthSyncEnabled = healthSyncEnabled;
    await _prefs.setBool(Prefs.healthSyncEnabled, healthSyncEnabled);
    _rescheduleBackground();
    notifyListeners();
  }

  Future<void> setSyncFrequency(int frequency) async {
    _syncFrequency = _clampMinutes(frequency, PrefsDefaults.syncFrequencyMinutes);
    await _prefs.setInt(Prefs.syncFrequency, _syncFrequency);
    _rescheduleBackground();
    notifyListeners();
  }

  Future<void> setActiveStartHour(int activeStartHour) async {
    _activeStartHour = _clampHour(activeStartHour, PrefsDefaults.activeStartHour);
    await _prefs.setInt(Prefs.activeStartHour, _activeStartHour);
    notifyListeners();
  }

  Future<void> setActiveEndHour(int activeEndHour) async {
    _activeEndHour = _clampHour(activeEndHour, PrefsDefaults.activeEndHour);
    await _prefs.setInt(Prefs.activeEndHour, _activeEndHour);
    notifyListeners();
  }

  Future<void> setDailyChartRange(String value) async {
    _dailyChartRange = value;
    await _prefs.setString(Prefs.dailyChartRange, value);
    notifyListeners();
  }

  Future<void> setShowCumulative(bool showCumulative) async {
    _showCumulative = showCumulative;
    await _prefs.setBool(Prefs.showCumulative, showCumulative);
    notifyListeners();
  }

  Future<void> setShowDailyStepGoal(bool showDailyStepGoal) async {
    _showDailyStepGoal = showDailyStepGoal;
    await _prefs.setBool(Prefs.showDailyStepGoal, showDailyStepGoal);
    notifyListeners();
  }

  Future<void> setDailyStepGoal(int dailyStepGoal) async {
    _dailyStepGoal = _clampGoal(dailyStepGoal);
    await _prefs.setInt(Prefs.dailyStepGoal, _dailyStepGoal);
    _rescheduleBackground();
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _prefs.setBool(Prefs.notificationsEnabled, value);
    _rescheduleBackground();
    notifyListeners();
  }

  Future<void> setNotificationFrequency(int value) async {
    _notificationFrequency = _clampMinutes(value, PrefsDefaults.notificationFrequencyMinutes);
    await _prefs.setInt(Prefs.notificationFrequency, _notificationFrequency);
    _rescheduleBackground();
    notifyListeners();
  }

  Future<void> setReachGoal(bool value) async {
    _reachGoal = value;
    await _prefs.setBool(Prefs.reachGoal, value);
    notifyListeners();
  }

  Future<void> setMotivation(bool value) async {
    _motivation = value;
    await _prefs.setBool(Prefs.motivation, value);
    notifyListeners();
  }

  Future<void> setMotivationTimeLimit(int value) async {
    _motivationTimeLimit = _clampRange(value, PrefsDefaults.motivationTimeLimitHours, 0, 24);
    await _prefs.setInt(Prefs.motivationTimeLimit, _motivationTimeLimit);
    notifyListeners();
  }

  Future<void> setException(bool value) async {
    _exception = value;
    await _prefs.setBool(Prefs.exception, value);
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    await _prefs.setBool(Prefs.soundEnabled, value);
    notifyListeners();
  }

  Future<void> setVibrationEnabled(bool value) async {
    _vibrationEnabled = value;
    await _prefs.setBool(Prefs.vibrationEnabled, value);
    notifyListeners();
  }

  Future<void> setPriority(String value) async {
    _priority = value;
    await _prefs.setString(Prefs.priority, value);
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
