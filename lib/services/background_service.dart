import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import 'package:workmanager/workmanager.dart';
import 'dart:io' show Platform;
import 'notification_service.dart';
import 'package:flutter/services.dart';

// Define the task key
const String stepTrackerTask = "com.example.step_tracker";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // This is for debug
      // await NotificationService.showErrorNotification("This is callbackdispatcher, task is $stepTrackerTask, stepTrackerTask is $stepTrackerTask");
      switch (task) {
        case stepTrackerTask:
          await BackgroundService.executeTask(inputData);
          break;
      }
      return true;
    } catch (e) {
      debugPrint("Workmanager task error: $e");
      return false;
    }
  });
}

class BackgroundService {
  static final GetIt getIt = GetIt.instance;
  static final Health health = Health();
  static const String _syncFrequencyKey = "health_sync_frequency";

  static Future<void> init() async {
    // Initialize Workmanager
    // (workmanager 0.10: isInDebugMode 已廢除且無作用，改用 WorkmanagerDebug handlers)
    await Workmanager().initialize(callbackDispatcher);

    // Schedule periodic task
    await scheduleTask();
  }

  static Future<void> scheduleTask() async {
    final prefs = SharedPreferencesAsync();
    final int interval = await prefs.getInt(_syncFrequencyKey) ?? 15;
    final int dailyStepGoal = await prefs.getInt('dailyStepGoal') ?? 300;
    final bool notificationEnabled = await prefs.getBool('notification_enabled') ?? true;

    // final steps = await _fetchTodaySteps();
    // debugPrint("Workmanager task fetched steps: $steps");

    // Cancel any existing tasks
    await Workmanager().cancelByUniqueName(stepTrackerTask);

    // Schedule new periodic task
    await Workmanager().registerPeriodicTask(
      stepTrackerTask,
      stepTrackerTask,
      frequency: Duration(minutes: interval),
      initialDelay: Duration(seconds: 30),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      inputData: <String, dynamic>{'dailyStepGoal': dailyStepGoal, 'notificationEnabled': notificationEnabled},
    );

    debugPrint("Scheduled Workmanager task with interval: $interval minutes");
  }

  static Future<void> executeTask(Map<String, dynamic>? inputData) async {
    try {
      final int dailyStepGoal = inputData?['dailyStepGoal'] ?? 327;
      final bool notificationEnabled = inputData?['notificationEnabled'] ?? true;

      final steps = await _fetchTodaySteps();
      debugPrint("Workmanager task fetched steps: $steps");

      if (notificationEnabled) {
        if (steps >= dailyStepGoal) {
          await NotificationService.showGoalReachedNotification(steps, dailyStepGoal);
        } else if (dailyStepGoal - steps < 1000) {
          await NotificationService.showAlmostThereNotification(steps, dailyStepGoal);
        } else {
          await NotificationService.showErrorNotification("Not fit any criteria. $steps $dailyStepGoal");
        }
      }
    } catch (e) {
      debugPrint("Task execution error: $e");
      await NotificationService.showErrorNotification("😢 Error: ${e.toString()}");
    }
  }

  static Future<int> _fetchTodaySteps() async {
    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      if (Platform.isAndroid) {
        return await _fetchAndroidSteps(midnight, now);
      }
      return await _fetchAppleHealthSteps(midnight, now);
    } catch (e) {
      debugPrint("Error fetching steps: $e");
      return 0;
    }
  }

  static Future<int> _fetchAndroidSteps(DateTime start, DateTime end) async {
    try {
      // bool authorized = await health.requestAuthorization(types, permissions: permissions);
      // if (!authorized) return 0;

      int steps = await getQ1(start, end);
      if (steps == 0) {
        steps = await _getAggregatedSteps(start, end);
      }

      return steps;
    } catch (e) {
      debugPrint("Error fetching Android steps: $e");
      return await _getAggregatedSteps(start, end);
    }
  }

  /// Define a platform channel for communication with native code
  static const MethodChannel platform = MethodChannel('com.example.health');

  /// Fetches health data from Android Health Connect for given types and time range.
  /// [types]: List of data types (e.g., ['steps', 'heart_rate']).
  /// [startTime]: Start time as DateTime.
  /// [endTime]: End time as DateTime.
  /// Returns a Map with data type as key and list of values as value.
  static Future<List<HealthDataPoint>> getHealthDataFromTypes({
    required List<String> types,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      // Convert DateTime to ISO 8601 string for platform channel
      final result = await platform.invokeMethod('getHealthData', {
        'types': types,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
      });

      // Parse the result as a List<Map> and convert to List<HealthDataPoint>
      final List<dynamic> dataList = result as List<dynamic>;
      return dataList.map((item) => HealthDataPoint.fromJson(item as Map<String, dynamic>)).toList();
    } on PlatformException catch (e) {
      throw Exception('Failed to get health data: ${e.message}');
    }
  }

  static Future<int> getQ1(DateTime start, DateTime end) async {
    final types = [HealthDataType.STEPS];
    final permissions = [HealthDataAccess.READ];

    bool? hasPermission = await health.hasPermissions(types, permissions: permissions);
    if (!hasPermission!) {
      debugPrint("No permission for health data in background");
      await NotificationService.showErrorNotification("No privilege");
      return 999;
    }

    List<HealthDataPoint> healthData = await getHealthDataFromTypes(
      types: ['steps'], // Add more types like 'heart_rate' if needed
      startTime: start,
      endTime: end,
    );

    // List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(types: types, startTime: start, endTime: end);
    int steps = healthData.fold<int>(0, (sum, data) => sum + (data.value as NumericHealthValue).numericValue.toInt());
    await NotificationService.showErrorNotification("debug for steps: $steps");
    return steps;
  }

  static Future<int> _fetchAppleHealthSteps(DateTime start, DateTime end) async {
    try {
      final types = [HealthDataType.STEPS];
      // final permissions = [HealthDataAccess.READ];

      // bool authorized = await health.requestAuthorization types, permissions: permissions);
      // if (!authorized) return 0;

      List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(types: types, startTime: start, endTime: end);

      int steps = healthData.fold<int>(0, (sum, data) => sum + (data.value as NumericHealthValue).numericValue.toInt());

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
}
