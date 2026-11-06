import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// 背景 isolate 與錯誤路徑的 log 出口。
///
/// main() 在 release 把 `debugPrint` 静音（不該把步數、DB 路徑噴到 logcat），
/// 但那只對「開發期噪音」正確；真正的失敗如果也只能用 debugPrint，正式版就等於
/// 沒有任何可觀察性（過去 import/export 全部失敗卻回報成功，就是這樣撐了這麼久）。
/// 所以：噪音留 debugPrint，錯誤一律走這裡（dart:developer 的 log 在 release 仍進 logcat）。
void appLog(String message) {
  developer.log(message, name: 'dhealth');
}

void appError(String message, Object error, [StackTrace? stackTrace]) {
  developer.log('$message: $error', name: 'dhealth.error', error: error, stackTrace: stackTrace);
  if (kDebugMode) debugPrint('$message: $error');
}
