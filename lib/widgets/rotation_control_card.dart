// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import '../utils/constants.dart';

// class RotationControlCard extends StatefulWidget {
//   const RotationControlCard({super.key});

//   @override
//   State<RotationControlCard> createState() => _RotationControlCardState();
// }

// class _RotationControlCardState extends State<RotationControlCard> {
//   int _currentDegree = 0;
//   bool _isLoading = false;

//   // Maps degree → Android ActivityInfo.screenOrientation constant
//   static const Map<int, int> _androidOrientationMap = {
//     0: 1, // SCREEN_ORIENTATION_PORTRAIT
//     90: 0, // SCREEN_ORIENTATION_LANDSCAPE
//     180: 9, // SCREEN_ORIENTATION_REVERSE_PORTRAIT
//     270: 8, // SCREEN_ORIENTATION_REVERSE_LANDSCAPE
//   };

//   static const _channel = MethodChannel('com.app/orientation');

//   Future<void> _setOrientation(int degree) async {
//     setState(() => _isLoading = true);

//     try {
//       // ✅ Step 1: Flutter SystemChrome (works on iOS + some Android)
//       DeviceOrientation orientation;
//       switch (degree) {
//         case 0:
//           orientation = DeviceOrientation.portraitUp;
//           break;
//         case 90:
//           orientation = DeviceOrientation.landscapeLeft;
//           break;
//         case 180:
//           orientation = DeviceOrientation.portraitDown;
//           break;
//         case 270:
//           orientation = DeviceOrientation.landscapeRight;
//           break;
//         default:
//           orientation = DeviceOrientation.portraitUp;
//       }

//       await SystemChrome.setPreferredOrientations([orientation]);

//       // ✅ Step 2: Android native fallback via MethodChannel
//       try {
//         await _channel.invokeMethod('setOrientation', {
//           'orientation': _androidOrientationMap[degree],
//         });
//       } catch (_) {
//         // MethodChannel not set up yet — SystemChrome alone will handle it
//       }

//       setState(() {
//         _currentDegree = degree;
//         _isLoading = false;
//       });

//       _showMessage('Rotated to $degree°', _getDegreeColor(degree));
//     } catch (e) {
//       setState(() => _isLoading = false);
//       _showMessage('Failed: $e', Colors.red);
//     }
//   }

//   Color _getDegreeColor(int degree) {
//     switch (degree) {
//       case 0:
//         return Colors.blue;
//       case 90:
//         return Colors.green;
//       case 180:
//         return Colors.purple;
//       case 270:
//         return Colors.orange;
//       default:
//         return Colors.grey;
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
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
//     final rotations = [
//       {'degree': 0, 'label': '0°', 'icon': Icons.stay_current_portrait},
//       {'degree': 90, 'label': '90°', 'icon': Icons.stay_current_landscape},
//       {'degree': 180, 'label': '180°', 'icon': Icons.screen_rotation_alt},
//       {'degree': 270, 'label': '270°', 'icon': Icons.stay_current_landscape},
//     ];

//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: rotations.map((r) {
//         final degree = r['degree'] as int;
//         final isSelected = _currentDegree == degree;
//         final color = isSelected ? _getDegreeColor(degree) : Colors.grey;

//         return _buildRotationOption(
//           icon: r['icon'] as IconData,
//           label: r['label'] as String,
//           degree: degree,
//           color: color,
//           backgroundColor: isSelected
//               ? _getDegreeColor(degree).withOpacity(0.2)
//               : Colors.grey.withOpacity(0.1),
//           flipHorizontal: degree == 270,
//         );
//       }).toList(),
//     );
//   }

//   Widget _buildStatusInfo() {
//     return Column(
//       children: [
//         Text(
//           'Current: $_currentDegree°',
//           style: TextStyle(
//               color: Colors.grey[600],
//               fontSize: 12,
//               fontStyle: FontStyle.italic),
//           textAlign: TextAlign.center,
//         ),
//         const SizedBox(height: 4),
//         const Text(
//           'Note: Rotation works within app only',
//           style: TextStyle(color: Colors.grey, fontSize: 10),
//           textAlign: TextAlign.center,
//         ),
//       ],
//     );
//   }

//   Widget _buildRotationOption({
//     required IconData icon,
//     required String label,
//     required int degree,
//     required Color color,
//     required Color backgroundColor,
//     bool flipHorizontal = false,
//   }) {
//     return GestureDetector(
//       onTap: () => _setOrientation(degree),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         decoration: BoxDecoration(
//           color: backgroundColor,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(color: color.withOpacity(0.3)),
//         ),
//         child: Column(
//           children: [
//             Transform(
//               alignment: Alignment.center,
//               transform: flipHorizontal
//                   ? (Matrix4.identity()..scale(-1.0, 1.0))
//                   : Matrix4.identity(),
//               child: Icon(icon, color: color, size: 28),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               label,
//               style: TextStyle(
//                   color: color, fontSize: 12, fontWeight: FontWeight.w500),
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
  int _currentDegree = 0;
  bool _isLoading = false;
  String _diagnosisResult = 'Tap 🔍 Diagnose to check device';

  static const Map<int, int> _androidOrientationMap = {
    0: 1, // PORTRAIT
    90: 0, // LANDSCAPE
    180: 9, // REVERSE_PORTRAIT
    270: 8, // REVERSE_LANDSCAPE
  };

  static const _channel = MethodChannel('com.example.app/orientation');

  // ✅ Diagnose why rotation isn't working
  Future<void> _diagnoseDevice() async {
    setState(() => _diagnosisResult = 'Checking...');
    try {
      final result = await _channel.invokeMethod('getDeviceInfo');
      final isTV = result['isTV'] as bool;
      final orientation = result['currentOrientation'] as int;
      final requestedOri = result['requestedOrientation'] as int;

      setState(() {
        _diagnosisResult = '📺 Is TV/Media Box: $isTV\n'
            '🔄 Current orientation: ${orientation == 1 ? "Portrait" : "Landscape"}\n'
            '📐 Requested orientation: $requestedOri\n'
            '${isTV ? "⚠️ TV devices cannot rotate!" : "✅ Device supports rotation"}';
      });
    } catch (e) {
      setState(() {
        _diagnosisResult =
            '❌ MethodChannel error:\n$e\n\nCheck MainActivity.kt setup';
      });
    }
  }

  Future<void> _setOrientation(int degree) async {
    setState(() => _isLoading = true);

    try {
      // Flutter layer
      DeviceOrientation orientation;
      switch (degree) {
        case 0:
          orientation = DeviceOrientation.portraitUp;
          break;
        case 90:
          orientation = DeviceOrientation.landscapeLeft;
          break;
        case 180:
          orientation = DeviceOrientation.portraitDown;
          break;
        case 270:
          orientation = DeviceOrientation.landscapeRight;
          break;
        default:
          orientation = DeviceOrientation.portraitUp;
      }
      await SystemChrome.setPreferredOrientations([orientation]);

      // Native Android layer
      String nativeResult = 'not called';
      try {
        final success = await _channel.invokeMethod('setOrientation', {
          'orientation': _androidOrientationMap[degree],
        });
        nativeResult = success == true ? '✅ success' : '❌ failed';
      } catch (e) {
        nativeResult = '❌ error: $e';
      }

      setState(() {
        _currentDegree = degree;
        _isLoading = false;
        _diagnosisResult = 'Native call: $nativeResult\n'
            'Tap 🔍 Diagnose to re-check device';
      });

      _showMessage('Rotated to $degree°', _getDegreeColor(degree));
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('Failed: $e', Colors.red);
    }
  }

  Color _getDegreeColor(int degree) {
    switch (degree) {
      case 0:
        return Colors.blue;
      case 90:
        return Colors.green;
      case 180:
        return Colors.purple;
      case 270:
        return Colors.orange;
      default:
        return Colors.grey;
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 12),

            // ✅ Diagnosis Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '🔍 Device Diagnosis',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _diagnoseDevice,
                        icon: const Icon(Icons.refresh, size: 14),
                        label: const Text('Diagnose',
                            style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _diagnosisResult,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildRotationOptions() {
    final rotations = [
      {'degree': 0, 'label': '0°', 'icon': Icons.stay_current_portrait},
      {'degree': 90, 'label': '90°', 'icon': Icons.stay_current_landscape},
      {'degree': 180, 'label': '180°', 'icon': Icons.screen_rotation_alt},
      {'degree': 270, 'label': '270°', 'icon': Icons.stay_current_landscape},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: rotations.map((r) {
        final degree = r['degree'] as int;
        final isSelected = _currentDegree == degree;
        final color = isSelected ? _getDegreeColor(degree) : Colors.grey;

        return _buildRotationOption(
          icon: r['icon'] as IconData,
          label: r['label'] as String,
          degree: degree,
          color: color,
          backgroundColor: isSelected
              ? _getDegreeColor(degree).withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
          flipHorizontal: degree == 270,
        );
      }).toList(),
    );
  }

  Widget _buildStatusInfo() {
    return Text(
      'Current: $_currentDegree°',
      style: TextStyle(
          color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildRotationOption({
    required IconData icon,
    required String label,
    required int degree,
    required Color color,
    required Color backgroundColor,
    bool flipHorizontal = false,
  }) {
    return GestureDetector(
      onTap: () => _setOrientation(degree),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Transform(
              alignment: Alignment.center,
              transform: flipHorizontal
                  ? (Matrix4.identity()..scale(-1.0, 1.0))
                  : Matrix4.identity(),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
