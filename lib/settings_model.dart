import 'package:dhealth/services/background_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsModel extends ChangeNotifier {
  late SharedPreferencesAsync _prefs;

  // Inferface
  String _language = 'system';
  String _theme = 'system';

  // Health Data Sync
  bool _healthSyncEnabled = true;
  int _syncFrequency = 15;
  final List<int> _predefinedSyncFrequency = [15, 30, 60]; // 15m, 30m, 1hr in minutes
  // String? _customSyncFrequency;
  int _activeStartHour = 7;
  int _activeEndHour = 23;
  bool _startOnBoot = true;
  bool _stopOnTerminate = false;
  bool _headlessMode = true;

  // Settings
  bool _showCumulative = true;
  bool _showDailyStepGoal = false;
  int _dailyStepGoal = 6000;

  // Notification settings
  static const String _prefix = 'notification_';
  bool _notificationsEnabled = true;
  int _notificationFrequency = 15; // in minutes
  bool _reachGoal = true;
  bool _motivation = true;
  int _motivationTimeLimit = 1; // in hours
  bool _exception = true;
  bool _accomplishment = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _priority = 'default'; // low, default, high
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 22, minute: 0);

  // Getters - Inferface
  String get language => _language;
  String get theme => _theme;

  // Getters - Health Data Sync
  bool get healthSyncEnabled => _healthSyncEnabled;
  int get syncFrequency => _syncFrequency;
  List<int> get predefinedSyncFrequency => _predefinedSyncFrequency;
  // String? get customSyncFrequency => _customSyncFrequency;
  int get activeStartHour => _activeStartHour;
  int get activeEndHour => _activeEndHour;
  bool get startOnBoot => _startOnBoot;
  bool get stopOnTerminate => _stopOnTerminate;
  bool get persistentSync => _headlessMode;

  // Getters - Settings
  bool get showCumulative => _showCumulative;
  bool get showDailyStepGoal => _showDailyStepGoal;
  int get dailyStepGoal => _dailyStepGoal;

  // Getters - Notification
  bool get notificationsEnabled => _notificationsEnabled;
  int get notificationFrequency => _notificationFrequency;
  bool get reachGoal => _reachGoal;
  bool get motivation => _motivation;
  int get motivationTimeLimit => _motivationTimeLimit;
  bool get exception => _exception;
  bool get accomplishment => _accomplishment;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  String get priority => _priority;
  TimeOfDay get startTime => _startTime;
  TimeOfDay get endTime => _endTime;

  SettingsModel() {
    _loadPreferences();
  }

  TimeOfDay? _timeFromString(String? time) {
    if (time == null) return null;
    final parts = time.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _loadPreferences() async {
    _prefs = SharedPreferencesAsync();
    _language = await _prefs.getString('language') ?? 'system';
    _theme = await _prefs.getString('theme') ?? 'system';

    // Health Data Sync
    _healthSyncEnabled = await _prefs.getBool('health_sync_enabled') ?? true;
    _syncFrequency = await _prefs.getInt('health_sync_frequency') ?? 15;
    _activeStartHour = await _prefs.getInt('health_sync_active_start_hour') ?? 7;
    _activeEndHour = await _prefs.getInt('health_sync_active_end_hour') ?? 23;
    _startOnBoot = await _prefs.getBool('health_sync_start_on_boot') ?? true;
    _stopOnTerminate = await _prefs.getBool('health_sync_stop_on_terminate') ?? false;
    _headlessMode = await _prefs.getBool('health_sync_headless_mode') ?? false;

    // Settings
    _showCumulative = await _prefs.getBool('showCumulative') ?? true;
    _showDailyStepGoal = await _prefs.getBool('showDailyStepGoal') ?? false;
    _dailyStepGoal = await _prefs.getInt('dailyStepGoal') ?? 6000;

    // Notification
    _notificationsEnabled = await _prefs.getBool('${_prefix}enabled') ?? true;
    _notificationFrequency = await _prefs.getInt('${_prefix}frequency') ?? 15;
    _reachGoal = await _prefs.getBool('${_prefix}reach_goal') ?? true;
    _motivation = await _prefs.getBool('${_prefix}motivation') ?? true;
    _motivationTimeLimit = await _prefs.getInt('${_prefix}motivation_time_limit') ?? 1;
    _exception = await _prefs.getBool('${_prefix}exception') ?? true;
    _accomplishment = await _prefs.getBool('${_prefix}accomplishment') ?? true;
    _soundEnabled = await _prefs.getBool('${_prefix}sound_enabled') ?? true;
    _vibrationEnabled = await _prefs.getBool('${_prefix}vibration_enabled') ?? true;
    _priority = await _prefs.getString('${_prefix}priority') ?? 'default';
    _startTime = _timeFromString(await _prefs.getString('${_prefix}start_time')) ?? const TimeOfDay(hour: 8, minute: 0);
    _endTime = _timeFromString(await _prefs.getString('${_prefix}end_time')) ?? const TimeOfDay(hour: 22, minute: 0);

    notifyListeners();
  }

  // Setters
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

  Future<void> setHealthSyncEnabled(bool healthSyncEnabled) async {
    _healthSyncEnabled = healthSyncEnabled;
    await _prefs.setBool('health_sync_enabled', healthSyncEnabled);
    notifyListeners();
  }

  Future<void> setSyncFrequency(int frequency) async {
    _syncFrequency = frequency;
    await _prefs.setInt('health_sync_frequency', frequency);
    notifyListeners();
  }

  // void setSyncFrequency(String value) {
  //   _syncFrequency = value;
  //   if (value != 'custom') {
  //     _customSyncFrequency = null; // Clear custom value if a predefined option is selected
  //   }
  //   notifyListeners();
  // }

  // void setCustomSyncFrequency(String customValue) {
  //   _syncFrequency = 'custom';
  //   _customSyncFrequency = customValue;
  //   notifyListeners();
  // }

  Future<void> setActiveStartHour(int activeStartHour) async {
    _activeStartHour = activeStartHour;
    await _prefs.setInt('health_sync_active_start_hour', activeStartHour);
    notifyListeners();
  }

  Future<void> setActiveEndHour(int activeEndtHour) async {
    _activeEndHour = activeEndHour;
    await _prefs.setInt('health_sync_active_end_hour', activeEndHour);
    notifyListeners();
  }

  Future<void> setStartOnBoot(bool startOnBoot) async {
    _startOnBoot = startOnBoot;
    await _prefs.setBool('health_sync_start_on_boot', startOnBoot);
    notifyListeners();
  }

  Future<void> setStopOnTerminate(bool stopOnTerminate) async {
    _startOnBoot = stopOnTerminate;
    await _prefs.setBool('health_sync_stop_on_terminate', stopOnTerminate);
    notifyListeners();
  }

  Future<void> setPersistentSync(bool headlessMode) async {
    _headlessMode = headlessMode;
    await _prefs.setBool('health_sync_headless_mode', headlessMode);
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

  Future<void> setDailyStepGoal(int dailyStepGoal) async {
    _dailyStepGoal = dailyStepGoal;
    await _prefs.setInt('dailyStepGoal', dailyStepGoal);
    BackgroundService.init(); // No need to await
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _prefs.setBool('${_prefix}enabled', value);
    if (value) {
      BackgroundService.init(); // No need to await
    }
    notifyListeners();
  }

  Future<void> setNotificationFrequency(int value) async {
    _notificationFrequency = value;
    await _prefs.setInt('${_prefix}frequency', value);
    BackgroundService.init(); // No need to await
    notifyListeners();
  }

  Future<void> setReachGoal(bool value) async {
    _reachGoal = value;
    await _prefs.setBool('${_prefix}reach_goal', value);
    notifyListeners();
  }

  Future<void> setMotivation(bool value) async {
    _motivation = value;
    await _prefs.setBool('${_prefix}motivation', value);
    notifyListeners();
  }

  Future<void> setMotivationTimeLimit(int value) async {
    _motivationTimeLimit = value;
    await _prefs.setInt('${_prefix}motivation_time_limit', value);
    notifyListeners();
  }

  Future<void> setException(bool value) async {
    _exception = value;
    await _prefs.setBool('${_prefix}exception', value);
    notifyListeners();
  }

  Future<void> setAccomplishment(bool value) async {
    _accomplishment = value;
    await _prefs.setBool('${_prefix}accomplishment', value);
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    await _prefs.setBool('${_prefix}sound_enabled', value);
    notifyListeners();
  }

  Future<void> setVibrationEnabled(bool value) async {
    _vibrationEnabled = value;
    await _prefs.setBool('${_prefix}vibration_enabled', value);
    notifyListeners();
  }

  Future<void> setPriority(String value) async {
    _priority = value;
    await _prefs.setString('${_prefix}priority', value);
    notifyListeners();
  }

  Future<void> setStartTime(TimeOfDay value) async {
    _startTime = value;
    await _prefs.setString('${_prefix}start_time', '${value.hour}:${value.minute}');
    notifyListeners();
  }

  Future<void> setEndTime(TimeOfDay value) async {
    _endTime = value;
    await _prefs.setString('${_prefix}end_time', '${value.hour}:${value.minute}');
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
