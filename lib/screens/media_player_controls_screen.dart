import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_player_port/screens/ScreenshotGalleryScreen.dart';
import 'package:media_player_port/screens/wauly_monitor_screen.dart';
import 'package:media_player_port/services/ScreenshotService.dart';
import 'package:media_player_port/services/connectivity_service.dart';
import 'package:media_player_port/services/usb_detection_service.dart';
import 'package:media_player_port/services/wauly_app_service.dart';
import 'package:media_player_port/widgets/connectivity_status_card.dart';
import 'package:media_player_port/widgets/storage_card.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/device_info_service.dart';
import '../services/volume_service.dart';
import '../services/brightness_service.dart';
import '../services/system_service.dart';
import '../widgets/device_info_card.dart';
import '../widgets/volume_control_card.dart';
import '../widgets/brightness_control_card.dart';
import '../widgets/rotation_control_card.dart';
import '../widgets/action_buttons_card.dart';
import '../utils/constants.dart';
import '../services/screen_service.dart';
import '../services/wauly_app_manager.dart';

class MediaPlayerControlsScreen extends StatefulWidget {
  const MediaPlayerControlsScreen({super.key});

  @override
  State<MediaPlayerControlsScreen> createState() =>
      _MediaPlayerControlsScreenState();
}

class _MediaPlayerControlsScreenState extends State<MediaPlayerControlsScreen>
    with SingleTickerProviderStateMixin {
  final DeviceInfoService _deviceInfoService = DeviceInfoService();
  final VolumeService _volumeService = VolumeService();
  final BrightnessService _brightnessService = BrightnessService();
  final SystemService _systemService = SystemService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final ScreenshotService _screenshotService = ScreenshotService();

  Map<String, dynamic>? _deviceDetails;
  bool _isLoading = true;
  bool _isCapturing = false;
  String _appVersion = '';
  String _currentDateTime = '';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  late UsbDetectionService _usbService;
  StreamSubscription? _usbSubscription;

  bool _isDisposed = false;
  bool _autoOpenEnabled = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _setupAnimation();
    _loadAutoOpenSetting();

    _usbService = UsbDetectionService();

    _usbSubscription = _usbService.usbEvents.listen((event) {
      debugPrint("USB EVENT: $event");

      if (event == "USB_ATTACHED") {
        _showSnackBar(
          "USB Device Connected",
          Colors.green,
        );
      }

      if (event == "USB_DETACHED") {
        _showSnackBar(
          "USB Device Removed",
          Colors.red,
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _volumeService.dispose();
    _connectivityService.dispose();
    super.dispose();
    _usbSubscription?.cancel();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: AppConstants.animationDuration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  Future<void> _initializeServices() async {
    await _loadDeviceInfo();

    _volumeService.initialize(onVolumeChanged: _onVolumeChanged);
    _brightnessService.initialize(onBrightnessChanged: _onBrightnessChanged);
    await _systemService.requestBrightnessPermission(context);

    if (!_isDisposed && mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onVolumeChanged() {
    if (!_isDisposed && mounted) {
      setState(() {});
    }
  }

  void _onBrightnessChanged() {
    if (!_isDisposed && mounted) {
      setState(() {});
    }
  }

  Future<void> _loadDeviceInfo() async {
    _deviceDetails = await _deviceInfoService.getDeviceDetails();
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    _systemService.showSnackBar(context, message, color);
  }

  // Add auto-launch methods
  Future<void> _loadAutoOpenSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoOpenEnabled = prefs.getBool('auto_open_wauly_app') ?? false;
    });
  }

  Future<void> _saveAutoOpenSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_open_wauly_app', value);
  }

  void _autoClickOpenWaulyApp() {
    // Optional: Trigger immediately when turned ON
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_autoOpenEnabled) {
        WaulyAppManager.handleAppFlow(context);
      }
    });
  }

  // Screenshot methods
  Future<void> _captureScreenshot() async {
    setState(() {
      _isCapturing = true;
    });

    // Wait for the current frame to be rendered
    await Future.delayed(const Duration(milliseconds: 200));

    final path = await _screenshotService.captureAndSaveScreenshot(
      filename: 'media_player_controls',
      onSuccess: () {
        _showSnackBar('Screenshot saved successfully!', Colors.green);
      },
      onError: (error) {
        _showSnackBar('Error: $error', Colors.red);
      },
    );

    if (path != null) {
      debugPrint('Screenshot saved at: $path');

      // Show full path in snackbar for easy access
      _showSnackBar('Saved: $path', Colors.blue);
    }

    setState(() {
      _isCapturing = false;
    });
  }

  // Add this method to open screenshots folder
  Future<void> _openScreenshotsFolder() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;

    if (Platform.isAndroid) {
      // On Android, you can't directly open folder, but you can show a dialog
      _showSnackBar('Screenshots folder: $path', Colors.blue);

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Screenshots Location'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else if (Platform.isIOS) {
      // On iOS, similar limitation
      _showSnackBar('Screenshots folder: $path', Colors.blue);
    }
  }

  Future<void> _turnOffScreen() async {
    try {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Screen Saver'),
          content: const Text(
            'This will show a black screen. Tap anywhere to exit.\n\n'
            'Note: This dims the screen but does not turn off the TV power.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
          ],
        ),
      );

      if (shouldContinue == true) {
        final success = await ScreenService.showBlackOverlay();
        if (success) {
          // Success message if needed
        } else {
          // Error message if needed
        }
      }
    } catch (e) {
      // Error handling if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppConstants.appName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Add screenshot button to app bar
          IconButton(
            icon: _isCapturing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.screenshot),
            onPressed: _isCapturing ? null : _captureScreenshot,
            tooltip: 'Take Screenshot',
          ),
        ],
      ),
      body: Screenshot(
        controller: _screenshotService.screenshotController,
        child: _isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(color: AppConstants.primaryColor))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(8.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConnectivityStatusCard(
                        connectivityService: _connectivityService,
                      ),
                      const SizedBox(height: 0),
                      DeviceInfoCard(deviceDetails: _deviceDetails),
                      const SizedBox(height: 0),
                      VolumeControlCard(
                        volumeService: _volumeService,
                        onShowSnackBar: _showSnackBar,
                      ),
                      const SizedBox(height: 8),
                      // const RotationControlCard(),
                      // const SizedBox(height: 8),
                      // const StorageCard(),
                      // const SizedBox(height: 8),
                      // ✅ ADD AUTO-LAUNCH TOGGLE HERE
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _autoOpenEnabled
                                ? [
                                    Colors.green.shade900.withOpacity(0.3),
                                    const Color(0xFF161B22)
                                  ]
                                : [
                                    Colors.grey.shade900.withOpacity(0.3),
                                    const Color(0xFF161B22)
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _autoOpenEnabled
                                ? Colors.greenAccent
                                : Colors.grey.shade700,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _autoOpenEnabled ? Icons.touch_app : Icons.block,
                              color: _autoOpenEnabled
                                  ? Colors.greenAccent
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _autoOpenEnabled
                                    ? 'Signage App - Auto launch ENABLED'
                                    : 'Signage App - Auto launch DISABLED',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            Switch(
                              value: _autoOpenEnabled,
                              onChanged: (bool value) async {
                                setState(() {
                                  _autoOpenEnabled = value;
                                });
                                await _saveAutoOpenSetting(value);

                                if (value) {
                                  // Optional: trigger once immediately when turned ON
                                  _autoClickOpenWaulyApp();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 0),
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.greenAccent.withOpacity(0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.greenAccent, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Signage App Status',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 0),
                            Text(
                              'Version: $_appVersion',
                              style: const TextStyle(
                                  color: Colors.black, fontSize: 13),
                            ),
                            const SizedBox(height: 0),
                            Text(
                              'Time: $_currentDateTime',
                              style: const TextStyle(
                                  color: Colors.black, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      // All buttons in a single row
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const WaulyMonitorScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.monitor_heart, size: 18),
                              label: const Text('Event Monitor'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ScreenshotGalleryScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.photo_library, size: 18),
                              label: const Text('View Gallery'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _turnOffScreen,
                              icon: const Icon(Icons.power_settings_new,
                                  size: 18),
                              label: const Text('Turn Off'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await WaulyAppManager.handleAppFlow(context);
                              },
                              icon: const Icon(Icons.tv,
                                  size: 18, color: Colors.white),
                              label: const Text(
                                'Open Wauly App',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2D3748),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
