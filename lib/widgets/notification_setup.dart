import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dsteps/generated/l10n/app_localizations.dart';
import '../settings_model.dart'; // Import your SettingsModel

// notification_enabled: Boolean, default true (Enable Notifications).
// notification_frequency: Integer (minutes), default 15 (Notification Frequency).
// notification_reach_goal: Boolean, default true (Reach Goal Notification).
// notification_motivation: Boolean, default true (Motivation Notification).
// notification_motivation_time_limit: Integer (hours), default 1 (Motivation Time Limit).
// notification_exception: Boolean, default true (Exception Notification).
// notification_accomplishment: Boolean, default true (New Accomplishment Notification).
// notification_sound_enabled: Boolean, default true (Notification Sound).
// notification_vibration_enabled: Boolean, default true (Vibration).
// notification_priority: String (low, default, high), default default (Notification Priority).
// notification_start_time: String (e.g., 8:0), default 8:0 (Start Time, 8 AM).
// notification_end_time: String (e.g., 22:0), default 22:0 (End Time, 10 PM).

// the above is my app's setup widget, I want to build another file to setup notification's setup.
// 1. suggest name for the 2 files and class name. the original is "setup", I want to add another for notification only
// 2. this new setup widget should config these settings by shared_preferences (use async)
// 2.1 enable notification or not (value is bool, default is true)
// 2.2 notify frequency, default is 15 mins. If users want to change, let me to choose some common values and another custom option
// 2.3 choose what notification want to show
// 2.3.1 reach goal notification, default is true
// 2.3.2 motivation (Almost There Notification) or not, default is true. => if I'm near the goal, show a message to encourage
// 2.3.2.1 motivation time limit: only show motivation at most 1 time in x hours (x is config, default is 1)
// 2.3.3 show exception or not, default is true
// 2.4 show a new accomplishment, default is true
// 3. all above setup use use the same prefix in shared_preferences and give me a list
// 4. reference the layout from https://github.com/AntennaPod/AntennaPod/blob/84907b114fc4688c5ede9e25066a597145cf8d89/ui/preferences/src/main/res/xml/preferences_import_export.xml#L9
// 5. I use awesome_notification, any setup I should open for users?

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
              value: settings.notificationFrequency,
              items: [
                DropdownMenuItem(value: 5, child: Text(localizations.minutes(5))),
                DropdownMenuItem(value: 15, child: Text(localizations.minutes(15))),
                DropdownMenuItem(value: 30, child: Text(localizations.minutes(30))),
                DropdownMenuItem(value: 60, child: Text(localizations.minutes(60))),
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
                value: settings.motivationTimeLimit,
                items: [
                  DropdownMenuItem(value: 1, child: Text(localizations.hours(1))),
                  DropdownMenuItem(value: 2, child: Text(localizations.hours(2))),
                  DropdownMenuItem(value: 4, child: Text(localizations.hours(4))),
                  DropdownMenuItem(value: 8, child: Text(localizations.hours(8))),
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

          // New Accomplishment
          SwitchListTile(
            title: Text(localizations.newAccomplishmentNotification, style: TextStyle(color: textColor)),
            subtitle: Text(localizations.newAccomplishmentNotificationDescription, style: TextStyle(color: secondaryTextColor)),
            value: settings.accomplishment,
            onChanged: (value) => settings.setAccomplishment(value),
          ),
          const Divider(),

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
              value: settings.priority,
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

          // Notification Time Window
          Text(localizations.notificationTimeWindow, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: textColor)),
          ListTile(
            title: Text(localizations.startTime, style: TextStyle(color: textColor)),
            subtitle: Text(localizations.startTimeDescription, style: TextStyle(color: secondaryTextColor)),
            trailing: Text(settings.startTime.format(context), style: TextStyle(color: textColor)),
            onTap: () async {
              final time = await showTimePicker(context: context, initialTime: settings.startTime);
              if (time != null) {
                settings.setStartTime(time);
              }
            },
          ),
          ListTile(
            title: Text(localizations.endTime, style: TextStyle(color: textColor)),
            subtitle: Text(localizations.endTimeDescription, style: TextStyle(color: secondaryTextColor)),
            trailing: Text(settings.endTime.format(context), style: TextStyle(color: textColor)),
            onTap: () async {
              final time = await showTimePicker(context: context, initialTime: settings.endTime);
              if (time != null) {
                settings.setEndTime(time);
              }
            },
          ),
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
