import 'package:dhealth/database/database.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:health/health.dart';

class StepDataService {
  final Health health = GetIt.I<Health>();
  final StepDatabase database = GetIt.I<StepDatabase>();

  StepDataService();

  // Helper method to format date as YYYY-MM-DD
  static String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Fetch health data for the specified time range
  Future<List<HealthDataPoint>?> fetchData({required DateTime startTime, required DateTime endTime}) async {
    try {
      final types = [HealthDataType.STEPS];
      final permissions = [HealthDataAccess.READ];

      // Ensure we have permissions
      bool? hasPermissions = await health.hasPermissions(types, permissions: permissions);

      if (hasPermissions == false) {
        debugPrint("Not authorized to fetch data");
        return null;
      }

      // Get health data
      List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(types: types, startTime: startTime, endTime: endTime);

      // Remove duplicates
      return health.removeDuplicates(healthData);
    } catch (error) {
      debugPrint("Exception in fetchData: $error");
      return null;
    }
  }

  // Process and save step data by day
  Future<void> processAndSaveStepData(List<HealthDataPoint> dataPoints) async {
    Map<String, int> dailySteps = {};
    DateTime now = DateTime.now();

    for (var point in dataPoints) {
      if (point.type == HealthDataType.STEPS) {
        // Get the date part only (YYYY-MM-DD)
        String dateStr = _formatDate(point.dateFrom);

        // Add steps to the corresponding day
        dailySteps[dateStr] = (dailySteps[dateStr] ?? 0) + (point.value as NumericHealthValue).numericValue.toInt();
        // dailySteps[dateStr] = (point.value as NumericHealthValue).numericValue.toInt();
      }
    }

    // Save each day's data to the database
    for (var entry in dailySteps.entries) {
      String date = entry.key;
      int steps = entry.value;

      // Check if we already have data for this day
      final existingData = await database.getDailyStep(DateTime.parse(date));

      // If we have existing data, add to it (unless it's marked complete)
      if (existingData != null && !existingData.isComplete) {
        steps += existingData.stepCount;
      }

      // Determine if this day is complete (data is final)
      // We consider a day complete if it's before today
      bool isComplete = DateTime.parse(date).isBefore(DateTime(now.year, now.month, now.day));

      // Save to database
      await database.upsertDailyStep(date, steps, DateTime.now(), isComplete: isComplete);
    }
  }

  Future<DateTime> _calculateStartDate(DateTime now) async {
    final lastDate = await database.getLastDate();
    if (lastDate != null) {
      return lastDate.subtract(const Duration(days: 1));
    } else {
      return now.subtract(const Duration(days: 30));
    }
  }

  Future<void> syncNewData() async {
    DateTime now = DateTime.now();
    DateTime startDate = await _calculateStartDate(now); // Waits for the whole logic
    await refreshDataRange(startDate, now);
  }

  // Get only new data since last update
  // ignore: non_constant_identifier_names
  Future<void> syncNewData_Old() async {
    DateTime now = DateTime.now();
    DateTime startDate;

    // Get the last updated date from the database
    final lastDate = await database.getLastDate();

    if (lastDate != null) {
      // If we have last updated date, start from 1 day before
      // (to handle possible midnight crossovers and timezone issues)
      startDate = lastDate.subtract(const Duration(days: 1));
    } else {
      // If no previous data, start from 30 days ago
      startDate = now.subtract(const Duration(days: 30));
    }

    // Fetch and process the data
    // await database.deleteDataInRange(startDate, now);
    // final healthData = await fetchData(startTime: startDate, endTime: now);
    await refreshDataRange(startDate, now);

    // if (healthData != null && healthData.isNotEmpty) {
    //   await processAndSaveStepData(healthData);
    // }
  }

  // Refresh all data (last 30 days by default)
  Future<void> refreshAllData({int days = 30}) async {
    DateTime now = DateTime.now();
    DateTime startDate = now.subtract(Duration(days: days));

    // Clear existing data
    await database.deleteAllData();

    // Fetch and process fresh data
    final healthData = await fetchData(startTime: startDate, endTime: now);

    if (healthData != null && healthData.isNotEmpty) {
      await processAndSaveStepData(healthData);
    }
  }

  // Refresh data for a specific date range
  Future<void> refreshDataRange(DateTime start, DateTime end, {bool clearData = false}) async {
    end = end.add(const Duration(days: 1)); // Include the end date fully

    // Delete data in the specified range
    await database.deleteDataInRange(start, end);

    if (clearData) {
      //TODO implement clear
      debugPrint("Start to clear database records");
      // Clear existing data logic
    }

    // Fetch and process fresh data for the range
    final healthData = await fetchData(
      startTime: start,
      endTime: end, // Include the end date fully
    );

    if (healthData != null && healthData.isNotEmpty) {
      await processAndSaveStepData(healthData);
    }
  }
}

// 4. Example usage in a main file
Future<void> setupStepTracking() async {
  // Get a location for the database on disk
  // final appDir = await getApplicationDocumentsDirectory();
  // final dbFile = File(p.join(appDir.path, 'dHealth.sqlite'));

  // Create database instance
  // final database = StepDatabase(NativeDatabase(dbFile));

  // For test
  // final database = StepDatabase(NativeDatabase.memory());

  // Create health factory
  // final health = Health();

  // Create step data service
  final stepService = StepDataService();

  // Sync new data daily
  stepService.syncNewData();

  // To refresh all data:
  // stepService.refreshAllData();

  // To refresh a specific range:
  // stepService.refreshDataRange(
  //   DateTime(2025, 1, 1),
  //   DateTime(2025, 1, 31),
  // );
}
