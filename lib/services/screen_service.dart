import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class ScreenService {
  static const MethodChannel _channel =
      MethodChannel('com.example.media_player/screen');

  // Check if overlay permission is granted
  static Future<bool> hasOverlayPermission() async {
    try {
      final bool hasPermission =
          await _channel.invokeMethod('hasOverlayPermission');
      return hasPermission;
    } catch (e) {
      debugPrint('Error checking overlay permission: $e');
      return false;
    }
  }

  // Test if channel is available
  static Future<bool> testChannel() async {
    try {
      await _channel.invokeMethod('test');
      return true;
    } catch (e) {
      return false;
    }
  }

  // Request overlay permission
  static Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (e) {
      debugPrint('Error requesting overlay permission: $e');
    }
  }

  // Turn off the screen on Android
  static Future<bool> turnOffScreen() async {
    try {
      if (kDebugMode) {
        debugPrint('Attempting to turn off screen...');
      }

      final bool result = await _channel.invokeMethod('turnOffScreen');

      if (kDebugMode) {
        debugPrint('Screen off result: $result');
      }
      return result;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to turn off screen: ${e.message}');
      }
      return false;
    }
  }

  // Check if screen is currently on
  static Future<bool> isScreenOn() async {
    try {
      final bool isOn = await _channel.invokeMethod('isScreenOn');
      return isOn;
    } catch (e) {
      return true; // Default to true if can't determine
    }
  }


    // Show black overlay
  // static Future<bool> showBlackOverlay() async {
  //   try {
  //     if (kDebugMode) {
  //       debugPrint('⬛ Calling showBlackOverlay method...');
  //     }

  //     final bool result = await _channel.invokeMethod('showBlackOverlay');

  //     if (kDebugMode) {
  //       debugPrint('✅ Black overlay result: $result');
  //     }

  //     return result;
  //   } catch (e) {
  //     if (kDebugMode) {
  //       debugPrint('❌ Error showing black overlay: $e');
  //     }
  //     return false;
  //   }
  // }
  
  static Future<bool> showBlackOverlay() async {
    try {
      final bool result = await _channel.invokeMethod('showBlackOverlay');
      return result;
    } on PlatformException catch (e) {
      print("Failed to show black overlay: ${e.message}");
      return false;
    }
  }
}

