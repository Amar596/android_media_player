import 'package:flutter/material.dart';
import '../services/system_service.dart';
import '../utils/constants.dart';

class ActionButtonsCard extends StatelessWidget {
  final SystemService systemService;
  final Function(String, Color) onShowSnackBar;

  const ActionButtonsCard({
    super.key,
    required this.systemService,
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
            const SizedBox(height: 16),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Row(
      children: [
        Icon(Icons.settings, color: AppConstants.primaryColor),
        SizedBox(width: 12),
        Text(
          AppStrings.actions,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(
          icon: Icons.refresh,
          label: AppStrings.reboot,
          color: AppConstants.warningColor,
          onPressed: () =>
              systemService.showRebootShutdownDialog(context, 'Reboot'),
        ),
        _buildActionButton(
          icon: Icons.power_settings_new,
          label: AppStrings.shutdown,
          color: AppConstants.errorColor,
          onPressed: () =>
              systemService.showRebootShutdownDialog(context, 'Shutdown'),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
