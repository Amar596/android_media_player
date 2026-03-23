import 'package:flutter/material.dart';
import '../services/brightness_service.dart';
import '../utils/constants.dart';

class BrightnessControlCard extends StatelessWidget {
  final BrightnessService brightnessService;
  final Function(String, Color) onShowSnackBar;

  const BrightnessControlCard({
    super.key,
    required this.brightnessService,
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
            _buildSlider(context),
            if (!brightnessService.isAvailable) _buildNotAvailableText(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.brightness_6,
          color: brightnessService.isAvailable
              ? AppConstants.primaryColor
              : Colors.grey,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            AppStrings.brightnessControl,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color:
                  brightnessService.isAvailable ? Colors.black87 : Colors.grey,
            ),
          ),
        ),
        if (brightnessService.isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppConstants.primaryColor,
            ),
          ),
      ],
    );
  }

  Widget _buildSlider(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.brightness_low, size: 20, color: Colors.grey),
        Expanded(
          child: Slider(
            value: brightnessService.currentBrightness,
            onChanged:
                brightnessService.isAvailable && !brightnessService.isLoading
                    ? (value) => _onSliderChanged(value)
                    : null,
            onChangeEnd:
                brightnessService.isAvailable && !brightnessService.isLoading
                    ? (value) => _onSliderChangeEnd(context, value)
                    : null,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            activeColor: AppConstants.primaryColor,
            inactiveColor: Colors.grey[300],
            label: '${(brightnessService.currentBrightness * 100).round()}%',
          ),
        ),
        const Icon(Icons.brightness_high, size: 20, color: Colors.grey),
      ],
    );
  }

  void _onSliderChanged(double value) {
    // Preview change without applying
  }

  Future<void> _onSliderChangeEnd(BuildContext context, double value) async {
    final success = await brightnessService.setBrightness(value);

    if (success) {
      // onShowSnackBar(
      //   'Brightness set to ${(value * 100).round()}%',
      //   AppConstants.successColor,
      // );
    } else {
      _showBrightnessSettingsDialog(context);
    }
  }

  void _showBrightnessSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Brightness Control'),
        content: const Text(
            'Unable to change brightness directly.\n\nWould you like to open system display settings to adjust brightness manually?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openBrightnessSettings();
            },
            child: const Text('Open Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openBrightnessSettings() async {
    await brightnessService.openBrightnessSettings();
  }

  Widget _buildNotAvailableText() {
    return const Padding(
      padding: EdgeInsets.only(top: 8),
      child: Text(
        'Tap to open system settings',
        style: TextStyle(color: Colors.blue, fontSize: 12),
      ),
    );
  }
}
