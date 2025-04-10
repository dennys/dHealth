import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
  ];

  /// No description provided for @oooooCommon.
  ///
  /// In en, this message translates to:
  /// **''**
  String get oooooCommon;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @interval.
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get interval;

  /// No description provided for @minutesUnit.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get minutesUnit;

  /// No description provided for @hoursUnit.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hoursUnit;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @oooooAbout.
  ///
  /// In en, this message translates to:
  /// **''**
  String get oooooAbout;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'dHealth is an app to track and manage your health data with support for importing and exporting SQLite databases.'**
  String get aboutDescription;

  /// No description provided for @platformSupportDesc.
  ///
  /// In en, this message translates to:
  /// **'Works with Health Connect (Android).'**
  String get platformSupportDesc;

  /// No description provided for @platformSupportDesc_xxx.
  ///
  /// In en, this message translates to:
  /// **'Works with Health Connect (Android) and HealthKit (iOS).'**
  String get platformSupportDesc_xxx;

  /// No description provided for @features.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get features;

  /// No description provided for @healthTracking.
  ///
  /// In en, this message translates to:
  /// **'Health Data Tracking'**
  String get healthTracking;

  /// No description provided for @healthTrackingDesc.
  ///
  /// In en, this message translates to:
  /// **'Monitor your steps and other health metrics.'**
  String get healthTrackingDesc;

  /// No description provided for @importExportDesc.
  ///
  /// In en, this message translates to:
  /// **'Backup or restore your data using SQLite files.'**
  String get importExportDesc;

  /// No description provided for @platformSupport.
  ///
  /// In en, this message translates to:
  /// **'Platform Support'**
  String get platformSupport;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @contactDesc.
  ///
  /// In en, this message translates to:
  /// **'For support or feedback, email us at: support@example.com'**
  String get contactDesc;

  /// No description provided for @oooooSetup.
  ///
  /// In en, this message translates to:
  /// **''**
  String get oooooSetup;

  /// No description provided for @setup.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get setup;

  /// No description provided for @interface.
  ///
  /// In en, this message translates to:
  /// **'Interface'**
  String get interface;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @selectTheme.
  ///
  /// In en, this message translates to:
  /// **'Select Theme'**
  String get selectTheme;

  /// No description provided for @followSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow System'**
  String get followSystem;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @traditionalChinese.
  ///
  /// In en, this message translates to:
  /// **'Traditional Chinese'**
  String get traditionalChinese;

  /// No description provided for @simplifiedChinese.
  ///
  /// In en, this message translates to:
  /// **'Simplified Chinese'**
  String get simplifiedChinese;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @healthDataSync.
  ///
  /// In en, this message translates to:
  /// **'Health Data Sync'**
  String get healthDataSync;

  /// No description provided for @healthDataSyncDesc.
  ///
  /// In en, this message translates to:
  /// **'Configure how to sync health data from your phone.'**
  String get healthDataSyncDesc;

  /// No description provided for @enableBackgroundSync.
  ///
  /// In en, this message translates to:
  /// **'Enable Background Sync'**
  String get enableBackgroundSync;

  /// No description provided for @syncFrequency.
  ///
  /// In en, this message translates to:
  /// **'Sync Frequency'**
  String get syncFrequency;

  /// No description provided for @customSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Sync Frequency'**
  String get customSyncTitle;

  /// No description provided for @every15Minutes.
  ///
  /// In en, this message translates to:
  /// **'Every 15 minutes'**
  String get every15Minutes;

  /// No description provided for @every30Minutes.
  ///
  /// In en, this message translates to:
  /// **'Every 30 minutes'**
  String get every30Minutes;

  /// No description provided for @every1Hour.
  ///
  /// In en, this message translates to:
  /// **'Every hour'**
  String get every1Hour;

  /// No description provided for @selectStartTime.
  ///
  /// In en, this message translates to:
  /// **'Select Start Time'**
  String get selectStartTime;

  /// No description provided for @selectEndTime.
  ///
  /// In en, this message translates to:
  /// **'Select End Time'**
  String get selectEndTime;

  /// No description provided for @endTimeError.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time'**
  String get endTimeError;

  /// No description provided for @activeHours.
  ///
  /// In en, this message translates to:
  /// **'Active Hours'**
  String get activeHours;

  /// No description provided for @startOnBoot.
  ///
  /// In en, this message translates to:
  /// **'Start on Boot'**
  String get startOnBoot;

  /// No description provided for @stopOnTerminate.
  ///
  /// In en, this message translates to:
  /// **'Stop on Terminate'**
  String get stopOnTerminate;

  /// No description provided for @persistentSync.
  ///
  /// In en, this message translates to:
  /// **'Persistent Sync'**
  String get persistentSync;

  /// No description provided for @persistentSyncReminder.
  ///
  /// In en, this message translates to:
  /// **'Note: Sync will continue even if you force-stop the app.'**
  String get persistentSyncReminder;

  /// No description provided for @hourly.
  ///
  /// In en, this message translates to:
  /// **'Hourly'**
  String get hourly;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @dailyStepGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily Step Goal'**
  String get dailyStepGoal;

  /// No description provided for @setDailyStepGoal.
  ///
  /// In en, this message translates to:
  /// **'Set your daily step goal'**
  String get setDailyStepGoal;

  /// No description provided for @steps.
  ///
  /// In en, this message translates to:
  /// **'steps'**
  String get steps;

  /// No description provided for @displaySettings.
  ///
  /// In en, this message translates to:
  /// **'Display Settings'**
  String get displaySettings;

  /// No description provided for @showCumulativeSteps.
  ///
  /// In en, this message translates to:
  /// **'Show cumulative steps'**
  String get showCumulativeSteps;

  /// No description provided for @showDailyStepGoal.
  ///
  /// In en, this message translates to:
  /// **'Show daily step goal'**
  String get showDailyStepGoal;

  /// No description provided for @oooooNotificationSetup.
  ///
  /// In en, this message translates to:
  /// **''**
  String get oooooNotificationSetup;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @enableNotificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Turn notifications on or off.'**
  String get enableNotificationsDescription;

  /// No description provided for @notificationFrequency.
  ///
  /// In en, this message translates to:
  /// **'Notification Frequency'**
  String get notificationFrequency;

  /// No description provided for @notificationFrequencyDescription.
  ///
  /// In en, this message translates to:
  /// **'How often to receive notifications.'**
  String get notificationFrequencyDescription;

  /// No description provided for @notificationTypes.
  ///
  /// In en, this message translates to:
  /// **'Notification Types'**
  String get notificationTypes;

  /// No description provided for @reachGoalNotification.
  ///
  /// In en, this message translates to:
  /// **'Goal Reached'**
  String get reachGoalNotification;

  /// No description provided for @reachGoalNotificationDescription.
  ///
  /// In en, this message translates to:
  /// **'Notify when a goal is achieved.'**
  String get reachGoalNotificationDescription;

  /// No description provided for @motivationNotification.
  ///
  /// In en, this message translates to:
  /// **'Motivation (Almost There)'**
  String get motivationNotification;

  /// No description provided for @motivationNotificationDescription.
  ///
  /// In en, this message translates to:
  /// **'Encourage when near a goal.'**
  String get motivationNotificationDescription;

  /// No description provided for @motivationTimeLimit.
  ///
  /// In en, this message translates to:
  /// **'Motivation Frequency Limit'**
  String get motivationTimeLimit;

  /// No description provided for @motivationTimeLimitDescription.
  ///
  /// In en, this message translates to:
  /// **'Minimum time between motivation notifications.'**
  String get motivationTimeLimitDescription;

  /// No description provided for @exceptionNotification.
  ///
  /// In en, this message translates to:
  /// **'Exceptions'**
  String get exceptionNotification;

  /// No description provided for @exceptionNotificationDescription.
  ///
  /// In en, this message translates to:
  /// **'Notify about exceptions or errors.'**
  String get exceptionNotificationDescription;

  /// No description provided for @newAccomplishmentNotification.
  ///
  /// In en, this message translates to:
  /// **'New Accomplishments'**
  String get newAccomplishmentNotification;

  /// No description provided for @newAccomplishmentNotificationDescription.
  ///
  /// In en, this message translates to:
  /// **'Notify about new achievements.'**
  String get newAccomplishmentNotificationDescription;

  /// No description provided for @customFrequency.
  ///
  /// In en, this message translates to:
  /// **'Custom Frequency'**
  String get customFrequency;

  /// No description provided for @minutesLabel.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get minutesLabel;

  /// No description provided for @enterMinutes.
  ///
  /// In en, this message translates to:
  /// **'Enter minutes'**
  String get enterMinutes;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Format for minutes
  ///
  /// In en, this message translates to:
  /// **'{count} minutes'**
  String minutes(Object count);

  /// Format for hours
  ///
  /// In en, this message translates to:
  /// **'{count} hours'**
  String hours(Object count);

  /// No description provided for @notification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notification;

  /// No description provided for @notificationAppearance.
  ///
  /// In en, this message translates to:
  /// **'Notification Appearance'**
  String get notificationAppearance;

  /// No description provided for @notificationSound.
  ///
  /// In en, this message translates to:
  /// **'Notification Sound'**
  String get notificationSound;

  /// No description provided for @notificationSoundDescription.
  ///
  /// In en, this message translates to:
  /// **'Play a sound when notifications are received.'**
  String get notificationSoundDescription;

  /// No description provided for @notificationVibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get notificationVibration;

  /// No description provided for @notificationVibrationDescription.
  ///
  /// In en, this message translates to:
  /// **'Vibrate when notifications are received.'**
  String get notificationVibrationDescription;

  /// No description provided for @notificationPriority.
  ///
  /// In en, this message translates to:
  /// **'Notification Priority'**
  String get notificationPriority;

  /// No description provided for @notificationPriorityDescription.
  ///
  /// In en, this message translates to:
  /// **'Set the importance of notifications.'**
  String get notificationPriorityDescription;

  /// No description provided for @lowPriority.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get lowPriority;

  /// No description provided for @defaultPriority.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultPriority;

  /// No description provided for @highPriority.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get highPriority;

  /// No description provided for @notificationTimeWindow.
  ///
  /// In en, this message translates to:
  /// **'Notification Time Window'**
  String get notificationTimeWindow;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @startTimeDescription.
  ///
  /// In en, this message translates to:
  /// **'Earliest time to receive notifications.'**
  String get startTimeDescription;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// No description provided for @endTimeDescription.
  ///
  /// In en, this message translates to:
  /// **'Latest time to receive notifications.'**
  String get endTimeDescription;

  /// No description provided for @importExport.
  ///
  /// In en, this message translates to:
  /// **'Import/Export'**
  String get importExport;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @importFromPhone.
  ///
  /// In en, this message translates to:
  /// **'Import from Phone'**
  String get importFromPhone;

  /// No description provided for @importFromFile.
  ///
  /// In en, this message translates to:
  /// **'Import from file'**
  String get importFromFile;

  /// No description provided for @importClearData.
  ///
  /// In en, this message translates to:
  /// **'Clear current data before import'**
  String get importClearData;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Import date range'**
  String get dateRange;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @importIncremental.
  ///
  /// In en, this message translates to:
  /// **'Import incremental'**
  String get importIncremental;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Import completed successfully'**
  String get importSuccess;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get importFailed;

  /// No description provided for @importIncrementalDesc.
  ///
  /// In en, this message translates to:
  /// **'Only import new data since last import'**
  String get importIncrementalDesc;

  /// No description provided for @importFromPhoneDesc.
  ///
  /// In en, this message translates to:
  /// **'Import step data from your phone'**
  String get importFromPhoneDesc;

  /// No description provided for @importFromFileDesc.
  ///
  /// In en, this message translates to:
  /// **'Import from a previously exported file'**
  String get importFromFileDesc;

  /// No description provided for @exportOptions.
  ///
  /// In en, this message translates to:
  /// **'Export Options'**
  String get exportOptions;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @exportToFile.
  ///
  /// In en, this message translates to:
  /// **'Export to file'**
  String get exportToFile;

  /// No description provided for @exportToCSV.
  ///
  /// In en, this message translates to:
  /// **'Export to CSV'**
  String get exportToCSV;

  /// No description provided for @shareDatabaseFile.
  ///
  /// In en, this message translates to:
  /// **'Share Database File'**
  String get shareDatabaseFile;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Export completed successfully'**
  String get exportSuccess;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailed;

  /// No description provided for @widgets.
  ///
  /// In en, this message translates to:
  /// **'Widgets'**
  String get widgets;

  /// No description provided for @chartTitle.
  ///
  /// In en, this message translates to:
  /// **'Last {steps} days, average is {average} steps'**
  String chartTitle(int steps, int average);

  /// No description provided for @todaySteps.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Steps: {steps}'**
  String todaySteps(int steps);

  /// No description provided for @stepGoalReachedTitle.
  ///
  /// In en, this message translates to:
  /// **'Step Goal Reached!'**
  String get stepGoalReachedTitle;

  /// No description provided for @stepGoalReachedBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve walked {steps} steps today. Great job!'**
  String stepGoalReachedBody(int steps);

  /// No description provided for @motivationTitle.
  ///
  /// In en, this message translates to:
  /// **'Almost There!'**
  String get motivationTitle;

  /// No description provided for @motivationBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re just 1000 steps away from your goal of {goal} steps!'**
  String motivationBody(int goal);

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// No description provided for @weeks.
  ///
  /// In en, this message translates to:
  /// **'Weeks'**
  String get weeks;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get months;

  /// No description provided for @years.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get years;

  /// No description provided for @average.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get average;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sunday;

  /// No description provided for @noDataInDatabase.
  ///
  /// In en, this message translates to:
  /// **'No data available in database'**
  String get noDataInDatabase;

  /// No description provided for @past.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get past;

  /// No description provided for @chartHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Chart Help'**
  String get chartHelpTitle;

  /// No description provided for @hourlyStepsChartExplanation.
  ///
  /// In en, this message translates to:
  /// **'This chart shows your hourly step count.\n\n - \'Cumulative\' switch: Toggle to see total steps accumulated over the day.\n - \'Goal\' switch: Toggle to display your daily step goal as a horizontal line.\n Adjust these settings to customize your view!'**
  String get hourlyStepsChartExplanation;

  /// No description provided for @chartHelpContent.
  ///
  /// In en, this message translates to:
  /// **'This chart shows your step count over the selected period. The bars represent daily/weekly/monthly/yearly steps, and the dotted line shows the average steps.'**
  String get chartHelpContent;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {

  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh': {
  switch (locale.scriptCode) {
    case 'Hans': return AppLocalizationsZhHans();
case 'Hant': return AppLocalizationsZhHant();
   }
  break;
   }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
