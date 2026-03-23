import 'package:flutter/material.dart';
import '../utils/constants.dart';

class DeviceInfoCard extends StatelessWidget {
  final Map<String, dynamic>? deviceDetails;

  const DeviceInfoCard({super.key, this.deviceDetails});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            // begin: Alignment.topLeft,
            // end: Alignment.bottomRight,
            colors: [Colors.white, Colors.blue.shade50],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const Divider(height: 20),
              _buildInfoTile(Icons.smartphone, 'Model',
                  deviceDetails?['model'] ?? 'Loading...'),
              _buildInfoTile(Icons.business, 'Manufacturer',
                  deviceDetails?['manufacturer'] ?? 'Loading...'),
              _buildInfoTile(Icons.android, 'Android Version',
                  '${deviceDetails?['androidVersion'] ?? 'Loading...'} (SDK ${deviceDetails?['sdkVersion'] ?? '?'})'),
              _buildInfoTile(
                  Icons.memory, 'RAM', deviceDetails?['ram'] ?? 'Loading...'),
              _buildInfoTile(Icons.storage, 'Storage',
                  deviceDetails?['storage'] ?? 'Loading...'),
              _buildInfoTile(Icons.speed, 'CPU',
                  deviceDetails?['cpuInfo'] ?? 'Loading...'),
              _buildInfoTile(Icons.info, 'Kernel',
                  deviceDetails?['kernelVersion'] ?? 'Loading...'),
              if (deviceDetails?['isTV'] == true)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.blue, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Android TV Device',
                        style: TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: AppConstants.primaryColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.devices, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          AppStrings.deviceInfo,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.blue[700]),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
