import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_player_port/screens/ScreenshotGalleryScreen.dart';
import 'package:media_player_port/screens/wauly_monitor_screen.dart';
import 'package:media_player_port/services/ScreenshotService.dart';
import 'package:media_player_port/services/connectivity_service.dart';
import 'package:media_player_port/widgets/connectivity_status_card.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
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

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _setupAnimation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _volumeService.dispose();
    _connectivityService.dispose();
    super.dispose();
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

    //setState(() => _isLoading = false);
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

  // void _onVolumeChanged() => setState(() {});
  // void _onBrightnessChanged() => setState(() {});

  Future<void> _loadDeviceInfo() async {
    _deviceDetails = await _deviceInfoService.getDeviceDetails();
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    _systemService.showSnackBar(context, message, color);
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
            // content: Text(
            //     'Files are saved at:\n$path\n\nUse a file manager app to view them.'),
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
        //_showSnackBar('Showing black screen...', Colors.orange);
        final success = await ScreenService.showBlackOverlay();
        if (success) {
          //_showSnackBar('Black screen activated', Colors.green);
        } else {
          //_showSnackBar('Failed to show black screen', Colors.red);
        }
      }
    } catch (e) {
      //_showSnackBar('Error: ${e.toString()}', Colors.red);
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
                padding: const EdgeInsets.all(10.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      ConnectivityStatusCard(
                        connectivityService: _connectivityService,
                      ),
                      const SizedBox(height: 10),
                      DeviceInfoCard(deviceDetails: _deviceDetails),
                      const SizedBox(height: 10),
                      VolumeControlCard(
                        volumeService: _volumeService,
                        onShowSnackBar: _showSnackBar,
                      ),
                      const SizedBox(height: 10),
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
                              icon: const Icon(Icons.monitor_heart),
                              label: const Text('Event Monitor'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Expanded(
                          //   child: ElevatedButton.icon(
                          //     onPressed: _openScreenshotsFolder,
                          //     icon: const Icon(Icons.folder),
                          //     label: const Text('Screenshots Location'),
                          //     style: ElevatedButton.styleFrom(
                          //       backgroundColor: Colors.orange,
                          //       foregroundColor: Colors.white,
                          //       shape: RoundedRectangleBorder(
                          //         borderRadius: BorderRadius.circular(12),
                          //       ),
                          //     ),
                          //   ),
                          // ),
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
                              icon: const Icon(Icons.photo_library),
                              label: const Text('View Gallery'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _turnOffScreen,
                              icon: const Icon(Icons.power_settings_new),
                              label: const Text('Turn Off Screen'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
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
