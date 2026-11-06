import 'package:get_it/get_it.dart';
import 'package:health/health.dart';

import 'database/database.dart';
import 'database/util.dart';
import 'services/data_service.dart';

/// 依賴註冊的唯一入口。
///
/// 背景 isolate 是**另一個獨立的 GetIt**：以前只有 main() 會 register，背景那边
/// 從沒注册過，所以 WorkManager 的任務其實從來沒有寫進資料庫（todo 裡「殺 app 後
/// 有沒有寫進 DB」那一項，答案是沒有）。兩邊都走這裡就不會再漏。
final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  if (!getIt.isRegistered<Health>()) {
    getIt.registerLazySingleton<Health>(() => Health());
  }
  if (!getIt.isRegistered<StepDatabase>()) {
    getIt.registerSingleton<StepDatabase>(await openStepDatabase());
  }
  if (!getIt.isRegistered<StepDataService>()) {
    getIt.registerLazySingleton<StepDataService>(() => StepDataService());
  }
}
