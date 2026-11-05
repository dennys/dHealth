import 'dart:io';

import 'package:drift/native.dart';
import 'package:dhealth/database/database.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

// Database setup with ability to copy to public location
Future<StepDatabase> openDatabase() async {
  // Get a location for the database on disk
  final appDir = await getApplicationDocumentsDirectory();
  final dbFile = File(p.join(appDir.path, 'dHealth.sqlite'));

  // Create the database with a native executor
  return StepDatabase(NativeDatabase(dbFile));
}

Future<String?> exportToCSV() async {
  return null;
}

// Function to copy the database file to Downloads directory
Future<String?> copyDatabaseToDownloads(String exportedPath) async {
  try {
    // Request storage permission (required for Android 12 or below)
    // var status = await Permission.storage.request();
    // if (!status.isGranted) {
    //   debugPrint("Storage permission denied");
    //   return null;
    // }

    // Get the app's database file path
    final appDir = await getApplicationDocumentsDirectory();
    final dbFilePath = p.join(appDir.path, 'dHealth.sqlite');
    final dbFile = File(dbFilePath);

    if (!await dbFile.exists()) {
      debugPrint("Database file does not exist");
      return null;
    }

    // Get the downloads directory
    Directory? downloadsDir;

    if (Platform.isAndroid) {
      // For Android
      // downloadsDir = Directory('/storage/emulated/0/Download');
      downloadsDir = Directory(exportedPath);

      // Alternative method if the above doesn't work
      if (!await downloadsDir.exists()) {
        final dirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
        if (dirs != null && dirs.isNotEmpty) {
          downloadsDir = dirs.first;
        }
      }
    } else if (Platform.isIOS) {
      // For iOS, we can only copy to app's documents directory that's accessible via Files app
      downloadsDir = await getApplicationDocumentsDirectory();
    }

    if (downloadsDir == null || !await downloadsDir.exists()) {
      debugPrint("Downloads directory not found");
      return null;
    }

    // Create destination file with timestamp to avoid overwriting
    final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final destPath = p.join(downloadsDir.path, 'dHealth_$timestamp.sqlite');
    final destFile = File(destPath);

    // Copy the file
    await dbFile.copy(destPath);

    if (await destFile.exists()) {
      debugPrint("Database copied to: $destPath");
      return destPath;
    } else {
      debugPrint("Failed to copy database");
      return null;
    }
  } catch (e) {
    debugPrint("Error copying database: $e");
    return null;
  }
}

// Function to export database as CSV (alternative for easier viewing)
Future<String?> exportStepsToCSV(StepDatabase database) async {
  try {
    // Request storage permission
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      debugPrint("Storage permission denied");
      return null;
    }

    // Get the steps data
    final steps = await database.getAllDailySteps();

    // Format as CSV
    final csvData = StringBuffer();
    csvData.writeln("Date,StepCount,LastUpdated,IsComplete");

    for (var step in steps) {
      csvData.writeln("${step.date},${step.stepCount},${step.lastUpdated.toIso8601String()},${step.isComplete}");
    }

    // Get the downloads directory
    Directory? downloadsDir;

    if (Platform.isAndroid) {
      // For Android
      downloadsDir = Directory('/storage/emulated/0/Download');

      // Alternative method
      if (!await downloadsDir.exists()) {
        final dirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
        if (dirs != null && dirs.isNotEmpty) {
          downloadsDir = dirs.first;
        }
      }
    } else if (Platform.isIOS) {
      // For iOS
      downloadsDir = await getApplicationDocumentsDirectory();
    }

    if (downloadsDir == null || !await downloadsDir.exists()) {
      debugPrint("Downloads directory not found");
      return null;
    }

    // Create CSV file with timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final csvPath = p.join(downloadsDir.path, 'steps_data_$timestamp.csv');

    // Write the file
    final csvFile = File(csvPath);
    await csvFile.writeAsString(csvData.toString());

    if (await csvFile.exists()) {
      debugPrint("CSV exported to: $csvPath");
      return csvPath;
    } else {
      debugPrint("Failed to export CSV");
      return null;
    }
  } catch (e) {
    debugPrint("Error exporting CSV: $e");
    return null;
  }
}
