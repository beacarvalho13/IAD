import 'dart:math';
import 'package:flutter/material.dart';
import 'package:meu_projeto/services/message_bus.dart';
import 'package:meu_projeto/services/words_decoder_service.dart' hide DeviceMorseDecoder;
import '../services/morse_decoder_service.dart';

// Main screen for Morse code writing, showing the Morse tree and current message, highlighting the current path

class WriterScreen extends StatefulWidget {
  final String deviceId;

  const WriterScreen({super.key, required this.deviceId});

  @override
  State<WriterScreen> createState() => _WriterScreenState();
}

// State for the writer screen, managing the Morse decoder and UI updates
class _WriterScreenState extends State<WriterScreen> {
  DeviceMorseDecoder? decoder;

  bool _isNewWord = false;
  String _lastMessage = ""; // State variables to manage new word highlighting and track the last message for comparison

  @override
  void initState() {
    super.initState();
    decoder = GlobalMorseService().getDecoder(widget.deviceId);

    GlobalMorseService().clearMessage();
    WordsDecoderService().clearMessage(); // Clear any previous message on start

    MessageBus.messageStream.listen((newMessage) {
      if (newMessage != _lastMessage && newMessage.endsWith(" ")) {
        setState(() {
          _isNewWord = true;
        });

        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _isNewWord = false);
        });
      }

      _lastMessage = newMessage;
    });

  }

  // Dispose the Morse decoder for this device when the screen is disposed to free resources
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Listen to the message stream to update the UI with the current message and path
    return StreamBuilder<String>(
      stream: MessageBus.messageStream,
      initialData: MessageBus.lastMessage,
      builder: (context, snapshot) {
        final currentMessage = snapshot.data ?? "";

        return Scaffold(
          backgroundColor: _isNewWord
            ? colors.primary.withOpacity(0.1)
            : theme.scaffoldBackgroundColor,

          appBar: AppBar(
            title: const Text("Writer Mode"), // App bar with title
          ),
          body: Column(
            children: [
              Expanded(
                flex: 3,
                child: StreamBuilder<String>(
                  stream: MessageBus.currentPathStream,
                  initialData: MessageBus.lastPath,
                  builder: (context, snapshot) {
                    final currentPath = snapshot.data ?? "";

                    // Dynamic Morse tree definition and visual settings
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
                            morseMap: decoder?.morseMap ?? {},
                            context: context,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
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
                      initialData: MessageBus.lastPath,
                      builder: (context, pathSnapshot) {
                        final currentPath = pathSnapshot.data ?? "";
                        return Text(
                          "Current: $currentPath",
                          style: theme.textTheme.bodyMedium,
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      currentMessage.isEmpty
                          ? "Decoded message will appear here"
                          : currentMessage,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _isNewWord
                            ? colors.primary
                            : colors.onSurface,
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
            },
            child: const Icon(
              Icons.delete_outline,
              size: 20,
            ),
          ),
        );
      },
    );
  }
}
// Morse Tree Painter
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
    
    // Draw letter if it exists
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
    
    // Draw branches and child nodes recursively
    if (level < 4) {
      double nextspacing = spacing * 0.4;
      double direction = (path.startsWith('.')) ? -1 : 1; // Up for dot, down for dash
      if (level == 0) {
        _drawBranch(canvas, x, y, x, y - verticalGap, paintLine("$path.", colors), "$path.");
        _drawNode(canvas, x, y - verticalGap, nextspacing, level + 1, "$path.", size, colors);
        _drawBranch(canvas, x, y, x, y + verticalGap, paintLine("$path-", colors), "$path-");
        _drawNode(canvas, x, y + verticalGap, nextspacing, level + 1, "$path-", size, colors);
      }
      else {
        if (direction == 1) {
          _drawBranch(canvas, x, y, x + spacing, y + (direction*verticalGap), paintLine("$path.", colors), "$path.");
          _drawNode(canvas, x + spacing, y + (direction*verticalGap), nextspacing, level + 1, "$path.", size, colors);
          _drawBranch(canvas, x, y, x - spacing, y + (direction*verticalGap), paintLine("$path-", colors), "$path-");
          _drawNode(canvas, x - spacing, y + (direction*verticalGap), nextspacing, level + 1, "$path-", size, colors);
        } else {
          _drawBranch(canvas, x, y, x + spacing, y + (direction*verticalGap), paintLine("$path.", colors), "$path.");
          _drawNode(canvas, x + spacing, y + (direction*verticalGap), nextspacing, level + 1, "$path.", size, colors);
          _drawBranch(canvas, x, y, x - spacing, y + (direction*verticalGap), paintLine("$path-", colors), "$path-");
          _drawNode(canvas, x - spacing, y + (direction*verticalGap), nextspacing, level + 1, "$path-", size, colors);
          }// Optimal spacing and direction for branches based on level and path, in order to avoid overlap
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
    bool nextStep = targetPath == "$currentPath." || targetPath == "$currentPath-";
    
    return Paint()
      ..color = nextStep 
        ? colors.primary
        : active 
          ? colors.primary : colors.outlineVariant
      ..strokeWidth = active ? 5 : (nextStep ? 4 : 2);
  }

  void _drawBranch(Canvas canvas, double x1, double y1, double x2, double y2, Paint p, String targetPath) {
    
    const double radius = 16;

    // Direction vector
    final dx = x2 - x1;
    final dy = y2 - y1;
    final dist = sqrt(dx * dx + dy * dy);

    // Normalization
    final ux = dx / dist;
    final uy = dy / dist;

    // Start/end points shifted to circle edge
    final start = Offset(
      x1 + ux * radius,
      y1 + uy * radius,
    );

    final end = Offset(
      x2 - ux * radius,
      y2 - uy * radius,
    );

    canvas.drawLine(start, end, p);

    
    final textPainter = TextPainter( // Label for the branch (dot or dash)
        text: TextSpan(
          text: targetPath.endsWith('.') ? '.' : '—',
          style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );

      final labelOffsetY = 5;

      textPainter.layout();
      textPainter.paint( // Position the label at the midpoint of the branch, with a slight vertical offset
        canvas,
        Offset((x1 + x2) / 2 - textPainter.width / 2, (y1 + y2) / 2 - textPainter.height / 2 + labelOffsetY),
      );

    }

  // Repaint only when the current path changes to optimize performance
  @override
  bool shouldRepaint(MorseTreePainter oldDelegate) =>
      oldDelegate.currentPath != currentPath;
}
