// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get oooooCommon => '';

  @override
  String get cancel => '取消';

  @override
  String get interval => '間隔';

  @override
  String get minutesUnit => '分鐘';

  @override
  String get hoursUnit => '小時';

  @override
  String get save => '儲存';

  @override
  String get custom => '自訂';

  @override
  String get menu => '選單';

  @override
  String get oooooAbout => '';

  @override
  String get about => '關於';

  @override
  String get aboutDescription =>
      'dHealth 只從 Health Connect 讀你的每日步數，並依小時、天、週、月呈現。資料留在這台裝置上。';

  @override
  String get platformSupportDesc =>
      'Android 13 以上，需 Health Connect 與 Google Play services。iOS 尚未支援。';

  @override
  String get platformSupportDesc_xxx =>
      '支援 Health Connect（安卓）和 HealthKit（iOS）。';

  @override
  String get features => '功能';

  @override
  String get healthTracking => '每日步數';

  @override
  String get healthTrackingDesc => '取自 Health Connect 的步數，含小時／每日／每週／每月圖表。';

  @override
  String get importExportDesc => '使用 SQLite 文件備份或還原您的數據。';

  @override
  String get platformSupport => '平台支援';

  @override
  String get version => '版本';

  @override
  String get contact => '聯繫';

  @override
  String contactDesc(String email) {
    return '如需支援或想回報問題，請写信給：$email';
  }

  @override
  String get oooooSetup => '';

  @override
  String get setup => '設定';

  @override
  String get interface => '介面';

  @override
  String get language => '語言';

  @override
  String get selectLanguage => '選擇語言';

  @override
  String get theme => '主題';

  @override
  String get selectTheme => '選擇主題';

  @override
  String get followSystem => '跟隨系統';

  @override
  String get english => '英文';

  @override
  String get traditionalChinese => '繁體中文';

  @override
  String get simplifiedChinese => '簡體中文';

  @override
  String get light => '淺色';

  @override
  String get dark => '深色';

  @override
  String get healthDataSync => '健康數據同步';

  @override
  String get healthDataSyncDesc => '設定如何從您的健康應用程式複製健康數據到此應用程式。';

  @override
  String get enableBackgroundSync => '啟用背景同步';

  @override
  String get syncFrequency => '同步頻率';

  @override
  String get customSyncTitle => '自訂同步頻率';

  @override
  String get every15Minutes => '每15分鐘';

  @override
  String get every30Minutes => '每30分鐘';

  @override
  String get every1Hour => '每小時';

  @override
  String get selectStartTime => '選擇開始時間';

  @override
  String get selectEndTime => '選擇結束時間';

  @override
  String get activeHours => '活動時間';

  @override
  String get hourly => '每小時';

  @override
  String get daily => '每天';

  @override
  String get dailyStepGoal => '每日目標';

  @override
  String get setDailyStepGoal => '設定每日目標';

  @override
  String get steps => '步數';

  @override
  String get displaySettings => '顯示設定';

  @override
  String get showCumulativeSteps => '顯示累積步數';

  @override
  String get showDailyStepGoal => '顯示每日目標';

  @override
  String get oooooNotificationSetup => '';

  @override
  String get notificationSettings => '通知設定';

  @override
  String get enableNotifications => '啟用通知';

  @override
  String get enableNotificationsDescription => '開啟或關閉通知。';

  @override
  String get notificationFrequency => '通知頻率';

  @override
  String get notificationFrequencyDescription => '接收通知的頻率。';

  @override
  String get notificationTypes => '通知類型';

  @override
  String get reachGoalNotification => '目標達成';

  @override
  String get reachGoalNotificationDescription => '達到目標時通知。';

  @override
  String get motivationNotification => '激勵（接近達成）';

  @override
  String get motivationNotificationDescription => '接近目標時鼓勵。';

  @override
  String get motivationTimeLimit => '激勵頻率限制';

  @override
  String get motivationTimeLimitDescription => '激勵通知之間的最小時間間隔。';

  @override
  String get exceptionNotification => '異常情況';

  @override
  String get exceptionNotificationDescription => '通知異常或錯誤。';

  @override
  String get customFrequency => '自訂頻率';

  @override
  String get minutesLabel => '分鐘';

  @override
  String get enterMinutes => '輸入分鐘數';

  @override
  String get ok => '確定';

  @override
  String minutes(Object count) {
    return '$count 分鐘';
  }

  @override
  String hours(Object count) {
    return '$count 小時';
  }

  @override
  String get notification => '通知';

  @override
  String get notificationAppearance => '通知外觀';

  @override
  String get notificationSound => '通知聲音';

  @override
  String get notificationSoundDescription => '收到通知時播放聲音。';

  @override
  String get notificationVibration => '震動';

  @override
  String get notificationVibrationDescription => '收到通知時震動。';

  @override
  String get notificationPriority => '通知優先級';

  @override
  String get notificationPriorityDescription => '設定通知的重要性。';

  @override
  String get lowPriority => '低';

  @override
  String get defaultPriority => '預設';

  @override
  String get highPriority => '高';

  @override
  String get notificationTimeWindow => '通知時間範圍';

  @override
  String get startTime => '開始時間';

  @override
  String get startTimeDescription => '接收通知的最早時間。';

  @override
  String get endTime => '結束時間';

  @override
  String get endTimeDescription => '接收通知的最晚時間。';

  @override
  String get importExport => '導入/導出';

  @override
  String get import => '匯入';

  @override
  String get importFromPhone => '從手機匯入';

  @override
  String get importFromFile => '從檔案匯入';

  @override
  String get importClearData => '匯入前清除當前數據';

  @override
  String get dateRange => '匯入日期範圍';

  @override
  String get startDate => '開始日期';

  @override
  String get endDate => '結束日期';

  @override
  String get importIncremental => '增量匯入';

  @override
  String get importSuccess => '匯入成功完成';

  @override
  String get importFailed => '匯入失敗';

  @override
  String get importIncrementalDesc => '僅導入自上次導入以來的新數據';

  @override
  String get importFromPhoneDesc => '從您的手機導入步數數據';

  @override
  String get importFromFileDesc => '從之前導出的文件導入';

  @override
  String get exportOptions => '導出選項';

  @override
  String get export => '匯出';

  @override
  String get exportToFile => '匯出到檔案';

  @override
  String get exportToCSV => '匯出為 CSV';

  @override
  String get shareDatabaseFile => '匯出到雲端';

  @override
  String get exportSuccess => '匯出成功完成';

  @override
  String get exportFailed => '匯出失敗';

  @override
  String get widgets => '小工具';

  @override
  String chartTitle(int steps, int average) {
    return '過去 $steps 天，平均 $average 步';
  }

  @override
  String todaySteps(int steps) {
    return '今日步數：$steps';
  }

  @override
  String get stepGoalReachedTitle => '步數目標達成！';

  @override
  String stepGoalReachedBody(int steps) {
    return '你今天已經走了 $steps 步，太棒了！';
  }

  @override
  String get motivationTitle => '就差一點！';

  @override
  String motivationBody(int gap, int goal) {
    return '距離 $goal 步的目標還差 $gap 步！';
  }

  @override
  String get viewDetails => '查看詳情';

  @override
  String get today => '今天';

  @override
  String get days => '天';

  @override
  String get weeks => '週';

  @override
  String get months => '月';

  @override
  String get years => '年';

  @override
  String get average => '平均';

  @override
  String get monday => '星期一';

  @override
  String get tuesday => '星期二';

  @override
  String get wednesday => '星期三';

  @override
  String get thursday => '星期四';

  @override
  String get friday => '星期五';

  @override
  String get saturday => '星期六';

  @override
  String get sunday => '星期日';

  @override
  String get noDataInDatabase => '數據庫中無可用數據';

  @override
  String get past => '過去';

  @override
  String get periods => '期';

  @override
  String get previousPage => '更早';

  @override
  String get nextPage => '更晚';

  @override
  String get latest => '最近';

  @override
  String get chartHelpTitle => '圖表說明';

  @override
  String get hourlyStepsChartExplanation =>
      '此圖表顯示您的每小時步數。\n\n - 「累積」開關：切換以查看當天累積的總步數。\n - 「目標」開關：切換以顯示您的每日步數目標為一條水平線。\n 調整這些設定來自訂您的視圖！';

  @override
  String get chartHelpContent => '此圖表顯示您在所選期間的步數。柱狀圖表示每日/每週/每月/每年的步數，虛線表示平均步數。';

  @override
  String get syncNow => '立即同步';

  @override
  String get syncSuccess => '已同步';

  @override
  String get syncFailed => '同步失敗';

  @override
  String get retry => '重試';

  @override
  String get permissionActivityRecognitionMissing => '未授予「身體活動」權限，步數會一直是 0。';

  @override
  String get permissionHealthReadMissing => 'Health Connect 未允許讀取你的步數。';

  @override
  String get healthConnectUnavailable => '這條裝置上沒有 Health Connect。';

  @override
  String get healthConnectUnavailableDesc => '請從 Play Store 安裝，才能讀取步數資料。';

  @override
  String get installHealthConnect => '安裝 Health Connect';

  @override
  String chartError(String error) {
    return '圖表錯誤：$error';
  }

  @override
  String get cumulativeShort => '累計';

  @override
  String get goalShort => '目標';

  @override
  String hourSteps(int hour, int steps) {
    return '$hour:00\n$steps 步';
  }

  @override
  String get percentOfAverage => '日均占比';

  @override
  String get importing => '正在匯入資料…';

  @override
  String percentComplete(String percent) {
    return '$percent% 完成';
  }

  @override
  String get dateRangeTo => '至';

  @override
  String get noDirectorySelected => '未選擇資料夾';

  @override
  String exportedTo(String path) {
    return '已匯出到 $path';
  }

  @override
  String importedDays(int days) {
    return '已匯入 $days 天的資料';
  }

  @override
  String get databaseNotFound => '找不到資料庫檔案';

  @override
  String get shareSuccess => '資料庫已分享';

  @override
  String get shareCancelled => '已取消分享';

  @override
  String get shareFailed => '分享失敗';

  @override
  String get notificationChannelName => '步數追蹤';

  @override
  String get notificationChannelDescription => '步數目標與鼓勵提醒';

  @override
  String get errorNotificationTitle => '步數追蹤有問題';

  @override
  String errorNotificationBody(String message) {
    return '$message';
  }

  @override
  String get hourlyDataUnavailable => '讀不到今天的步數（Health Connect）';

  @override
  String get importClearDataWarning => '注意：這會先刪除 app 裡現有的全部資料。';

  @override
  String get notificationTimeWindowHint => '通知只會在「設定 → 活動時間」設定的時間內發送。';

  @override
  String get oneHour => '1 小時';

  @override
  String activeHoursRange(int from, int to) {
    return '從 $from:00 到 $to:00';
  }

  @override
  String get activeHoursSameHourError => '開始與結束是同一小時，請選一個不同的結束時間';

  @override
  String get syncReasonPermissionDenied => 'Health Connect 沒有給本 app 讀取步數的授權';

  @override
  String get syncReasonUnavailable =>
      '讀不到 Health Connect（未安裝，或這台裝置沒有 Google Play services）';

  @override
  String get syncReasonInvalidRange => '結束日期早於開始日期';

  @override
  String get importReasonFileNotFound => '選定的檔案不存在';

  @override
  String get importReasonNoData => '這個檔案裡沒有步數資料';

  @override
  String get importReasonReadFailed => '檔案讀不起來（不是 dHealth 的匯出檔？）';

  @override
  String get dailyStepGoalRange => '每日目標要介於 1000 與 20000 步之間';

  @override
  String get backupReminderTitle => '步數備份可能過期了';

  @override
  String backupReminderBody(int days) {
    return '距上次匯出已經 $days 天。雲端備份是關著的，匯出出去的那份就是你唯一的一份。';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get oooooCommon => '';

  @override
  String get cancel => '取消';

  @override
  String get interval => '间隔';

  @override
  String get minutesUnit => '分钟';

  @override
  String get hoursUnit => '小时';

  @override
  String get save => '储存';

  @override
  String get custom => '自订';

  @override
  String get menu => '选单';

  @override
  String get oooooAbout => '';

  @override
  String get about => '关于';

  @override
  String get aboutDescription =>
      'dHealth 只从 Health Connect 读你的每日步数，并按小时、天、周、月呈现。资料留在这台设备上。';

  @override
  String get platformSupportDesc =>
      'Android 13 以上，需 Health Connect 与 Google Play services。iOS 尚未支持。';

  @override
  String get platformSupportDesc_xxx =>
      '支援 Health Connect（安卓）和 HealthKit（iOS）。';

  @override
  String get features => '功能';

  @override
  String get healthTracking => '每日步数';

  @override
  String get healthTrackingDesc => '取自 Health Connect 的步数，含小时／每日／每周／每月图表。';

  @override
  String get importExportDesc => '使用 SQLite 文件备份或还原您的数据。';

  @override
  String get platformSupport => '平台支持';

  @override
  String get version => '版本';

  @override
  String get contact => '联系';

  @override
  String contactDesc(String email) {
    return '如需支援或想反馈问题，请写信给：$email';
  }

  @override
  String get oooooSetup => '';

  @override
  String get setup => '设定';

  @override
  String get interface => '介面';

  @override
  String get language => '语言';

  @override
  String get selectLanguage => '选择语言';

  @override
  String get theme => '主题';

  @override
  String get selectTheme => '选择主题';

  @override
  String get followSystem => '跟随系统';

  @override
  String get english => '英文';

  @override
  String get traditionalChinese => '繁体中文';

  @override
  String get simplifiedChinese => '简体中文';

  @override
  String get light => '浅色';

  @override
  String get dark => '深色';

  @override
  String get healthDataSync => '健康数据同步';

  @override
  String get healthDataSyncDesc => '设定如何从您的健康应用程式复制健康数据到此应用程式。';

  @override
  String get enableBackgroundSync => '启用背景同步';

  @override
  String get syncFrequency => '同步频率';

  @override
  String get customSyncTitle => '自订同步频率';

  @override
  String get every15Minutes => '每15分钟';

  @override
  String get every30Minutes => '每30分钟';

  @override
  String get every1Hour => '每小时';

  @override
  String get selectStartTime => '选择开始时间';

  @override
  String get selectEndTime => '选择结束时间';

  @override
  String get activeHours => '活动时间';

  @override
  String get hourly => '每小时';

  @override
  String get daily => '每天';

  @override
  String get dailyStepGoal => '每日目标';

  @override
  String get setDailyStepGoal => '设定每日目标';

  @override
  String get steps => '步数';

  @override
  String get displaySettings => '显示设定';

  @override
  String get showCumulativeSteps => '显示累积步数';

  @override
  String get showDailyStepGoal => '显示每日目标';

  @override
  String get oooooNotificationSetup => '';

  @override
  String get notificationSettings => '通知设定';

  @override
  String get enableNotifications => '启用通知';

  @override
  String get enableNotificationsDescription => '开启或关闭通知。';

  @override
  String get notificationFrequency => '通知频率';

  @override
  String get notificationFrequencyDescription => '接收通知的频率。';

  @override
  String get notificationTypes => '通知类型';

  @override
  String get reachGoalNotification => '目标达成';

  @override
  String get reachGoalNotificationDescription => '达到目标时通知。';

  @override
  String get motivationNotification => '激励（接近达成）';

  @override
  String get motivationNotificationDescription => '接近目标时鼓励。';

  @override
  String get motivationTimeLimit => '激励频率限制';

  @override
  String get motivationTimeLimitDescription => '激励通知之间的最小时间间隔。';

  @override
  String get exceptionNotification => '异常情况';

  @override
  String get exceptionNotificationDescription => '通知异常或错误。';

  @override
  String get customFrequency => '自订频率';

  @override
  String get minutesLabel => '分钟';

  @override
  String get enterMinutes => '输入分钟数';

  @override
  String get ok => '确定';

  @override
  String minutes(Object count) {
    return '$count 分钟';
  }

  @override
  String hours(Object count) {
    return '$count 小时';
  }

  @override
  String get notification => '通知';

  @override
  String get notificationAppearance => '通知外观';

  @override
  String get notificationSound => '通知声音';

  @override
  String get notificationSoundDescription => '收到通知时播放声音。';

  @override
  String get notificationVibration => '震动';

  @override
  String get notificationVibrationDescription => '收到通知时震动。';

  @override
  String get notificationPriority => '通知优先级';

  @override
  String get notificationPriorityDescription => '设定通知的重要性。';

  @override
  String get lowPriority => '低';

  @override
  String get defaultPriority => '预设';

  @override
  String get highPriority => '高';

  @override
  String get notificationTimeWindow => '通知时间范围';

  @override
  String get startTime => '开始时间';

  @override
  String get startTimeDescription => '接收通知的最早时间。';

  @override
  String get endTime => '结束时间';

  @override
  String get endTimeDescription => '接收通知的最晚时间。';

  @override
  String get importExport => '导入/导出';

  @override
  String get import => '汇入';

  @override
  String get importFromPhone => '从手机汇入';

  @override
  String get importFromFile => '从档案汇入';

  @override
  String get importClearData => '汇入前清除当前数据';

  @override
  String get dateRange => '汇入日期范围';

  @override
  String get startDate => '开始日期';

  @override
  String get endDate => '结束日期';

  @override
  String get importIncremental => '增量汇入';

  @override
  String get importSuccess => '汇入成功完成';

  @override
  String get importFailed => '汇入失败';

  @override
  String get importIncrementalDesc => '仅导入自上次导入以来的新数据';

  @override
  String get importFromPhoneDesc => '从您的手机导入步数数据';

  @override
  String get importFromFileDesc => '从之前导出的文件导入';

  @override
  String get exportOptions => '导出选项';

  @override
  String get export => '汇出';

  @override
  String get exportToFile => '汇出到档案';

  @override
  String get exportToCSV => '汇出为 CSV';

  @override
  String get shareDatabaseFile => '汇出到云端';

  @override
  String get exportSuccess => '汇出成功完成';

  @override
  String get exportFailed => '汇出失败';

  @override
  String get widgets => '小工具';

  @override
  String chartTitle(int steps, int average) {
    return '过去 $steps 天，平均 $average 步';
  }

  @override
  String todaySteps(int steps) {
    return '今日步数：$steps';
  }

  @override
  String get stepGoalReachedTitle => '步数目标达成！';

  @override
  String stepGoalReachedBody(int steps) {
    return '你今天已经走了 $steps 步，太棒了！';
  }

  @override
  String get motivationTitle => '就差一点！';

  @override
  String motivationBody(int gap, int goal) {
    return '距离 $goal 步的目标还差 $gap 步！';
  }

  @override
  String get viewDetails => '查看详情';

  @override
  String get today => '今天';

  @override
  String get days => '天';

  @override
  String get weeks => '周';

  @override
  String get months => '月';

  @override
  String get years => '年';

  @override
  String get average => '平均';

  @override
  String get monday => '星期一';

  @override
  String get tuesday => '星期二';

  @override
  String get wednesday => '星期三';

  @override
  String get thursday => '星期四';

  @override
  String get friday => '星期五';

  @override
  String get saturday => '星期六';

  @override
  String get sunday => '星期日';

  @override
  String get noDataInDatabase => '数据库中无可用数据';

  @override
  String get past => '过去';

  @override
  String get periods => '期';

  @override
  String get previousPage => '更早';

  @override
  String get nextPage => '更晚';

  @override
  String get latest => '最近';

  @override
  String get chartHelpTitle => '图表说明';

  @override
  String get hourlyStepsChartExplanation =>
      '此图表显示您的每小时步数。\n\n - 「累积」开关：切换以查看当天累积的总步数。\n - 「目标」开关：切换以显示您的每日步数目标为一条水平线。\n 调整这些设定来自订您的视图！';

  @override
  String get chartHelpContent => '此图表显示您在所选期间的步数。柱状图表示每日/每周/每月/每年的步数，虚线表示平均步数。';

  @override
  String get syncNow => '立即同步';

  @override
  String get syncSuccess => '已同步';

  @override
  String get syncFailed => '同步失敗';

  @override
  String get retry => '重試';

  @override
  String get permissionActivityRecognitionMissing => '未授予“身体活动”权限，步数会一直为 0。';

  @override
  String get permissionHealthReadMissing => 'Health Connect 未允许读取你的步数。';

  @override
  String get healthConnectUnavailable => '此设备上沒有 Health Connect。';

  @override
  String get healthConnectUnavailableDesc => '请从 Play Store 安装，才能读取步数资料。';

  @override
  String get installHealthConnect => '安装 Health Connect';

  @override
  String chartError(String error) {
    return '图表错误：$error';
  }

  @override
  String get cumulativeShort => '累计';

  @override
  String get goalShort => '目标';

  @override
  String hourSteps(int hour, int steps) {
    return '$hour:00\n$steps 步';
  }

  @override
  String get percentOfAverage => '日均占比';

  @override
  String get importing => '正在导入资料…';

  @override
  String percentComplete(String percent) {
    return '$percent% 完成';
  }

  @override
  String get dateRangeTo => '至';

  @override
  String get noDirectorySelected => '未选择文件夹';

  @override
  String exportedTo(String path) {
    return '已导出到 $path';
  }

  @override
  String importedDays(int days) {
    return '已导入 $days 天的资料';
  }

  @override
  String get databaseNotFound => '找不到数据库文件';

  @override
  String get shareSuccess => '数据库已分享';

  @override
  String get shareCancelled => '已取消分享';

  @override
  String get shareFailed => '分享失败';

  @override
  String get notificationChannelName => '步数追踪';

  @override
  String get notificationChannelDescription => '步数目标与鼓励提醒';

  @override
  String get errorNotificationTitle => '步数跟踪有问题';

  @override
  String errorNotificationBody(String message) {
    return '$message';
  }

  @override
  String get hourlyDataUnavailable => '读不到今天的步数（Health Connect）';

  @override
  String get importClearDataWarning => '注意：这会先删除 app 里现有的全部资料。';

  @override
  String get notificationTimeWindowHint => '通知只会在「设置 → 活动时间」设定的时间内发送。';

  @override
  String get oneHour => '1 小时';

  @override
  String activeHoursRange(int from, int to) {
    return '从 $from:00 到 $to:00';
  }

  @override
  String get activeHoursSameHourError => '开始与结束是同一小时，请选一个不同的结束时间';

  @override
  String get syncReasonPermissionDenied => 'Health Connect 没有给本 app 读取步数的授权';

  @override
  String get syncReasonUnavailable =>
      '读不到 Health Connect（未安装，或这台设备没有 Google Play services）';

  @override
  String get syncReasonInvalidRange => '结束日期早于开始日期';

  @override
  String get importReasonFileNotFound => '选定的文件不存在';

  @override
  String get importReasonNoData => '这个文件里没有步数资料';

  @override
  String get importReasonReadFailed => '文件读不起来（不是 dHealth 的导出文件？）';

  @override
  String get dailyStepGoalRange => '每日目标要介于 1000 与 20000 步之间';

  @override
  String get backupReminderTitle => '步数备份可能过期了';

  @override
  String backupReminderBody(int days) {
    return '距上次汇出已经 $days 天。云端备份是关着的，汇出去的那份就是你唯一的一份。';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get oooooCommon => '';

  @override
  String get cancel => '取消';

  @override
  String get interval => '間隔';

  @override
  String get minutesUnit => '分鐘';

  @override
  String get hoursUnit => '小時';

  @override
  String get save => '儲存';

  @override
  String get custom => '自訂';

  @override
  String get menu => '選單';

  @override
  String get oooooAbout => '';

  @override
  String get about => '關於';

  @override
  String get aboutDescription =>
      'dHealth 只從 Health Connect 讀你的每日步數，並依小時、天、週、月呈現。資料留在這台裝置上。';

  @override
  String get platformSupportDesc =>
      'Android 13 以上，需 Health Connect 與 Google Play services。iOS 尚未支援。';

  @override
  String get platformSupportDesc_xxx =>
      '支援 Health Connect（安卓）和 HealthKit（iOS）。';

  @override
  String get features => '功能';

  @override
  String get healthTracking => '每日步數';

  @override
  String get healthTrackingDesc => '取自 Health Connect 的步數，含小時／每日／每週／每月圖表。';

  @override
  String get importExportDesc => '使用 SQLite 文件備份或還原您的數據。';

  @override
  String get platformSupport => '平台支援';

  @override
  String get version => '版本';

  @override
  String get contact => '聯繫';

  @override
  String contactDesc(String email) {
    return '如需支援或想回報問題，請寫信給：$email';
  }

  @override
  String get oooooSetup => '';

  @override
  String get setup => '設定';

  @override
  String get interface => '介面';

  @override
  String get language => '語言';

  @override
  String get selectLanguage => '選擇語言';

  @override
  String get theme => '主題';

  @override
  String get selectTheme => '選擇主題';

  @override
  String get followSystem => '跟隨系統';

  @override
  String get english => '英文';

  @override
  String get traditionalChinese => '繁體中文';

  @override
  String get simplifiedChinese => '簡體中文';

  @override
  String get light => '淺色';

  @override
  String get dark => '深色';

  @override
  String get healthDataSync => '健康數據同步';

  @override
  String get healthDataSyncDesc => '設定如何從您的健康應用程式複製健康數據到此應用程式。';

  @override
  String get enableBackgroundSync => '啟用背景同步';

  @override
  String get syncFrequency => '同步頻率';

  @override
  String get customSyncTitle => '自訂同步頻率';

  @override
  String get every15Minutes => '每15分鐘';

  @override
  String get every30Minutes => '每30分鐘';

  @override
  String get every1Hour => '每小時';

  @override
  String get selectStartTime => '選擇開始時間';

  @override
  String get selectEndTime => '選擇結束時間';

  @override
  String get activeHours => '活動時間';

  @override
  String get hourly => '每小時';

  @override
  String get daily => '每天';

  @override
  String get dailyStepGoal => '每日目標';

  @override
  String get setDailyStepGoal => '設定每日目標';

  @override
  String get steps => '步數';

  @override
  String get displaySettings => '顯示設定';

  @override
  String get showCumulativeSteps => '顯示累積步數';

  @override
  String get showDailyStepGoal => '顯示每日目標';

  @override
  String get oooooNotificationSetup => '';

  @override
  String get notificationSettings => '通知設定';

  @override
  String get enableNotifications => '啟用通知';

  @override
  String get enableNotificationsDescription => '開啟或關閉通知。';

  @override
  String get notificationFrequency => '通知頻率';

  @override
  String get notificationFrequencyDescription => '接收通知的頻率。';

  @override
  String get notificationTypes => '通知類型';

  @override
  String get reachGoalNotification => '目標達成';

  @override
  String get reachGoalNotificationDescription => '達到目標時通知。';

  @override
  String get motivationNotification => '激勵（接近達成）';

  @override
  String get motivationNotificationDescription => '接近目標時鼓勵。';

  @override
  String get motivationTimeLimit => '激勵頻率限制';

  @override
  String get motivationTimeLimitDescription => '激勵通知之間的最小時間間隔。';

  @override
  String get exceptionNotification => '異常情況';

  @override
  String get exceptionNotificationDescription => '通知異常或錯誤。';

  @override
  String get customFrequency => '自訂頻率';

  @override
  String get minutesLabel => '分鐘';

  @override
  String get enterMinutes => '輸入分鐘數';

  @override
  String get ok => '確定';

  @override
  String minutes(Object count) {
    return '$count 分鐘';
  }

  @override
  String hours(Object count) {
    return '$count 小時';
  }

  @override
  String get notification => '通知';

  @override
  String get notificationAppearance => '通知外觀';

  @override
  String get notificationSound => '通知聲音';

  @override
  String get notificationSoundDescription => '收到通知時播放聲音。';

  @override
  String get notificationVibration => '震動';

  @override
  String get notificationVibrationDescription => '收到通知時震動。';

  @override
  String get notificationPriority => '通知優先級';

  @override
  String get notificationPriorityDescription => '設定通知的重要性。';

  @override
  String get lowPriority => '低';

  @override
  String get defaultPriority => '預設';

  @override
  String get highPriority => '高';

  @override
  String get notificationTimeWindow => '通知時間範圍';

  @override
  String get startTime => '開始時間';

  @override
  String get startTimeDescription => '接收通知的最早時間。';

  @override
  String get endTime => '結束時間';

  @override
  String get endTimeDescription => '接收通知的最晚時間。';

  @override
  String get importExport => '導入/導出';

  @override
  String get import => '匯入';

  @override
  String get importFromPhone => '從手機匯入';

  @override
  String get importFromFile => '從檔案匯入';

  @override
  String get importClearData => '匯入前清除當前數據';

  @override
  String get dateRange => '匯入日期範圍';

  @override
  String get startDate => '開始日期';

  @override
  String get endDate => '結束日期';

  @override
  String get importIncremental => '增量匯入';

  @override
  String get importSuccess => '匯入成功完成';

  @override
  String get importFailed => '匯入失敗';

  @override
  String get importIncrementalDesc => '僅導入自上次導入以來的新數據';

  @override
  String get importFromPhoneDesc => '從您的手機導入步數數據';

  @override
  String get importFromFileDesc => '從之前導出的文件導入';

  @override
  String get exportOptions => '導出選項';

  @override
  String get export => '匯出';

  @override
  String get exportToFile => '匯出到檔案';

  @override
  String get exportToCSV => '匯出為 CSV';

  @override
  String get shareDatabaseFile => '匯出到雲端';

  @override
  String get exportSuccess => '匯出成功完成';

  @override
  String get exportFailed => '匯出失敗';

  @override
  String get widgets => '小工具';

  @override
  String chartTitle(int steps, int average) {
    return '過去 $steps 天，平均 $average 步';
  }

  @override
  String todaySteps(int steps) {
    return '今日步數：$steps';
  }

  @override
  String get stepGoalReachedTitle => '步數目標達成！';

  @override
  String stepGoalReachedBody(int steps) {
    return '你今天已經走了 $steps 步，太棒了！';
  }

  @override
  String get motivationTitle => '就差一點！';

  @override
  String motivationBody(int gap, int goal) {
    return '距離 $goal 步的目標還差 $gap 步！';
  }

  @override
  String get viewDetails => '查看詳情';

  @override
  String get today => '今天';

  @override
  String get days => '天';

  @override
  String get weeks => '週';

  @override
  String get months => '月';

  @override
  String get years => '年';

  @override
  String get average => '平均';

  @override
  String get monday => '星期一';

  @override
  String get tuesday => '星期二';

  @override
  String get wednesday => '星期三';

  @override
  String get thursday => '星期四';

  @override
  String get friday => '星期五';

  @override
  String get saturday => '星期六';

  @override
  String get sunday => '星期日';

  @override
  String get noDataInDatabase => '數據庫中無可用數據';

  @override
  String get past => '過去';

  @override
  String get periods => '期';

  @override
  String get previousPage => '更早';

  @override
  String get nextPage => '更晚';

  @override
  String get latest => '最近';

  @override
  String get chartHelpTitle => '圖表說明';

  @override
  String get hourlyStepsChartExplanation =>
      '此圖表顯示您的每小時步數。\n\n - 「累積」開關：切換以查看當天累積的總步數。\n - 「目標」開關：切換以顯示您的每日步數目標為一條水平線。\n 調整這些設定來自訂您的視圖！';

  @override
  String get chartHelpContent => '此圖表顯示您在所選期間的步數。柱狀圖表示每日/每週/每月/每年的步數，虛線表示平均步數。';

  @override
  String get syncNow => '立即同步';

  @override
  String get syncSuccess => '已同步';

  @override
  String get syncFailed => '同步失敗';

  @override
  String get retry => '重試';

  @override
  String get permissionActivityRecognitionMissing => '未授予「身體活動」權限，步數會一直是 0。';

  @override
  String get permissionHealthReadMissing => 'Health Connect 未允許讀取你的步數。';

  @override
  String get healthConnectUnavailable => '此裝置上沒有 Health Connect。';

  @override
  String get healthConnectUnavailableDesc => '請從 Play Store 安裝，才能讀取步數資料。';

  @override
  String get installHealthConnect => '安裝 Health Connect';

  @override
  String chartError(String error) {
    return '圖表錯誤：$error';
  }

  @override
  String get cumulativeShort => '累計';

  @override
  String get goalShort => '目標';

  @override
  String hourSteps(int hour, int steps) {
    return '$hour:00\n$steps 步';
  }

  @override
  String get percentOfAverage => '日均佔比';

  @override
  String get importing => '正在匯入資料…';

  @override
  String percentComplete(String percent) {
    return '$percent% 完成';
  }

  @override
  String get dateRangeTo => '至';

  @override
  String get noDirectorySelected => '未選擇資料夾';

  @override
  String exportedTo(String path) {
    return '已匯出到 $path';
  }

  @override
  String importedDays(int days) {
    return '已匯入 $days 天的資料';
  }

  @override
  String get databaseNotFound => '找不到資料庫檔案';

  @override
  String get shareSuccess => '資料庫已分享';

  @override
  String get shareCancelled => '已取消分享';

  @override
  String get shareFailed => '分享失敗';

  @override
  String get notificationChannelName => '步數追蹤';

  @override
  String get notificationChannelDescription => '步數目標與鼓勵提醒';

  @override
  String get errorNotificationTitle => '步數追蹤有問題';

  @override
  String errorNotificationBody(String message) {
    return '$message';
  }

  @override
  String get hourlyDataUnavailable => '讀不到今天的步數（Health Connect）';

  @override
  String get importClearDataWarning => '注意：這會先刪除 app 裡現有的全部資料。';

  @override
  String get notificationTimeWindowHint => '通知只會在「設定 → 活動時間」設定的時間內發送。';

  @override
  String get oneHour => '1 小時';

  @override
  String activeHoursRange(int from, int to) {
    return '從 $from:00 到 $to:00';
  }

  @override
  String get activeHoursSameHourError => '開始與結束是同一小時，請選一個不同的結束時間';

  @override
  String get syncReasonPermissionDenied => 'Health Connect 沒有給本 app 讀取步數的授權';

  @override
  String get syncReasonUnavailable =>
      '讀不到 Health Connect（未安裝，或這台裝置沒有 Google Play services）';

  @override
  String get syncReasonInvalidRange => '結束日期早於開始日期';

  @override
  String get importReasonFileNotFound => '選定的檔案不存在';

  @override
  String get importReasonNoData => '這個檔案裡沒有步數資料';

  @override
  String get importReasonReadFailed => '檔案讀不起來（不是 dHealth 的匯出檔？）';

  @override
  String get dailyStepGoalRange => '每日目標要介於 1000 與 20000 步之間';

  @override
  String get backupReminderTitle => '步數備份可能過期了';

  @override
  String backupReminderBody(int days) {
    return '距上次匯出已經 $days 天。雲端備份是關著的，匯出出去的那份就是你唯一的一份。';
  }
}
