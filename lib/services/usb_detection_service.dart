import 'dart:async';
import 'package:flutter/services.dart';

class UsbDetectionService {
  static const MethodChannel _channel = MethodChannel('usb_detection');

  static const EventChannel _eventChannel =
      EventChannel('usb_detection_events');

  Stream<dynamic>? _usbStream;

  Stream<dynamic> get usbEvents {
    _usbStream ??= _eventChannel.receiveBroadcastStream();
    return _usbStream!;
  }

  Future<String?> getPlatformVersion() async {
    try {
      final String? version = await _channel.invokeMethod('getPlatformVersion');
      return version;
    } on PlatformException catch (e) {
      return "Failed: ${e.message}";
    }
  }
}
