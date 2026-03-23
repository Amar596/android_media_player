import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

class BrightnessService {
  static const MethodChannel _brightnessChannel =
      MethodChannel(AppConstants.brightnessChannel);
  static const MethodChannel _systemChannel =
      MethodChannel(AppConstants.systemChannel);

  double _currentBrightness = 0.5;
  bool _isAvailable = true;
  bool _isLoading = false;
  VoidCallback? _onBrightnessChanged;

  double get currentBrightness => _currentBrightness;
  bool get isAvailable => _isAvailable;
  bool get isLoading => _isLoading;

  void initialize({VoidCallback? onBrightnessChanged}) {
    _onBrightnessChanged = onBrightnessChanged;
    _getCurrentBrightness();
  }

  Future<void> _getCurrentBrightness() async {
    try {
      final brightness = await _brightnessChannel.invokeMethod('getBrightness');
      if (brightness != null) {
        _currentBrightness = brightness;
        _isAvailable = true;
        _onBrightnessChanged?.call();
      }
    } catch (e) {
      print('Error getting brightness: $e');
      _isAvailable = false;
      _onBrightnessChanged?.call();
    }
  }

  Future<bool> setBrightness(double value) async {
    if (!_isAvailable) return false;

    _isLoading = true;
    _onBrightnessChanged?.call();

    try {
      final success = await _brightnessChannel.invokeMethod(
        'setBrightness',
        {'brightness': value},
      );

      if (success == true) {
        _currentBrightness = value;
        _isLoading = false;
        _onBrightnessChanged?.call();
        return true;
      } else {
        throw Exception('Failed to set brightness');
      }
    } catch (e) {
      print('Error setting brightness: $e');
      _isAvailable = false;
      _isLoading = false;
      _onBrightnessChanged?.call();
      return false;
    }
  }

  Future<void> openBrightnessSettings() async {
    try {
      await _systemChannel.invokeMethod('openBrightnessSettings');
    } catch (e) {
      print('Error opening settings: $e');
    }
  }

  Future<bool> checkAvailability() async {
    try {
      final isAvailable =
          await _brightnessChannel.invokeMethod('isBrightnessAvailable');
      _isAvailable = isAvailable ?? true;
      return _isAvailable;
    } catch (e) {
      print('Error checking brightness availability: $e');
      return false;
    }
  }
}
