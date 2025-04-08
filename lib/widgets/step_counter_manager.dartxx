import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dsteps/generated/l10n/app_localizations.dart';
import 'package:dsteps/settings_model.dart';
import 'package:flutter/material.dart';
import 'package:health/health.dart';

class StepCounterManager {
  final SettingsModel settings;
  final VoidCallback onPermissionDenied;
  final VoidCallback onNavigateToMain;
  final Health health = Health();
  int? todaySteps;
  bool goalReachedNotified = false;
  DateTime? lastMotivationTime;
  late AppLocalizations _l10n;
  Timer? _timer; // Keep for foreground if desired

  StepCounterManager({required this.settings, required this.onPermissionDenied, required this.onNavigateToMain});

  Future<void> initialize() async {
    _l10n = await AppLocalizations.delegate.load(settings.getLocale() ?? const Locale('en'));
    await _initializeNotifications();
    await _requestPermissionsAndFetchSteps();
    _startPeriodicCheck(); // Optional: Keep for foreground
    await _scheduleHealthCheck(); // Add for background/terminated
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

    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      bool granted = await AwesomeNotifications().requestPermissionToSendNotifications();
      if (!granted) {
        debugPrint('Notification permission denied');
        return;
      }
    }

    // Set up action listeners for both navigation and health checks
    AwesomeNotifications().setListeners(onActionReceivedMethod: _handleNotificationAction);
  }

  Future<void> _requestPermissionsAndFetchSteps() async {
    List<HealthDataType> types = [HealthDataType.STEPS];
    bool authorized = await health.requestAuthorization(types);
    if (!authorized) {
      onPermissionDenied();
      return;
    }
    await _fetchTodaySteps();
  }

  Future<void> _fetchTodaySteps() async {
    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(types: [HealthDataType.STEPS], startTime: midnight, endTime: now);

      int steps = healthData.fold(0, (sum, data) => sum + (data.value as NumericHealthValue).numericValue.toInt());
      todaySteps = steps;
      debugPrint('Steps successfully fetched: $steps');
      await _checkAndNotify(steps, now);
    } catch (e) {
      debugPrint('Error fetching steps: $e');
      todaySteps = null; // Reset steps to indicate failure
      await _showErrorNotification(e.toString()); // Show error notification
    }
  }

  // New method to show an error notification
  Future<void> _showErrorNotification(String errorMessage) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 4, // Unique ID for error notifications
        channelKey: 'step_channel',
        title: 'Error', // _l10n.errorTitle ?? 'Error', // Use localized title or fallback
        body:
            'Failed to fetch steps: $errorMessage', //_l10n.errorFetchingSteps(errorMessage) ?? 'Failed to fetch steps: $errorMessage', // Localized or raw error
        color: Colors.red, // Red to indicate an error
        notificationLayout: NotificationLayout.BigText,
        icon: 'resource://mipmap/ic_launcher',
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'view_details',
          label: _l10n.viewDetails ?? 'View Details',
          color: Colors.blue,
          actionType: ActionType.SilentAction,
        ),
      ],
    );
  }

  bool _isWithinActiveHours(DateTime time) {
    final int hour = time.hour;
    return hour >= 7 && hour < 22; // 7 AM - 10 PM
  }

  bool _canShowMotivation(DateTime now) {
    return lastMotivationTime == null || now.difference(lastMotivationTime!).inHours >= 1;
  }

  Future<void> _checkAndNotify(int steps, DateTime now) async {
    int goal = settings.dailyStepGoal;
    if (_isWithinActiveHours(now)) {
      if (steps >= goal && !goalReachedNotified) {
        await _showGoalReachedNotification(steps);
        goalReachedNotified = true;
      } else if (steps >= goal - 1000 && !goalReachedNotified && _canShowMotivation(now)) {
        await _showMotivationNotification(goal);
        lastMotivationTime = now;
      }
    }
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
        wakeUpScreen: true,
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

  // Optional: Keep for foreground periodic checks
  void _startPeriodicCheck() {
    _timer = Timer.periodic(Duration(minutes: 60), (timer) async {
      final now = DateTime.now();
      if (_isWithinActiveHours(now)) {
        await _fetchTodaySteps();
      }
    });
  }

  // Schedule periodic health checks for background/terminated state
  Future<void> _scheduleHealthCheck() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 2,
        channelKey: 'step_channel',
        title: 'Health Check',
        body: 'Checking steps in background...',
        displayOnForeground: false, // Silent notification
      ),
      actionButtons: [NotificationActionButton(key: 'check_steps', label: 'Check', actionType: ActionType.SilentAction)],
      schedule: NotificationInterval(
        interval: Duration(seconds: 3600), // Every 60 minutes (in seconds)
        repeats: true,
        preciseAlarm: true, // Exact timing on Android
      ),
    );
    debugPrint('Scheduled health check');
  }

  // Handle notification actions (both view_details and check_steps)
  Future<void> _handleNotificationAction(ReceivedAction action) async {
    if (action.buttonKeyPressed == 'view_details') {
      onNavigateToMain();
    } else if (action.buttonKeyPressed == 'check_steps') {
      final now = DateTime.now();
      if (_isWithinActiveHours(now)) {
        await _fetchTodaySteps();
        if (goalReachedNotified) {
          // Cancel the schedule if goal is reached
          await AwesomeNotifications().cancelSchedule(2);
        }
      }
    }
  }

  void dispose() {
    _timer?.cancel();
    // Note: Scheduled notifications persist unless explicitly canceled
  }
}
