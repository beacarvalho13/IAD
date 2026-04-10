import 'package:flutter/material.dart';
import 'package:meu_projeto/services/message_bus.dart';
import 'package:meu_projeto/services/morse_decoder_service.dart';
import '../services/words_decoder_service.dart' hide DeviceMorseDecoder;

class WordsWriterScreen extends StatefulWidget {
  final String deviceId;

  const WordsWriterScreen({super.key, required this.deviceId});

  @override
  State<WordsWriterScreen> createState() => _WordsWriterScreenState();
}

class _WordsWriterScreenState extends State<WordsWriterScreen> {
  DeviceMorseDecoder? decoder;

  final Map<String, String> wordMap = const {
    ".": "YES",
    "..": "NO",
    "-": "HELLO",
    "--": "GOODBYE",
    "-.": "MORE",
    "-..": "LESS",
    "..-": "PLEASE",
    ".-": "THANK YOU",
    "...": "GOOD",
    "---": "BAD"
  };

  @override
  void initState() {
    super.initState();
    
    WordsDecoderService().clearMessage(); // Clear any previous message on start~
    GlobalMorseService().clearMessage(); // Clear Morse decoder as well since they share the same input
  }

  @override
  void dispose() {
    WordsDecoderService().getDecoder(widget.deviceId)?.dispose();
    super.dispose();
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

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: wordMap.entries.map((entry) {
                    final morse = entry.key;
                    final word = entry.value;

                    final isActive = currentPath == morse;
                    
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(16),
                      
                      decoration: BoxDecoration(
                        color: isActive
                            ? colors.primary.withOpacity(0.3)
                            : colors.surface,
                        borderRadius: BorderRadius.circular(12),
                      
                          // 👇 glow effect
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: colors.primary.withOpacity(0.4),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  )
                                ]
                              : [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            word,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isActive ? colors.onPrimary : null,
                            ),
                          ),
                          Text(
                            morse,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: isActive ? colors.onPrimary : null,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
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
              WordsDecoderService().clearMessage();
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
