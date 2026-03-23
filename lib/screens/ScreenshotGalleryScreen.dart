import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class ScreenshotGalleryScreen extends StatefulWidget {
  const ScreenshotGalleryScreen({super.key});

  @override
  State<ScreenshotGalleryScreen> createState() =>
      _ScreenshotGalleryScreenState();
}

class _ScreenshotGalleryScreenState extends State<ScreenshotGalleryScreen> {
  List<FileSystemEntity> _screenshots = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScreenshots();
  }

  Future<void> _loadScreenshots() async {
    final directory = await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> files = directory.listSync();

    // Filter for PNG files (screenshots)
    setState(() {
      _screenshots = files
          .where((file) =>
              file.path.endsWith('.png') &&
              file.path.contains('media_player_controls'))
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _deleteScreenshot(String path) async {
    try {
      final file = File(path);
      await file.delete();
      _loadScreenshots(); // Refresh the list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Screenshot deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screenshot Gallery'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _screenshots.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No screenshots yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Take a screenshot using the camera icon',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _screenshots.length,
                  itemBuilder: (context, index) {
                    final file = _screenshots[index];
                    return GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.file(File(file.path)),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(file.path),
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteScreenshot(file.path),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}