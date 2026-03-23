import 'package:flutter/material.dart';
import 'package:media_player_port/screens/media_player_controls_screen.dart';
import 'package:media_player_port/services/screen_service.dart';
import 'screens/media_player_controls_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());

  // Test channel on startup
  ScreenService.testChannel().then((available) {
    debugPrint('📱 ScreenService channel available: $available');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Player Control',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const MediaPlayerControlsScreen(),
    );
  }
}
