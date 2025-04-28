import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:dsteps/generated/l10n/app_localizations.dart';
import 'package:dsteps/services/background_service.dart';
import 'package:dsteps/services/data_service.dart';
import 'package:dsteps/services/notification_service.dart';
import 'package:dsteps/widgets/about.dart';
import 'package:dsteps/widgets/import_export.dart';
import 'package:dsteps/widgets/notification_setup.dart';
import 'package:dsteps/widgets/setup.dart';
// import 'package:dsteps/widgets/step_counter_manager.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:health/health.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'appstate.dart';
import 'data.dart';
import 'database/database.dart';
import 'services/health_service.dart';
import 'settings_model.dart';
import 'util.dart';
import 'widgets/charts.dart';

// Global GetIt instance
final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  getIt.registerLazySingleton<Health>(() => Health());
  final Directory appDir = await getApplicationDocumentsDirectory();
  final File dbFile = File(p.join(appDir.path, 'dHealth.sqlite'));
  getIt.registerLazySingleton<StepDatabase>(() => StepDatabase(NativeDatabase(dbFile)));
}

// void main() => runApp(HealthApp());

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();

  await NotificationService.initialize();
  await BackgroundService.init();
  await BackgroundService.executeTask();

  runApp(ChangeNotifierProvider(create: (_) => SettingsModel(), child: const HealthApp()));
}

class HealthApp extends StatefulWidget {
  const HealthApp({super.key});

  @override
  HealthAppState createState() => HealthAppState();
}

class HealthAppState extends State<HealthApp> {
  // late StepCounterManager _stepCounterManager;
  String _language = 'system';
  String _theme = 'system';
  List<HealthDataPoint> _healthDataList = [];
  AppState _state = AppState.DATA_NOT_FETCHED;
  bool _isAuthorized = false;
  String? _errorMessage;

  late HealthService _healthService;
  int _nofSteps = 0;
  List<RecordingMethod> recordingMethodsToFilter = [];

  // All types available depending on platform (iOS ot Android).
  List<HealthDataType> get types =>
      (Platform.isAndroid)
          ? dataTypesAndroid
          : (Platform.isIOS)
          ? dataTypesIOS
          : [];

  // // Or specify specific types
  // static final types = [
  //   HealthDataType.WEIGHT,
  //   HealthDataType.STEPS,
  //   HealthDataType.HEIGHT,
  //   HealthDataType.BLOOD_GLUCOSE,
  //   HealthDataType.WORKOUT,
  //   HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
  //   HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
  //   // Uncomment this line on iOS - only available on iOS
  //   // HealthDataType.AUDIOGRAM
  // ];

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

  @override
  void initState() {
    super.initState();
    // _loadPreferences();
    // Listen to settings changes and rebuild the widget tree
    Provider.of<SettingsModel>(context, listen: false).addListener(() {
      if (mounted) {
        setState(() {}); // Rebuild the app when settings change
      }
    });

    // configure the health plugin before use and check the Health Connect status
    final health = GetIt.I<Health>();
    health.configure();
    health.getHealthConnectSdkStatus();

    _healthService = HealthService(types: [HealthDataType.STEPS], permissions: [HealthDataAccess.READ]);

    final settings = Provider.of<SettingsModel>(context, listen: false);
    // _stepCounterManager = StepCounterManager(
    //   settings: settings,
    //   onPermissionDenied: () {
    //     if (mounted) {
    //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please grant Health Connect permissions')));
    //     }
    //   },
    //   onNavigateToMain: () {
    //     if (mounted) {
    //       Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HealthApp()));
    //     }
    //   },
    // );
    // _stepCounterManager.initialize();

    // 在 Widgets 渲染完成后调用 authorize，避免在 initState 中直接使用 async
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  @override
  void dispose() {
    // _stepCounterManager.dispose(); // 清理計時器
    super.dispose();
  }

  // Future<void> _loadPreferences() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     _language = prefs.getString('language') ?? 'system';
  //     _theme = prefs.getString('theme') ?? 'system';
  //   });
  // }

  /// 初始化方法，确保 authorize 和 fetchData 只调用一次
  Future<void> _initialize() async {
    await fetchData();

    // 调用授权方法
    final authorized = await _healthService.authorize();
    setState(() {
      _isAuthorized = authorized;
      if (!authorized) {
        _errorMessage = "Authorization failed. Please grant the required permissions.";
      }
    });

    // 如果授权成功，自动获取数据
    // if (authorized) {
    //   await fetchData();
    // }
  }

  /// Install Google Health Connect on this phone.
  Future<void> installHealthConnect() async {
    final health = GetIt.I<Health>();
    await health.installHealthConnect();
  }

  /// Authorize, i.e. get permissions to access relevant health data.
  Future<void> authorize() async {
    final health = GetIt.I<Health>();
    // If we are trying to read Step Count, Workout, Sleep or other data that requires
    // the ACTIVITY_RECOGNITION permission, we need to request the permission first.
    // This requires a special request authorization call.
    //
    // The location permission is requested for Workouts using the Distance information.
    await Permission.activityRecognition.request();
    await Permission.location.request();

    // Check if we have health permissions
    bool? hasPermissions = await health.hasPermissions(types, permissions: permissions);

    // hasPermissions = false because the hasPermission cannot disclose if WRITE access exists.
    // Hence, we have to request with WRITE as well.
    hasPermissions = false;

    bool authorized = false;
    if (!hasPermissions) {
      // requesting access to the data types before reading them
      try {
        authorized = await health.requestAuthorization(types, permissions: permissions);
        await health.requestHealthDataHistoryAuthorization(); // for READ_HEALTH_DATA_HISTORY
      } catch (error) {
        debugPrint("Exception in authorize: $error");
      }
    }

    authorized = await health.requestHealthDataInBackgroundAuthorization();

    setState(() => _state = (authorized) ? AppState.AUTHORIZED : AppState.AUTH_NOT_GRANTED);
  }

  /// Gets the Health Connect status on Android.
  Future<void> getHealthConnectSdkStatus() async {
    final health = GetIt.I<Health>();
    assert(Platform.isAndroid, "This is only available on Android");

    final status = await health.getHealthConnectSdkStatus();

    setState(() {
      _contentHealthConnectStatus = Text('Health Connect Status: ${status?.name.toUpperCase()}');
      _state = AppState.HEALTH_CONNECT_STATUS;
    });
  }

  /// Fetch data points from the health plugin and show them in the app.
  Future<void> fetchData() async {
    setState(() => _state = AppState.FETCHING_DATA);

    // get data within the last 24 hours
    final DateTime now = DateTime.now();
    final DateTime yesterday = now.subtract(const Duration(hours: 24 * 6)); // 將時間設置為 00:00:00
    DateTime adjustedResult = DateTime(yesterday.year, yesterday.month, yesterday.day);

    // Clear old data points
    _healthDataList.clear();

    _healthDataList = await _healthService.fetchData(startTime: adjustedResult, endTime: now) ?? [];

    // Get a location for the database on disk
    // final Directory appDir = await getApplicationDocumentsDirectory();
    // final File dbFile = File(p.join(appDir.path, 'dHealth.sqlite'));

    // Create database instance
    // final StepDatabase database = StepDatabase(NativeDatabase(dbFile));
    // For test
    // final database = StepDatabase(NativeDatabase.memory());

    // Create step data service
    final StepDataService stepService = StepDataService();

    // Sync new data daily
    await stepService.syncNewData();

    // To refresh a specific range:
    // await stepService.refreshDataRange(DateTime(2025, 3, 29), DateTime(2025, 4, 30));
    // await stepService.refreshDataRange(DateTime.now().subtract(const Duration(days: 1)), DateTime.now().add(const Duration(days: 3)));

    // To refresh all data:
    // stepService.refreshAllData();

    // final destPath = await copyDatabaseToDownloads();

    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Database copied to: $destPath")));

    // // get data from the last week
    // try {
    //   // fetch health data
    //   List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
    //     types: types,
    //     startTime: yesterday,
    //     endTime: now,
    //     recordingMethodsToFilter: recordingMethodsToFilter,
    //   );

    //   debugPrint(
    //     'Total number of data points: ${healthData.length}. '
    //     '${healthData.length > 100 ? 'Only showing the first 100.' : ''}',
    //   );

    //   // sort the data points by date
    //   healthData.sort((a, b) => b.dateTo.compareTo(a.dateTo));

    //   // save all the new data points (only the first 100)
    //   _healthDataList.addAll(
    //     (healthData.length < 10000) ? healthData : healthData.sublist(0, 100),
    //   );
    // } catch (error) {
    //   debugPrint("Exception in getHealthDataFromTypes: $error");
    // }

    // // filter out duplicates
    // _healthDataList = health.removeDuplicates(_healthDataList);

    // for (var data in _healthDataList) {
    //   debugPrint("QQQ ${toJsonString(data)}");
    // }

    // update the UI to display the results
    setState(() {
      _state = _healthDataList.isEmpty ? AppState.NO_DATA : AppState.DATA_READY;
    });
  }

  /// Fetch steps from the health plugin and show them in the app.
  Future<void> fetchStepData() async {
    final health = GetIt.I<Health>();
    int? steps;

    // get steps for today (i.e., since midnight)
    final DateTime now = DateTime.now();
    final DateTime midnight = DateTime(now.year, now.month, now.day - 7);

    bool stepsPermission = await health.hasPermissions([HealthDataType.STEPS]) ?? false;
    if (!stepsPermission) {
      stepsPermission = await health.requestAuthorization([HealthDataType.STEPS]);
    }

    if (stepsPermission) {
      try {
        steps = await health.getTotalStepsInInterval(midnight, now, includeManualEntry: !recordingMethodsToFilter.contains(RecordingMethod.manual));
      } catch (error) {
        debugPrint("Exception in getTotalStepsInInterval: $error");
      }

      debugPrint('(1)Total number of steps: $steps');

      setState(() {
        _nofSteps = (steps == null) ? 0 : steps;
        _state = (steps == null) ? AppState.NO_DATA : AppState.STEPS_READY;
      });
    } else {
      debugPrint("Authorization not granted - error in authorization");
      setState(() => _state = AppState.DATA_NOT_FETCHED);
    }
  }

  /// Revoke access to health data. Note, this only has an effect on Android.
  Future<void> revokeAccess() async {
    final health = GetIt.I<Health>();
    setState(() => _state = AppState.PERMISSIONS_REVOKING);

    bool success = false;

    try {
      await health.revokePermissions();
      success = true;
    } catch (error) {
      debugPrint("Exception in revokeAccess: $error");
    }

    setState(() {
      _state = success ? AppState.PERMISSIONS_REVOKED : AppState.PERMISSIONS_NOT_REVOKED;
    });
  }

  // UI building below

  @override
  Widget build(BuildContext context) {
    final health = GetIt.I<Health>();
    final SettingsModel settings = Provider.of<SettingsModel>(context);
    return MaterialApp(
      // theme: ThemeData.light(),
      theme: ThemeData(
        primarySwatch: Colors.green,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.green, accentColor: Colors.greenAccent),
        drawerTheme: DrawerThemeData(
          backgroundColor: Colors.green[50], // 淺綠色背景
        ),
      ),
      // darkTheme: ThemeData.dark(),
      darkTheme: ThemeData(primarySwatch: Colors.green, colorScheme: ColorScheme.dark(primary: Colors.green[700]!, secondary: Colors.greenAccent)),
      themeMode: settings.getThemeMode(),
      locale: settings.getLocale(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [Locale('en', ''), Locale('zh', 'Hant'), Locale('zh', 'Hans')],
      home: Builder(
        // Add Builder here to ensure Scaffold gets a localized context
        builder: (BuildContext scaffoldContext) {
          return Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              title: const Text('dHealth'),
              leading: Builder(
                builder: (BuildContext context) {
                  return IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer());
                },
              ),
            ),
            drawer: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(color: Theme.of(scaffoldContext).primaryColor),
                    child: Text(AppLocalizations.of(scaffoldContext)?.menu ?? 'Menu', style: const TextStyle(color: Colors.white, fontSize: 24)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.widgets),
                    title: Text(AppLocalizations.of(scaffoldContext)?.widgets ?? 'Widgets'),
                    onTap: () {
                      Navigator.pop(scaffoldContext);
                      Navigator.push(scaffoldContext, MaterialPageRoute(builder: (context) => const WidgetsScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.import_export),
                    title: Text(AppLocalizations.of(scaffoldContext)?.importExport ?? 'Import/Export'),
                    onTap: () {
                      Navigator.pop(scaffoldContext);
                      Navigator.push(scaffoldContext, MaterialPageRoute(builder: (context) => ImportExportScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: Text(AppLocalizations.of(scaffoldContext)?.setup ?? 'Setup'),
                    onTap: () {
                      Navigator.pop(scaffoldContext);
                      Navigator.push(scaffoldContext, MaterialPageRoute(builder: (context) => const SetupScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications_rounded),
                    title: Text(AppLocalizations.of(scaffoldContext)?.notificationSettings ?? 'Notification Settings'),
                    onTap: () {
                      Navigator.pop(scaffoldContext);
                      Navigator.push(scaffoldContext, MaterialPageRoute(builder: (context) => const NotificationSetupScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: Text(AppLocalizations.of(scaffoldContext)?.about ?? 'About'),
                    onTap: () {
                      Navigator.pop(scaffoldContext);
                      Navigator.push(scaffoldContext, MaterialPageRoute(builder: (context) => const AboutScreen()));
                    },
                  ),
                ],
              ),
            ),
            body: Column(
              children: [
                Wrap(
                  spacing: 10,
                  children: [
                    if (Platform.isAndroid)
                      TextButton(
                        onPressed: getHealthConnectSdkStatus,
                        style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.blue)),
                        child: const Text("Check Health Connect Status", style: TextStyle(color: Colors.white)),
                      ),
                    if (Platform.isAndroid && health.healthConnectSdkStatus != HealthConnectSdkStatus.sdkAvailable)
                      TextButton(
                        onPressed: installHealthConnect,
                        style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.blue)),
                        child: const Text("Install Health Connect", style: TextStyle(color: Colors.white)),
                      ),
                    if (Platform.isIOS || Platform.isAndroid && health.healthConnectSdkStatus == HealthConnectSdkStatus.sdkAvailable)
                      Wrap(
                        spacing: 10,
                        children: [
                          TextButton(
                            onPressed: authorize,
                            style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.blue)),
                            child: const Text("Authenticate", style: TextStyle(color: Colors.white)),
                          ),
                          TextButton(
                            // onPressed: fetchData,
                            onPressed: () async {
                              // Call fetchData and wait for the result
                              await fetchData();
                              // Show the returned message in a dialog, if still mounted
                              // if (mounted) {
                              //   showDialog(
                              //     context: context,
                              //     builder:
                              //         (context) => AlertDialog(
                              //           title: Text('Result'),
                              //           content: Text("Fetch data ok"), // Display the message from fetchData
                              //           actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('OK'))],
                              //         ),
                              //   );
                              // }
                            },

                            style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.blue)),
                            child: const Text("Fetch Data", style: TextStyle(color: Colors.white)),
                          ),
                          TextButton(
                            // onPressed: addData,
                            onPressed: () => addData(health),
                            style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.blue)),
                            child: const Text("Add Data", style: TextStyle(color: Colors.white)),
                          ),
                          TextButton(
                            // onPressed: deleteData,
                            onPressed: () => deleteData(health),
                            style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.blue)),
                            child: const Text("Delete Data", style: TextStyle(color: Colors.white)),
                          ),
                          TextButton(
                            onPressed: fetchStepData,
                            style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.blue)),
                            child: const Text("Fetch Step Data", style: TextStyle(color: Colors.white)),
                          ),
                          TextButton(
                            onPressed: revokeAccess,
                            style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.blue)),
                            child: const Text("Revoke Access", style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                  ],
                ),
                const Divider(thickness: 3),
                // if (_state == AppState.DATA_READY) _dataFiltration,
                if (_state == AppState.STEPS_READY) _stepsFiltration,
                Expanded(child: Center(child: _content)),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget get _dataFiltration => Column(
  //   children: [
  //     Wrap(
  //       children: [
  //         for (final method
  //             in Platform.isAndroid
  //                 ? [RecordingMethod.manual, RecordingMethod.automatic, RecordingMethod.active, RecordingMethod.unknown]
  //                 : [RecordingMethod.automatic, RecordingMethod.manual])
  //           SizedBox(
  //             width: 150,
  //             child: CheckboxListTile(
  //               title: Text('${method.name[0].toUpperCase()}${method.name.substring(1)} entries'),
  //               value: !recordingMethodsToFilter.contains(method),
  //               onChanged: (value) {
  //                 setState(() {
  //                   if (value!) {
  //                     recordingMethodsToFilter.remove(method);
  //                   } else {
  //                     recordingMethodsToFilter.add(method);
  //                   }
  //                   fetchData();
  //                 });
  //               },
  //               controlAffinity: ListTileControlAffinity.leading,
  //               contentPadding: EdgeInsets.zero,
  //               dense: true,
  //             ),
  //           ),
  //         // Add other entries here if needed
  //       ],
  //     ),
  //     const Divider(thickness: 3),
  //   ],
  // );

  Widget get _stepsFiltration => Column(
    children: [
      Wrap(
        children: [
          for (final method in [RecordingMethod.manual])
            SizedBox(
              width: 150,
              child: CheckboxListTile(
                title: Text('${method.name[0].toUpperCase()}${method.name.substring(1)} entries'),
                value: !recordingMethodsToFilter.contains(method),
                onChanged: (value) {
                  setState(() {
                    if (value!) {
                      recordingMethodsToFilter.remove(method);
                    } else {
                      recordingMethodsToFilter.add(method);
                    }
                    fetchStepData();
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          // Add other entries here if needed
        ],
      ),
      const Divider(thickness: 3),
    ],
  );

  Widget get _permissionsRevoking => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      Container(padding: const EdgeInsets.all(20), child: const CircularProgressIndicator(strokeWidth: 10)),
      const Text('Revoking permissions...'),
    ],
  );

  Widget get _permissionsRevoked => const Text('Permissions revoked.');

  Widget get _permissionsNotRevoked => const Text('Failed to revoke permissions');

  Widget get _contentFetchingData => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      Container(padding: const EdgeInsets.all(20), child: const CircularProgressIndicator(strokeWidth: 10)),
      const Text('Fetching data...'),
    ],
  );

  Widget get _contentDataReady => ListView.builder(
    padding: const EdgeInsets.all(8),
    itemCount: _healthDataList.length + 4, // +2 for histograms
    itemBuilder: (context, index) {
      if (index == 0) {
        return SizedBox(height: 310, child: _buildHourlyHistogram(context));
      }
      if (index == 1) {
        return SizedBox(height: 300, child: _build7DaysHistogram(context));
      }
      if (index == 2) {
        return SizedBox(height: 300, child: _build7WeeksHistogram(context));
      }
      if (index == 3) {
        return SizedBox(height: 300, child: _build7MonthsHistogram(context));
      }

      // 取得健康數據
      final p = _healthDataList[index - 4];

      // 過濾不需要的數據
      if (recordingMethodsToFilter.contains(p.recordingMethod)) {
        return const SizedBox.shrink();
      }

      return _buildHealthDataTile(p);
    },
  );

  // 健康數據的 ListTile 生成函式
  Widget _buildHealthDataTile(HealthDataPoint p) {
    if (p.value is AudiogramHealthValue) {
      return ListTile(
        title: Text("${p.typeString}: ${p.value}"),
        trailing: Text(p.unitString),
        subtitle: Text('${p.dateFrom} - ${p.dateTo}\n${p.recordingMethod}'),
      );
    }
    if (p.value is WorkoutHealthValue) {
      return ListTile(
        title: Text(
          "${p.typeString}: ${(p.value as WorkoutHealthValue).totalEnergyBurned} ${(p.value as WorkoutHealthValue).totalEnergyBurnedUnit?.name}",
        ),
        trailing: Text((p.value as WorkoutHealthValue).workoutActivityType.name),
        subtitle: Text('${p.dateFrom} - ${p.dateTo}\n${p.recordingMethod}'),
      );
    }
    if (p.value is NutritionHealthValue) {
      return ListTile(
        title: Text("${p.typeString} ${(p.value as NutritionHealthValue).meal_type}: ${(p.value as NutritionHealthValue).name}"),
        trailing: Text('${(p.value as NutritionHealthValue).calories} kcal'),
        subtitle: Text('${p.dateFrom} - ${p.dateTo}\n${p.recordingMethod}'),
      );
    }
    return ListTile(
      title: Text("${p.typeString}: ${p.value}"),
      trailing: Text(p.unitString),
      subtitle: Text('${p.dateFrom} - ${p.dateTo}\n${p.recordingMethod}'),
    );
  }

  // Function to get the StepDatabase instance
  Future<StepDatabase> getStepDatabase() async {
    // 1. Get the directory for storing the database file
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'dHealth.sqlite'));

    // 2. Create a QueryExecutor using NativeDatabase
    final executor = NativeDatabase(file);

    // 3. Return the StepDatabase instance
    return StepDatabase(executor);
  }

  Widget _buildHourlyHistogram(BuildContext context) {
    // 此函式如果直接寫在 children 裡面，每次 UI 更新時，函式都會被重新執行（特別是 _healthDataList 變動時）。
    // 如果這些函式內有較多邏輯，可能會影響效能。
    return buildHourlyHistogram(context, _healthDataList);
  }

  Widget _build7DaysHistogram(BuildContext context) {
    // return buildDailyHistogram(_healthDataList);
    return FutureBuilder<StepDatabase>(
      future: getStepDatabase(), // Fetch the database instance
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator()); // Show loading indicator
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}')); // Handle errors
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('Database not available')); // Fallback
        }

        final database = snapshot.data!;
        // return buildLast7DaysChart(database); // Pass the database to your chart function
        return buildLastNDaysChart(context, database, n: 7); // Last 7 days
      },
    );
  }

  Widget _build7WeeksHistogram(BuildContext context) {
    // return buildDailyHistogram(_healthDataList);
    return FutureBuilder<StepDatabase>(
      future: getStepDatabase(), // Fetch the database instance
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator()); // Show loading indicator
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}')); // Handle errors
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('Database not available')); // Fallback
        }

        final database = snapshot.data!;
        // return buildLast31DaysChart(database); // Pass the database to your chart function
        return buildLastNWeeksChart(context, database, n: 7); // Last 31 weeks
      },
    );
  }

  Widget _build7MonthsHistogram(BuildContext context) {
    // return buildDailyHistogram(_healthDataList);
    return FutureBuilder<StepDatabase>(
      future: getStepDatabase(), // Fetch the database instance
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator()); // Show loading indicator
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}')); // Handle errors
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('Database not available')); // Fallback
        }

        final database = snapshot.data!;
        // return buildLast31DaysChart(database); // Pass the database to your chart function
        return buildLastNMonthsChart(context, database, n: 7); // Last 31 weeks
      },
    );
  }

  final Widget _contentNoData = const Text('No Data to show');

  final Widget _contentNotFetched = const Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text("Press 'Auth' to get permissions to access health data."),
      Text("Press 'Fetch Dat' to get health data."),
      Text("Press 'Add Data' to add some random health data."),
      Text("Press 'Delete Data' to remove some random health data."),
    ],
  );

  final Widget _authorized = const Text('Authorization granted!');

  final Widget _authorizationNotGranted = const Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text('Authorization not given.'),
      Text('For Google Health Connect please check if you have added the right permissions and services to the manifest file.'),
      Text('For Apple Health check your permissions in Apple Health.'),
    ],
  );

  Widget _contentHealthConnectStatus = const Text('No status, click getHealthConnectSdkStatus to get the status.');

  final Widget _dataAdded = const Text('Data points inserted successfully.');

  final Widget _dataDeleted = const Text('Data points deleted successfully.');

  Widget get _stepsFetched => Text('(2)Total number of steps: $_nofSteps.');

  final Widget _dataNotAdded = const Text('Failed to add data.\nDo you have permissions to add data?');

  final Widget _dataNotDeleted = const Text('Failed to delete data');

  Widget get _content => switch (_state) {
    AppState.DATA_READY => _contentDataReady,
    AppState.DATA_NOT_FETCHED => _contentNotFetched,
    AppState.FETCHING_DATA => _contentFetchingData,
    AppState.NO_DATA => _contentNoData,
    AppState.AUTHORIZED => _authorized,
    AppState.AUTH_NOT_GRANTED => _authorizationNotGranted,
    AppState.DATA_ADDED => _dataAdded,
    AppState.DATA_DELETED => _dataDeleted,
    AppState.DATA_NOT_ADDED => _dataNotAdded,
    AppState.DATA_NOT_DELETED => _dataNotDeleted,
    AppState.STEPS_READY => _stepsFetched,
    AppState.HEALTH_CONNECT_STATUS => _contentHealthConnectStatus,
    AppState.PERMISSIONS_REVOKING => _permissionsRevoking,
    AppState.PERMISSIONS_REVOKED => _permissionsRevoked,
    AppState.PERMISSIONS_NOT_REVOKED => _permissionsNotRevoked,
  };
}

class WidgetsScreen extends StatelessWidget {
  const WidgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)?.widgets ?? 'Widgets')),
      body: const Center(child: Text('Widgets Screen Content')),
    );
  }
}

// class ImportExportScreen extends StatelessWidget {
//   const ImportExportScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(AppLocalizations.of(context)?.importExport ?? 'Import/Export')),
//       body: const Center(child: Text('Import/Export Screen Content')),
//     );
//   }
// }

// class AboutScreen extends StatelessWidget {
//   const AboutScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(AppLocalizations.of(context)?.about ?? 'About')),
//       body: const Center(child: Text('About Screen Content')),
//     );
//   }
// }
