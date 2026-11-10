import 'package:get_it/get_it.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database/database.dart';
import 'database/util.dart';
import 'services/background_service.dart';
import 'services/data_service.dart';
import 'services/notification_service.dart';
import 'services/permission_service.dart';

/// 依賴註冊的唯一入口。
///
/// 背景 isolate 是**另一個獨立的 GetIt**：以前只有 main() 會 register，背景那边
/// 從沒注册過，所以 WorkManager 的任務其實從來沒有寫進資料庫（todo 裡「殺 app 後
/// 有沒有寫進 DB」那一項，答案是沒有）。兩邊都走這裡就不會再漏。
///
/// 服務本身不碰 GetIt（constructor injection）：GetIt 只是「誰來 new」的便利層，
/// 測試直接 new 服務、注入 mock，不需要先註冊整個世界。
final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  if (!getIt.isRegistered<Health>()) {
    getIt.registerLazySingleton<Health>(() => Health());
  }
  if (!getIt.isRegistered<StepDatabase>()) {
    getIt.registerSingleton<StepDatabase>(await openStepDatabase());
  }
  if (!getIt.isRegistered<SharedPreferencesAsync>()) {
    getIt.registerSingleton<SharedPreferencesAsync>(SharedPreferencesAsync());
  }
  if (!getIt.isRegistered<StepDataService>()) {
    getIt.registerLazySingleton<StepDataService>(() => StepDataService(getIt<Health>(), getIt<StepDatabase>()));
  }
  if (!getIt.isRegistered<NotificationService>()) {
    getIt.registerLazySingleton<NotificationService>(() => NotificationService(getIt<SharedPreferencesAsync>()));
  }
  if (!getIt.isRegistered<PermissionService>()) {
    getIt.registerLazySingleton<PermissionService>(() => PermissionService(getIt<Health>(), getIt<SharedPreferencesAsync>()));
  }
  if (!getIt.isRegistered<BackgroundService>()) {
    getIt.registerLazySingleton<BackgroundService>(() => BackgroundService(getIt<StepDataService>(), getIt<NotificationService>(), getIt<SharedPreferencesAsync>()));
  }
}