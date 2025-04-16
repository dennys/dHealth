import 'dart:io';

import 'package:dsteps/util.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

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
  /// Authorize, i.e. get permissions to access relevant health data.
  static Future<bool> authorize() async {
    final health = GetIt.I<Health>();
    try {
      // Request activityRecognition and location
      List<Permission> permissionsList = [Permission.location, Permission.notification];
      if (Platform.isAndroid) {
        permissionsList.add(Permission.activityRecognition); // iOS doesn't need this permission
      }

      for (Permission permission in permissionsList) {
        if (!await permission.request().isGranted) {
          debugPrint("${permission.toString()} is not granted");
          return false;
        }
      }

      // Request access health data
      List<HealthDataType> type1 = [HealthDataType.STEPS];
      List<HealthDataAccess> permission1 = [HealthDataAccess.READ];
      // bool? hasPermissions = await health.hasPermissions(types, permissions: permissions);
      bool? hasPermissions = await health.hasPermissions(type1, permissions: permission1);
      if (hasPermissions == false) {
        // await health.requestAuthorization(types, permissions: permissions);
        await health.requestAuthorization(type1, permissions: permission1);
      }

      // 1. backgroud needs READ_HEALTH_DATA_IN_BACKGROUND
      // https: //developer.android.com/health-and-fitness/guides/health-connect/develop/read-data?hl=zh-tw
      // <uses-permission android:name="android.permission.health.READ_HEALTH_DATA_IN_BACKGROUND" />

      // request access to read health historic data
      await health.requestHealthDataHistoryAuthorization(); // for android.permission.health.READ_HEALTH_DATA_HISTORY

      return true;
    } catch (error) {
      debugPrint("Exception in authorize: $error");
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
