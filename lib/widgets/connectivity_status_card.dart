import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

class ConnectivityStatusCard extends StatefulWidget {
  final ConnectivityService connectivityService;

  const ConnectivityStatusCard({
    super.key,
    required this.connectivityService,
  });

  @override
  State<ConnectivityStatusCard> createState() => _ConnectivityStatusCardState();
}

class _ConnectivityStatusCardState extends State<ConnectivityStatusCard> {
  bool _isConnected = false;
  String _connectionType = 'Unknown';
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _isConnected = widget.connectivityService.isConnected;
    _connectionType = widget.connectivityService.connectionType;

    // Listen to connectivity changes
    widget.connectivityService.addListener(_onConnectivityChanged);
  }

  void _onConnectivityChanged() {
    if (!_isDisposed && mounted) {
      setState(() {
        _isConnected = widget.connectivityService.isConnected;
        _connectionType = widget.connectivityService.connectionType;
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    widget.connectivityService.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: _isConnected ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isConnected ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isConnected ? Icons.wifi : Icons.wifi_off,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Connection info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isConnected ? 'Connected' : 'Disconnected',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isConnected
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _connectionType,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _isConnected ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _isConnected ? 'ONLINE' : 'OFFLINE',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
