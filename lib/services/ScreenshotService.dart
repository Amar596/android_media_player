import 'dart:io';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ScreenshotService {
  final ScreenshotController screenshotController = ScreenshotController();

  // Request storage permission
  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.request().isGranted) {
        return true;
      }
    } else if (Platform.isIOS) {
      // iOS doesn't need explicit storage permission
      return true;
    }
    return false;
  }

  // Get the local directory path
  Future<String> _getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // Capture and save screenshot
  Future<String?> captureAndSaveScreenshot({
    required String filename,
    VoidCallback? onSuccess,
    Function(String)? onError,
  }) async {
    try {
      // Request permission
      bool hasPermission = await _requestPermission();
      if (!hasPermission) {
        onError?.call('Storage permission denied');
        return null;
      }

      // Add a small delay to ensure widget is rendered
      await Future.delayed(const Duration(milliseconds: 100));

      // Capture screenshot
      final imageFile = await screenshotController.capture();
      if (imageFile == null) {
        onError?.call('Failed to capture screenshot - widget may not be ready');
        return null;
      }

      // Get local path
      final localPath = await _getLocalPath();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fullPath = '$localPath/${filename}_$timestamp.png';

      // Save the file
      final File file = File(fullPath);
      await file.writeAsBytes(imageFile);

      onSuccess?.call();
      return fullPath;
    } catch (e) {
      onError?.call('Error saving screenshot: $e');
      return null;
    }
  }

  // Share screenshot (optional)
  Future<void> shareScreenshot(String path) async {
    // You can implement sharing functionality here
    // using the share_plus package
  }
}
