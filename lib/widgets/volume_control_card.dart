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
            _buildSlider(),
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
      ],
    );
  }

  Widget _buildSlider() {
    return Row(
      children: [
        const Icon(Icons.volume_down, size: 20, color: Colors.grey),
        Expanded(
          child: Slider(
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
            label: '${(volumeService.currentVolume * 100).round()}%',
          ),
        ),
        const Icon(Icons.volume_up, size: 20, color: Colors.grey),
      ],
    );
  }

  void _onSliderChanged(double value) {
    // Preview change without applying
  }

  Future<void> _onSliderChangeEnd(double value) async {
    await volumeService.setVolume(value);
    // onShowSnackBar(
    //   'Volume set to ${(value * 100).round()}%',
    //   AppConstants.successColor,
    // );
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
