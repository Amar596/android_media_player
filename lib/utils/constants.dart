import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Media Player Control';
  static const String brightnessChannel = 'com.example.app/brightness';
  static const String systemChannel = 'com.example.app/system';
  static const String permissionsChannel = 'com.example.app/permissions';

  // Device default values
  static const String defaultModel = 'SW-01';
  static const String defaultMacAddress = '90:0E:B3:4E:15:76';
  static const String defaultRam = '2GB';
  static const String defaultStorage = '16GB';
  static const String defaultAndroidVersion = '10';

  // Animation durations
  static const Duration animationDuration = Duration(milliseconds: 300);

  // Colors
  static const Color primaryColor = Colors.blue;
  static const Color successColor = Colors.green;
  static const Color warningColor = Colors.orange;
  static const Color errorColor = Colors.red;
}

class AppStrings {
  static const String volumeControl = 'Volume Control';
  static const String brightnessControl = 'Brightness Control';
  static const String screenRotation = 'Screen Rotation';
  static const String deviceInfo = 'Device Information';
  static const String actions = 'Actions';
  static const String screenshot = 'Screenshot';
  static const String reboot = 'Reboot';
  static const String shutdown = 'Shutdown';
  static const String portrait = 'Portrait';
  static const String landscape = 'Landscape';
  static const String auto = 'Auto';
}
