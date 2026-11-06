import 'package:dhealth/database/util.dart';
import 'package:dhealth/generated/l10n/app_localizations.dart';
import 'package:dhealth/services/data_service.dart';

/// 把「原因」翻成使用者看得懂的話。
///
/// 之前是服務層直接吐硬編中文（`'Health Connect 讀取失敗'`）進 SnackBar 與通知，
/// 於是英文介面會混出中文、也沒辦法翻譯。慣例跟 `PermissionFailure` 一樣：
/// **服務層只回 enum，字串由這一支集中取**（背景 isolate 沒有 context，
/// 用 `NotificationService` 那側的 `lookupAppLocalizations` 取得 AppLocalizations 再傳進來）。
extension StepSyncStatusLabel on StepSyncStatus {
  String label(AppLocalizations l10n) => switch (this) {
    StepSyncStatus.success => l10n.syncSuccess,
    StepSyncStatus.permissionDenied => l10n.syncReasonPermissionDenied,
    StepSyncStatus.unavailable => l10n.syncReasonUnavailable,
    StepSyncStatus.invalidRange => l10n.syncReasonInvalidRange,
  };
}

extension ImportFailureLabel on ImportFailure {
  String label(AppLocalizations l10n) => switch (this) {
    ImportFailure.fileNotFound => l10n.importReasonFileNotFound,
    ImportFailure.noData => l10n.importReasonNoData,
    ImportFailure.readFailed => l10n.importReasonReadFailed,
  };
}
