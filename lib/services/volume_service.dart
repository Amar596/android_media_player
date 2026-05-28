import 'package:flutter/material.dart';
import 'package:volume_controller/volume_controller.dart';

class VolumeService {
  static final VolumeService _instance = VolumeService._internal();
  factory VolumeService() => _instance;
  VolumeService._internal();

  double _currentVolume = 0.5;
  double _volumeBeforeMute = 0.5; // Store volume before muting
  bool _isAvailable = true;
  bool _isMuted = false;
  VoidCallback? _onVolumeChanged;

  double get currentVolume => _currentVolume;
  bool get isAvailable => _isAvailable;
  bool get isMuted => _isMuted;

  void initialize({VoidCallback? onVolumeChanged}) {
    _onVolumeChanged = onVolumeChanged;

    try {
      // Get current volume
      VolumeController().getVolume().then((volume) {
        _currentVolume = volume;
        _volumeBeforeMute = volume;
        _onVolumeChanged?.call();
      }).catchError((error) {
        print('Error getting volume: $error');
        _isAvailable = false;
        _onVolumeChanged?.call();
      });

      // Listen for volume changes
      VolumeController().listener((volume) {
        _currentVolume = volume;
        // If volume changes from 0 to >0 while muted, unmute
        if (_isMuted && volume > 0) {
          _isMuted = false;
        }
        // If volume changes to 0, consider it muted
        if (volume == 0 && !_isMuted) {
          _isMuted = true;
        }
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

    // If setting volume to 0, mark as muted
    if (value == 0) {
      _isMuted = true;
    } else if (_isMuted) {
      // If setting volume > 0 while muted, unmute
      _isMuted = false;
    }

    try {
      VolumeController().setVolume(value);
      _currentVolume = value;
      if (!_isMuted) {
        _volumeBeforeMute = value; // Only update if not muted
      }
      _onVolumeChanged?.call();
    } catch (e) {
      print('Error setting volume: $e');
      _isAvailable = false;
      _onVolumeChanged?.call();
    }
  }

  Future<void> toggleMute() async {
    if (!_isAvailable) return;

    if (_isMuted) {
      // Unmute: restore previous volume
      final volumeToRestore = _volumeBeforeMute > 0 ? _volumeBeforeMute : 0.5;
      await setVolume(volumeToRestore);
      _isMuted = false;
    } else {
      // Mute: save current volume and set to 0
      _volumeBeforeMute = _currentVolume;
      await setVolume(0);
      _isMuted = true;
    }
  }

  void dispose() {
    VolumeController().removeListener();
  }
}
