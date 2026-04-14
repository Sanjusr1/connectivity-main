import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/monitoring_provider.dart';
import 'screens/home_screen.dart';
import 'services/live_sensor_stream_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  await storageService.init();

  runApp(MainApp(storageService: storageService));
}

class MainApp extends StatelessWidget {
  const MainApp({required this.storageService, super.key});

  final StorageService storageService;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MonitoringProvider(
        streamService: LiveSensorStreamService(),
        storageService: storageService,
      ),
      child: MaterialApp(
        title: 'Multimodal Sensor Monitor',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
