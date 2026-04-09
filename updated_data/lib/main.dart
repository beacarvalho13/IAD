import 'package:flutter/material.dart';
import 'package:meu_projeto/models/app_mode.dart';
import 'package:meu_projeto/screens/home_screen.dart' hide CommunicationMode;
//import 'screens/home_screen.dart';

void main() {
  // Garante que os bindings do Flutter estão inicializados antes de começar
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CommunicationMode>(
      valueListenable: appMode,
      builder: (context, mode, _) {
        final isMorse = mode == CommunicationMode.morse;

        return MaterialApp(
          title: 'BLE Sensor App',
          debugShowCheckedModeBanner: false,

          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: isMorse ? Colors.indigoAccent : Colors.pinkAccent,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),

          home: const HomeScreen(),
        );
      },
    );
  }
}