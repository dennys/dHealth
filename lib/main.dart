import 'dart:async';
import 'dart:io';

import 'package:dhealth/di.dart';
import 'package:dhealth/generated/l10n/app_localizations.dart';
import 'package:dhealth/services/background_service.dart';
import 'package:dhealth/services/data_service.dart';
import 'package:dhealth/services/notification_service.dart';
import 'package:dhealth/services/permission_service.dart';
import 'package:dhealth/settings_model.dart';
import 'package:dhealth/widgets/about.dart';
import 'package:dhealth/widgets/charts.dart';
import 'package:dhealth/widgets/import_export.dart';
import 'package:dhealth/widgets/notification_setup.dart';
import 'package:dhealth/widgets/setup.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:provider/provider.dart';

import 'database/database.dart';
import 'database/util.dart';
import 'utils/chart_range.dart';
import 'utils/log.dart';
import 'utils/sync_reason.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // release 版不該把步數、DB 路徑這類 debugPrint 喷到 logcat；
  // 真正的錯誤走 utils/log.dart 的 appError（release 仍進 logcat）。
  if (kReleaseMode) debugPrint = (String? message, {int? wrapWidth}) {};

  await configureDependencies();
  final settings = await SettingsModel.load(); // 載入完成才 runApp：首幀就是正確的設定值
  await NotificationService.initialize();
  await BackgroundService.init();

  runApp(ChangeNotifierProvider.value(value: settings, child: const HealthApp()));
}

class HealthApp extends StatelessWidget {
  const HealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsModel>(context);
    return MaterialApp(
      title: 'dHealth',
      // 與 dNeko 用同一顆 seed（Colors.green）+ 同一個 ColorScheme.fromSeed 做法，
      // 兩案看起來才是一家人；accentColor 已 deprecated，不再手調。
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        drawerTheme: DrawerThemeData(backgroundColor: Colors.green[50]),
      ),
      darkTheme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.dark)),
      themeMode: settings.getThemeMode(),
      locale: settings.getLocale(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// 每次同步完成就 +1，圖表用它決定要不要重抓（避免 FutureBuilder 在 build 裡
  /// 現做 future —— 那是「每次重建都重查一次、畫面一直閃」的根源）。
  int _refreshToken = 0;

  /// 圖表往前翻了几頁（不持久化：重進首頁回到最近一頁）。
  int _rangeOffset = 0;

  /// 上一次畫面的頁碼，只用來決定翻頁動畫的方向。
  int _lastOffset = 0;
  bool _syncing = false;
  PermissionFailure? _permissionFailure;
  HealthConnectSdkStatus? _healthConnectStatus;

  /// null = 「今天到底走了多少我們不知道」（讀取失敗）；有值才是真的讀到（0 步也是有值）。
  Map<int, int>? _hourlyTotals;

  /// 還沒第一次查完今天的小時資料：這段要畫「載入中」，不能跟「讀不到」長一樣。
  bool _hourlyLoading = true;

  StepDatabase get _database => getIt<StepDatabase>();
  StepDataService get _stepService => getIt<StepDataService>();

  @override
  void initState() {
    super.initState();
    unawaited(getIt<Health>().configure().catchError((Object e) => appError('Health.configure() 失敗', e)));
    _checkHealthConnect();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _checkHealthConnect() async {
    if (!Platform.isAndroid) return;
    final status = await getIt<Health>().getHealthConnectSdkStatus();
    if (mounted) setState(() => _healthConnectStatus = status);
  }

  /// 進場：先要權限（沒權限讀到 0 步會看起來像「今天真的沒走路」），再同步一次。
  Future<void> _bootstrap() async {
    // 今天的小時圖不該等「整段歷史同步」跑完才有資料：先獨立查一次，同步結束後會再查一次。
    unawaited(_loadHourlyTotals());
    final failure = await PermissionService.requestStepAccess();
    if (!mounted) return;
    setState(() => _permissionFailure = failure);
    if (failure != null) {
      _showMessage(_permissionMessage(AppLocalizations.of(context)!, failure), error: true);
      return;
    }
    await _sync();
  }

  String _permissionMessage(AppLocalizations l10n, PermissionFailure failure) => switch (failure) {
    PermissionFailure.activityRecognition => l10n.permissionActivityRecognitionMissing,
    PermissionFailure.healthRead => l10n.permissionHealthReadMissing,
  };

  /// 手動/進場同步。失敗一定讓使用者看得见 —— 讀不到資料時資料庫不會被動過，
  /// 但使用者需要知道「現在畫面上的數字是舊的」。
  Future<void> _sync() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final result = await _stepService.syncNewData();
      await _loadHourlyTotals();
      if (!mounted) return;
      setState(() {
        _refreshToken++;
        if (result.status == StepSyncStatus.permissionDenied) _permissionFailure = PermissionFailure.healthRead;
      });
      if (result.status == StepSyncStatus.success) {
        _showMessage(l10n.syncSuccess);
      } else {
        _showMessage('${l10n.syncFailed}: ${result.status.label(l10n)}', error: true);
      }
    } catch (e, st) {
      appError('同步失敗', e, st);
      // 面板只給「失敗了」，例外內容進 log：把 `$e` 攤在面板上通常是英文堆疊，
      // 既看不懂也翻譯不了（跟 StepSyncStatus 走 enum 是同一個理由）。
      if (mounted) _showMessage(l10n.syncFailed, error: true);
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  /// 小時圖的讀取順序：先畫 DB 裡上次存的（冷啟動時 Health Connect 常讀不到，不能讓圖空著），
  /// 再向 Health Connect 查今天的值；讀到就寫回 DB。讀不到則保留舊值，不會因此變成「讀不到」。
  Future<void> _loadHourlyTotals({int maxRetries = 3}) async {
    final now = DateTime.now();
    if (_hourlyTotals == null) {
      final stored = await _database.getHourlySteps(now);
      if (stored.isNotEmpty && mounted) {
        setState(() {
          _hourlyTotals = stored;
          _hourlyLoading = false;
        });
      }
    }

    Map<int, int>? totals;
    // Health Connect 冷啟動時 native 端會吞掉例外並回 null，所以讀不到就隔 2、4、8 秒再試
    for (var attempt = 0; ; attempt++) {
      totals = await _stepService.fetchHourlyTotals(DateTime.now());
      if (totals != null || attempt >= maxRetries || !mounted) break;
      final delay = Duration(seconds: 2 << attempt);
      appLog('今天的小時步數讀不到，${delay.inSeconds} 秒後重試（第 ${attempt + 1} 次）');
      await Future<void>.delayed(delay);
    }
    if (totals != null) await _database.upsertHourlySteps(now, totals);

    if (mounted) {
      setState(() {
        // 讀不到時保留先前的值（DB 快取或上一次成功的結果），null 只代表「從沒讀到過」
        _hourlyTotals = totals ?? _hourlyTotals;
        _hourlyLoading = false;
      });
    }
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? Theme.of(context).colorScheme.error : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
  }

  Future<void> _installHealthConnect() => getIt<Health>().installHealthConnect();

  /// 開子頁面，回來時重抓一次資料。
  ///
  /// 一定要重抓：`Navigator.push` 不會 dispose 底下這棵 tree，圖表是 FutureBuilder +
  /// `_refreshToken`，token 不變就不會重新查詢 —— 使用者在匯入頁讀了 30 天資料按返回，
  /// 看到的還是匯入前的舊圖，會以為匯入沒生效（同樣的問題也適用於改了每日目標/顯示開關）。
  Future<void> _open(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (!mounted) return;
    setState(() => _refreshToken++);
    await _loadHourlyTotals();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = Provider.of<SettingsModel>(context);
    final range = ChartRange.decode(settings.dailyChartRange, _rangeOffset, DateTime.now());
    final healthConnectUnavailable = Platform.isAndroid && _healthConnectStatus != null && _healthConnectStatus != HealthConnectSdkStatus.sdkAvailable;
    // 翻頁動畫方向：offset 變大 = 往舊頁走，新頁從左邊滑入。
    final older = _rangeOffset >= _lastOffset;
    _lastOffset = _rangeOffset;
    final pageKey = ValueKey('${range.periods}-$_rangeOffset');

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('dHealth'),
        // 注意：這裡一定要用 Builder 的 context。Scaffold.of() 要用「Scaffold 之下」的
        // context，直接用 HomeScreen build 的 context 會拿到 Scaffold 之上 → 一點選單就 assertion。
        leading: Builder(
          builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer()),
        ),
        actions: [
          IconButton(
            tooltip: l10n.syncNow,
            icon: _syncing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.sync),
            onPressed: _syncing ? null : _sync,
          ),
        ],
      ),
      drawer: _Drawer(onSelect: _open),
      body: RefreshIndicator(
        onRefresh: _sync,
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            if (healthConnectUnavailable) _HealthConnectUnavailableBanner(onInstall: _installHealthConnect),
            if (_permissionFailure != null)
              _PermissionBanner(
                  message: _permissionMessage(l10n, _permissionFailure!),
                  onRetry: _bootstrap),
            // The old file SQLite could not read is still on the phone as *.corrupt;
            // say so, otherwise the missing history looks like a sync bug.
            if (databaseWasQuarantined) _NoticeCard(message: l10n.databaseQuarantined),
            SizedBox(height: 310, child: HourlyStepsChart(totals: _hourlyTotals, loading: _hourlyLoading)),
            ChartRangeSelector(
              range: range,
              onPeriods: (periods) {
                setState(() => _rangeOffset = 0);
                settings.setDailyChartRange(ChartRange(periods, 0, DateTime.now()).encode());
              },
              onOffset: (offset) => setState(() => _rangeOffset = offset),
            ),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: (details) {
                // 往右滑 = 看更舊的一頁（手指帶動頁面，與常見相簿手勢一致）。
                final dx = details.velocity.pixelsPerSecond.dx;
                if (dx > 200) {
                  setState(() => _rangeOffset++);
                } else if (dx < -200 && _rangeOffset > 0) {
                  setState(() => _rangeOffset--);
                }
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  // 進入頁從滑動來的方向滑入，舊頁往反方向滑出。
                  final isEnter = child.key == pageKey;
                  final begin = isEnter == older ? const Offset(-1, 0) : const Offset(1, 0);
                  return SlideTransition(
                    position: Tween(begin: begin, end: Offset.zero).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Column(
                  key: pageKey,
                  children: [
                    SizedBox(height: 300, child: DailyStepsChart(database: _database, refreshToken: _refreshToken, range: range)),
                    SizedBox(height: 300, child: WeeklyStepsChart(database: _database, refreshToken: _refreshToken, range: range)),
                    SizedBox(height: 300, child: MonthlyStepsChart(database: _database, refreshToken: _refreshToken, range: range)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Drawer extends StatelessWidget {
  const _Drawer({required this.onSelect});

  final void Function(Widget page) onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
            child: Text(l10n.menu, style: const TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            leading: const Icon(Icons.import_export),
            title: Text(l10n.importExport),
            onTap: () {
              Navigator.pop(context);
              onSelect(const ImportExportScreen());
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(l10n.setup),
            onTap: () {
              Navigator.pop(context);
              onSelect(const SetupScreen());
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_rounded),
            title: Text(l10n.notificationSettings),
            onTap: () {
              Navigator.pop(context);
              onSelect(const NotificationSetupScreen());
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(l10n.about),
            onTap: () {
              Navigator.pop(context);
              onSelect(const AboutScreen());
            },
          ),
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.error_outline),
        title: Text(message),
      ),
    );
  }
}

class _HealthConnectUnavailableBanner extends StatelessWidget {
  const _HealthConnectUnavailableBanner({required this.onInstall});

  final Future<void> Function() onInstall;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.health_and_safety),
        title: Text(l10n.healthConnectUnavailable),
        subtitle: Text(l10n.healthConnectUnavailableDesc),
        trailing: FilledButton(onPressed: onInstall, child: Text(l10n.installHealthConnect)),
      ),
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: ListTile(
        leading: Icon(Icons.lock, color: Theme.of(context).colorScheme.onErrorContainer),
        title: Text(message),
        trailing: FilledButton(onPressed: onRetry, child: Text(l10n.retry)),
      ),
    );
  }
}
