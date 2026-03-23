import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_player_port/services/connectivity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MonitoringEvent {
  final String timestamp;
  final String message;
  final String type;
  final String? lastActiveTime;

  MonitoringEvent({
    required this.timestamp,
    required this.message,
    required this.type,
    this.lastActiveTime,
  });

  factory MonitoringEvent.fromJson(Map<String, dynamic> json) {
    return MonitoringEvent(
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
      message: json['message'] ?? '',
      type: json['type'] ?? 'info',
      lastActiveTime: json['lastActiveTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'message': message,
      'type': type,
      'lastActiveTime': lastActiveTime,
    };
  }

  @override
  String toString() => '[$timestamp] [$type] $message';
}

class WaulyStatus {
  final String lastMessage;
  final String lastMessageTime;
  final String lastActiveTime;
  final String appStatus;
  final int messageCount;

  WaulyStatus({
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastActiveTime,
    required this.appStatus,
    required this.messageCount,
  });

  factory WaulyStatus.fromJson(Map<String, dynamic> json) {
    return WaulyStatus(
      lastMessage: json['lastMessage'] ?? 'No messages',
      lastMessageTime: json['lastMessageTime'] ?? 'N/A',
      lastActiveTime: json['lastActiveTime'] ?? 'N/A',
      appStatus: json['appStatus'] ?? 'UNKNOWN',
      messageCount: json['messageCount'] ?? 0,
    );
  }

  bool get isRunning => appStatus == 'RUNNING';
  bool get isStopped => appStatus == 'STOPPED';
  bool get isBackground => appStatus == 'BACKGROUND';

  Color get statusColor {
    switch (appStatus) {
      case 'RUNNING':
        return Colors.green;
      case 'STOPPED':
        return Colors.red;
      case 'BACKGROUND':
        return Colors.orange;
      case 'TESTING':
        return Colors.blue;
      case 'ERROR':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (appStatus) {
      case 'RUNNING':
        return Icons.play_circle_filled;
      case 'STOPPED':
        return Icons.stop_circle;
      case 'BACKGROUND':
        return Icons.pause_circle_filled;
      case 'TESTING':
        return Icons.bug_report;
      case 'ERROR':
        return Icons.error;
      default:
        return Icons.help;
    }
  }
}

class MonitoringService {
  static const String _methodChannel = 'port_control';
  static const String _eventChannel =
      'com.example.media_player_port/monitoring_events';
  static const String _historyKey = 'wauly_event_history';

  static final MonitoringService _instance = MonitoringService._internal();
  factory MonitoringService() => _instance;
  MonitoringService._internal();

  final MethodChannel _methodChannelHandler =
      const MethodChannel(_methodChannel);
  final EventChannel _eventChannelHandler = const EventChannel(_eventChannel);

  // MOVE THIS INSIDE MonitoringService class (not in MonitoringEvent)
  final ConnectivityService _connectivityService = ConnectivityService();

  StreamSubscription? _eventSubscription;
  final List<MonitoringEvent> _events = [];
  final int _maxEvents = 100;

  WaulyStatus? _currentStatus;

  final StreamController<List<MonitoringEvent>> _eventsController =
      StreamController<List<MonitoringEvent>>.broadcast();
  final StreamController<WaulyStatus> _statusController =
      StreamController<WaulyStatus>.broadcast();

  // Public streams
  Stream<List<MonitoringEvent>> get eventsStream => _eventsController.stream;
  Stream<WaulyStatus> get statusStream => _statusController.stream;

  List<MonitoringEvent> get events => List.unmodifiable(_events);
  WaulyStatus? get currentStatus => _currentStatus;

  // Add getter for connectivity service
  ConnectivityService get connectivityService => _connectivityService;

  bool _isDisposed = false;

  Future<void> initialize() async {
    print('📡 Initializing Monitoring Service...');

    try {
      // Load saved history
      await _loadHistory();

      // Get current status
      await _refreshStatus();

      // Start listening for events
      _startListening();

      print('✅ Monitoring Service initialized');
    } catch (e) {
      print('❌ Failed to initialize Monitoring Service: $e');
    }
  }

  void _startListening() {
    _eventSubscription = _eventChannelHandler
        .receiveBroadcastStream()
        .listen(_onEvent, onError: _onError);
    print('🎧 Started listening for monitoring events');
  }

  void _onEvent(dynamic event) {
    print('📨 Event received: $event');

    if (event is Map) {
      try {
        final message = event['message']?.toString() ?? '';
        final type = event['type']?.toString() ?? 'info';
        final lastActiveTime = event['lastActiveTime']?.toString();

        // FILTER OUT both BACKGROUND and ALIVE events
        if (type == 'background' ||
            type == 'alive' ||
            message.contains('BACKGROUND') ||
            message.contains('ALIVE')) {
          print('⏭️ Filtering out unwanted event: $type');
          return; // Don't add to history
        }

        final monitoringEvent = MonitoringEvent(
          timestamp: event['timestamp']?.toString() ??
              DateTime.now().toIso8601String(),
          message: message,
          type: type,
          lastActiveTime: lastActiveTime,
        );

        _addEvent(monitoringEvent);

        // Update status with last active time
        if (monitoringEvent.lastActiveTime != null) {
          _currentStatus = WaulyStatus(
            lastMessage: monitoringEvent.message,
            lastMessageTime: monitoringEvent.timestamp,
            lastActiveTime: monitoringEvent.lastActiveTime!,
            appStatus: _currentStatus?.appStatus ?? 'UNKNOWN',
            messageCount: _events.length,
          );
          _statusController.add(_currentStatus!);
        } else {
          _refreshStatus();
        }
      } catch (e) {
        print('❌ Error processing event: $e');
      }
    }
  }

  void _onError(Object error) {
    print('❌ Event channel error: $error');
  }

  void _addEvent(MonitoringEvent event) {
    _events.insert(0, event);

    if (_events.length > _maxEvents) {
      _events.removeRange(_maxEvents, _events.length);
    }

    _eventsController.add(_events);
    _saveHistory();
  }

  Future<void> _refreshStatus() async {
    try {
      final status =
          await _methodChannelHandler.invokeMethod<Map>('getWaulyStatus');
      if (status != null) {
        _currentStatus =
            WaulyStatus.fromJson(Map<String, dynamic>.from(status));
        _statusController.add(_currentStatus!);
      }
    } catch (e) {
      print('❌ Failed to refresh status: $e');
    }
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);

      if (historyJson != null && historyJson.isNotEmpty) {
        final List<dynamic> decoded = json.decode(historyJson);
        _events.clear();
        _events.addAll(decoded.map((item) => MonitoringEvent.fromJson(item)));
        _eventsController.add(_events);
        print('📂 Loaded ${_events.length} events from SharedPreferences');
      }
    } catch (e) {
      print('❌ Failed to load history: $e');
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = json.encode(_events.map((e) => e.toJson()).toList());
      await prefs.setString(_historyKey, historyJson);
      print('💾 History saved to SharedPreferences');
    } catch (e) {
      print('❌ Failed to save history: $e');
    }
  }

  Future<Map?> testConnection() async {
    try {
      return await _methodChannelHandler.invokeMethod<Map>('testConnection');
    } catch (e) {
      print('❌ Connection test failed: $e');
      return null;
    }
  }

  Future<List<MonitoringEvent>?> sendSelfTest() async {
    try {
      final events =
          await _methodChannelHandler.invokeMethod<List>('sendSelfTest');
      if (events != null) {
        return events.map((e) => MonitoringEvent.fromJson(e)).toList();
      }
      return null;
    } catch (e) {
      print('❌ Self test failed: $e');
      return null;
    }
  }

  Future<Map?> getSystemInfo() async {
    try {
      return await _methodChannelHandler.invokeMethod<Map>('getSystemInfo');
    } catch (e) {
      print('❌ Failed to get system info: $e');
      return null;
    }
  }

  Future<String?> ping() async {
    try {
      return await _methodChannelHandler.invokeMethod<String>('ping');
    } catch (e) {
      print('❌ Ping failed: $e');
      return null;
    }
  }

  Future<void> clearData() async {
    try {
      await _methodChannelHandler.invokeMethod('clearWaulyData');
      _events.clear();
      _eventsController.add(_events);

      // Also clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);

      await _refreshStatus();
    } catch (e) {
      print('❌ Failed to clear data: $e');
    }
  }

  // void dispose() {
  //   _eventSubscription?.cancel();
  //   _eventsController.close();
  //   _statusController.close();
  //   _connectivityService.dispose(); // Now this works
  // }

    void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    _eventSubscription?.cancel();
    _eventSubscription = null;

    _eventsController.close();
    _statusController.close();

    // Dispose connectivity service
    _connectivityService.dispose();

    print('✅ Monitoring Service disposed');
  }
}
