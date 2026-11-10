import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dhealth/generated/l10n/app_localizations.dart';
import '../settings_keys.dart';
import '../settings_model.dart'; // Import your SettingsModel

/// 通知設定頁。
///
/// 這裡只放「通知」相關的控制項；**通知時段（Active Hours）不在本頁** ——
/// 它的唯一來源是 `setup.dart` 的 Active Hours（寫 `Prefs.activeStartHour/EndHour`），
/// `NotificationService.canSend()` 讀的就是那一組。之前本頁另有一組 Start/End Time，
/// 存進 `notification_start_time`/`notification_end_time` 兩個沒有人讀的 key：
/// 使用者在這裡調好時段，實際生效的卻是另一頁的設定（而且兩個時間選譯器都預設成 end）。
/// 所以把這組裝飾品刪掉，保留一個來源。

/// dropdown 的選項清單。items 與「目前值是否可顯示」的判斷共用同一個來源 ——
/// 兩邊各寫一次的話，日後加選項只改一邊就會重新踩進 DropdownButton 的 assertion。
///
/// 没有「5 分鐘」这一項：背景一律 `clamp(15, …)`（`background_service.dart`），
/// WorkManager 也不允許更密 —— 放一顆「選了不會生效」的選項比不放更糟。
/// 舊安裝存過 5 的話不會崩：下面的 value 判斷會改走 hint 顯示現值。
const _frequencies = PrefsDefaults.frequencyPresets;
const _timeLimits = [1, 2, 4, 8];
const _priorities = ['low', 'default', 'high'];

class NotificationSetupScreen extends StatelessWidget {
  const NotificationSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final settings = Provider.of<SettingsModel>(context);
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkTheme ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor = isDarkTheme ? Colors.white.withValues(alpha: .8) : Theme.of(context).hintColor;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.notificationSettings)),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(localizations.notification, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: textColor)),
          // Enable Notifications
          SwitchListTile(
            title: Text(localizations.enableNotifications, style: TextStyle(color: textColor)),
            subtitle: Text(localizations.enableNotificationsDescription, style: TextStyle(color: secondaryTextColor)),
            value: settings.notificationsEnabled,
            onChanged: (value) => settings.setNotificationsEnabled(value),
          ),

          // Notification Frequency
          ListTile(
            title: Text(localizations.notificationFrequency, style: TextStyle(color: textColor)),
            subtitle: Text(localizations.notificationFrequencyDescription, style: TextStyle(color: secondaryTextColor)),
            trailing: DropdownButton<int>(
              // 自訂值（例如 45）不在 items 裡時一定要傳 null + hint：直接傳 value 會讓
              // DropdownButton 在 debug 模式 assertion 炸、release 顯示空白看不到現值。
              // （同專案 setup.dart 的同步頻率 dropdown 已經是這個寫法。）
              value: _frequencies.contains(settings.notificationFrequency) ? settings.notificationFrequency : null,
              hint: Text(localizations.minutes(settings.notificationFrequency)),
              items: [
                for (final m in _frequencies) DropdownMenuItem(value: m, child: Text(localizations.minutes(m))),
                DropdownMenuItem(value: -1, child: Text(localizations.custom)),
              ],
              onChanged: (value) async {
                if (value == -1) {
                  final customValue = await showDialog<int>(context: context, builder: (context) => _CustomFrequencyDialog());
                  if (customValue != null) {
                    settings.setNotificationFrequency(customValue);
                  }
                } else if (value != null) {
                  settings.setNotificationFrequency(value);
                }
              },
            ),
          ),
          const Divider(),

          // Notification Types Section
          Text(localizations.notificationTypes, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: textColor)),
          SwitchListTile(
            title: Text(localizations.reachGoalNotification, style: TextStyle(color: textColor)),
            subtitle: Text(localizations.reachGoalNotificationDescription, style: TextStyle(color: secondaryTextColor)),
            value: settings.reachGoal,
            onChanged: (value) => settings.setReachGoal(value),
          ),
          SwitchListTile(
            title: Text(localizations.motivationNotification, style: TextStyle(color: textColor)),
            subtitle: Text(localizations.motivationNotificationDescription, style: TextStyle(color: secondaryTextColor)),
            value: settings.motivation,
            onChanged: (value) => settings.setMotivation(value),
          ),
          if (settings.motivation)
            ListTile(
              title: Text(localizations.motivationTimeLimit, style: TextStyle(color: textColor)),
              subtitle: Text(localizations.motivationTimeLimitDescription, style: TextStyle(color: secondaryTextColor)),
              trailing: DropdownButton<int>(
                // 同款防護：motivationTimeLimit 是 0..24 的任意值（_clampRange），
                // 舊版殘留的 3 這種值落在 items 外，直接傳 value 會 assertion。
                value: _timeLimits.contains(settings.motivationTimeLimit) ? settings.motivationTimeLimit : null,
                hint: Text(localizations.hours(settings.motivationTimeLimit)),
                items: [
                  for (final h in _timeLimits) DropdownMenuItem(value: h, child: Text(localizations.hours(h))),
                ],
                onChanged: (value) {
                  if (value != null) {
                    settings.setMotivationTimeLimit(value);
                  }
                },
              ),
            ),
          SwitchListTile(
            title: Text(localizations.exceptionNotification, style: TextStyle(color: textColor)),
            subtitle: Text(localizations.exceptionNotificationDescription, style: TextStyle(color: secondaryTextColor)),
            value: settings.exception,
            onChanged: (value) => settings.setException(value),
          ),
          const Divider(),
          // New Accomplishment 的開關刪了：它只寫進 prefs，全案 0 個讀取者，
          // 而且本案只有 Goal Reached / Almost There / Error 三種通知，沒有第四種可以開。

          // Notification Appearance
          Text(localizations.notificationAppearance, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: textColor)),
          SwitchListTile(
            title: Text(localizations.notificationSound, style: TextStyle(color: textColor)),
            subtitle: Text(localizations.notificationSoundDescription, style: TextStyle(color: secondaryTextColor)),
            value: settings.soundEnabled,
            onChanged: (value) => settings.setSoundEnabled(value),
          ),
          SwitchListTile(
            title: Text(localizations.notificationVibration, style: TextStyle(color: textColor)),
            subtitle: Text(localizations.notificationVibrationDescription, style: TextStyle(color: secondaryTextColor)),
            value: settings.vibrationEnabled,
            onChanged: (value) => settings.setVibrationEnabled(value),
          ),
          ListTile(
            title: Text(localizations.notificationPriority, style: TextStyle(color: textColor)),
            subtitle: Text(localizations.notificationPriorityDescription, style: TextStyle(color: secondaryTextColor)),
            trailing: DropdownButton<String>(
              // 同款防護：priority 存了不在清單的值（舊版殘留）時走 null + hint。
              value: _priorities.contains(settings.priority) ? settings.priority : null,
              hint: Text(settings.priority),
              items: [
                DropdownMenuItem(value: 'low', child: Text(localizations.lowPriority)),
                DropdownMenuItem(value: 'default', child: Text(localizations.defaultPriority)),
                DropdownMenuItem(value: 'high', child: Text(localizations.highPriority)),
              ],
              onChanged: (value) {
                if (value != null) {
                  settings.setPriority(value);
                }
              },
            ),
          ),
          const Divider(),

        ],
      ),
    );
  }
}

class _CustomFrequencyDialog extends StatefulWidget {
  @override
  _CustomFrequencyDialogState createState() => _CustomFrequencyDialogState();
}

class _CustomFrequencyDialogState extends State<_CustomFrequencyDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(localizations.customFrequency),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: localizations.minutesLabel, hintText: localizations.enterMinutes),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(localizations.cancel)),
        TextButton(
          onPressed: () {
            final value = int.tryParse(_controller.text);
            if (value != null && value > 0) {
              Navigator.pop(context, value);
            }
          },
          child: Text(localizations.ok),
        ),
      ],
    );
  }
}
