import 'package:dhealth/generated/l10n/app_localizations.dart';
import 'package:dhealth/settings_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// dropdown 的選項清單。items 與「目前值是否可顯示」的判斷共用同一個來源 ——
/// 兩邊各寫一次的話，日後加選項只改一邊就會重新踩進 DropdownButton 的 assertion
/// （value 不在 items 裡：debug 直接炸、release 空白看不到現值）。
const _languages = ['system', 'en', 'zh_Hant', 'zh_Hans'];
const _themes = ['system', 'light', 'dark'];

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  // 每日目標輸入框的 controller 收進 State：以前每次 build 現做一顆新的 ——
  // 傳了 controller 的 TextField 不會 dispose 它（每 build 洩一顆），
  // 而且游標/輸入法狀態每次重建都跳回結尾。
  final _goalController = TextEditingController();
  bool _goalInitialized = false;

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  /// 外部改目標（+/- 按鈕、合法 submit）時同步進 controller。
  /// 只在 handler 裡動 controller（不在 build 裡 —— build 中 notify 會讓
  /// TextField 在 build 期間 setState）。
  void _setGoal(SettingsModel settings, int value) {
    settings.setDailyStepGoal(value);
    _goalController.text = value.toString();
    _goalController.selection = TextSelection.fromPosition(TextPosition(offset: value.toString().length));
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final settings = Provider.of<SettingsModel>(context);
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDarkTheme ? Colors.white.withValues(alpha: .8) : Theme.of(context).hintColor;

    // 首次 build 把現值放進 controller（此刻 TextField 的 State 還沒建立、
    // 沒有 listener，設 text 不會 notify；之後的同步都走 _setGoal 的 handler）。
    if (!_goalInitialized) {
      _goalInitialized = true;
      _goalController.text = settings.dailyStepGoal.toString();
      _goalController.selection = TextSelection.fromPosition(TextPosition(offset: _goalController.text.length));
    }

    // Custom Sync Frequency Dialog
    Future<void> showCustomDialog(SettingsModel settings) async {
      int? customValue;
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(localizations.customSyncTitle),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[700]! // Visible in dark theme
                        : Colors.grey[300]!, // Visible in light theme
              ),
            ),
            // backgroundColor: Theme.of(context).dialogBackgroundColor,
            backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
            content: TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: localizations.interval,
                suffixText: localizations.minutesUnit,
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors
                                .white70 // Visible in dark theme
                            : Colors.black54, // Visible in light theme
                  ),
                ),
              ),
              onChanged: (value) {
                customValue = int.tryParse(value);
              },
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(localizations.cancel)),
              TextButton(
                onPressed: () {
                  if (customValue != null) {
                    settings.setSyncFrequency(customValue!);
                  }
                  Navigator.pop(context);
                },
                child: Text(localizations.save),
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(localizations.setup), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          // Interface Section (Language and Theme)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              localizations.interface,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            dense: true, // Reduces height
            title: Text(localizations.selectLanguage),
            subtitle: DropdownButton<String>(
              // 存了不在清單的值（舊版殘留／手工改過）時走 null + hint 顯示現值。
              value: _languages.contains(settings.language) ? settings.language : null,
              hint: Text(settings.language),
              isExpanded: true,
              items: [
                DropdownMenuItem(value: 'system', child: Text(localizations.followSystem)),
                DropdownMenuItem(value: 'en', child: Text(localizations.english)),
                DropdownMenuItem(value: 'zh_Hant', child: Text(localizations.traditionalChinese)),
                DropdownMenuItem(value: 'zh_Hans', child: Text(localizations.simplifiedChinese)),
              ],
              onChanged: (value) => value != null ? settings.setLanguage(value) : null,
            ),
          ),
          ListTile(
            dense: true, // Reduces height
            title: Text(localizations.selectTheme),
            subtitle: DropdownButton<String>(
              // 同款防護（見 language 那顆的註解）。
              value: _themes.contains(settings.theme) ? settings.theme : null,
              hint: Text(settings.theme),
              isExpanded: true,
              items: [
                DropdownMenuItem(value: 'system', child: Text(localizations.followSystem)),
                DropdownMenuItem(value: 'light', child: Text(localizations.light)),
                DropdownMenuItem(value: 'dark', child: Text(localizations.dark)),
              ],
              onChanged: (value) => value != null ? settings.setTheme(value) : null,
            ),
          ),

          // Health Data Sync Section
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              localizations.healthDataSync,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            localizations.healthDataSyncDesc,
            style: TextStyle(color: secondaryTextColor),
          ),
          SwitchListTile(
            title: Text(localizations.enableBackgroundSync),
            value: settings.healthSyncEnabled,
            onChanged: (value) => settings.setHealthSyncEnabled(value),
          ),
          if (settings.healthSyncEnabled) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text(localizations.syncFrequency),
                    trailing: SizedBox(
                      width: 150, // Adjust this value based on your layout
                      child: DropdownButton<int>(
                        isExpanded: true,
                        // syncFrequency 非 nullable，只需檢查是否落在預設清單內（不在時才顯示 hint）
                        value:
                            settings.predefinedSyncFrequency.contains(settings.syncFrequency)
                                ? settings.syncFrequency
                                : null,
                        hint: Text('${settings.syncFrequency} ${localizations.minutesUnit}'),
                        items:
                            settings.predefinedSyncFrequency
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value == 60 ? localizations.oneHour : '$value ${localizations.minutesUnit}'),
                                  ),
                                )
                                .toList()
                              ..add(
                                DropdownMenuItem(
                                  value: -1, // Flag for custom
                                  child: Text(localizations.custom),
                                ),
                              ),
                        onChanged: (value) async {
                          if (value == -1) {
                            await showCustomDialog(settings);
                          } else if (value != null) {
                            settings.setSyncFrequency(value);
                          }
                        },
                        dropdownColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[800] // Visible dropdown in dark theme
                                : Colors.white, // Light theme
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  ListTile(
                    title: Text(localizations.activeHours),
                    subtitle: Text(localizations.activeHoursRange(settings.activeStartHour, settings.activeEndHour)),
                    onTap: () => showActiveHoursPicker(settings),
                  ),
                  // 這裡原本有 Start on Boot / Stop on Terminate / Persistent Sync 三顆開關：
                  // 它們只是把值寫進 prefs，全案沒有任何一行程式碼讀它們（而且 Android 上也做不到
                  // 「使用者強制停止後還繼續同步」）。會騙人的開關比沒有開關更糟，整組刪除。
                  // 背景同步真正的開關是上面的 Enable Background Sync（真的會去重排 WorkManager）。
                ],
              ),
            ),
          ],

          // Display Settings
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              localizations.displaySettings,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: Text(localizations.showCumulativeSteps),
            value: settings.showCumulative,
            onChanged: (value) => settings.setShowCumulative(value),
          ),
          SwitchListTile(
            title: Text(localizations.showDailyStepGoal),
            // 這裡原本寫 `value: settings.showCumulative`（從上面那顆複製過來忘了改）：
            // 開關顯示的狀態跟它實際控制的值是兩回事 —— 關掉「累計步數」後這顆會顯示 OFF，
            // 但目標線其實還在，點第一下只是把 OFF 改成 ON、圖表完全沒變化，看起來像壞掉。
            // 同一個設定在 charts.dart 的 _MiniSwitch 綁的是對的欄位，兩個畫面會互相打臉。
            value: settings.showDailyStepGoal,
            onChanged: (value) => settings.setShowDailyStepGoal(value),
          ),

          // Daily Step Goal Section
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              localizations.dailyStepGoal,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: Text(localizations.setDailyStepGoal),
            subtitle: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    if (settings.dailyStepGoal > 1000) {
                      _setGoal(settings, settings.dailyStepGoal - 1000);
                    }
                  },
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '1000-20000',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                    ),
                    controller: _goalController,
                    onSubmitted: (value) {
                      final int? newValue = int.tryParse(value);
                      if (newValue != null && newValue >= 1000 && newValue <= 20000) {
                        _setGoal(settings, newValue);
                        return;
                      }
                      // 原本這裡是 `if (合法) 才 set`，不合法就什麼都不做 —— 欄位下次 build
                      // 就跳回舊值，使用者看到的是「我打了數字沒有反應」。起碼講一句範圍。
                      ScaffoldMessenger.of(context)
                        ..clearSnackBars()
                        ..showSnackBar(SnackBar(content: Text(localizations.dailyStepGoalRange), duration: const Duration(seconds: 2)));
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (settings.dailyStepGoal < 20000) {
                      _setGoal(settings, settings.dailyStepGoal + 1000);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showActiveHoursPicker(SettingsModel settings) async {
    final localizations = AppLocalizations.of(context)!;

    // Helper function to convert hour to TimeOfDay
    TimeOfDay hourToTimeOfDay(int hour) => TimeOfDay(hour: hour, minute: 0);

    // Initial values from settings
    TimeOfDay initialStart = hourToTimeOfDay(settings.activeStartHour);
    TimeOfDay initialEnd = hourToTimeOfDay(settings.activeEndHour);

    // Pick start time using TimePickerDialog explicitly
    final TimeOfDay? pickedStart = await showDialog<TimeOfDay>(
      context: context,
      builder:
          (context) => TimePickerDialog(
            initialTime: initialStart,
            helpText: localizations.selectStartTime,
            initialEntryMode: TimePickerEntryMode.dial,
          ),
    );

    if (pickedStart == null || !mounted) return; // User canceled or widget unmounted

    // Pick end time using TimePickerDialog explicitly
    final TimeOfDay? pickedEnd = await showDialog<TimeOfDay>(
      context: context,
      builder:
          (context) => TimePickerDialog(
            initialTime: initialEnd,
            helpText: localizations.selectEndTime,
            initialEntryMode: TimePickerEntryMode.dial,
          ),
    );

    if (pickedEnd == null || !mounted) return; // User canceled or widget unmounted

    // 只有「開始＝結束」才是真的設定錯。以前這裡用 `endMinutes <= startMinutes` 把
    // 22:00 → 07:00 這種跨午夜時段也一起擋掉，但 `NotificationWindow.contains()` 本來
    // 就支援跨午夜 —— 夜貓子因此永遠設不了自己要的通知時段。
    // （資料庫只有「時」的解析度，所以比較的是小時；選了同一小時代表整點範圍沒有意義。）
    if (pickedStart.hour == pickedEnd.hour) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.activeHoursSameHourError), duration: const Duration(seconds: 2)),
        );
      }
      return;
    }

    // Update settings with new values
    settings.setActiveStartHour(pickedStart.hour);
    settings.setActiveEndHour(pickedEnd.hour);
  }
}
