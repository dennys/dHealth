import 'package:dsteps/generated/l10n/app_localizations.dart';
import 'package:dsteps/settings_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final settings = Provider.of<SettingsModel>(context);
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkTheme ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor = isDarkTheme ? Colors.white.withValues(alpha: 0.8) : Theme.of(context).hintColor;

    // Helper method for Active Hours picker (example implementation)
    void showActiveHoursPicker(BuildContext context, SettingsModel settings) async {
      // Implement a time range picker here (e.g., using showTimePicker or a custom dialog)
      // Update settings.activeStartHour and settings.activeEndHour based on user input
    }

    // Custom Sync Frequency Dialog
    Future<void> showCustomSyncDialog(BuildContext context, SettingsModel settings) async {
      int? interval;
      String unit = 'minutes'; // Default unit

      await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(localizations?.customSyncTitle ?? 'Custom Sync Frequency'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: localizations?.interval ?? 'Interval', hintText: 'e.g., 45'),
                    onChanged: (value) => interval = int.tryParse(value),
                  ),
                  DropdownButton<String>(
                    value: unit,
                    items: [
                      DropdownMenuItem(value: 'minutes', child: Text(localizations?.minutesUnit ?? 'Minutes')),
                      DropdownMenuItem(value: 'hours', child: Text(localizations?.hoursUnit ?? 'Hours')),
                    ],
                    onChanged: (value) => unit = value ?? 'minutes',
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text(localizations?.cancel ?? 'Cancel')),
                TextButton(
                  onPressed: () {
                    if (interval != null && interval! > 0) {
                      final value = unit == 'minutes' ? '${interval}m' : '${interval}h';
                      settings.setCustomSyncFrequency(value); // Use the new method
                    }
                    Navigator.pop(context);
                  },
                  child: Text(localizations?.save ?? 'Save'),
                ),
              ],
            ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.setup ?? 'Setup', style: TextStyle(color: Colors.white)),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.3), Theme.of(context).scaffoldBackgroundColor],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Language Setting
            _buildSectionTitle(context, localizations?.language ?? 'Language', Icons.language, isDarkTheme),
            const SizedBox(height: 12),
            _buildCard(
              context,
              DropdownButtonFormField<String>(
                value: settings.language,
                icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).primaryColor),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  labelText: localizations?.selectLanguage ?? 'Select Language',
                  labelStyle: TextStyle(color: secondaryTextColor),
                ),
                dropdownColor: isDarkTheme ? Colors.grey[850] : Theme.of(context).cardColor,
                items: [
                  DropdownMenuItem(value: 'system', child: Text(localizations?.followSystem ?? 'Follow System', style: TextStyle(color: textColor))),
                  DropdownMenuItem(value: 'en', child: Text(localizations?.english ?? 'English', style: TextStyle(color: textColor))),
                  DropdownMenuItem(
                    value: 'zh_Hant',
                    child: Text(localizations?.traditionalChinese ?? 'Traditional Chinese', style: TextStyle(color: textColor)),
                  ),
                  DropdownMenuItem(
                    value: 'zh_Hans',
                    child: Text(localizations?.simplifiedChinese ?? 'Simplified Chinese', style: TextStyle(color: textColor)),
                  ),
                ],
                onChanged: (value) => value != null ? settings.setLanguage(value) : null,
              ),
              isDarkTheme,
            ),
            const SizedBox(height: 24),

            // Theme Setting
            _buildSectionTitle(context, localizations?.theme ?? 'Theme', Icons.palette, isDarkTheme),
            const SizedBox(height: 12),
            _buildCard(
              context,
              DropdownButtonFormField<String>(
                value: settings.theme,
                icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).primaryColor),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  labelText: localizations?.selectTheme ?? 'Select Theme',
                  labelStyle: TextStyle(color: secondaryTextColor),
                ),
                dropdownColor: isDarkTheme ? Colors.grey[850] : Theme.of(context).cardColor,
                items: [
                  DropdownMenuItem(value: 'system', child: Text(localizations?.followSystem ?? 'Follow System', style: TextStyle(color: textColor))),
                  DropdownMenuItem(value: 'light', child: Text(localizations?.light ?? 'Light', style: TextStyle(color: textColor))),
                  DropdownMenuItem(value: 'dark', child: Text(localizations?.dark ?? 'Dark', style: TextStyle(color: textColor))),
                ],
                onChanged: (value) => value != null ? settings.setTheme(value) : null,
              ),
              isDarkTheme,
            ),
            const SizedBox(height: 24),

            // // Sync Frequency Setting
            // _buildSectionTitle(context, localizations?.syncFrequency ?? 'Sync Frequency', Icons.sync, isDarkTheme),
            // const SizedBox(height: 12),
            // _buildCard(
            //   context,
            //   DropdownButtonFormField<String>(
            //     value: settings.syncFrequency,
            //     icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).primaryColor),
            //     decoration: InputDecoration(
            //       border: InputBorder.none,
            //       labelText: localizations?.selectSyncFrequency ?? 'Select Sync Frequency',
            //       labelStyle: TextStyle(color: secondaryTextColor),
            //     ),
            //     dropdownColor: isDarkTheme ? Colors.grey[850] : Theme.of(context).cardColor,
            //     items: [
            //       DropdownMenuItem(value: 'manual', child: Text(localizations?.manual ?? 'Manual', style: TextStyle(color: textColor))),
            //       DropdownMenuItem(value: 'hourly', child: Text(localizations?.hourly ?? 'Hourly', style: TextStyle(color: textColor))),
            //       DropdownMenuItem(value: 'daily', child: Text(localizations?.daily ?? 'Daily', style: TextStyle(color: textColor))),
            //     ],
            //     onChanged: (value) => value != null ? settings.setSyncFrequency(value) : null,
            //   ),
            //   isDarkTheme,
            // ),
            // const SizedBox(height: 24),

            // Health Data Sync Setting
            _buildSectionTitle(context, localizations?.healthDataSync ?? 'Health Data Sync', Icons.sync, isDarkTheme),
            const SizedBox(height: 8),
            Text(
              localizations?.healthDataSyncDesc ?? 'Configure how health data is copied from your health app to this app.',
              style: TextStyle(color: secondaryTextColor, fontSize: 14),
            ),
            const SizedBox(height: 12),
            _buildCard(
              context,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enable Background Sync
                  SwitchListTile(
                    title: Text(localizations?.enableBackgroundSync ?? 'Enable Background Sync', style: TextStyle(color: textColor)),
                    value: settings.healthSyncEnabled,
                    onChanged: (value) => settings.setHealthSyncEnabled(value),
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  if (settings.healthSyncEnabled) ...[
                    // Sync Frequency
                    DropdownButtonFormField<String>(
                      value: settings.syncFrequency,
                      icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).primaryColor),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        labelText: localizations?.syncFrequency ?? 'Sync Frequency',
                        labelStyle: TextStyle(color: secondaryTextColor),
                      ),
                      dropdownColor: isDarkTheme ? Colors.grey[850] : Theme.of(context).cardColor,
                      items: [
                        DropdownMenuItem(
                          value: '15m',
                          child: Text(localizations?.every15Minutes ?? 'Every 15 minutes', style: TextStyle(color: textColor)),
                        ),
                        DropdownMenuItem(
                          value: '30m',
                          child: Text(localizations?.every30Minutes ?? 'Every 30 minutes', style: TextStyle(color: textColor)),
                        ),
                        DropdownMenuItem(value: '1h', child: Text(localizations?.every1Hour ?? 'Every hour', style: TextStyle(color: textColor))),
                        DropdownMenuItem(value: 'custom', child: Text(localizations?.custom ?? 'Custom', style: TextStyle(color: textColor))),
                        DropdownMenuItem(value: 'manual', child: Text(localizations?.custom ?? 'manual', style: TextStyle(color: textColor))),
                      ],
                      onChanged: (value) async {
                        if (value == 'custom') {
                          await showCustomSyncDialog(context, settings);
                        } else if (value != null) {
                          settings.setSyncFrequency(value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // Active Hours
                    ListTile(
                      title: Text(localizations?.activeHours ?? 'Active Hours', style: TextStyle(color: textColor)),
                      subtitle: Text(
                        'From ${settings.activeStartHour}:00 to ${settings.activeEndHour}:00',
                        style: TextStyle(color: secondaryTextColor),
                      ),
                      trailing: Icon(Icons.edit, color: Theme.of(context).primaryColor),
                      onTap: () => showActiveHoursPicker(context, settings),
                    ),
                  ],
                  // Start on Boot
                  SwitchListTile(
                    title: Text(localizations?.startOnBoot ?? 'Start on Boot', style: TextStyle(color: textColor)),
                    value: settings.startOnBoot,
                    onChanged: (value) => settings.setStartOnBoot(value),
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  // Stop on Terminate (optional, hidden by default)
                  SwitchListTile(
                    title: Text(localizations?.stopOnTerminate ?? 'Stop on Terminate', style: TextStyle(color: textColor)),
                    value: settings.stopOnTerminate,
                    onChanged: (value) => settings.setStopOnTerminate(value),
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  // Persistent Sync (replacing Headless Mode)
                  SwitchListTile(
                    title: Text(localizations?.persistentSync ?? 'Persistent Sync', style: TextStyle(color: textColor)),
                    value: settings.persistentSync,
                    onChanged: (value) => settings.setPersistentSync(value),
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  Visibility(
                    visible: settings.persistentSync,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                      child: Text(
                        localizations?.persistentSyncReminder ?? 'Note: Sync will continue even if you force-stop the app.',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              isDarkTheme,
            ),
            const SizedBox(height: 24),

            // Display Settings
            _buildSectionTitle(context, localizations?.displaySettings ?? 'Display Settings', Icons.visibility, isDarkTheme),
            const SizedBox(height: 12),
            _buildCard(
              context,
              Column(
                children: [
                  _buildSwitchListTile(
                    context,
                    title: localizations?.showCumulativeSteps ?? 'Show cumulative steps',
                    value: settings.showCumulative,
                    onChanged: (value) => settings.setShowCumulative(value),
                    icon: Icons.timeline,
                    isDarkTheme: isDarkTheme,
                    textColor: textColor,
                  ),
                  Divider(
                    height: 1,
                    color: isDarkTheme ? Colors.white.withValues(alpha: 0.1) : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  ),
                  _buildSwitchListTile(
                    context,
                    title: localizations?.showDailyStepGoal ?? 'Show daily step goal',
                    value: settings.showDailyStepGoal,
                    onChanged: (value) => settings.setShowDailyStepGoal(value),
                    icon: Icons.flag,
                    isDarkTheme: isDarkTheme,
                    textColor: textColor,
                  ),
                ],
              ),
              isDarkTheme,
            ),
            const SizedBox(height: 24),

            // Daily Step Goal Setting
            _buildSectionTitle(context, localizations?.dailyStepGoal ?? 'Daily Step Goal', Icons.directions_walk, isDarkTheme),
            const SizedBox(height: 12),
            _buildCard(
              context,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(localizations?.setDailyStepGoal ?? 'Set your daily step goal', style: TextStyle(color: secondaryTextColor, fontSize: 14)),
                  const SizedBox(height: 8),
                  Slider(
                    value: settings.dailyStepGoal.toDouble(),
                    min: 1000,
                    max: 20000,
                    divisions: 19,
                    label: '${settings.dailyStepGoal}',
                    activeColor: isDarkTheme ? Theme.of(context).iconTheme.color : Theme.of(context).primaryColor,
                    inactiveColor: Theme.of(context).iconTheme.color?.withValues(alpha: 0.3),
                    onChanged: (value) => settings.setDailyStepGoal(value.toInt()),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('1,000', style: TextStyle(color: secondaryTextColor)),
                      Text(
                        '${settings.dailyStepGoal} ${localizations?.steps ?? 'steps'}',
                        style: TextStyle(
                          color: isDarkTheme ? Theme.of(context).iconTheme.color : Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('20,000', style: TextStyle(color: secondaryTextColor)),
                    ],
                  ),
                ],
              ),
              isDarkTheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon, bool isDarkTheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Theme.of(context).primaryColor.withValues(alpha: isDarkTheme ? 0.2 : 0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: isDarkTheme ? Colors.white : Theme.of(context).primaryColor),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, Widget child, bool isDarkTheme) {
    return Card(
      elevation: isDarkTheme ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDarkTheme ? Colors.white.withValues(alpha: 0.1) : Theme.of(context).dividerColor.withValues(alpha: 0.1), width: 1),
      ),
      color: isDarkTheme ? Colors.grey[900] : Theme.of(context).cardColor,
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), child: child),
    );
  }

  Widget _buildSwitchListTile(
    BuildContext context, {
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required bool isDarkTheme,
    required Color? textColor,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      title: Row(children: [Icon(icon, size: 24), const SizedBox(width: 16), Text(title, style: TextStyle(color: textColor))]),
      value: value,
      activeColor: Theme.of(context).primaryColor,
      activeTrackColor: Theme.of(context).primaryColor.withValues(alpha: isDarkTheme ? 0.5 : 0.3),
      inactiveThumbColor: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
      inactiveTrackColor: isDarkTheme ? Colors.grey[600]!.withValues(alpha: 0.3) : Colors.grey[400]!.withValues(alpha: 0.3),
      onChanged: onChanged,
    );
  }
}
