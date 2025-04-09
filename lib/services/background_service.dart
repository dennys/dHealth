import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart'; // Add this for permissions
import 'notification_service.dart';
import '../main.dart'; // Assuming GetIt setup is in main.dart

void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  if (isTimeout) {
    BackgroundFetch.finish(taskId);
    return;
  }
  await BackgroundService._executeTask();
  BackgroundFetch.finish(taskId);
}

class BackgroundService {
  static const String TASK_ID = "com.example.step_tracker";
  static final GetIt getIt = GetIt.instance;

  static Future<void> init() async {
    // Check and request necessary permissions
    await _requestPermissions();

    await BackgroundFetch.configure(
      BackgroundFetchConfig(
        minimumFetchInterval: await _getInterval(),
        stopOnTerminate: false,
        enableHeadless: await _isHeadlessEnabled(),
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresStorageNotLow: false,
        requiresDeviceIdle: false,
        // requiredNetworkType: NetworkType.NONE, // Removed requiredNetworkType since no network is needed
        // Removed requiredNetworkType since no network is needed
      ),
      _onBackgroundFetch,
      _onBackgroundFetchTimeout,
    );

    BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
  }

  static Future<void> _requestPermissions() async {
    // Request activity recognition permission (for steps, adjust based on your health package)
    if (await Permission.activityRecognition.isDenied) {
      await Permission.activityRecognition.request();
    }

    // Request notification permission
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  static Future<int> _getInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('fetch_interval') ?? 15; // Default 60 minutes
  }

  static Future<bool> _isHeadlessEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('headless_mode') ?? false; // Default false
  }

  static void _onBackgroundFetch(String taskId) async {
    await _executeTask();
    BackgroundFetch.finish(taskId);
  }

  static void _onBackgroundFetchTimeout(String taskId) {
    BackgroundFetch.finish(taskId);
  }

  static Future<void> _executeTask() async {
    try {
      // Check if permissions are granted before proceeding
      if (await Permission.activityRecognition.isDenied) {
        NotificationService.showPermissionDeniedNotification();
        return;
      }

      // Get goal
      final prefs = SharedPreferencesAsync();
      final goal = await prefs.getInt('dailyStepGoal') ?? 1000; // Default 6000 steps
      final steps = await _fetchTodaySteps();

      // Get today steps
      // final now = DateTime.now();
      // final midnight = DateTime(now.year, now.month, now.day);
      // List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(types: [HealthDataType.STEPS], startTime: midnight, endTime: now);
      // final int steps = healthData.fold(0, (sum, data) => sum + (data.value as NumericHealthValue).numericValue.toInt());

      if (steps >= goal) {
        NotificationService.showGoalReachedNotification(steps, goal);
      } else if (goal - steps < 1000) {
        NotificationService.showAlmostThereNotification(steps, goal);
      } else {
        NotificationService.showAlmostThereNotification(goal, steps);
      }

      // Call another function (placeholder)
      await _callAnotherFunction();
    } catch (e) {
      NotificationService.showErrorNotification(e.toString());
    }
  }

  // static Future<int> _fetchTodaySteps() async {
  //   final health = Health();
  //   final now = DateTime.now();
  //   int step = 1000;
  //   final midnight = DateTime(now.year, now.month, now.day);
  //   List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(types: [HealthDataType.STEPS], startTime: midnight, endTime: now);

  //   // Calculate the sum directly from the list
  //   step = healthData.fold<int>(0, (sum, data) => sum + (data.value as NumericHealthValue).numericValue.toInt());
  //   return step;
  // }

  static Future<int> _fetchTodaySteps() async {
    final health = Health();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    // Add debug print
    debugPrint("Fetching steps from $midnight to $now");

    List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(types: [HealthDataType.STEPS], startTime: midnight, endTime: now);

    // Check if we got any data
    debugPrint("Retrieved ${healthData.length} health data points");

    // Examine the data if available
    if (healthData.isNotEmpty) {
      for (var data in healthData) {
        debugPrint("Step data: ${data.value}");
      }
    }

    // Calculate steps
    int steps = healthData.fold<int>(0, (sum, data) => sum + (data.value as NumericHealthValue).numericValue.toInt());

    debugPrint("Calculated steps: $steps");
    return steps;
  }

  static Future<void> _callAnotherFunction() async {
    // Placeholder for future implementation
  }

  static Future<void> showHeadlessWarning() async {
    if (await _isHeadlessEnabled()) {
      NotificationService.showHeadlessModeNotification();
    }
  }
}
