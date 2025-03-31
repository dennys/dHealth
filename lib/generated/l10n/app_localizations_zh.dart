// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get menu => '選單';

  @override
  String get about => '關於';

  @override
  String get aboutDescription => 'dHealth 是一款用於追蹤和管理您的健康數據的應用程式，支持導入和導出 SQLite 數據庫。';

  @override
  String get platformSupportDesc => '支援 Health Connect（安卓）。';

  @override
  String get platformSupportDesc_xxx => '支援 Health Connect（安卓）和 HealthKit（iOS）。';

  @override
  String get features => '功能';

  @override
  String get healthTracking => '健康數據追蹤';

  @override
  String get healthTrackingDesc => '監控您的步數和其他健康指標。';

  @override
  String get importExportDesc => '使用 SQLite 文件備份或還原您的數據。';

  @override
  String get platformSupport => '平台支援';

  @override
  String get version => '版本';

  @override
  String get contact => '聯繫';

  @override
  String get contactDesc => '如需支援或反饋，請發送電子郵件至：support@example.com';

  @override
  String get setup => '設定';

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
  String get syncFrequency => '同步頻率';

  @override
  String get selectSyncFrequency => '選擇同步頻率';

  @override
  String get manual => '手動';

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
    return 'Last $steps days, average is $average steps';
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
  String motivationBody(int goal) {
    return '你離 $goal 步的目標只差 1000 步了！';
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
  String get ok => '確定';

  @override
  String get chartHelpTitle => '圖表說明';

  @override
  String get hourlyStepsChartExplanation => '此圖表顯示您的每小時步數。\n\n - 「累積」開關：切換以查看當天累積的總步數。\n - 「目標」開關：切換以顯示您的每日步數目標為一條水平線。\n 調整這些設定來自訂您的視圖！';

  @override
  String get chartHelpContent => '此圖表顯示您在所選期間的步數。柱狀圖表示每日/每週/每月/每年的步數，虛線表示平均步數。';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans(): super('zh_Hans');

  @override
  String get menu => '选单';

  @override
  String get about => '关于';

  @override
  String get aboutDescription => 'dHealth 是一款用于追踪和管理您的健康数据的应用程式，支持导入和导出 SQLite 数据库。';

  @override
  String get platformSupportDesc => '支援 Health Connect（安卓）。';

  @override
  String get platformSupportDesc_xxx => '支援 Health Connect（安卓）和 HealthKit（iOS）。';

  @override
  String get features => '功能';

  @override
  String get healthTracking => '健康数据追踪';

  @override
  String get healthTrackingDesc => '监控您的步数和其他健康指标。';

  @override
  String get importExportDesc => '使用 SQLite 文件备份或还原您的数据。';

  @override
  String get platformSupport => '平台支援';

  @override
  String get version => '版本';

  @override
  String get contact => '联系';

  @override
  String get contactDesc => '如需支援或反馈，请发送电子邮件至：support@example.com';

  @override
  String get setup => '设定';

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
  String get syncFrequency => '同步频率';

  @override
  String get selectSyncFrequency => '选择同步频率';

  @override
  String get manual => '手动';

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
  String motivationBody(int goal) {
    return '你离 $goal 步的目标只差 1000 步了！';
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
  String get ok => '确定';

  @override
  String get chartHelpTitle => '图表说明';

  @override
  String get hourlyStepsChartExplanation => '此图表显示您的每小时步数。\n\n - 「累积」开关：切换以查看当天累积的总步数。\n - 「目标」开关：切换以显示您的每日步数目标为一条水平线。\n 调整这些设定来自订您的视图！';

  @override
  String get chartHelpContent => '此图表显示您在所选期间的步数。柱状图表示每日/每周/每月/每年的步数，虚线表示平均步数。';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant(): super('zh_Hant');

  @override
  String get menu => '選單';

  @override
  String get about => '關於';

  @override
  String get aboutDescription => 'dHealth 是一款用於追蹤和管理您的健康數據的應用程式，支持導入和導出 SQLite 數據庫。';

  @override
  String get platformSupportDesc => '支援 Health Connect（安卓）。';

  @override
  String get platformSupportDesc_xxx => '支援 Health Connect（安卓）和 HealthKit（iOS）。';

  @override
  String get features => '功能';

  @override
  String get healthTracking => '健康數據追蹤';

  @override
  String get healthTrackingDesc => '監控您的步數和其他健康指標。';

  @override
  String get importExportDesc => '使用 SQLite 文件備份或還原您的數據。';

  @override
  String get platformSupport => '平台支援';

  @override
  String get version => '版本';

  @override
  String get contact => '聯繫';

  @override
  String get contactDesc => '如需支援或反饋，請發送電子郵件至：support@example.com';

  @override
  String get setup => '設定';

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
  String get syncFrequency => '同步頻率';

  @override
  String get selectSyncFrequency => '選擇同步頻率';

  @override
  String get manual => '手動';

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
  String motivationBody(int goal) {
    return '你離 $goal 步的目標只差 1000 步了！';
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
  String get ok => '確定';

  @override
  String get chartHelpTitle => '圖表說明';

  @override
  String get hourlyStepsChartExplanation => '此圖表顯示您的每小時步數。\n\n - 「累積」開關：切換以查看當天累積的總步數。\n - 「目標」開關：切換以顯示您的每日步數目標為一條水平線。\n 調整這些設定來自訂您的視圖！';

  @override
  String get chartHelpContent => '此圖表顯示您在所選期間的步數。柱狀圖表示每日/每週/每月/每年的步數，虛線表示平均步數。';
}
