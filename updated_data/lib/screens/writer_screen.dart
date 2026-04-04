import 'dart:async';

import 'package:flutter/material.dart';
import '../data/device_data_source.dart';
import '../models/device.dart';

class WriterScreen extends StatefulWidget {
  final Device device;
  final DeviceDataSource dataSource;

  const WriterScreen({super.key, required this.device, required this.dataSource});

  @override
  State<WriterScreen> createState() => _WriterScreenState();
}

class _WriterScreenState extends State<WriterScreen> {
  String currentPath = "";      // Tracks current letter in Morse
  String currentMorseLine = ""; // Full line of Morse code
  String finalMessage = "";     // Translated letters

  int _pressStartTime = 0;
  int _lastReleaseTime = 0;
  bool _isPressing = false;

  static const int threshold = 50;        // force threshold (adjust!)
  static const int dotDuration = 500;     // < 300ms = dot
  static const int dashDuration = 1000;    // > 300ms = dash
  static const int letterPause = 3000; // > 2s = new letter
  static const int wordPause = 5000;   // > 4s = new word

  late Stream<int> _sensorStream;

  @override
  void initState() {
    super.initState();

    _sensorStream = widget.dataSource.getSensorValue(
      widget.device,
      "6E400003-B5A3-F393-E0A9-E50E24DCCA9E",
    );

    // Timer checks letter/word pauses independently
    Timer.periodic(const Duration(milliseconds: 50), (_) {
      final now = DateTime.now().millisecondsSinceEpoch;

      if (!_isPressing && currentPath.isNotEmpty) {
        final sinceRelease = now - _lastReleaseTime;

        // Letter completed
        if (sinceRelease > letterPause && sinceRelease <= wordPause) {
          setState(() {
            finalMessage += _translate(currentPath);
            currentMorseLine += " ";
            currentPath = "";
          });
        }
        // Word completed
        else if (sinceRelease > wordPause) {
          setState(() {
            finalMessage += _translate(currentPath);
            finalMessage += " ";       // Space between words
            currentMorseLine += "   "; // Extra space in Morse line
            currentPath = "";
          });
        }
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Fundo escuro para o neon brilhar
      appBar: AppBar(title: const Text("Writer Mode"), backgroundColor: Colors.transparent),
      body: StreamBuilder<int>(
        stream: _sensorStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _processInput(snapshot.data!);
            });
          }

          return Column(
            children: [
              // A Árvore Visual
              Expanded(
                flex: 3,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: MorseTreePainter(currentPath: currentPath),
                ),
              ),

              // Texto em tempo real
               Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                    "Last sensor value: ${snapshot.data}",
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                    Text(
                      "Morse code: $currentMorseLine",
                      style: const TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Message: $finalMessage",
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  void _processInput(int value) {
    final now = DateTime.now().millisecondsSinceEpoch;

    // ---------------- PRESS ----------------
    if (value > threshold && !_isPressing) {
      _isPressing = true;
      _pressStartTime = now;
    }

    // ---------------- RELEASE ----------------
    else if (value <= threshold && _isPressing) {
      _isPressing = false;

      final duration = now - _pressStartTime;
      _lastReleaseTime = now;

      setState(() {
        if (duration < dotDuration) {
          currentPath += ".";
          currentMorseLine += ".";
        } else {
          currentPath += "-";
          currentMorseLine += "-";
        }
      });
    }
  }


  String _translate(String path) {
    const morseAlphabet = {
      ".-": "A",
      "-...": "B",
      "-.-.": "C",
      "-..": "D",
      ".": "E",
      "..-.": "F",
      "--.": "G",
      "....": "H",
      "..": "I",
      ".---": "J",
      "-.-": "K",
      ".-..": "L",
      "--": "M",
      "-.": "N",
      "---": "O",
      ".--.": "P",
      "--.-": "Q",
      ".-.": "R",
      "...": "S",
      "-": "T",
      "..-": "U",
      "...-": "V",
      ".--": "W",
      "-..-": "X",
      "-.--": "Y",
      "--..": "Z",
      "-----": "0",
      ".----": "1",
      "..---": "2",
      "...--": "3",
      "....-": "4",
      ".....": "5",
      "-....": "6",
      "--...": "7",
      "---..": "8",
      "----.": "9",
    };

    return morseAlphabet[path] ?? "?";
  }
}

// O "Pintor" da Árvore
class MorseTreePainter extends CustomPainter {
  final String currentPath;
  MorseTreePainter({required this.currentPath});

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = Colors.white10
      ..strokeWidth = 2;

    final paintActive = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    _drawNode(canvas, size.width / 2, 50, size.width / 4, 0, "", size);
  }

  void _drawNode(Canvas canvas, double x, double y, double spacing, int level, String path, Size size) {
    if (level > 3) return;

    // Desenhar círculo do nó
    final bool isActive = currentPath == path;
    final bool isParentOfActive = currentPath.startsWith(path) && path.isNotEmpty;

    canvas.drawCircle(Offset(x, y), 15, Paint()..color = (isActive ? Colors.blueAccent : Colors.white24));

    // Desenhar caminhos para os filhos
    if (level < 3) {
      // Esquerda (Ponto)
      _drawBranch(canvas, x, y, x - spacing, y + 80, path + ".", paintLine(path + "."));
      _drawNode(canvas, x - spacing, y + 80, spacing / 2, level + 1, path + ".", size);

      // Direita (Traço)
      _drawBranch(canvas, x, y, x + spacing, y + 80, path + "-", paintLine(path + "-"));
      _drawNode(canvas, x + spacing, y + 80, spacing / 2, level + 1, path + "-", size);
    }
  }

  Paint paintLine(String targetPath) {
    bool active = currentPath.startsWith(targetPath);
    return Paint()
      ..color = active ? Colors.blueAccent : Colors.white12
      ..strokeWidth = active ? 4 : 2;
  }

  void _drawBranch(Canvas canvas, double x1, double y1, double x2, double y2, String target, Paint p) {
    canvas.drawLine(Offset(x1, y1 + 15), Offset(x2, y2 - 15), p);
  }

  @override
  bool shouldRepaint(MorseTreePainter oldDelegate) => oldDelegate.currentPath != currentPath;
}