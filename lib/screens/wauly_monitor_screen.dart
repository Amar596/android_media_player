import 'dart:async';
import 'package:flutter/material.dart';
import '../services/monitoring_service.dart';
import '../services/connectivity_service.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';

class WaulyMonitorScreen extends StatefulWidget {
  const WaulyMonitorScreen({super.key});

  @override
  State<WaulyMonitorScreen> createState() => _WaulyMonitorScreenState();
}

class _WaulyMonitorScreenState extends State<WaulyMonitorScreen> {
  final MonitoringService _monitoringService = MonitoringService();
  List<MonitoringEvent> _events = [];
  WaulyStatus? _status;
  bool _isLoading = true;

  // Add this to track listener
  bool _isListening = false;

  StreamSubscription? _eventsSubscription;
  StreamSubscription? _statusSubscription;

  @override
  void initState() {
    super.initState();
    
    _initialize();
  }

  Future<void> _initialize() async {
    await _monitoringService.initialize();

    _eventsSubscription = _monitoringService.eventsStream.listen((events) {
      if (mounted) {
        setState(() {
          _events = events;
        });
      }
    });

    _statusSubscription = _monitoringService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _status = status;
          _isLoading = false;
        });
      }
    });

    // Get initial status
    setState(() {
      _status = _monitoringService.currentStatus;
      _events = _monitoringService.events;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    _statusSubscription?.cancel();
    _monitoringService.dispose();
   // _connectivityService.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final result = await _monitoringService.testConnection();
    if (result != null) {
      _showSnackBar('Connection successful', Colors.green);
    } else {
      _showSnackBar('Connection failed', Colors.red);
    }
  }

  Future<void> _sendSelfTest() async {
    final events = await _monitoringService.sendSelfTest();
    if (events != null) {
      _showSnackBar('Self-test completed', Colors.green);
    }
  }

  Future<void> _clearData() async {
    await _monitoringService.clearData();
    _showSnackBar('Data cleared', Colors.orange);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showMessageDetails(MonitoringEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Event Details - ${event.type.toUpperCase()}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Type', event.type),
              const SizedBox(height: 8),
              _buildDetailRow('Time', event.timestamp),
              const SizedBox(height: 16),
              const Text('Message:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  event.message,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text('$label:',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = _monitoringService.connectivityService;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wauly Monitor'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.science),
          //   onPressed: _sendSelfTest,
          //   tooltip: 'Self Test',
          // ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _testConnection,
            tooltip: 'Test Connection',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearData,
            tooltip: 'Clear Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                const SizedBox(height: 10),
                  // Status Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildInfoRow(
                            'Last Active', _status?.lastActiveTime ?? 'N/A'),
                      ],
                    ),
                  ),
                ),

                  const SizedBox(height: 10),

                  // Events List
                  Expanded(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Event History',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: _events.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No events received',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    )
                                    :ListView.builder(
                                      itemCount: _events.where((event) =>
                                        event.type != 'background' &&
                                        event.type != 'alive' &&
                                        !event.message.contains('BACKGROUND') &&
                                        !event.message.contains('ALIVE')
                                      ).length,
                                      itemBuilder: (context, index) {
                                        // Get filtered list
                                        final filteredEvents = _events.where((event) =>
                                          event.type != 'background' &&
                                          event.type != 'alive' &&
                                          !event.message.contains('BACKGROUND') &&
                                          !event.message.contains('ALIVE')
                                        ).toList();

                                        final event = filteredEvents[index];
                                        return ListTile(
                                          leading: Icon(
                                            _getEventIcon(event.type),
                                            color: _getEventColor(event.type),
                                            size: 15,
                                          ),
                                          title: Text(
                                            event.message,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                          subtitle: Text(
                                            _formatTime(event.timestamp),
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                          dense: true,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          onTap: () => _showMessageDetails(event),
                                        );
                                      },
                                    )
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'started':
        return Icons.play_arrow;
      case 'stopped':
        return Icons.stop;
      case 'background':
        return Icons.pause;
      case 'alive':
        return Icons.favorite;
      case 'heartbeat':
        return Icons.favorite_border;
      case 'running':
        return Icons.directions_run;
      case 'test':
        return Icons.bug_report;
      case 'error':
        return Icons.error;
      default:
        return Icons.message;
    }
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'started':
        return Colors.green;
      case 'stopped':
        return Colors.red;
      case 'background':
        return Colors.orange;
      case 'alive':
        return Colors.blue;
      case 'heartbeat':
        return Colors.lightBlue;
      case 'running':
        return Colors.teal;
      case 'test':
        return Colors.purple;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(String timestamp) {
    try {
      final parts = timestamp.split(' ');
      if (parts.length >= 2) {
        return parts[1]; // Return time part
      }
      return timestamp;
    } catch (e) {
      return timestamp;
    }
  }
}
