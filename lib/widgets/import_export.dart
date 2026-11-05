import 'dart:io';

import 'package:dhealth/database/util.dart';
import 'package:dhealth/generated/l10n/app_localizations.dart';
import 'package:dhealth/services/data_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum ImportMode { pastDays, dateRange, incremental }

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
  bool _clearDataBeforeImport = false;
  bool _isImporting = false;
  double _importProgress = 0.0;

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
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
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _importFromPhone() async {
    setState(() {
      _isImporting = true;
      _importProgress = 0.0;
    });
    try {
      DateTime startDate;
      DateTime endDate = DateTime.now();

      if (_selectedMode == ImportMode.pastDays) {
        startDate = DateTime.now().subtract(Duration(days: _pastDays));
      } else {
        startDate = _startDate;
        endDate = _endDate;
      }

      final totalDays = endDate.difference(startDate).inDays;
      final stepService = StepDataService();

      const chunkSize = 30;
      final totalChunks = (totalDays / chunkSize).ceil();

      for (int i = 0; i < totalChunks; i++) {
        final chunkStart = startDate.add(Duration(days: i * chunkSize));
        final chunkEnd =
            chunkStart.add(const Duration(days: chunkSize - 1)).isAfter(endDate) ? endDate : chunkStart.add(const Duration(days: chunkSize - 1));

        await stepService.refreshDataRange(chunkStart, chunkEnd, clearData: _clearDataBeforeImport && i == 0);

        if (mounted) {
          setState(() {
            _importProgress = (i + 1) / totalChunks;
          });
        }

        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.importSuccess ?? 'Import completed successfully'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.importFailed ?? 'Import failed'}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
          _importProgress = 0.0;
        });
      }
    }
  }

  Future<void> _importFromFile() async {
    try {
      // file_picker 13: FilePicker.platform / FilePickerResult 已移除，
      // 單檔選取改用靜態 FilePicker.pickFile()（回傳 PlatformFile?，取消為 null）
      final PlatformFile? file = await FilePicker.pickFile(type: FileType.any);

      if (file != null) {
        // TODO: Implement SQLite file import logic here
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.importSuccess ?? 'Import completed successfully'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.importFailed ?? 'Import failed'}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _exportToFile() async {
    try {
      // final String? savePath = await FilePicker.platform.saveFile(
      //   dialogTitle: 'Export database',
      //   fileName: 'dHealth.sqlite',
      //   allowedExtensions: ['sqlite'],
      // );

      String? result = await FilePicker.getDirectoryPath(dialogTitle: 'Select Export Directory');
      if (result != null) {
        // setState(() {
        //   selectedDirectory = result;
        // });
        // Pass the selected directory to your export function
        await copyDatabaseToDownloads(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export completed successfully')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No directory selected')));
        }
      }

      // await copyDatabaseToDownloads(savePath);
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text(AppLocalizations.of(context)?.exportSuccess ?? 'Export completed successfully'),
      //       behavior: SnackBarBehavior.floating,
      //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      //     ),
      //   );
      // }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.exportFailed ?? 'Export failed'}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _exportToCSV() async {
    try {
      await exportToCSV();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.exportSuccess ?? 'Export completed successfully'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.exportFailed ?? 'Export failed'}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _share() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dbFilePath = p.join(appDir.path, 'dHealth.sqlite');
      final dbFile = File(dbFilePath);

      if (!await dbFile.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Database file not found'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        return;
      }

      // share_plus 13: Share.shareXFiles 已廢除，改走 SharePlus.instance.share(ShareParams(...))
      final result = await SharePlus.instance.share(
        ShareParams(files: [XFile(dbFilePath)], text: 'Sharing steps database'),
      );

      if (result.status == ShareResultStatus.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Database shared successfully'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else if (result.status == ShareResultStatus.dismissed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sharing was cancelled'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share database: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Widget _buildProgressDialog(BuildContext context) {
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
            CircularProgressIndicator(
              value: _importProgress == 0 ? null : _importProgress,
              color: Theme.of(context).colorScheme.primary,
              strokeWidth: 4,
            ),
            const SizedBox(height: 24),
            Text('Importing Data...', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _importProgress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text('${(_importProgress * 100).toStringAsFixed(0)}% Complete', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildImportOptions(BuildContext context) {
    // RadioListTile 的 groupValue/onChanged 自 3.32 棄用，改由 RadioGroup 統一管理
    return RadioGroup<ImportMode>(
      groupValue: _selectedMode,
      onChanged: (value) => setState(() => _selectedMode = value!),
      child: Column(
        children: [
          RadioListTile<ImportMode>(
            title: Row(
              children: [
                Text('${AppLocalizations.of(context)?.import ?? 'Import'}  '),
                SizedBox(
                  width: 60,
                  child: TextFormField(
                    initialValue: _pastDays.toString(),
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (value) {
                      final days = int.tryParse(value) ?? 30;
                      setState(() => _pastDays = days);
                    },
                  ),
                ),
                Text('  ${AppLocalizations.of(context)?.days ?? 'days'}'),
              ],
            ),
            value: ImportMode.pastDays,
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<ImportMode>(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)?.dateRange ?? 'Date Range'),
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
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('to', style: TextStyle(color: Colors.grey))),
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
            title: Text(AppLocalizations.of(context)?.importIncremental ?? 'Import incremental'),
            subtitle: Text(
              AppLocalizations.of(context)?.importIncrementalDesc ?? 'Only import new data since last import',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            value: ImportMode.incremental,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildImportSection(BuildContext context) {
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
              title: Text(
                AppLocalizations.of(context)?.importFromPhone ?? 'Import from Phone',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                AppLocalizations.of(context)?.importFromPhoneDesc ?? 'Import step data from your phone',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppLocalizations.of(context)?.importClearData ?? 'Clear current data before import'),
              value: _clearDataBeforeImport,
              onChanged: (value) => setState(() => _clearDataBeforeImport = value),
            ),
            const SizedBox(height: 12),
            _buildImportOptions(context),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: Text(AppLocalizations.of(context)?.import ?? 'Import'),
                onPressed: _isImporting ? null : _importFromPhone,
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
              title: Text(
                AppLocalizations.of(context)?.importFromFile ?? 'Import from file',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                AppLocalizations.of(context)?.importFromFileDesc ?? 'Import from a previously exported file',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppLocalizations.of(context)?.importClearData ?? 'Clear current data before import'),
              value: _clearDataBeforeImport,
              onChanged: (value) => setState(() => _clearDataBeforeImport = value),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: Text(AppLocalizations.of(context)?.import ?? 'Import'),
                onPressed: _isImporting ? null : _importFromFile,
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text('Database Export', style: Theme.of(context).textTheme.titleMedium),
            // _buildExportButton(context, icon: Icons.save, label: 'Export to file', onPressed: _exportDatabaseToFile),
            // _buildExportButton(context, icon: Icons.share, label: 'Share database file', onPressed: _share),

            // const Divider(),

            // Text('CSV Export', style: Theme.of(context).textTheme.titleMedium),
            // _buildExportButton(context, icon: Icons.insert_drive_file, label: 'Export CSV to file', onPressed: _exportToCSV),
            // _buildExportButton(context, icon: Icons.share, label: 'Share CSV file', onPressed: _share), //TODO this share is for DB only now
            Text(
              AppLocalizations.of(context)?.exportOptions ?? 'Export Options',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 16),
            _buildExportButton(
              context,
              icon: Icons.save_alt,
              label: AppLocalizations.of(context)?.exportToFile ?? 'Export to file',
              onPressed: _exportToFile,
            ),
            const SizedBox(height: 8),
            _buildExportButton(
              context,
              icon: Icons.table_chart,
              label: AppLocalizations.of(context)?.exportToCSV ?? 'Export to CSV',
              onPressed: _exportToCSV,
            ),
            const SizedBox(height: 8),
            _buildExportButton(
              context,
              icon: Icons.share,
              label: AppLocalizations.of(context)?.shareDatabaseFile ?? 'Share database',
              onPressed: _share,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onPressed}) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 20),
      label: Text(label),
      onPressed: _isImporting ? null : onPressed,
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
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)?.importExport ?? 'Import/Export'), elevation: 0),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: [_buildImportSection(context), _buildFileImportSection(context), _buildExportSection(context)]),
          ),
          if (_isImporting) _buildProgressDialog(context),
        ],
      ),
    );
  }
}
