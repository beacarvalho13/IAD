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
  String currentPath = "";
  String finalMessage = "";
  Timer? _letterTimer;
  DateTime? _lastInputTime;

  // Morse code map
  final Map<String, String> morseMap = {
    '.-': 'A', '-...': 'B', '-.-.': 'C', '-..': 'D', '.': 'E',
    '..-.': 'F', '--.': 'G', '....': 'H', '..': 'I', '.---': 'J',
    '-.-': 'K', '.-..': 'L', '--': 'M', '-.': 'N', '---': 'O',
    '.--.': 'P', '--.-': 'Q', '.-.': 'R', '...': 'S', '-': 'T',
    '..-': 'U', '...-': 'V', '.--': 'W', '-..-': 'X', '-.--': 'Y',
    '--..': 'Z',
  };

  // Timing thresholds
  static const int letterGapThreshold = 800; // ms for letter gap
  static const int wordGapThreshold = 1500;  // ms for word gap

  @override
  void initState() {
    super.initState();

    widget.dataSource
        .getSensorValue(widget.device, "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
        .listen(_processInput);
  }

  void _processInput(int value) {
    final now = DateTime.now();

    if (value == 1 || value == 2) {
      currentPath += (value == 1 ? '.' : '-');
      _lastInputTime = now;

      // Reset letter timer
      _letterTimer?.cancel();
      _letterTimer = Timer(Duration(milliseconds: letterGapThreshold), () {
        if (currentPath.isNotEmpty) {
          // Translate current letter
          finalMessage += _translate(currentPath);
          currentPath = "";
          setState(() {});

          // Clear the word after word gap
          Future.delayed(Duration(milliseconds: wordGapThreshold), () {
            if (_lastInputTime != null &&
                DateTime.now().difference(_lastInputTime!).inMilliseconds >= wordGapThreshold) {
              setState(() {
                finalMessage = ""; // clear instantly
              });
            }
          });
        }
      });
    }

    setState(() {}); // update currentPath
  }

  String _translate(String path) => morseMap[path] ?? "?";

  @override
  void dispose() {
    _letterTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text("Writer Mode"),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Morse tree visual
          Expanded(
            flex: 3,
            child: CustomPaint(
              size: Size.infinite,
              painter: MorseTreePainter(currentPath: currentPath),
            ),
          ),

          // Text box for current and final message
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text("Current: $currentPath",
                    style: const TextStyle(color: Colors.white70, fontSize: 18)),
                const SizedBox(height: 10),
                Text(
                  finalMessage,
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// Morse Tree Painter (unchanged)
class MorseTreePainter extends CustomPainter {
  final String currentPath;
  MorseTreePainter({required this.currentPath});

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = Colors.white10
      ..strokeWidth = 2;

    _drawNode(canvas, size.width / 2, 50, size.width / 4, 0, "", size);
  }

  void _drawNode(Canvas canvas, double x, double y, double spacing, int level, String path, Size size) {
    if (level > 3) return;
    final bool isActive = currentPath == path;
    canvas.drawCircle(Offset(x, y), 15,
        Paint()..color = isActive ? Colors.blueAccent : Colors.white24);
    if (level < 3) {
      _drawBranch(canvas, x, y, x - spacing, y + 80, paintLine(path + "."));
      _drawNode(canvas, x - spacing, y + 80, spacing / 2, level + 1, path + ".", size);
      _drawBranch(canvas, x, y, x + spacing, y + 80, paintLine(path + "-"));
      _drawNode(canvas, x + spacing, y + 80, spacing / 2, level + 1, path + "-", size);
    }
  }

  Paint paintLine(String targetPath) {
    bool active = currentPath.startsWith(targetPath);
    return Paint()
      ..color = active ? Colors.blueAccent : Colors.white12
      ..strokeWidth = active ? 4 : 2;
  }

  void _drawBranch(Canvas canvas, double x1, double y1, double x2, double y2, Paint p) {
    canvas.drawLine(Offset(x1, y1 + 15), Offset(x2, y2 - 15), p);
  }

  @override
  bool shouldRepaint(MorseTreePainter oldDelegate) =>
      oldDelegate.currentPath != currentPath;
}