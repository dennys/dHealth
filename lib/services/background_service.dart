import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';
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
      await NotificationService.showErrorNotification("This is callbackdispatcher, task is $stepTrackerTask, stepTrackerTask is $stepTrackerTask");
      switch (task) {
        case stepTrackerTask:
          await BackgroundService.executeTask();
          break;
      }
      return Future.value(true);
    } catch (e) {
      debugPrint("Workmanager task error: $e");
      return Future.value(false);
    }
  });
}

class BackgroundService {
  static final GetIt getIt = GetIt.instance;
  static final Health health = Health();
  static const String HEALTH_AUTH_KEY = "health_auth_token";
  static const String SYNC_FREQUENCY_KEY = "health_sync_frequency";

  static Future<void> init() async {
    // Initialize Workmanager
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);

    // // Request permissions
    // await _requestPermissions();

    // // Initialize health access
    // await _initializeHealthAccess();

    // Schedule periodic task
    await scheduleTask();
  }

  static Future<void> scheduleTask() async {
    final interval = await _getInterval();

    // Cancel any existing tasks
    await Workmanager().cancelByUniqueName(stepTrackerTask);

    // Schedule new periodic task
    await Workmanager().registerPeriodicTask(
      stepTrackerTask,
      stepTrackerTask,
      frequency: Duration(minutes: 15),
      initialDelay: Duration(seconds: 30),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );

    debugPrint("Scheduled Workmanager task with interval: $interval minutes");
  }

  static Future<void> _initializeHealthAccess() async {
    try {
      final types = [HealthDataType.STEPS];
      final permissions = [HealthDataAccess.READ];

      bool authorized = await health.requestAuthorization(types, permissions: permissions);
      debugPrint("Health authorization status: $authorized");

      if (authorized) {
        final prefs = SharedPreferencesAsync();
        await prefs.setBool(HEALTH_AUTH_KEY, true);

        final now = DateTime.now();
        final midnight = DateTime(now.year, now.month, now.day);
        await health.getHealthDataFromTypes(types: types, startTime: midnight, endTime: now);
      }
    } catch (e) {
      debugPrint("Error initializing health access: $e");
    }
  }

  static Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await [Permission.activityRecognition, Permission.notification].request();
    } else {
      await Permission.notification.request();
    }
  }

  static Future<int> _getInterval() async {
    final prefs = SharedPreferencesAsync();
    return await prefs.getInt(SYNC_FREQUENCY_KEY) ?? 15;
  }

  // Method to save user-selected interval
  static Future<void> saveSyncInterval(String interval) async {
    final prefs = SharedPreferencesAsync();
    int minutes;

    switch (interval) {
      case '15m':
        minutes = 15;
        break;
      case '30m':
        minutes = 30;
        break;
      case '1hr':
        minutes = 60;
        break;
      default:
        // Handle custom interval
        if (interval.startsWith('custom-')) {
          minutes = int.parse(interval.replaceFirst('custom-', ''));
        } else {
          minutes = 15; // Default fallback
        }
    }

    await prefs.setInt(SYNC_FREQUENCY_KEY, minutes);
    // Reschedule task with new interval
    await scheduleTask();
  }

  static Future<void> executeTask() async {
    try {
      // final prefs = SharedPreferencesAsync();
      final prefs = await SharedPreferences.getInstance();

      final dailyStepGoal = prefs.getInt('dailyStepGoal') ?? 300;

      final steps = await _fetchTodaySteps();
      debugPrint("Workmanager task fetched steps: $steps");

      if (steps >= dailyStepGoal) {
        await NotificationService.showGoalReachedNotification(steps, dailyStepGoal);
      } else if (dailyStepGoal - steps < 1000) {
        await NotificationService.showAlmostThereNotification(steps, dailyStepGoal);
      } else {
        await NotificationService.showErrorNotification("Not fit any criteria. $steps $dailyStepGoal");
      }
    } catch (e) {
      debugPrint("Task execution error: $e");
      await NotificationService.showErrorNotification("😢 Error: ${e.toString()}");
    }
  }

  // static Future<int> _fetchTodaySteps() async {
  //   try {
  //     final client = await HealthConnectClient.getOrCreate();
  //     final now = DateTime.now();
  //     final midnight = DateTime(now.year, now.month, now.day);
  //     final steps = await client.readRecords<StepCountRecord>(startTime: midnight, endTime: now);
  //     int totalSteps = steps.fold(0, (sum, record) => sum + record.count);
  //     debugPrint("Fetched steps: $totalSteps");
  //     return totalSteps;
  //   } catch (e) {
  //     debugPrint("Error fetching steps: $e");
  //     return 0;
  //   }
  // }

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
      final permissions = [HealthDataAccess.READ];

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
