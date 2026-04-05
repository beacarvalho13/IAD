import 'dart:math';
import 'package:flutter/material.dart';
import 'package:meu_projeto/data/fake_device_data_source.dart';
import 'package:meu_projeto/models/device.dart';
import 'package:meu_projeto/services/message_bus.dart';
import '../services/morse_decoder_service.dart';

class WriterScreen extends StatefulWidget {
  final String deviceId;

  const WriterScreen({super.key, required this.deviceId});

  @override
  State<WriterScreen> createState() => _WriterScreenState();
}

class _WriterScreenState extends State<WriterScreen> {
  DeviceMorseDecoder? decoder;
  @override
  void initState() {
    super.initState();

    decoder = GlobalMorseService().getDecoder(widget.deviceId);
    GlobalMorseService().clearMessage(); // Clear any previous message on start
  
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
          stream: MessageBus.messageStream,
          builder: (context, snapshot) {
            final currentMessage = snapshot.data ?? "";

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
            child: StreamBuilder<String>(
              stream: MessageBus.currentPathStream,
              initialData: decoder?.currentPath ?? "",
              builder: (context, snapshot) {
                final currentPath = snapshot.data ?? "";

                return InteractiveViewer(
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
                            morseMap: decoder!.morseMap,
                          ),
                        ),
                      ),
                    );
                  },
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
                    StreamBuilder<String>(
                      stream: MessageBus.currentPathStream,
                      initialData: decoder?.currentPath ?? "",
                      builder: (context, pathSnapshot) {
                        final currentPath = pathSnapshot.data ?? "";
                        return Text(
                          "Current: $currentPath",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      currentMessage.isEmpty
                          ? "Decoded message will appear here"
                          : currentMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.pinkAccent,
            onPressed: () {
              GlobalMorseService().clearMessage();
              setState(() {}); // rebuild to reset currentPath display
            },
            child: const Icon(
              Icons.delete_outline,
              size: 20, // <-- smaller size
            ),
          ),
        );
      },
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

    const double verticalGap = 50; 

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
      double nextspacing = spacing * 0.4;
      double direction = (path.startsWith('.')) ? -1 : 1; // Up for dot, down for dash
      if (level == 0) {
        _drawBranch(canvas, x, y, x, y - verticalGap, paintLine(path + "."), path + ".");
        _drawNode(canvas, x, y - verticalGap, nextspacing, level + 1, path + ".", size);
        _drawBranch(canvas, x, y, x, y + verticalGap, paintLine(path + "-"), path + "-");
        _drawNode(canvas, x, y + verticalGap, nextspacing, level + 1, path + "-", size);
      }
      else {
        if (direction == 1) {
          _drawBranch(canvas, x, y, x + spacing, y + (direction*verticalGap), paintLine(path + "."), path + ".");
          _drawNode(canvas, x + spacing, y + (direction*verticalGap), nextspacing, level + 1, path + ".", size);
          _drawBranch(canvas, x, y, x - spacing, y + (direction*verticalGap), paintLine(path + "-"), path + "-");
          _drawNode(canvas, x - spacing, y + (direction*verticalGap), nextspacing, level + 1, path + "-", size);

        } else {
          _drawBranch(canvas, x, y, x + spacing, y + (direction*verticalGap), paintLine(path + "."), path + ".");
          _drawNode(canvas, x + spacing, y + (direction*verticalGap), nextspacing, level + 1, path + ".", size);
          _drawBranch(canvas, x, y, x - spacing, y + (direction*verticalGap), paintLine(path + "-"), path + "-");
          _drawNode(canvas, x - spacing, y + (direction*verticalGap), nextspacing, level + 1, path + "-", size);
          }
        }
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
          text: targetPath.endsWith('.') ? '.' : '—',
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
    ;

    }

  @override
  bool shouldRepaint(MorseTreePainter oldDelegate) =>
      oldDelegate.currentPath != currentPath;
}
