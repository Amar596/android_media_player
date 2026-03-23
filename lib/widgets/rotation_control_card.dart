// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import '../services/orientation_service.dart';
// import '../utils/constants.dart';

// class RotationControlCard extends StatefulWidget {
//   const RotationControlCard({super.key});

//   @override
//   State<RotationControlCard> createState() => _RotationControlCardState();
// }

// class _RotationControlCardState extends State<RotationControlCard> {
//   final OrientationService _orientationService = OrientationService();
//   String _currentOrientation = 'auto';
//   bool _isLoading = false;
//   bool _useFlutterOrientation = false; // Fallback method

//   @override
//   void initState() {
//     super.initState();
//     _initializeOrientation();

//     // Set callback for orientation changes
//     _orientationService.onOrientationChanged = () {
//       if (mounted) {
//         setState(() {
//           _currentOrientation = _orientationService.currentOrientation;
//         });
//       }
//     };
//   }

//   Future<void> _initializeOrientation() async {
//     await _orientationService.initialize();
//     if (mounted) {
//       setState(() {
//         _currentOrientation = _orientationService.currentOrientation;
//       });
//     }
//   }

//   Future<void> _setOrientation(String mode) async {
//     setState(() => _isLoading = true);

//     bool success = false;

//     // Try native method first
//     if (!_useFlutterOrientation) {
//       switch (mode) {
//         case 'portrait':
//           success = await _orientationService.setPortrait();
//           break;
//         case 'landscape':
//           success = await _orientationService.setLandscape();
//           break;
//         case 'auto':
//           success = await _orientationService.setAuto();
//           break;
//       }
//     }

//     // If native method fails, use Flutter's orientation control
//     if (!success) {
//       _useFlutterOrientation = true;
//       OrientationService.setOrientationFlutter(mode);

//       setState(() {
//         _currentOrientation = mode;
//       });

//       _showMessage('Orientation changed (App only)', Colors.orange);
//     } else {
//       _showMessage(
//           'Orientation changed to ${mode.toUpperCase()}', Colors.green);
//     }

//     if (mounted) {
//       setState(() => _isLoading = false);
//     }
//   }

//   void _showMessage(String message, Color color) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: color,
//         behavior: SnackBarBehavior.floating,
//         duration: const Duration(seconds: 1),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(15),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             _buildHeader(),
//             const SizedBox(height: 16),
//             if (_isLoading)
//               const Center(
//                 child: Padding(
//                   padding: EdgeInsets.all(8.0),
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     color: AppConstants.primaryColor,
//                   ),
//                 ),
//               )
//             else
//               _buildRotationOptions(),
//             const SizedBox(height: 12),
//             _buildStatusInfo(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: AppConstants.primaryColor.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: const Icon(Icons.screen_rotation,
//               color: AppConstants.primaryColor),
//         ),
//         const SizedBox(width: 12),
//         const Expanded(
//           child: Text(
//             AppStrings.screenRotation,
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//         if (_useFlutterOrientation)
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//             decoration: BoxDecoration(
//               color: Colors.orange.withOpacity(0.2),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: const Text(
//               'App Only',
//               style: TextStyle(
//                 color: Colors.orange,
//                 fontSize: 10,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildRotationOptions() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: [
//         _buildRotationOption(
//           icon: Icons.portrait,
//           label: AppStrings.portrait,
//           mode: 'portrait',
//           color: _currentOrientation == 'portrait' ? Colors.blue : Colors.grey,
//           backgroundColor: _currentOrientation == 'portrait'
//               ? Colors.blue.withOpacity(0.2)
//               : Colors.grey.withOpacity(0.1),
//         ),
//         _buildRotationOption(
//           icon: Icons.landscape,
//           label: AppStrings.landscape,
//           mode: 'landscape',
//           color:
//               _currentOrientation == 'landscape' ? Colors.green : Colors.grey,
//           backgroundColor: _currentOrientation == 'landscape'
//               ? Colors.green.withOpacity(0.2)
//               : Colors.grey.withOpacity(0.1),
//         ),
//         _buildRotationOption(
//           icon: Icons.screen_rotation,
//           label: AppStrings.auto,
//           mode: 'auto',
//           color: _currentOrientation == 'auto' ? Colors.orange : Colors.grey,
//           backgroundColor: _currentOrientation == 'auto'
//               ? Colors.orange.withOpacity(0.2)
//               : Colors.grey.withOpacity(0.1),
//         ),
//       ],
//     );
//   }

//   Widget _buildStatusInfo() {
//     String statusText = 'Current: ${_currentOrientation.toUpperCase()}';
//     if (_useFlutterOrientation) {
//       statusText += ' (App only - System rotation may be locked)';
//     }

//     return Text(
//       statusText,
//       style: TextStyle(
//         color: Colors.grey[600],
//         fontSize: 12,
//         fontStyle: FontStyle.italic,
//       ),
//       textAlign: TextAlign.center,
//     );
//   }

//   Widget _buildRotationOption({
//     required IconData icon,
//     required String label,
//     required String mode,
//     required Color color,
//     required Color backgroundColor,
//   }) {
//     return GestureDetector(
//       onTap: () => _setOrientation(mode),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         decoration: BoxDecoration(
//           color: backgroundColor,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(color: color.withOpacity(0.3)),
//         ),
//         child: Column(
//           children: [
//             Icon(icon, color: color, size: 28),
//             const SizedBox(height: 4),
//             Text(
//               label,
//               style: TextStyle(
//                 color: color,
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import '../utils/constants.dart';

// class RotationControlCard extends StatefulWidget {
//   const RotationControlCard({super.key});

//   @override
//   State<RotationControlCard> createState() => _RotationControlCardState();
// }

// class _RotationControlCardState extends State<RotationControlCard> {
//   String _currentOrientation = 'auto';
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _getCurrentOrientation();
//   }

//   Future<void> _getCurrentOrientation() async {
//     try {
//       // Get current orientation from SystemChrome
//       final preferences = await SystemChrome.getPreferredOrientations();
//       if (preferences.isEmpty) {
//         setState(() => _currentOrientation = 'auto');
//       } else if (preferences.contains(DeviceOrientation.portraitUp) ||
//           preferences.contains(DeviceOrientation.portraitDown)) {
//         setState(() => _currentOrientation = 'portrait');
//       } else if (preferences.contains(DeviceOrientation.landscapeLeft) ||
//           preferences.contains(DeviceOrientation.landscapeRight)) {
//         setState(() => _currentOrientation = 'landscape');
//       }
//     } catch (e) {
//       print('Error getting orientation: $e');
//     }
//   }

//   Future<void> _setOrientation(String mode) async {
//     setState(() => _isLoading = true);

//     try {
//       if (mode == 'portrait') {
//         await SystemChrome.setPreferredOrientations([
//           DeviceOrientation.portraitUp,
//           DeviceOrientation.portraitDown,
//         ]);
//       } else if (mode == 'landscape') {
//         await SystemChrome.setPreferredOrientations([
//           DeviceOrientation.landscapeLeft,
//           DeviceOrientation.landscapeRight,
//         ]);
//       } else {
//         await SystemChrome.setPreferredOrientations([
//           DeviceOrientation.portraitUp,
//           DeviceOrientation.portraitDown,
//           DeviceOrientation.landscapeLeft,
//           DeviceOrientation.landscapeRight,
//         ]);
//       }

//       setState(() {
//         _currentOrientation = mode;
//         _isLoading = false;
//       });

//       _showMessage('Orientation changed to $mode', Colors.green);
//     } catch (e) {
//       print('Error setting orientation: $e');
//       setState(() => _isLoading = false);
//       _showMessage('Failed to change orientation', Colors.red);
//     }
//   }

//   void _showMessage(String message, Color color) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: color,
//         behavior: SnackBarBehavior.floating,
//         duration: const Duration(seconds: 1),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(15),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             _buildHeader(),
//             const SizedBox(height: 16),
//             if (_isLoading)
//               const Center(
//                 child: Padding(
//                   padding: EdgeInsets.all(8.0),
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     color: AppConstants.primaryColor,
//                   ),
//                 ),
//               )
//             else
//               _buildRotationOptions(),
//             const SizedBox(height: 12),
//             _buildStatusInfo(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: AppConstants.primaryColor.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: const Icon(Icons.screen_rotation,
//               color: AppConstants.primaryColor),
//         ),
//         const SizedBox(width: 12),
//         const Expanded(
//           child: Text(
//             AppStrings.screenRotation,
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//           decoration: BoxDecoration(
//             color: Colors.orange.withOpacity(0.2),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: const Text(
//             'App Only',
//             style: TextStyle(
//               color: Colors.orange,
//               fontSize: 10,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildRotationOptions() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: [
//         _buildRotationOption(
//           icon: Icons.portrait,
//           label: AppStrings.portrait,
//           mode: 'portrait',
//           color: _currentOrientation == 'portrait' ? Colors.blue : Colors.grey,
//           backgroundColor: _currentOrientation == 'portrait'
//               ? Colors.blue.withOpacity(0.2)
//               : Colors.grey.withOpacity(0.1),
//         ),
//         _buildRotationOption(
//           icon: Icons.landscape,
//           label: AppStrings.landscape,
//           mode: 'landscape',
//           color:
//               _currentOrientation == 'landscape' ? Colors.green : Colors.grey,
//           backgroundColor: _currentOrientation == 'landscape'
//               ? Colors.green.withOpacity(0.2)
//               : Colors.grey.withOpacity(0.1),
//         ),
//         _buildRotationOption(
//           icon: Icons.screen_rotation,
//           label: AppStrings.auto,
//           mode: 'auto',
//           color: _currentOrientation == 'auto' ? Colors.orange : Colors.grey,
//           backgroundColor: _currentOrientation == 'auto'
//               ? Colors.orange.withOpacity(0.2)
//               : Colors.grey.withOpacity(0.1),
//         ),
//       ],
//     );
//   }

//   Widget _buildStatusInfo() {
//     String statusText = 'Current: ${_currentOrientation.toUpperCase()}';

//     return Column(
//       children: [
//         Text(
//           statusText,
//           style: TextStyle(
//             color: Colors.grey[600],
//             fontSize: 12,
//             fontStyle: FontStyle.italic,
//           ),
//           textAlign: TextAlign.center,
//         ),
//         const SizedBox(height: 4),
//         const Text(
//           'Note: Rotation works within app only',
//           style: TextStyle(
//             color: Colors.grey,
//             fontSize: 10,
//           ),
//           textAlign: TextAlign.center,
//         ),
//       ],
//     );
//   }

//   Widget _buildRotationOption({
//     required IconData icon,
//     required String label,
//     required String mode,
//     required Color color,
//     required Color backgroundColor,
//   }) {
//     return GestureDetector(
//       onTap: () => _setOrientation(mode),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         decoration: BoxDecoration(
//           color: backgroundColor,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(color: color.withOpacity(0.3)),
//         ),
//         child: Column(
//           children: [
//             Icon(icon, color: color, size: 28),
//             const SizedBox(height: 4),
//             Text(
//               label,
//               style: TextStyle(
//                 color: color,
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

class RotationControlCard extends StatefulWidget {
  const RotationControlCard({super.key});

  @override
  State<RotationControlCard> createState() => _RotationControlCardState();
}

class _RotationControlCardState extends State<RotationControlCard> {
  String _currentOrientation = 'auto';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // There's no way to get current orientation from SystemChrome
    // We'll just default to 'auto'
  }

  Future<void> _setOrientation(String mode) async {
    setState(() => _isLoading = true);

    try {
      if (mode == 'portrait') {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        setState(() => _currentOrientation = 'portrait');
      } else if (mode == 'landscape') {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        setState(() => _currentOrientation = 'landscape');
      } else {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        setState(() => _currentOrientation = 'auto');
      }

      setState(() => _isLoading = false);

      _showMessage(
        'Orientation changed to $mode',
        mode == 'portrait'
            ? Colors.blue
            : mode == 'landscape'
                ? Colors.green
                : Colors.orange,
      );
    } catch (e) {
      print('Error setting orientation: $e');
      setState(() => _isLoading = false);
      _showMessage('Failed to change orientation', Colors.red);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

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
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppConstants.primaryColor,
                  ),
                ),
              )
            else
              _buildRotationOptions(),
            const SizedBox(height: 12),
            _buildStatusInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.screen_rotation,
              color: AppConstants.primaryColor),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            AppStrings.screenRotation,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'App Only',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRotationOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildRotationOption(
          icon: Icons.portrait,
          label: AppStrings.portrait,
          mode: 'portrait',
          color: _currentOrientation == 'portrait' ? Colors.blue : Colors.grey,
          backgroundColor: _currentOrientation == 'portrait'
              ? Colors.blue.withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
        ),
        _buildRotationOption(
          icon: Icons.landscape,
          label: AppStrings.landscape,
          mode: 'landscape',
          color:
              _currentOrientation == 'landscape' ? Colors.green : Colors.grey,
          backgroundColor: _currentOrientation == 'landscape'
              ? Colors.green.withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
        ),
        _buildRotationOption(
          icon: Icons.screen_rotation,
          label: AppStrings.auto,
          mode: 'auto',
          color: _currentOrientation == 'auto' ? Colors.orange : Colors.grey,
          backgroundColor: _currentOrientation == 'auto'
              ? Colors.orange.withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
        ),
      ],
    );
  }

  Widget _buildStatusInfo() {
    String statusText = 'Current: ${_currentOrientation.toUpperCase()}';

    return Column(
      children: [
        Text(
          statusText,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const Text(
          'Note: Rotation works within app only',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRotationOption({
    required IconData icon,
    required String label,
    required String mode,
    required Color color,
    required Color backgroundColor,
  }) {
    return GestureDetector(
      onTap: () => _setOrientation(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
