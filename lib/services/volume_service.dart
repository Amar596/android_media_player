import 'package:flutter/material.dart';
import 'package:volume_controller/volume_controller.dart';

class VolumeService {
  static final VolumeService _instance = VolumeService._internal();
  factory VolumeService() => _instance;
  VolumeService._internal();

  double _currentVolume = 0.5;
  bool _isAvailable = true;
  VoidCallback? _onVolumeChanged;

  double get currentVolume => _currentVolume;
  bool get isAvailable => _isAvailable;

  void initialize({VoidCallback? onVolumeChanged}) {
    _onVolumeChanged = onVolumeChanged;

    try {
      // Get current volume
      VolumeController().getVolume().then((volume) {
        _currentVolume = volume;
        _onVolumeChanged?.call();
      }).catchError((error) {
        print('Error getting volume: $error');
        _isAvailable = false;
        _onVolumeChanged?.call();
      });

      // Listen for volume changes
      VolumeController().listener((volume) {
        _currentVolume = volume;
        _onVolumeChanged?.call();
      });
    } catch (e) {
      print('Volume controller error: $e');
      _isAvailable = false;
      _onVolumeChanged?.call();
    }
  }

  Future<void> setVolume(double value) async {
    if (!_isAvailable) return;

    try {
      VolumeController().setVolume(value);
    } catch (e) {
      print('Error setting volume: $e');
      _isAvailable = false;
      _onVolumeChanged?.call();
    }
  }

  void dispose() {
    VolumeController().removeListener();
  }
}
