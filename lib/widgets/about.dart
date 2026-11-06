import 'package:flutter/material.dart';
import 'package:dhealth/generated/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart'; // For app version

/// 上架前要填的聯絡信箱（Play 控制台填的也要同一個）。
///
/// 原本 About 頁寫死 `support@dhealth.app` —— 那個網域不是我們的，使用者的抱怨信會
/// 進到陌生人的收件匣（而我們永遠不會知道）。沒有真的信箱之前，寧可整段不顯示，
/// 也不要放一個假的。
const String? kSupportEmail = null; // TODO(上架前): 换成真正要收信的地址

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
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(localizations.about)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Title and Description
            Text('dHealth', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              localizations.aboutDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Features Section
            Text(localizations.features, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            _buildFeatureItem(
              context,
              Icons.favorite,
              localizations.healthTracking,
              localizations.healthTrackingDesc,
            ),
            _buildFeatureItem(
              context,
              Icons.import_export,
              localizations.importExport,
              localizations.importExportDesc,
            ),
            _buildFeatureItem(
              context,
              Icons.phone_android,
              localizations.platformSupport,
              localizations.platformSupportDesc,
            ),
            const SizedBox(height: 16),

            // Version Info
            Text('${localizations.version}: $_appVersion', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),

            // Contact Info
            if (kSupportEmail != null) ...[
              Text(localizations.contact, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              SelectableText(
                localizations.contactDesc(kSupportEmail!),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
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
