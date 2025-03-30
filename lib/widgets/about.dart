import 'package:flutter/material.dart';
import 'package:dsteps/generated/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart'; // For app version

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _appVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(localizations?.about ?? 'About')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Title and Description
            Text('dHealth', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              localizations?.aboutDescription ??
                  'dHealth is an app to track and manage your health data with support for importing and exporting SQLite databases.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Features Section
            Text(localizations?.features ?? 'Features', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            _buildFeatureItem(
              context,
              Icons.favorite,
              localizations?.healthTracking ?? 'Health Data Tracking',
              localizations?.healthTrackingDesc ?? 'Monitor your steps and other health metrics.',
            ),
            _buildFeatureItem(
              context,
              Icons.import_export,
              localizations?.importExport ?? 'Import/Export',
              localizations?.importExportDesc ?? 'Backup or restore your data using SQLite files.',
            ),
            _buildFeatureItem(
              context,
              Icons.phone_android,
              localizations?.platformSupport ?? 'Platform Support',
              localizations?.platformSupportDesc ?? 'Works with Health Connect (Android) and HealthKit (iOS).',
            ),
            const SizedBox(height: 16),

            // Version Info
            Text('${localizations?.version ?? 'Version'}: $_appVersion', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),

            // Contact Info
            Text(localizations?.contact ?? 'Contact', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              localizations?.contactDesc ?? 'For support or feedback, email us at: support@dhealth.app',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
