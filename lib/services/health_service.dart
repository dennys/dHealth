import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthService {
  final Health health = GetIt.I<Health>();
  final List<HealthDataType> types;
  final List<HealthDataAccess> permissions;

  HealthService({required this.types, required this.permissions});

  /// Authorize, i.e. get permissions to access relevant health data.
  Future<bool> authorize() async {
    try {
      // 请求必要的权限（运动识别和位置权限）
      if (!await Permission.activityRecognition.request().isGranted || !await Permission.location.request().isGranted) {
        debugPrint("Required permissions not granted");
        return false;
      }

      // 检查是否已有健康数据权限
      bool? hasPermissions = await health.hasPermissions(types, permissions: permissions);
      // 强制设置为 false，因为 hasPermissions 无法判断是否有 WRITE 权限
      hasPermissions = false;
      bool authorized = false;

      if (hasPermissions == false) {
        // 请求健康数据授权
        authorized = await health.requestAuthorization(types, permissions: permissions);
      } else {
        authorized = true; // 如果已有权限，则认为已授权
      }

      if (!authorized) {
        debugPrint("Authorization failed");
      }
      return authorized;
    } catch (error) {
      debugPrint("Exception in authorize: $error");
      return false;
    }
  }

  /// Fetch health data for the specified time range.
  Future<List<HealthDataPoint>?> fetchData({required DateTime startTime, required DateTime endTime}) async {
    try {
      // 确保已授权
      bool? hasPermissions = await health.hasPermissions(types, permissions: permissions);
      if (hasPermissions == false) {
        debugPrint("Not authorized to fetch data");
        return null;
      }

      // 获取健康数据
      List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(types: types, startTime: startTime, endTime: endTime);

      // 移除重复数据（可选，根据需求决定是否需要）
      return health.removeDuplicates(healthData);
    } catch (error) {
      debugPrint("Exception in fetchData: $error");
      return null;
    }
  }

  /// Write health data (optional, can be removed if not used).
  Future<bool> writeData({required HealthDataType dataType, required double value, required DateTime startTime, required DateTime endTime}) async {
    try {
      // 确保已授权
      bool? hasPermissions = await health.hasPermissions([dataType], permissions: [HealthDataAccess.WRITE]);
      if (hasPermissions == false) {
        debugPrint("Not authorized to write data");
        return false;
      }

      // 写入健康数据
      return await health.writeHealthData(value: value, type: dataType, startTime: startTime, endTime: endTime);
    } catch (error) {
      debugPrint("Exception in writeData: $error");
      return false;
    }
  }
}
