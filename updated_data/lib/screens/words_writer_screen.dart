import 'dart:math';
import 'package:flutter/material.dart';
import 'package:meu_projeto/data/fake_device_data_source.dart';
import 'package:meu_projeto/models/device.dart';
import 'package:meu_projeto/services/message_bus.dart';
import '../services/morse_decoder_service.dart';

class WordsWriterScreen extends StatefulWidget {
  final String deviceId;

  const WordsWriterScreen({super.key, required this.deviceId});

  @override
  State<WordsWriterScreen> createState() => _WordsWriterScreenState();
}

class _WordsWriterScreenState extends State<WordsWriterScreen> {
  DeviceMorseDecoder? decoder;
  @override
  void initState() {
    super.initState();

    decoder = GlobalMorseService().getDecoder(widget.deviceId);
    GlobalMorseService().clearMessage(); // Clear any previous message on start
  
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return StreamBuilder<String>(
          stream: MessageBus.messageStream,
          builder: (context, snapshot) {
            final currentMessage = snapshot.data ?? "";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Writer Mode"),
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
                      panEnabled: false,
                      scaleEnabled: false,
                      child: SizedBox(
                        width: 1500,
                        height: 1200,
                        child: CustomPaint(
                          painter: MorseTreePainter(
                            currentPath: currentPath,
                            morseMap: decoder!.morseMap,
                            context: context,
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
              color: theme.cardColor,
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
                          style: theme.textTheme.bodyMedium
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      currentMessage.isEmpty
                          ? "Decoded message will appear here"
                          : currentMessage,
                      style:  theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
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
  final BuildContext context;

  MorseTreePainter({required this.currentPath, required this.morseMap, required this.context});

  @override
  void paint(Canvas canvas, Size size) {
    final colors = Theme.of(context).colorScheme;

    _drawNode(canvas, size.width/2, size.height/2 , size.height/3 , 0, "",size, colors);
  }

  void _drawNode(Canvas canvas, double x, double y, double spacing, int level, String path, Size size, ColorScheme colors) {
    if (level > 4) return;

    final bool isActive = currentPath == path;
    final String letter = morseMap[path] ?? "";

    const double verticalGap = 50; 

    canvas.drawCircle(Offset(x, y), 14,
        Paint()..color = isActive ? colors.primary : colors.outlineVariant);
    
    // Draw letter if exist
    if (level > 0 && letter.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: letter,
          style: TextStyle(color: colors.onSurface, fontSize: 12, fontWeight: FontWeight.bold),
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
        _drawBranch(canvas, x, y, x, y - verticalGap, paintLine(path + ".", colors), path + ".");
        _drawNode(canvas, x, y - verticalGap, nextspacing, level + 1, path + ".", size, colors);
        _drawBranch(canvas, x, y, x, y + verticalGap, paintLine(path + "-", colors), path + "-");
        _drawNode(canvas, x, y + verticalGap, nextspacing, level + 1, path + "-", size, colors);
      }
      else {
        if (direction == 1) {
          _drawBranch(canvas, x, y, x + spacing, y + (direction*verticalGap), paintLine(path + ".", colors), path + ".");
          _drawNode(canvas, x + spacing, y + (direction*verticalGap), nextspacing, level + 1, path + ".", size, colors);
          _drawBranch(canvas, x, y, x - spacing, y + (direction*verticalGap), paintLine(path + "-", colors), path + "-");
          _drawNode(canvas, x - spacing, y + (direction*verticalGap), nextspacing, level + 1, path + "-", size, colors);
        } else {
          _drawBranch(canvas, x, y, x + spacing, y + (direction*verticalGap), paintLine(path + ".", colors), path + ".");
          _drawNode(canvas, x + spacing, y + (direction*verticalGap), nextspacing, level + 1, path + ".", size, colors);
          _drawBranch(canvas, x, y, x - spacing, y + (direction*verticalGap), paintLine(path + "-", colors), path + "-");
          _drawNode(canvas, x - spacing, y + (direction*verticalGap), nextspacing, level + 1, path + "-", size, colors);
          }
        }
      } 

    if (isActive) {
      canvas.drawCircle(
        Offset(x, y),
        28,
        Paint()
          ..color = colors.primary.withOpacity(0.2)
          ..style = PaintingStyle.fill,
      );
    }
  }

  Paint paintLine(String targetPath, ColorScheme colors) {
    bool active = currentPath.startsWith(targetPath);
    bool nextStep = targetPath == currentPath + "." || targetPath == currentPath + "-";
    
    return Paint()
      ..color = nextStep 
        ? colors.primary
        : active 
          ? colors.primary : colors.outlineVariant
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
          style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
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
