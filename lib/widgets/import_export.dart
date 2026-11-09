import 'package:dhealth/database/database.dart';
import 'package:dhealth/database/util.dart';
import 'package:dhealth/di.dart';
import 'package:dhealth/generated/l10n/app_localizations.dart';
import 'package:dhealth/services/data_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../utils/log.dart';
import '../utils/sync_reason.dart';

enum ImportMode { pastDays, dateRange, incremental }

/// 備份與還原畫面。
///
/// manifest 是 `allowBackup="false"`（健康資料不進雲備份 —— 對的），所以這一頁是
/// 使用者唯一的備份/還原路。之前這裡最危險的地方是「回報成功但其實什麼都沒做」：
/// `exportToCSV()` 是 `return null;` 的空殼、匯入檔案那邊只有一句 TODO，
/// 兩者卻都跳 "completed successfully"。現在每個動作都以實際結果說話。
class ImportExportScreen extends StatefulWidget {
  const ImportExportScreen({super.key});

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  ImportMode _selectedMode = ImportMode.pastDays;
  int _pastDays = 30;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  /// 兩個「匯入前清除」分開：以前是同一個 bool 同時控制「從手機匯入」與「從檔案還原」
  /// 兩個卡片，動其中一個另一個也跟着變 —— 而兩個都會先刪掉既有資料。
  bool _clearBeforePhoneImport = false;
  bool _clearBeforeFileImport = false;
  bool _isBusy = false;
  double _progress = 0.0;

  StepDataService get _stepService => getIt<StepDataService>();

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
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

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Theme.of(context).colorScheme.primary,
            onPrimary: Colors.white,
            surface: Theme.of(context).colorScheme.surface,
            onSurface: Theme.of(context).colorScheme.onSurface,
          ),
          dialogTheme: DialogThemeData(backgroundColor: Theme.of(context).colorScheme.surface),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => isStart ? _startDate = picked : _endDate = picked);
  }

  /// 從手機（Health Connect）匯入。三種模式：最近 N 天 / 指定日期區間 / 只補新的。
  Future<void> _importFromPhone() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isBusy = true;
      _progress = 0.0;
    });

    try {
      final StepSyncResult result;
      if (_selectedMode == ImportMode.incremental) {
        result = await _stepService.syncNewData();
      } else {
        // 「最近 N 天」是自由輸入：在用的時候夾一次。每一次都是 Health Connect 呼叫，
        // 没上限就等於讓使用者一脚踩爆同步（9999 = 9999 次串行 IPC）；
        // 0/負数也不该透到下游才由 invalidRange 兵底。
        final pastDays = _pastDays.clamp(1, 3650);
        final startDate = _selectedMode == ImportMode.pastDays ? DateTime.now().subtract(Duration(days: pastDays)) : _startDate;
        result = await _stepService.importFromPhone(
          startDate: startDate,
          endDate: _endDate,
          clearAllFirst: _clearBeforePhoneImport,
          onProgress: (p) {
            if (mounted) setState(() => _progress = p);
          },
        );
      }

      if (result.status == StepSyncStatus.success) {
        _toast(l10n.importSuccess);
      } else {
        // 讀不到資料時資料庫不會被動過，但要讓使用者知道這次什麼都沒進來。
        _toast('${l10n.importFailed}: ${result.status.label(l10n)}', error: true);
      }
    } catch (e) {
      appError('從手機匯入失敗', e);
      _toast(l10n.importFailed, error: true); // 例外內容進 log，不攤給使用者看
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// 從之前匯出的 sqlite 檔還原。
  Future<void> _importFromFile() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // file_picker 13: 單檔選取是靜態 FilePicker.pickFile()（取消回 null）
      final file = await FilePicker.pickFile(type: FileType.any);
      if (file?.path == null) return;

      setState(() => _isBusy = true);
      final result = await importStepsFromFile(file!.path!, replaceAll: _clearBeforeFileImport);

      if (result.imported == null) {
        // 只有「原因」給使用者看；例外內容（result.detail）進 log，不要拿一堆英文堆疊去糊面板。
        _toast('${l10n.importFailed}: ${result.failure?.label(l10n) ?? l10n.importFailed}', error: true);
      } else {
        _toast(l10n.importedDays(result.imported!));
      }
    } catch (e) {
      appError('從檔案匯入失敗', e);
      _toast(l10n.importFailed, error: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<String?> _pickDirectory(String title) => FilePicker.getDirectoryPath(dialogTitle: title);

  Future<void> _exportToFile() async {
    final l10n = AppLocalizations.of(context)!;
    final directory = await _pickDirectory(l10n.exportToFile);
    if (directory == null) {
      _toast(l10n.noDirectorySelected);
      return;
    }
    final path = await copyDatabaseToDirectory(getIt<StepDatabase>(), directory);
    if (path == null) {
      _toast(l10n.exportFailed, error: true);
    } else {
      _toast(l10n.exportedTo(path));
    }
  }

  Future<void> _exportToCsv() async {
    final l10n = AppLocalizations.of(context)!;
    final directory = await _pickDirectory(l10n.exportToCSV);
    if (directory == null) {
      _toast(l10n.noDirectorySelected);
      return;
    }
    final path = await exportStepsToCsv(getIt<StepDatabase>(), directory);
    if (path == null) {
      _toast(l10n.exportFailed, error: true);
    } else {
      _toast(l10n.exportedTo(path));
    }
  }

  /// 分享資料庫快照。分享的是暫存快照而不是活著的 DB 檔，避免邊寫邊被讀到半套。
  Future<void> _share() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final snapshot = await createDatabaseSnapshot(getIt<StepDatabase>(), 'dHealth_share.sqlite');
      if (snapshot == null) {
        _toast(l10n.databaseNotFound, error: true);
        return;
      }

      final result = await SharePlus.instance.share(ShareParams(files: [XFile(snapshot.path)], text: 'dHealth database'));
      try {
        await snapshot.delete();
      } catch (e) {
        appLog('清除分享暫存檔失敗：$e');
      }

      switch (result.status) {
        case ShareResultStatus.success:
          _toast(l10n.shareSuccess);
        case ShareResultStatus.dismissed:
          _toast(l10n.shareCancelled);
        default:
          _toast(l10n.shareFailed, error: true);
      }
    } catch (e) {
      appError('分享資料庫失敗', e);
      _toast(l10n.shareFailed, error: true);
    }
  }

  Widget _buildProgressDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(value: _progress == 0 ? null : _progress, color: Theme.of(context).colorScheme.primary, strokeWidth: 4),
            const SizedBox(height: 24),
            Text(l10n.importing, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(l10n.percentComplete((_progress * 100).toStringAsFixed(0)), style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildImportOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // RadioListTile 的 groupValue/onChanged 自 3.32 棄用，改由 RadioGroup 統一管理
    return RadioGroup<ImportMode>(
      groupValue: _selectedMode,
      onChanged: (value) => setState(() => _selectedMode = value!),
      child: Column(
        children: [
          RadioListTile<ImportMode>(
            title: Row(
              children: [
                Text('${l10n.import}  '),
                SizedBox(
                  width: 60,
                  child: TextFormField(
                    initialValue: _pastDays.toString(),
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(counterText: '', contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    onChanged: (value) => setState(() => _pastDays = int.tryParse(value) ?? 30),
                  ),
                ),
                Text('  ${l10n.days}'),
              ],
            ),
            value: ImportMode.pastDays,
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<ImportMode>(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.dateRange),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(DateFormat('yyyy/MM/dd').format(_startDate)),
                        onPressed: () => _selectDate(context, true),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(l10n.dateRangeTo, style: const TextStyle(color: Colors.grey))),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(DateFormat('yyyy/MM/dd').format(_endDate)),
                        onPressed: () => _selectDate(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            value: ImportMode.dateRange,
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<ImportMode>(
            title: Text(l10n.importIncremental),
            subtitle: Text(l10n.importIncrementalDesc, style: Theme.of(context).textTheme.bodySmall),
            value: ImportMode.incremental,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildImportSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.phone_android, color: Theme.of(context).colorScheme.primary),
              title: Text(l10n.importFromPhone, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              subtitle: Text(l10n.importFromPhoneDesc, style: Theme.of(context).textTheme.bodySmall),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.importClearData),
              subtitle: Text(l10n.importClearDataWarning),
              value: _clearBeforePhoneImport,
              onChanged: (value) => setState(() => _clearBeforePhoneImport = value),
            ),
            const SizedBox(height: 12),
            _buildImportOptions(context),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: Text(l10n.import),
                onPressed: _isBusy ? null : _importFromPhone,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileImportSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.file_upload, color: Theme.of(context).colorScheme.primary),
              title: Text(l10n.importFromFile, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              subtitle: Text(l10n.importFromFileDesc, style: Theme.of(context).textTheme.bodySmall),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.importClearData),
              subtitle: Text(l10n.importClearDataWarning),
              value: _clearBeforeFileImport,
              onChanged: (value) => setState(() => _clearBeforeFileImport = value),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: Text(l10n.import),
                onPressed: _isBusy ? null : _importFromFile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.exportOptions,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 16),
            _buildExportButton(context, icon: Icons.save_alt, label: l10n.exportToFile, onPressed: _exportToFile),
            const SizedBox(height: 8),
            _buildExportButton(context, icon: Icons.table_chart, label: l10n.exportToCSV, onPressed: _exportToCsv),
            const SizedBox(height: 8),
            _buildExportButton(context, icon: Icons.share, label: l10n.shareDatabaseFile, onPressed: _share),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onPressed}) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 20),
      label: Text(label),
      onPressed: _isBusy ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.importExport), elevation: 0),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: [_buildImportSection(context), _buildFileImportSection(context), _buildExportSection(context)]),
          ),
          if (_isBusy) _buildProgressDialog(context),
        ],
      ),
    );
  }
}
