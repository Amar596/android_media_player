// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// class StorageCard extends StatefulWidget {
//   const StorageCard({super.key});

//   @override
//   State<StorageCard> createState() => _StorageCardState();
// }

// class _StorageCardState extends State<StorageCard> {
//   static const _channel = MethodChannel('com.example.app/system_info');
//   List<Map<String, dynamic>> _storageList = [];
//   bool _isLoading = true;
//   String _error = '';

//   @override
//   void initState() {
//     super.initState();
//     _loadStorage();
//   }

//   Future<void> _loadStorage() async {
//     setState(() {
//       _isLoading = true;
//       _error = '';
//     });

//     try {
//       final raw = await _channel.invokeMethod('getStorageInfo');

//       if (raw == null) {
//         setState(() {
//           _error = 'No storage data returned';
//           _isLoading = false;
//         });
//         return;
//       }

//       // ✅ Safe parsing — handles Long/int/double from Android
//       final list = (raw as List).map((item) {
//         final m = Map<String, dynamic>.from(item as Map);
//         return <String, dynamic>{
//           'label': m['label']?.toString() ?? 'Unknown',
//           'path': m['path']?.toString() ?? '',
//           // ✅ Use num.toInt() — fixes Long casting crash
//           'total': (m['total'] as num?)?.toInt() ?? 0,
//           'free': (m['free'] as num?)?.toInt() ?? 0,
//           'used': (m['used'] as num?)?.toInt() ?? 0,
//         };
//       }).toList();

//       setState(() {
//         _storageList = list;
//         _isLoading = false;
//       });
//     } on PlatformException catch (e) {
//       setState(() {
//         _error = 'Platform error: ${e.message}';
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _error = 'Error: $e';
//         _isLoading = false;
//       });
//     }
//   }

//   String _formatBytes(int bytes) {
//     if (bytes <= 0) return '0 B';
//     if (bytes >= 1073741824) {
//       return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
//     }
//     if (bytes >= 1048576) {
//       return '${(bytes / 1048576).toStringAsFixed(0)} MB';
//     }
//     return '$bytes B';
//   }

//   Color _getProgressColor(double pct) {
//     if (pct > 0.9) return Colors.red;
//     if (pct > 0.7) return Colors.orange;
//     return Colors.blue;
//   }

//   IconData _getStorageIcon(String label) {
//     if (label.contains('USB')) return Icons.usb;
//     if (label.contains('SD')) return Icons.sd_card;
//     if (label.contains('Internal')) return Icons.phone_android;
//     return Icons.storage;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildHeader(),
//             const Divider(height: 20),
//             _buildBody(),
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
//             color: Colors.blue.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: const Icon(Icons.storage, color: Colors.blue, size: 20),
//         ),
//         const SizedBox(width: 10),
//         const Text(
//           'Storage Info',
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//         const Spacer(),
//         IconButton(
//           icon: const Icon(Icons.refresh, size: 18),
//           tooltip: 'Refresh',
//           onPressed: _loadStorage,
//         ),
//       ],
//     );
//   }

//   Widget _buildBody() {
//     // Loading state
//     if (_isLoading) {
//       return const Center(
//         child: Padding(
//           padding: EdgeInsets.all(16),
//           child: CircularProgressIndicator(strokeWidth: 2),
//         ),
//       );
//     }

//     // Error state
//     if (_error.isNotEmpty) {
//       return Container(
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.red.shade50,
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Row(
//           children: [
//             const Icon(Icons.error_outline, color: Colors.red, size: 18),
//             const SizedBox(width: 8),
//             Expanded(
//               child: Text(
//                 _error,
//                 style: const TextStyle(color: Colors.red, fontSize: 12),
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     // Empty state
//     if (_storageList.isEmpty) {
//       return const Center(
//         child: Padding(
//           padding: EdgeInsets.all(12),
//           child: Text(
//             'No storage found',
//             style: TextStyle(color: Colors.grey),
//           ),
//         ),
//       );
//     }

//     // ✅ Storage list
//     return Column(
//       children: _storageList.map((s) => _buildStorageItem(s)).toList(),
//     );
//   }

//   Widget _buildStorageItem(Map<String, dynamic> s) {
//     final total = s['total'] as int;
//     final used = s['used'] as int;
//     final free = s['free'] as int;
//     final pct = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;
//     final label = s['label'] as String;

//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Label + size
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Row(
//                 children: [
//                   Icon(
//                     _getStorageIcon(label),
//                     size: 16,
//                     color: Colors.blue.shade400,
//                   ),
//                   const SizedBox(width: 6),
//                   Text(
//                     label,
//                     style: const TextStyle(
//                       fontWeight: FontWeight.w600,
//                       fontSize: 13,
//                     ),
//                   ),
//                 ],
//               ),
//               Text(
//                 '${_formatBytes(used)} / ${_formatBytes(total)}',
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: Colors.grey.shade600,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),

//           // Progress bar
//           ClipRRect(
//             borderRadius: BorderRadius.circular(6),
//             child: LinearProgressIndicator(
//               value: pct,
//               minHeight: 10,
//               backgroundColor: Colors.grey.shade200,
//               color: _getProgressColor(pct),
//             ),
//           ),
//           const SizedBox(height: 6),

//           // Free + percentage row
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Free: ${_formatBytes(free)}',
//                 style: const TextStyle(fontSize: 11, color: Colors.grey),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                 decoration: BoxDecoration(
//                   color: _getProgressColor(pct).withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Text(
//                   '${(pct * 100).round()}% used',
//                   style: TextStyle(
//                     fontSize: 11,
//                     color: _getProgressColor(pct),
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StorageCard extends StatefulWidget {
  const StorageCard({super.key});

  @override
  State<StorageCard> createState() => _StorageCardState();
}

class _StorageCardState extends State<StorageCard> {
  // static const _channel = MethodChannel('com.example.app/system_info');
  static const platform = MethodChannel('port_control');
  List<Map<String, dynamic>> _storageList = [];
  bool _isLoading = true;
  String _error = '';
  String _debugLog = 'Not started yet';

  @override
  void initState() {
    super.initState();
    debugPrint('🟡 StorageCard initState called');
    _loadStorage();
  }

  Future<void> getStorageInfo() async {
    try {
      final result = await platform.invokeMethod('getStorageInfo');
      print('Storage info: $result');
    } on MissingPluginException catch (e) {
      print('🔴 MissingPluginException: $e');
    }
  }

  Future<void> _loadStorage() async {
    debugPrint('🟡 _loadStorage() started');
    setState(() {
      _isLoading = true;
      _error = '';
      _debugLog = 'Calling channel...';
    });

    try {
      debugPrint('🟡 Invoking getStorageInfo on channel...');

      final raw = await platform.invokeMethod('getStorageInfo');

      debugPrint('🟢 Raw response type: ${raw.runtimeType}');
      debugPrint('🟢 Raw response: $raw');

      if (raw == null) {
        debugPrint('🔴 Raw is NULL');
        setState(() {
          _error = 'Returned null from native';
          _debugLog = '❌ null returned';
          _isLoading = false;
        });
        return;
      }

      final rawList = raw as List;
      debugPrint('🟢 List length: ${rawList.length}');

      if (rawList.isEmpty) {
        debugPrint('🔴 List is EMPTY');
        setState(() {
          _debugLog = '⚠️ Empty list returned';
          _isLoading = false;
        });
        return;
      }

      final list = rawList.map((item) {
        debugPrint('🟡 Parsing item: $item');
        final m = Map<String, dynamic>.from(item as Map);
        debugPrint('🟢 Parsed map: $m');

        return <String, dynamic>{
          'label': m['label']?.toString() ?? 'Unknown',
          'path': m['path']?.toString() ?? '',
          'total': (m['total'] as num?)?.toInt() ?? 0,
          'free': (m['free'] as num?)?.toInt() ?? 0,
          'used': (m['used'] as num?)?.toInt() ?? 0,
        };
      }).toList();

      debugPrint('🟢 Final parsed list: $list');

      setState(() {
        _storageList = list;
        _isLoading = false;
        _debugLog = '✅ ${list.length} storage(s) found';
      });
    } on PlatformException catch (e) {
      debugPrint('🔴 PlatformException: ${e.code} — ${e.message}');
      setState(() {
        _error = '${e.code}: ${e.message}';
        _debugLog = '❌ PlatformException: ${e.message}';
        _isLoading = false;
      });
    } on MissingPluginException catch (e) {
      debugPrint('🔴 MissingPluginException: $e');
      setState(() {
        _error = 'Channel not found. Run flutter clean + flutter run';
        _debugLog = '❌ MissingPlugin: $e';
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('🔴 Unknown error: $e');
      debugPrint('🔴 StackTrace: $stackTrace');
      setState(() {
        _error = e.toString();
        _debugLog = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes >= 1073741824) {
      return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1048576) {
      return '${(bytes / 1048576).toStringAsFixed(0)} MB';
    }
    return '$bytes B';
  }

  Color _getProgressColor(double pct) {
    if (pct > 0.9) return Colors.red;
    if (pct > 0.7) return Colors.orange;
    return Colors.blue;
  }

  IconData _getStorageIcon(String label) {
    if (label.contains('USB')) return Icons.usb;
    if (label.contains('SD')) return Icons.sd_card;
    if (label.contains('Internal')) return Icons.phone_android;
    return Icons.storage;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(height: 20),

            // ✅ Debug info box — always visible
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '🐛 Debug: $_debugLog',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),

            _buildBody(),
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
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.storage, color: Colors.blue, size: 20),
        ),
        const SizedBox(width: 10),
        const Text(
          'Storage Info',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.refresh, size: 18),
          tooltip: 'Refresh',
          onPressed: _loadStorage,
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _error,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (_storageList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'No storage found',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: _storageList.map((s) => _buildStorageItem(s)).toList(),
    );
  }

  Widget _buildStorageItem(Map<String, dynamic> s) {
    final total = s['total'] as int;
    final used = s['used'] as int;
    final free = s['free'] as int;
    final pct = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;
    final label = s['label'] as String;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(_getStorageIcon(label),
                    size: 16, color: Colors.blue.shade400),
                const SizedBox(width: 6),
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
              Text(
                '${_formatBytes(used)} / ${_formatBytes(total)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              color: _getProgressColor(pct),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Free: ${_formatBytes(free)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getProgressColor(pct).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(pct * 100).round()}% used',
                  style: TextStyle(
                    fontSize: 11,
                    color: _getProgressColor(pct),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
