import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dsteps/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:health/health.dart';

import '../settings_model.dart';

class StepCounterManager {
  final SettingsModel settings;
  final VoidCallback onPermissionDenied; // 回調處理權限拒絕
  final VoidCallback onNavigateToMain; // 回調處理導航
  final Health health = Health();
  int? todaySteps;
  bool goalReachedNotified = false;
  DateTime? lastMotivationTime;
  late AppLocalizations _l10n; // 在初始化時設置
  Timer? _timer; // 用於定期檢查

  StepCounterManager({required this.settings, required this.onPermissionDenied, required this.onNavigateToMain});

  Future<void> initialize() async {
    // 假設這裡需要一個初始的 context 來獲取 l10n，我們改用預設語言
    // 實際上，l10n 應在需要時從外部傳入，這裡簡化處理
    // _l10n = await AppLocalizations.delegate.load(const Locale('en')); // 預設英文
    _l10n = await AppLocalizations.delegate.load(settings.getLocale() ?? const Locale('en')); // 預設英文
    await _initializeNotifications();
    await _requestPermissionsAndFetchSteps();
    _startPeriodicCheck();

    // 測試用：強制顯示目標達成通知
    // await _showGoalReachedNotification(5000);
  }

  Future<void> _initializeNotifications() async {
    await AwesomeNotifications().initialize('resource://drawable/ic_launcher', [
      NotificationChannel(
        channelKey: 'step_channel',
        channelName: 'Step Alerts',
        channelDescription: 'Notifications for step goals',
        defaultColor: Colors.blue,
        ledColor: Colors.white,
        importance: NotificationImportance.High,
      ),
    ]);

    // 檢查並請求通知權限
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      bool granted = await AwesomeNotifications().requestPermissionToSendNotifications();
      if (!granted) {
        debugPrint('Notification permission denied');
        return; // 如果用戶拒絕，可以選擇退出或稍後重試
      }
    }

    // 設置通知監聽器
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: (ReceivedAction action) async {
        if (action.buttonKeyPressed == 'view_details') {
          onNavigateToMain(); // 使用回調處理導航
        }
      },
    );
  }

  Future<void> _requestPermissionsAndFetchSteps() async {
    List<HealthDataType> types = [HealthDataType.STEPS];
    bool authorized = await health.requestAuthorization(types);
    if (!authorized) {
      onPermissionDenied(); // 使用回調通知權限問題
      return;
    }
    await _fetchTodaySteps();
  }

  Future<void> _fetchTodaySteps() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(types: [HealthDataType.STEPS], startTime: midnight, endTime: now);

    int steps = healthData.fold(0, (sum, data) => sum + (data.value as NumericHealthValue).numericValue.toInt());

    todaySteps = steps;

    int goal = settings.dailyStepGoal;

    if (_isWithinActiveHours(now)) {
      if (steps >= goal && !goalReachedNotified) {
        _showGoalReachedNotification(steps);
        goalReachedNotified = true;
      } else if (steps >= goal - 1000 && !goalReachedNotified && _canShowMotivation(now)) {
        _showMotivationNotification(goal);
        lastMotivationTime = now;
      }
    }
  }

  bool _isWithinActiveHours(DateTime time) {
    final int hour = time.hour;
    return hour >= 7 && hour < 22; // 7 AM - 10 PM
  }

  bool _canShowMotivation(DateTime now) {
    // return true;
    return lastMotivationTime == null || now.difference(lastMotivationTime!).inHours >= 1;
  }

  Future<void> _showGoalReachedNotification(int steps) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 0,
        channelKey: 'step_channel',
        title: _l10n.stepGoalReachedTitle,
        body: _l10n.stepGoalReachedBody(steps),
        color: Colors.green,
        notificationLayout: NotificationLayout.BigText,
        icon: 'resource://mipmap/ic_launcher',
      ),
      actionButtons: [
        NotificationActionButton(key: 'view_details', label: _l10n.viewDetails, color: Colors.blue, actionType: ActionType.SilentAction),
      ],
    );
  }

  Future<void> _showMotivationNotification(int goal) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'step_channel',
        title: _l10n.motivationTitle,
        body: _l10n.motivationBody(goal),
        color: Colors.orange,
        notificationLayout: NotificationLayout.BigText,
        icon: 'resource://mipmap/ic_launcher',
      ),
      actionButtons: [
        NotificationActionButton(key: 'view_details', label: _l10n.viewDetails, color: Colors.blue, actionType: ActionType.SilentAction),
      ],
    );
  }

  void _startPeriodicCheck() {
    _timer = Timer.periodic(Duration(minutes: 60), (timer) async {
      final now = DateTime.now();
      if (_isWithinActiveHours(now)) {
        await _fetchTodaySteps();
      }
    });
  }

  void dispose() {
    _timer?.cancel(); // 停止計時器
  }
}
