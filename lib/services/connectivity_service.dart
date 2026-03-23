import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService with ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  bool _isConnected = true;
  String _connectionType = 'Unknown';

  bool get isConnected => _isConnected;
  String get connectionType => _connectionType;

  ConnectivityService() {
    _initConnectivity();
    _subscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      print('Connectivity init error: $e');
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;

    bool wasConnected = _isConnected;

    switch (result) {
      case ConnectivityResult.wifi:
        _isConnected = true;
        _connectionType = 'WiFi';
        break;
      case ConnectivityResult.mobile:
        _isConnected = true;
        _connectionType = 'Mobile Data';
        break;
      case ConnectivityResult.ethernet:
        _isConnected = true;
        _connectionType = 'Ethernet';
        break;
      case ConnectivityResult.vpn:
        _isConnected = true;
        _connectionType = 'VPN';
        break;
      case ConnectivityResult.bluetooth:
        _isConnected = true;
        _connectionType = 'Bluetooth';
        break;
      case ConnectivityResult.other:
        _isConnected = true;
        _connectionType = 'Other';
        break;
      case ConnectivityResult.none:
        _isConnected = false;
        _connectionType = 'No Connection';
        break;
    }

    print('📶 Connection changed: $_connectionType');

    if (wasConnected != _isConnected) {
      notifyListeners();
    } else {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
