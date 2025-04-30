import 'dart:io';

import 'package:dsteps/util.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

// All types available depending on platform (iOS ot Android).
List<HealthDataType> get types =>
    (Platform.isAndroid)
        ? dataTypesAndroid
        : (Platform.isIOS)
        ? dataTypesIOS
        : [];

// Set up corresponding permissions

// READ only
// List<HealthDataAccess> get permissions =>
//     types.map((e) => HealthDataAccess.READ).toList();

// Or both READ and WRITE
List<HealthDataAccess> get permissions =>
    types
        .map(
          (type) =>
              // can only request READ permissions to the following list of types on iOS
              [
                    HealthDataType.WALKING_HEART_RATE,
                    HealthDataType.ELECTROCARDIOGRAM,
                    HealthDataType.HIGH_HEART_RATE_EVENT,
                    HealthDataType.LOW_HEART_RATE_EVENT,
                    HealthDataType.IRREGULAR_HEART_RATE_EVENT,
                    HealthDataType.EXERCISE_TIME,
                  ].contains(type)
                  ? HealthDataAccess.READ
                  : HealthDataAccess.READ_WRITE,
        )
        .toList();

class PermissionService {
  static Future<bool> authorize() async {
    final health = GetIt.I<Health>();
    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    try {
      // Request activityRecognition and location
      // List<Permission> permissionsList = [Permission.location, Permission.notification];
      // if (Platform.isAndroid) {
      //   permissionsList.add(Permission.activityRecognition); // iOS doesn't need this permission
      // }

      // for (Permission permission in permissionsList) {
      //   if (!await permission.request().isGranted) {
      //     debugPrint("${permission.toString()} is not granted");
      //     return false;
      //   }
      // }

      // Request location permission
      if (!await Permission.location.request().isGranted) {
        if (await Permission.location.isPermanentlyDenied) {
          await openAppSettings();
        }
        // debugPrint("Location permission not granted");
        // return false;
      }

      // Request to access activityRecognition data, iOS doesn't need this permission
      if (Platform.isAndroid) {
        if (!await Permission.activityRecognition.request().isGranted) {
          if (await Permission.activityRecognition.isPermanentlyDenied) {
            await openAppSettings();
          }
          // debugPrint("${Permission.activityRecognition.toString()} is not granted");
          // return false;
        }
      }

      // Request notification privilege
      final bool notificationEnabled = await prefs.getBool('notification_enabled') ?? true;
      if (notificationEnabled) {
        if (!await Permission.notification.request().isGranted) {
          if (await Permission.notification.isPermanentlyDenied) {
            await openAppSettings();
          }
          // debugPrint("${Permission.notification.toString()} is not granted");
          // return false;
        }
      }

      // Request access health data
      List<HealthDataType> types = [HealthDataType.STEPS];
      List<HealthDataAccess> permissions = [HealthDataAccess.READ];
      bool? hasPermissions = await health.hasPermissions(types, permissions: permissions);
      if (hasPermissions == false) {
        bool authorized = await health.requestAuthorization(types, permissions: permissions);
        if (!authorized) {
          debugPrint("Health data authorization failed");
          // return false;
        }
      }

      // request access to read health historic data more than 30 days
      final bool isHealthDataHistoryAuthorized = await health.isHealthDataHistoryAuthorized();
      if (!isHealthDataHistoryAuthorized) {
        bool authorized = await health.requestHealthDataHistoryAuthorization();
        if (!authorized) {
          debugPrint("Health data history authorization failed");
          // return false;
        }
      }

      // request to access data in backgroud (after health v12.x)
      final bool isHealthDataInBackgroundAuthorized = await health.isHealthDataInBackgroundAuthorized();
      if (!isHealthDataInBackgroundAuthorized) {
        bool authorized = await health.requestHealthDataInBackgroundAuthorization();
        if (!authorized) {
          debugPrint("Background health data authorization failed");
          // return false;
        }
      }

      return true;
    } catch (error, stackTrace) {
      debugPrint("Exception in authorize: $error\n$stackTrace");
      return false;
    }
  }

  static Future<bool> requestStoragePermission() async {
    // For Android 10 and above, we need WRITE_EXTERNAL_STORAGE permission
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        return status.isGranted;
      }
      return true;
    }
    return true;
  }
}
