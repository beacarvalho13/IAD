import 'dart:async';
import 'dart:math';
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
  static const int letterGapThreshold = 1000; // ms for letter gap
  static const int wordGapThreshold = 2000;  // ms for word gap

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

          // Push the updated message to Reader
          MessageBus.updateMessage(finalMessage);

          // Clear the word after word gap
          Future.delayed(Duration(milliseconds: wordGapThreshold), () {
            if (_lastInputTime != null &&
                DateTime.now().difference(_lastInputTime!).inMilliseconds >= wordGapThreshold) {
              setState(() {
                finalMessage = ""; // clear instantly
              });

              // Clear Reader as well
              MessageBus.updateMessage(finalMessage);
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
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(500),
              minScale: 1.0,
              maxScale: 1.0,
              panEnabled: true,
              scaleEnabled: false,
              child: SizedBox(
                width: 1500,
                height: 1200,
                child: CustomPaint(
                  painter: MorseTreePainter(
                    currentPath: currentPath,
                    morseMap: morseMap,
                  ),
                ),
              ),
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
  final Map<String, String> morseMap;

  MorseTreePainter({required this.currentPath, required this.morseMap});

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = Colors.white10
      ..strokeWidth = 2;

    _drawNode(canvas, 40, size.height/2 , size.height/3 , 0, "",size);
  }

  void _drawNode(Canvas canvas, double x, double y, double spacing, int level, String path, Size size) {
    if (level > 4) return;

    final bool isActive = currentPath == path;
    final String letter = morseMap[path] ?? "";

    const double horizontalGap = 100; 

    canvas.drawCircle(Offset(x, y), 14,
        Paint()..color = isActive ? Colors.blueAccent : Colors.white24);
    
    // Draw letter if exist
    if (level > 0 && letter.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: letter,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
    }
    
    if (level < 4) {
      double nextspacing = spacing * 0.5;

      _drawBranch(canvas, x, y, x + horizontalGap, y - spacing, paintLine(path + "."), path + ".");
      _drawNode(canvas, x + horizontalGap, y - spacing, nextspacing , level + 1, path + ".", size);
      _drawBranch(canvas, x, y, x + horizontalGap, y + spacing, paintLine(path + "-"), path + "-");
      _drawNode(canvas, x + horizontalGap, y + spacing, nextspacing , level + 1, path + "-", size);
    }

    if (isActive) {
      canvas.drawCircle(
        Offset(x, y),
        28,
        Paint()
          ..color = Colors.greenAccent.withOpacity(0.25)
          ..style = PaintingStyle.fill,
      );
    }
  }

  Paint paintLine(String targetPath) {
    bool active = currentPath.startsWith(targetPath);
    bool nextStep = targetPath == currentPath + "." || targetPath == currentPath + "-";
    
    return Paint()
      ..color = nextStep 
        ? Colors.greenAccent 
        : active 
          ? Colors.blueAccent : Colors.white12
      ..strokeWidth = active ? 5 : (nextStep ? 4 : 2);
  }

  void _drawBranch(Canvas canvas, double x1, double y1, double x2, double y2, Paint p, String targetPath) {
    
    const double radius = 16;

    // direction vector
    final dx = x2 - x1;
    final dy = y2 - y1;
    final dist = sqrt(dx * dx + dy * dy);

    // normalize
    final ux = dx / dist;
    final uy = dy / dist;

    // start/end points shifted to circle edge
    final start = Offset(
      x1 + ux * radius,
      y1 + uy * radius,
    );

    final end = Offset(
      x2 - ux * radius,
      y2 - uy * radius,
    );

    canvas.drawLine(start, end, p);

    final textPainter = TextPainter(
        text: TextSpan(
          text: targetPath.endsWith('.') ? '.' : '-',
          style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255), fontSize: 15, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );

      const double offset = 8; // distance from branch
      final labelOffsetY = targetPath.endsWith('.') ? -offset : offset;

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset((x1 + x2) / 2 - textPainter.width / 2, (y1 + y2) / 2 - textPainter.height / 2 + labelOffsetY),
      );

  }

  @override
  bool shouldRepaint(MorseTreePainter oldDelegate) =>
      oldDelegate.currentPath != currentPath;
}
