import 'package:flutter/material.dart';
import '../services/volume_service.dart';
import '../utils/constants.dart';

class VolumeControlCard extends StatelessWidget {
  final VolumeService volumeService;
  final Function(String, Color) onShowSnackBar;

  const VolumeControlCard({
    super.key,
    required this.volumeService,
    required this.onShowSnackBar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            _buildVolumeControls(),
            if (!volumeService.isAvailable) _buildNotAvailableText(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          volumeService.isAvailable ? Icons.volume_up : Icons.volume_off,
          color: volumeService.isAvailable
              ? AppConstants.primaryColor
              : Colors.grey,
        ),
        const SizedBox(width: 12),
        Text(
          AppStrings.volumeControl,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: volumeService.isAvailable ? Colors.black87 : Colors.grey,
          ),
        ),
        const Spacer(),
        if (volumeService.isAvailable) _buildMuteButton(),
      ],
    );
  }

  Widget _buildMuteButton() {
    return ValueListenableBuilder(
      valueListenable: _VolumeNotifier(volumeService),
      builder: (context, _, __) {
        return IconButton(
          icon: Icon(
            volumeService.isMuted ? Icons.volume_off : Icons.volume_up,
            color:
                volumeService.isMuted ? Colors.grey : AppConstants.primaryColor,
          ),
          onPressed: () => _toggleMute(),
          tooltip: volumeService.isMuted ? 'Unmute' : 'Mute',
        );
      },
    );
  }

  Widget _buildVolumeControls() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 24),
          onPressed: volumeService.isAvailable ? () => _decreaseVolume() : null,
          color: AppConstants.primaryColor,
        ),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: _VolumeNotifier(volumeService),
            builder: (context, _, __) {
              return Slider(
                value: volumeService.currentVolume,
                onChanged: volumeService.isAvailable
                    ? (value) => _onSliderChanged(value)
                    : null,
                onChangeEnd: volumeService.isAvailable
                    ? (value) => _onSliderChangeEnd(value)
                    : null,
                min: 0.0,
                max: 1.0,
                divisions: 20,
                activeColor: AppConstants.primaryColor,
                inactiveColor: Colors.grey[300],
                label: volumeService.isMuted
                    ? 'Muted'
                    : '${(volumeService.currentVolume * 100).round()}%',
              );
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 24),
          onPressed: volumeService.isAvailable ? () => _increaseVolume() : null,
          color: AppConstants.primaryColor,
        ),
      ],
    );
  }

  void _onSliderChanged(double value) {
    // Preview change without applying - you might want to show a preview
  }

  Future<void> _onSliderChangeEnd(double value) async {
    await volumeService.setVolume(value);
    if (!volumeService.isMuted && value > 0) {
      onShowSnackBar(
        'Volume set to ${(value * 100).round()}%',
        AppConstants.successColor,
      );
    } else if (value == 0) {
      onShowSnackBar(
        'Volume muted',
        AppConstants.warningColor, // Make sure you have this color
      );
    }
  }

  Future<void> _toggleMute() async {
    await volumeService.toggleMute();
    onShowSnackBar(
      volumeService.isMuted ? 'Volume muted' : 'Volume unmuted',
      volumeService.isMuted
          ? AppConstants.warningColor
          : AppConstants.successColor,
    );
  }

  Future<void> _decreaseVolume() async {
    double newVolume = (volumeService.currentVolume - 0.05).clamp(0.0, 1.0);
    await volumeService.setVolume(newVolume);
  }

  Future<void> _increaseVolume() async {
    double newVolume = (volumeService.currentVolume + 0.05).clamp(0.0, 1.0);
    await volumeService.setVolume(newVolume);
  }

  Widget _buildNotAvailableText() {
    return const Padding(
      padding: EdgeInsets.only(top: 8),
      child: Text(
        'Volume control not available',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }
}

// Helper class to make VolumeService listenable
class _VolumeNotifier extends ValueNotifier<void> {
  final VolumeService volumeService;

  _VolumeNotifier(this.volumeService) : super(null) {
    // You'll need to add a way to notify when volume changes
    // One approach: modify VolumeService to accept a callback or use StreamController
  }
}
