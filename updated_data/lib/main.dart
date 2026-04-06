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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigoAccent, brightness: Brightness.light),
        useMaterial3: true,

        scaffoldBackgroundColor: const Color(0xFFF5F6FA),

        appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        ),

         floatingActionButtonTheme: const FloatingActionButtonThemeData(
            // let Flutter use colorScheme.primary automatically
        ),

        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15),),
        ),

        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.black87),),
        
        ),
      home: const HomeScreen(),
    );
  }
}