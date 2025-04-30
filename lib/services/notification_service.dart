import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const String _defaultChannel = 'dhealth_step_tracker_channel';

  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, // Use default icon
      // 'resource://drawable/res_app_icon',
      [
        NotificationChannel(
          channelKey: _defaultChannel,
          channelName: 'Step Tracker Notifications',
          channelDescription: 'Notifications for step tracking',
          // defaultColor: const Color(0xFF9D50BB),
          defaultColor: Colors.green,
          ledColor: Colors.white,
        ),
      ],
    );
  }

  static Future<void> _showNotification({required String title, required String body, String channelKey = _defaultChannel}) async {
    PermissionStatus status = await Permission.notification.status;

    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    final bool notificationEnabled = await prefs.getBool('notification_enabled') ?? true;

    // final prefs = await SharedPreferences.getInstance();
    // final bool notification_enabled = prefs.getBool('notification_enabled') ?? true;

    if (notificationEnabled && status.isGranted) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(id: DateTime.now().millisecondsSinceEpoch ~/ 1000, channelKey: channelKey, title: title, body: body),
      );
    } else {
      status = await Permission.notification.request();
      if (status.isGranted) {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(id: DateTime.now().millisecondsSinceEpoch ~/ 1000, channelKey: channelKey, title: title, body: body),
        );
      }
    }
  }

  static Future<void> showGoalReachedNotification(int steps, int goal) async {
    // await AwesomeNotifications().createNotification(
    //   content: NotificationContent(
    //     id: 1,
    //     channelKey: 'dhealth_step_tracker_channel',
    //     title: 'Goal Reached!',
    //     body: 'Congratulations! You’ve hit $steps steps, surpassing your goal of $goal.',
    //   ),
    // );
    await _showNotification(title: 'Goal Reached!', body: 'Congratulations! You’ve hit $steps steps, surpassing your goal of $goal.');
  }

  static Future<void> showAlmostThereNotification(int steps, int goal) async {
    // await AwesomeNotifications().createNotification(
    //   content: NotificationContent(
    //     id: 2,
    //     channelKey: 'dhealth_step_tracker_channel',
    //     title: 'Almost There!',
    //     body: 'You’re at $steps steps, just ${goal - steps} steps away from your goal of $goal!',
    //   ),
    // );
    await _showNotification(title: 'Almost There!', body: 'You’re at $steps steps, just ${goal - steps} steps away from your goal of $goal!');
  }

  static Future<void> showErrorNotification(String error) async {
    // await AwesomeNotifications().createNotification(
    //   content: NotificationContent(id: 3, channelKey: 'dhealth_step_tracker_channel', title: 'Error Occurred', body: 'Something went wrong: $error'),
    // );
    await _showNotification(title: 'Error Occurred', body: 'Something went wrong: $error');
  }

  static Future<void> showHeadlessModeNotification() async {
    // await AwesomeNotifications().createNotification(
    //   content: NotificationContent(
    //     id: 4,
    //     channelKey: 'dhealth_step_tracker_channel',
    //     title: 'Headless Mode Active',
    //     body: 'Step tracking continues even if the app is closed.',
    //   ),
    // );
    await _showNotification(title: 'Headless Mode Active', body: 'Step tracking continues even if the app is closed.');
  }

  static Future<void> showPermissionDeniedNotification() async {
    // await AwesomeNotifications().createNotification(
    //   content: NotificationContent(
    //     id: 5,
    //     channelKey: 'dhealth_step_tracker_channel',
    //     title: 'Permission Denied',
    //     body: 'Please grant activity recognition permission to track steps.',
    //   ),
    // );
    await _showNotification(title: 'Permission Denied', body: 'Please grant activity recognition permission to track steps.');
  }
}
