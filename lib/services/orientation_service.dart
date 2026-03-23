import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OrientationService {
  static final OrientationService _instance = OrientationService._internal();
  factory OrientationService() => _instance;
  OrientationService._internal();

  // Method channel for native orientation control
  static const MethodChannel _orientationChannel =
      MethodChannel('com.example.app/orientation');

  // Track current orientation
  String _currentOrientation = 'auto';
  String get currentOrientation => _currentOrientation;

  // Callback for orientation changes
  VoidCallback? onOrientationChanged;

  // Initialize and get current orientation
  Future<void> initialize() async {
    try {
      final orientation =
          await _orientationChannel.invokeMethod('getCurrentOrientation');
      _currentOrientation = orientation ?? 'auto';
      onOrientationChanged?.call();
    } catch (e) {
      print('Error initializing orientation: $e');
      _currentOrientation = 'auto';
    }
  }

  // Set portrait orientation
  Future<bool> setPortrait() async {
    try {
      final success = await _orientationChannel.invokeMethod('setPortrait');
      if (success == true) {
        _currentOrientation = 'portrait';
        onOrientationChanged?.call();
        return true;
      }
      return false;
    } catch (e) {
      print('Error setting portrait: $e');
      return false;
    }
  }

  // Set landscape orientation
  Future<bool> setLandscape() async {
    try {
      final success = await _orientationChannel.invokeMethod('setLandscape');
      if (success == true) {
        _currentOrientation = 'landscape';
        onOrientationChanged?.call();
        return true;
      }
      return false;
    } catch (e) {
      print('Error setting landscape: $e');
      return false;
    }
  }

  // Set auto orientation
  Future<bool> setAuto() async {
    try {
      final success = await _orientationChannel.invokeMethod('setAuto');
      if (success == true) {
        _currentOrientation = 'auto';
        onOrientationChanged?.call();
        return true;
      }
      return false;
    } catch (e) {
      print('Error setting auto: $e');
      return false;
    }
  }

  // Fallback method using Flutter's orientation (works on all devices)
  static void setOrientationFlutter(String orientation) {
    if (orientation == 'portrait') {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else if (orientation == 'landscape') {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }
}
