import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

class SystemService {
  static const MethodChannel _permissionsChannel =
      MethodChannel(AppConstants.permissionsChannel);

  Future<void> requestBrightnessPermission(BuildContext context) async {
    if (Theme.of(context).platform == TargetPlatform.android) {
      try {
        final hasPermission = await _permissionsChannel
            .invokeMethod('checkWriteSettingsPermission');

        if (!hasPermission) {
          await _permissionsChannel
              .invokeMethod('requestWriteSettingsPermission');
        }
      } catch (e) {
        print('Permission request error: $e');
      }
    }
  }

  void showRebootShutdownDialog(BuildContext context, String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action Required'),
        content: const Text(
            'This device requires root access to perform this action.\n\nThis feature is not available on standard Android devices.'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void showFeatureNotAvailable(BuildContext context, String feature) {
    _showSnackBar(
      context,
      '$feature is not available on this device',
      AppConstants.warningColor,
    );
  }

  void showSnackBar(BuildContext context, String message, Color color) {
    _showSnackBar(context, message, color);
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
