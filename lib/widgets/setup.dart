import 'package:dhealth/generated/l10n/app_localizations.dart';
import 'package:dhealth/settings_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final settings = Provider.of<SettingsModel>(context);
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDarkTheme ? Colors.white.withValues(alpha: .8) : Theme.of(context).hintColor;

    // Custom Sync Frequency Dialog
    Future<void> showCustomDialog(SettingsModel settings) async {
      int? customValue;
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(localizations?.customSyncTitle ?? 'Custom Sync Frequency'),
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
                labelText: localizations?.interval ?? 'Interval',
                suffixText: localizations?.minutesUnit ?? 'minutes',
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
              TextButton(onPressed: () => Navigator.pop(context), child: Text(localizations?.cancel ?? 'Cancel')),
              TextButton(
                onPressed: () {
                  if (customValue != null) {
                    settings.setSyncFrequency(customValue!);
                  }
                  Navigator.pop(context);
                },
                child: Text(localizations?.save ?? 'Save'),
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(localizations?.setup ?? 'Setup'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          // Interface Section (Language and Theme)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              localizations?.interface ?? 'Interface',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            dense: true, // Reduces height
            title: Text(localizations?.selectLanguage ?? 'Select Language'),
            subtitle: DropdownButton<String>(
              value: settings.language,
              isExpanded: true,
              items: [
                DropdownMenuItem(value: 'system', child: Text(localizations?.followSystem ?? 'Follow System')),
                DropdownMenuItem(value: 'en', child: Text(localizations?.english ?? 'English')),
                DropdownMenuItem(value: 'zh_Hant', child: Text(localizations?.traditionalChinese ?? 'Traditional Chinese')),
                DropdownMenuItem(value: 'zh_Hans', child: Text(localizations?.simplifiedChinese ?? 'Simplified Chinese')),
              ],
              onChanged: (value) => value != null ? settings.setLanguage(value) : null,
            ),
          ),
          ListTile(
            dense: true, // Reduces height
            title: Text(localizations?.selectTheme ?? 'Select Theme'),
            subtitle: DropdownButton<String>(
              value: settings.theme,
              isExpanded: true,
              items: [
                DropdownMenuItem(value: 'system', child: Text(localizations?.followSystem ?? 'Follow System')),
                DropdownMenuItem(value: 'light', child: Text(localizations?.light ?? 'Light')),
                DropdownMenuItem(value: 'dark', child: Text(localizations?.dark ?? 'Dark')),
              ],
              onChanged: (value) => value != null ? settings.setTheme(value) : null,
            ),
          ),

          // Health Data Sync Section
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              localizations?.healthDataSync ?? 'Health Data Sync',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            localizations?.healthDataSyncDesc ?? 'Configure how to sync health data from your phone.',
            style: TextStyle(color: secondaryTextColor),
          ),
          SwitchListTile(
            title: Text(localizations?.enableBackgroundSync ?? 'Enable Background Sync'),
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
                    title: Text(localizations?.syncFrequency ?? 'Sync Frequency'),
                    trailing: SizedBox(
                      width: 150, // Adjust this value based on your layout
                      child: DropdownButton<int>(
                        isExpanded: true,
                        // syncFrequency 非 nullable，只需檢查是否落在預設清單內（不在時才顯示 hint）
                        value:
                            settings.predefinedSyncFrequency.contains(settings.syncFrequency)
                                ? settings.syncFrequency
                                : null,
                        hint: Text('${settings.syncFrequency} ${localizations?.minutesUnit ?? 'minutes'}'),
                        items:
                            settings.predefinedSyncFrequency
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value == 60 ? '1 hr' : '$value ${localizations?.minutesUnit ?? 'm'}'),
                                  ),
                                )
                                .toList()
                              ..add(
                                DropdownMenuItem(
                                  value: -1, // Flag for custom
                                  child: Text(localizations?.custom ?? 'Custom'),
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
                    title: Text(localizations?.activeHours ?? 'Active Hours'),
                    subtitle: Text('From ${settings.activeStartHour}:00 to ${settings.activeEndHour}:00'),
                    onTap: () => showActiveHoursPicker(settings),
                  ),
                  SwitchListTile(
                    title: Text(localizations?.startOnBoot ?? 'Start on Boot'),
                    value: settings.startOnBoot,
                    onChanged: (value) => settings.setStartOnBoot(value),
                  ),
                  SwitchListTile(
                    title: Text(localizations?.stopOnTerminate ?? 'Stop on Terminate'),
                    value: settings.stopOnTerminate,
                    onChanged: (value) => settings.setStopOnTerminate(value),
                  ),
                  SwitchListTile(
                    title: Text(localizations?.persistentSync ?? 'Persistent Sync'),
                    value: settings.persistentSync,
                    onChanged: (value) => settings.setPersistentSync(value),
                  ),
                  if (settings.persistentSync)
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                      child: Text(
                        localizations?.persistentSyncReminder ?? 'Note: Sync will continue even if you force-stop the app.',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ],

          // Display Settings
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              localizations?.displaySettings ?? 'Display Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: Text(localizations?.showCumulativeSteps ?? 'Show cumulative steps'),
            value: settings.showCumulative,
            onChanged: (value) => settings.setShowCumulative(value),
          ),
          SwitchListTile(
            title: Text(localizations?.showDailyStepGoal ?? 'Show daily step goal'),
            value: settings.showCumulative,
            onChanged: (value) => settings.setShowDailyStepGoal(value),
          ),

          // Daily Step Goal Section
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              localizations?.dailyStepGoal ?? 'Daily Step Goal',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: Text(localizations?.setDailyStepGoal ?? 'Set your daily step goal'),
            subtitle: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    if (settings.dailyStepGoal > 1000) {
                      settings.setDailyStepGoal(settings.dailyStepGoal - 1000);
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
                    controller: TextEditingController(text: settings.dailyStepGoal.toString())
                      ..selection = TextSelection.fromPosition(TextPosition(offset: settings.dailyStepGoal.toString().length)),
                    onSubmitted: (value) {
                      final int? newValue = int.tryParse(value);
                      if (newValue != null && newValue >= 1000 && newValue <= 20000) {
                        settings.setDailyStepGoal(newValue);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (settings.dailyStepGoal < 20000) {
                      settings.setDailyStepGoal(settings.dailyStepGoal + 1000);
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
    final localizations = AppLocalizations.of(context);

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
            helpText: localizations?.selectStartTime ?? 'Select Start Time',
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
            helpText: localizations?.selectEndTime ?? 'Select End Time',
            initialEntryMode: TimePickerEntryMode.dial,
          ),
    );

    if (pickedEnd == null || !mounted) return; // User canceled or widget unmounted

    // Validate that end time is after start time
    final startMinutes = pickedStart.hour * 60 + pickedStart.minute;
    final endMinutes = pickedEnd.hour * 60 + pickedEnd.minute;

    if (endMinutes <= startMinutes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations?.endTimeError ?? 'End time must be after start time.'), duration: const Duration(seconds: 2)),
        );
      }
      return;
    }

    // Update settings with new values
    settings.setActiveStartHour(pickedStart.hour);
    settings.setActiveEndHour(pickedEnd.hour);
  }
}
