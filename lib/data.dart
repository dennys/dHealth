import 'dart:io';
import 'dart:math';

import 'package:health/health.dart';

import 'util.dart';

// TODO 和 main.dart 重複
// All types available depending on platform (iOS ot Android).
// List<HealthDataType> get types =>
//     (Platform.isAndroid)
//         ? dataTypesAndroid
//         : (Platform.isIOS)
//         ? dataTypesIOS
//         : [];

/// Add some random health data.
/// Note that you should ensure that you have permissions to add the
/// following data types.
Future<bool> addData(Health health) async {
  final now = DateTime.now();
  final earlier = now.subtract(const Duration(minutes: 20));

  // Add data for supported types
  // NOTE: These are only the ones supported on Androids new API Health Connect.
  // Both Android's Health Connect and iOS' HealthKit have more types that we support in the enum list [HealthDataType]
  // Add more - like AUDIOGRAM, HEADACHE_SEVERE etc. to try them.
  bool success = true;

  // misc. health data examples using the writeHealthData() method
  success &= await health.writeHealthData(
    value: 1.925,
    type: HealthDataType.HEIGHT,
    startTime: earlier,
    endTime: now,
    recordingMethod: RecordingMethod.manual,
  );
  success &= await health.writeHealthData(value: 90, type: HealthDataType.WEIGHT, startTime: now, recordingMethod: RecordingMethod.manual);
  success &= await health.writeHealthData(
    value: 90,
    type: HealthDataType.HEART_RATE,
    startTime: earlier,
    endTime: now,
    recordingMethod: RecordingMethod.manual,
  );

  // write step data
  final random = Random();
  final randomStep = random.nextInt(100).toDouble() + 1; // Random value between 1 and 100

  final randomDaysAgo = random.nextInt(7); // Random day within the past week
  final startTime = now.subtract(Duration(days: randomDaysAgo, hours: random.nextInt(24), minutes: random.nextInt(60)));
  final endTime = startTime.add(Duration(minutes: random.nextInt(30) + 1)); // Ensuring duration is 1~29 minutes

  success &= await health.writeHealthData(
    value: randomStep,
    type: HealthDataType.STEPS,
    startTime: startTime,
    endTime: endTime,
    recordingMethod: RecordingMethod.manual,
  );
  success &= await health.writeHealthData(value: 200, type: HealthDataType.ACTIVE_ENERGY_BURNED, startTime: earlier, endTime: now);
  success &= await health.writeHealthData(value: 70, type: HealthDataType.HEART_RATE, startTime: earlier, endTime: now);
  if (Platform.isIOS) {
    success &= await health.writeHealthData(value: 30, type: HealthDataType.HEART_RATE_VARIABILITY_SDNN, startTime: earlier, endTime: now);
  } else {
    success &= await health.writeHealthData(value: 30, type: HealthDataType.HEART_RATE_VARIABILITY_RMSSD, startTime: earlier, endTime: now);
  }
  success &= await health.writeHealthData(value: 37, type: HealthDataType.BODY_TEMPERATURE, startTime: earlier, endTime: now);
  success &= await health.writeHealthData(value: 105, type: HealthDataType.BLOOD_GLUCOSE, startTime: earlier, endTime: now);
  success &= await health.writeHealthData(value: 1.8, type: HealthDataType.WATER, startTime: earlier, endTime: now);

  // different types of sleep
  success &= await health.writeHealthData(value: 0.0, type: HealthDataType.SLEEP_REM, startTime: earlier, endTime: now);
  success &= await health.writeHealthData(value: 0.0, type: HealthDataType.SLEEP_ASLEEP, startTime: earlier, endTime: now);
  success &= await health.writeHealthData(value: 0.0, type: HealthDataType.SLEEP_AWAKE, startTime: earlier, endTime: now);
  success &= await health.writeHealthData(value: 0.0, type: HealthDataType.SLEEP_DEEP, startTime: earlier, endTime: now);
  success &= await health.writeHealthData(value: 22, type: HealthDataType.LEAN_BODY_MASS, startTime: earlier, endTime: now);

  // specialized write methods
  success &= await health.writeBloodOxygen(saturation: 98, startTime: earlier, endTime: now);
  success &= await health.writeWorkoutData(
    activityType: HealthWorkoutActivityType.AMERICAN_FOOTBALL,
    title: "Random workout name that shows up in Health Connect",
    start: now.subtract(const Duration(minutes: 15)),
    end: now,
    totalDistance: 2430,
    totalEnergyBurned: 400,
  );
  success &= await health.writeBloodPressure(systolic: 90, diastolic: 80, startTime: now);
  success &= await health.writeMeal(
    mealType: MealType.SNACK,
    startTime: earlier,
    endTime: now,
    caloriesConsumed: 1000,
    carbohydrates: 50,
    protein: 25,
    fatTotal: 50,
    name: "Banana",
    caffeine: 0.002,
    vitaminA: 0.001,
    vitaminC: 0.002,
    vitaminD: 0.003,
    vitaminE: 0.004,
    vitaminK: 0.005,
    b1Thiamin: 0.006,
    b2Riboflavin: 0.007,
    b3Niacin: 0.008,
    b5PantothenicAcid: 0.009,
    b6Pyridoxine: 0.010,
    b7Biotin: 0.011,
    b9Folate: 0.012,
    b12Cobalamin: 0.013,
    calcium: 0.015,
    copper: 0.016,
    iodine: 0.017,
    iron: 0.018,
    magnesium: 0.019,
    manganese: 0.020,
    phosphorus: 0.021,
    potassium: 0.022,
    selenium: 0.023,
    sodium: 0.024,
    zinc: 0.025,
    water: 0.026,
    molybdenum: 0.027,
    chloride: 0.028,
    chromium: 0.029,
    cholesterol: 0.030,
    fiber: 0.031,
    fatMonounsaturated: 0.032,
    fatPolyunsaturated: 0.033,
    fatUnsaturated: 0.065,
    fatTransMonoenoic: 0.65,
    fatSaturated: 066,
    sugar: 0.067,
    recordingMethod: RecordingMethod.manual,
  );

  // Store an Audiogram - only available on iOS
  // const frequencies = [125.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0];
  // const leftEarSensitivities = [49.0, 54.0, 89.0, 52.0, 77.0, 35.0];
  // const rightEarSensitivities = [76.0, 66.0, 90.0, 22.0, 85.0, 44.5];
  // success &= await health.writeAudiogram(
  //   frequencies,
  //   leftEarSensitivities,
  //   rightEarSensitivities,
  //   now,
  //   now,
  //   metadata: {
  //     "HKExternalUUID": "uniqueID",
  //     "HKDeviceName": "bluetooth headphone",
  //   },
  // );

  success &= await health.writeMenstruationFlow(flow: MenstrualFlow.medium, isStartOfCycle: true, startTime: earlier, endTime: now);

  // Available on iOS 16.0+ only
  if (Platform.isIOS) {
    success &= await health.writeHealthData(
      value: 22,
      type: HealthDataType.WATER_TEMPERATURE,
      startTime: earlier,
      endTime: now,
      recordingMethod: RecordingMethod.manual,
    );

    success &= await health.writeHealthData(
      value: 55,
      type: HealthDataType.UNDERWATER_DEPTH,
      startTime: earlier,
      endTime: now,
      recordingMethod: RecordingMethod.manual,
    );
  }

  // TODO 以下暫時 mark
  // setState(() {
  //   _state = success ? AppState.DATA_ADDED : AppState.DATA_NOT_ADDED;
  // });
  return success;
}

/// Delete some random health data.
Future<bool> deleteData(Health health, List<HealthDataType> typesToProcess) async {
  final now = DateTime.now();
  final earlier = now.subtract(const Duration(hours: 24));

  bool success = true;
  for (HealthDataType type in typesToProcess) {
    success &= await health.delete(type: type, startTime: earlier, endTime: now);
  }

  // TODO 以下暫時 mark
  // setState(() {
  //   _state = success ? AppState.DATA_DELETED : AppState.DATA_NOT_DELETED;
  // });
  return success;
}
