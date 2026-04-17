import 'package:flutter/material.dart';
import 'package:meu_projeto/models/app_mode.dart';
import 'package:meu_projeto/screens/home_screen.dart' hide CommunicationMode;

// Main entry point of the app, which initializes the Flutter bindings and runs the main widget

void main() {
  // Ensures that Flutter bindings are initialized before running the app, then runs the main widget
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Main widget of the app, which listens to the communication mode and updates the theme accordingly

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CommunicationMode>(
      valueListenable: appMode,
      builder: (context, mode, _) {
        final isMorse = mode == CommunicationMode.morse; // Determines if the current mode is Morse or Words to set the theme color

        return MaterialApp(
          title: 'BLE Sensor App',// Title of the app
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