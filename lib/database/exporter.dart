import 'dart:io';

import 'package:dhealth/database/database.dart';
import 'package:dhealth/database/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DatabaseExporter {
  final StepDatabase database;

  DatabaseExporter(this.database);

  // Export database to Downloads folder
  Future<String?> exportDatabaseToDownloads(BuildContext context) async {
    try {
      // Close the database connection to ensure all data is saved
      await database.close();

      // Request storage permission
      if (!await _requestStoragePermission()) {
        return "Storage permission denied";
      }

      // Get the path to the database file
      final appDir = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(appDir.path, 'steps_database.sqlite'));

      if (!await dbFile.exists()) {
        return "Database file not found";
      }

      // For Android 10+ (API level 29+), use MediaStore
      if (Platform.isAndroid) {
        return await _exportUsingMediaStore(dbFile);
      }
      // For iOS, use a different approach or share functionality
      else if (Platform.isIOS) {
        return "Export to Downloads not supported on iOS";
      }

      return "Platform not supported for export";
    } catch (e) {
      return "Export failed: $e";
    } finally {
      // Re-open the database connection
      await openStepDatabase();
    }
  }

  Future<bool> _requestStoragePermission() async {
    // For Android 10 and above, we need WRITE_EXTERNAL_STORAGE permission
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        return status.isGranted;
      }
      return true;
    }
    return true;
  }

  Future<String?> _exportUsingMediaStore(File dbFile) async {
    try {
      // Get the current timestamp for the filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'step_data_backup_$timestamp.sqlite';

      // For Android 10+ (API level 29+), use MediaStore
      if (Platform.isAndroid) {
        // This is the MediaStore approach
        final bytes = await dbFile.readAsBytes();

        // Create a temporary file in the app's cache directory
        final cacheDir = await getTemporaryDirectory();
        final tempFile = File('${cacheDir.path}/$fileName');
        await tempFile.writeAsBytes(bytes);

        // Use the MediaStore API via platform channel
        const platform = MethodChannel('com.example.app/database_export');
        final result = await platform.invokeMethod('saveToDownloads', {
          'filePath': tempFile.path,
          'fileName': fileName,
          'mimeType': 'application/x-sqlite3',
        });

        // Clean up the temporary file
        await tempFile.delete();

        return result ? "Database exported to Downloads/$fileName" : "Export failed";
      }

      return "Platform not supported";
    } catch (e) {
      return "Export failed: $e";
    }
  }
}
