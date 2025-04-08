import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, // Use default icon
      [
        NotificationChannel(
          channelKey: 'step_tracker_channel',
          channelName: 'Step Tracker Notifications',
          channelDescription: 'Notifications for step tracking',
          defaultColor: const Color(0xFF9D50BB),
          ledColor: Colors.white,
        ),
      ],
    );
  }

  static Future<void> showGoalReachedNotification(int steps, int goal) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'step_tracker_channel',
        title: 'Goal Reached!',
        body: 'Congratulations! You’ve hit $steps steps, surpassing your goal of $goal.',
      ),
    );
  }

  static Future<void> showAlmostThereNotification(int steps, int goal) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 2,
        channelKey: 'step_tracker_channel',
        title: 'Almost There!',
        body: 'You’re at $steps steps, just ${goal - steps} steps away from your goal of $goal!',
      ),
    );
  }

  static Future<void> showErrorNotification(String error) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(id: 3, channelKey: 'step_tracker_channel', title: 'Error Occurred', body: 'Something went wrong: $error'),
    );
  }

  static Future<void> showHeadlessModeNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 4,
        channelKey: 'step_tracker_channel',
        title: 'Headless Mode Active',
        body: 'Step tracking continues even if the app is closed.',
      ),
    );
  }

  static Future<void> showPermissionDeniedNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 5,
        channelKey: 'step_tracker_channel',
        title: 'Permission Denied',
        body: 'Please grant activity recognition permission to track steps.',
      ),
    );
  }
}
