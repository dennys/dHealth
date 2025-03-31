// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get menu => 'Menu';

  @override
  String get about => 'About';

  @override
  String get aboutDescription => 'dHealth is an app to track and manage your health data with support for importing and exporting SQLite databases.';

  @override
  String get platformSupportDesc => 'Works with Health Connect (Android).';

  @override
  String get platformSupportDesc_xxx => 'Works with Health Connect (Android) and HealthKit (iOS).';

  @override
  String get features => 'Features';

  @override
  String get healthTracking => 'Health Data Tracking';

  @override
  String get healthTrackingDesc => 'Monitor your steps and other health metrics.';

  @override
  String get importExportDesc => 'Backup or restore your data using SQLite files.';

  @override
  String get platformSupport => 'Platform Support';

  @override
  String get version => 'Version';

  @override
  String get contact => 'Contact';

  @override
  String get contactDesc => 'For support or feedback, email us at: support@example.com';

  @override
  String get setup => 'Setup';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get theme => 'Theme';

  @override
  String get selectTheme => 'Select Theme';

  @override
  String get followSystem => 'Follow System';

  @override
  String get english => 'English';

  @override
  String get traditionalChinese => 'Traditional Chinese';

  @override
  String get simplifiedChinese => 'Simplified Chinese';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get syncFrequency => 'Sync Frequency';

  @override
  String get selectSyncFrequency => 'Select Sync Frequency';

  @override
  String get manual => 'Manual';

  @override
  String get hourly => 'Hourly';

  @override
  String get daily => 'Daily';

  @override
  String get dailyStepGoal => 'Daily Step Goal';

  @override
  String get setDailyStepGoal => 'Set your daily step goal';

  @override
  String get steps => 'steps';

  @override
  String get displaySettings => 'Display Settings';

  @override
  String get showCumulativeSteps => 'Show cumulative steps';

  @override
  String get showDailyStepGoal => 'Show daily step goal';

  @override
  String get importExport => 'Import/Export';

  @override
  String get import => 'Import';

  @override
  String get importFromPhone => 'Import from Phone';

  @override
  String get importFromFile => 'Import from file';

  @override
  String get importClearData => 'Clear current data before import';

  @override
  String get dateRange => 'Import date range';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String get importIncremental => 'Import incremental';

  @override
  String get importSuccess => 'Import completed successfully';

  @override
  String get importFailed => 'Import failed';

  @override
  String get importIncrementalDesc => 'Only import new data since last import';

  @override
  String get importFromPhoneDesc => 'Import step data from your phone';

  @override
  String get importFromFileDesc => 'Import from a previously exported file';

  @override
  String get exportOptions => 'Export Options';

  @override
  String get export => 'Export';

  @override
  String get exportToFile => 'Export to file';

  @override
  String get exportToCSV => 'Export to CSV';

  @override
  String get shareDatabaseFile => 'Share Database File';

  @override
  String get exportSuccess => 'Export completed successfully';

  @override
  String get exportFailed => 'Export failed';

  @override
  String get widgets => 'Widgets';

  @override
  String chartTitle(int steps, int average) {
    return 'Last $steps days, average is $average steps';
  }

  @override
  String todaySteps(int steps) {
    return 'Today\'s Steps: $steps';
  }

  @override
  String get stepGoalReachedTitle => 'Step Goal Reached!';

  @override
  String stepGoalReachedBody(int steps) {
    return 'You\'ve walked $steps steps today. Great job!';
  }

  @override
  String get motivationTitle => 'Almost There!';

  @override
  String motivationBody(int goal) {
    return 'You\'re just 1000 steps away from your goal of $goal steps!';
  }

  @override
  String get viewDetails => 'View Details';

  @override
  String get today => 'Today';

  @override
  String get days => 'Days';

  @override
  String get weeks => 'Weeks';

  @override
  String get months => 'Months';

  @override
  String get years => 'Years';

  @override
  String get average => 'Average';

  @override
  String get monday => 'Mon';

  @override
  String get tuesday => 'Tue';

  @override
  String get wednesday => 'Wed';

  @override
  String get thursday => 'Thu';

  @override
  String get friday => 'Fri';

  @override
  String get saturday => 'Sat';

  @override
  String get sunday => 'Sun';

  @override
  String get noDataInDatabase => 'No data available in database';

  @override
  String get past => 'Past';

  @override
  String get ok => 'OK';

  @override
  String get chartHelpTitle => 'Chart Help';

  @override
  String get hourlyStepsChartExplanation => 'This chart shows your hourly step count.\n\n - \'Cumulative\' switch: Toggle to see total steps accumulated over the day.\n - \'Goal\' switch: Toggle to display your daily step goal as a horizontal line.\n Adjust these settings to customize your view!';

  @override
  String get chartHelpContent => 'This chart shows your step count over the selected period. The bars represent daily/weekly/monthly/yearly steps, and the dotted line shows the average steps.';
}
