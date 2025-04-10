import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'notification_service.dart';

@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  await NotificationService.showGoalReachedNotification(11111, 11111);
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
  static final Health health = Health();
  static const String HEALTH_AUTH_KEY = "health_auth_token";

  static Future<void> init() async {
    // Check and request necessary permissions
    await _requestPermissions();

    // Initialize health data access when app is in foreground
    await _initializeHealthAccess();

    if (Platform.isAndroid) {
      // Request all necessary permissions
      var statuses =
          await [
            Permission.activityRecognition,
            Permission.notification,
            Permission.ignoreBatteryOptimizations,
            Permission.scheduleExactAlarm,
          ].request();

      // Check if any permission was denied
      if (statuses.values.any((status) => status.isDenied)) {
        debugPrint('Some permissions were denied: $statuses');
        // Handle denied permissions
      }
    }

    int status = await BackgroundFetch.configure(
      BackgroundFetchConfig(
        minimumFetchInterval: 15, //await _getInterval(),
        forceAlarmManager: false, //false,
        stopOnTerminate: false, //await _isStopOnTerminateEnabled(),
        startOnBoot: true, //await _isStartOnBootEnabled(),
        enableHeadless: false,
        // requiresBatteryNotLow: false,
        // requiresCharging: false,
        // requiresStorageNotLow: false,
        // requiresDeviceIdle: false,
        requiredNetworkType: NetworkType.NONE,
      ),
      // _onBackgroundFetch,
      (String taskId) async {
        debugPrint('[BackgroundFetch] Event received: $taskId');
        _onBackgroundFetch(taskId);
        // BackgroundFetch.finish(taskId);
      },
      (String taskId) async {
        debugPrint('[BackgroundFetch] Task timeout: $taskId');
        // _onBackgroundFetchTimeout(taskId);
        BackgroundFetch.finish(taskId);
      },
    );
    if (status != 0) {
      debugPrint("BackgroundFetch failed to start: $status");
      await NotificationService.showGoalReachedNotification(22222222, 22222222);
    } else {
      debugPrint("BackgroundFetch started successfully: $status");
      await NotificationService.showGoalReachedNotification(33333, 33333);
    }

    BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
  }

  static Future<void> _initializeHealthAccess() async {
    try {
      // Request authorization for health data when app is in foreground
      final types = [HealthDataType.STEPS];
      final permissions = [HealthDataAccess.READ];

      bool authorized = await health.requestAuthorization(types, permissions: permissions);
      debugPrint("Health authorization status: $authorized");

      if (authorized) {
        // Store authorization status in shared preferences
        final prefs = SharedPreferencesAsync();
        await prefs.setBool(HEALTH_AUTH_KEY, true);

        // Fetch steps once to establish connection
        final now = DateTime.now();
        final midnight = DateTime(now.year, now.month, now.day);
        await health.getHealthDataFromTypes(types: types, startTime: midnight, endTime: now);
      }
    } catch (e) {
      debugPrint("Error initializing health access: $e");
    }
  }

  static Future<void> _requestPermissions() async {
    // Request activity recognition permission (for steps)
    if (Platform.isAndroid) {
      if (await Permission.activityRecognition.isDenied) {
        await Permission.activityRecognition.request();
      }
    }

    // Request notification permission
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  static Future<int> _getInterval() async {
    final prefs = SharedPreferencesAsync();
    final interval = await prefs.getInt('health_sync_frequency') ?? 15;
    return interval;
  }

  // In flutter, I want to let users to choose a time interval, users can choose 15m, 30m, 1hr, or custom
  // And save the result to shared_preference. is there a best practice?
  // What should I save to shared_preference? a string '15m', '30m', '1hr', 'custom'
  // When user choose 'custom', save the value into another value?
  // Or save 'custom-xxx' in the same field?

  static Future<bool> _isHeadlessEnabled() async {
    final prefs = SharedPreferencesAsync();
    final headless = await prefs.getBool('health_sync_headless_mode') ?? true; // Default true
    return headless;
  }

  static Future<bool> _isStopOnTerminateEnabled() async {
    final prefs = SharedPreferencesAsync();
    final stopOnTerminate = await prefs.getBool('health_sync_stop_on_terminate') ?? true; // Default true
    return stopOnTerminate;
  }

  static Future<bool> _isStartOnBootEnabled() async {
    final prefs = SharedPreferencesAsync();
    final startOnBoot = await prefs.getBool('health_sync_start_on_boot') ?? true; // Default true
    return startOnBoot;
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
      // Check if health auth was granted while in foreground
      final prefs = SharedPreferencesAsync();
      // final healthAuthGranted = await prefs.getBool(HEALTH_AUTH_KEY);

      // if (!healthAuthGranted) {
      //   NotificationService.showPermissionDeniedNotification();
      //   return;
      // }

      // Get goal
      final dailyStepGoal = await prefs.getInt('dailyStepGoal') ?? 10000; // Default 10000 steps

      // Get steps for today
      final steps = await _fetchTodaySteps();
      debugPrint("Background task fetched steps: $steps");

      // Send appropriate notification
      if (steps >= dailyStepGoal) {
        NotificationService.showGoalReachedNotification(steps, dailyStepGoal);
      } else if (dailyStepGoal - steps < 1000) {
        NotificationService.showAlmostThereNotification(steps, dailyStepGoal);
      } else {
        // Show progress notification
        NotificationService.showAlmostThereNotification(dailyStepGoal, steps);
        // NotificationService.showProgressNotification(steps, dailyStepGoal);
      }
    } catch (e) {
      NotificationService.showErrorNotification("Error: ${e.toString()}");
      debugPrint("Background task error: $e");
    }
  }

  static Future<int> _fetchTodaySteps() async {
    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      // For Android, we need to handle this differently
      if (Platform.isAndroid) {
        return await _fetchAndroidSteps(midnight, now);
      }

      // For iOS
      return await _fetchAppleHealthSteps(midnight, now);
    } catch (e) {
      debugPrint("Error fetching steps: $e");
      return 0;
    }
  }

  static Future<int> _fetchAndroidSteps(DateTime start, DateTime end) async {
    try {
      // Try to get step data from platform-specific APIs
      final types = [HealthDataType.STEPS];
      final permissions = [HealthDataAccess.READ];

      // Re-request authorization to ensure it's fresh
      bool authorized = await health.requestAuthorization(types, permissions: permissions);
      if (!authorized) {
        debugPrint("Health data access not authorized");
        return 0;
      }

      // Get data from Health API
      List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(types: types, startTime: start, endTime: end);

      // Calculate steps
      int steps = 0;
      if (healthData.isNotEmpty) {
        // Filter out any null values first
        var validData =
            healthData.where((data) => data.value is NumericHealthValue && (data.value as NumericHealthValue).numericValue != null).toList();

        steps = validData.fold<int>(0, (sum, data) => sum + (data.value as NumericHealthValue).numericValue.toInt());
      }

      // Fallback to aggregate data if individual data points are empty or return 0
      if (steps == 0) {
        healthData = await health.getHealthDataFromTypes(
          types: types,
          startTime: start,
          endTime: end,
          // dataSource: Platform.isAndroid ? "com.google.android.gms" : "com.apple.healthkit",
        );

        if (healthData.isNotEmpty) {
          steps = healthData.fold<int>(0, (sum, data) => sum + (data.value as NumericHealthValue).numericValue.toInt());
        }
      }

      // Last resort - get aggregated data
      if (steps == 0) {
        steps = await _getAggregatedSteps(start, end);
      }

      return steps;
    } catch (e) {
      debugPrint("Error fetching Android steps: $e");
      return await _getAggregatedSteps(start, end);
    }
  }

  static Future<int> _fetchAppleHealthSteps(DateTime start, DateTime end) async {
    try {
      final types = [HealthDataType.STEPS];
      final permissions = [HealthDataAccess.READ];

      bool authorized = await health.requestAuthorization(types, permissions: permissions);
      if (!authorized) {
        debugPrint("Health data access not authorized");
        return 0;
      }

      List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(types: types, startTime: start, endTime: end);

      int steps = 0;
      if (healthData.isNotEmpty) {
        steps = healthData.fold<int>(0, (sum, data) => sum + (data.value as NumericHealthValue).numericValue.toInt());
      }

      // If no steps found, try the aggregated method
      if (steps == 0) {
        steps = await _getAggregatedSteps(start, end);
      }

      return steps;
    } catch (e) {
      debugPrint("Error fetching Apple Health steps: $e");
      return await _getAggregatedSteps(start, end);
    }
  }

  static Future<int> _getAggregatedSteps(DateTime start, DateTime end) async {
    try {
      int? steps = await health.getTotalStepsInInterval(start, end);
      return steps ?? 0;
    } catch (e) {
      debugPrint("Error getting aggregated steps: $e");
      return 0;
    }
  }

  static Future<void> showHeadlessWarning() async {
    if (await _isHeadlessEnabled()) {
      NotificationService.showHeadlessModeNotification();
    }
  }
}
