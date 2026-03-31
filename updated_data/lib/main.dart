import 'package:flutter/material.dart';
import 'package:meu_projeto/screens/home_screen.dart';
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
    return MaterialApp(
      title: 'BLE Sensor App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 255, 68, 233)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}