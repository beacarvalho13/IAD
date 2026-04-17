import 'package:flutter/material.dart';
import 'package:meu_projeto/services/message_bus.dart';
import 'package:meu_projeto/services/morse_decoder_service.dart';
import '../services/words_decoder_service.dart' hide DeviceMorseDecoder;

// Main screen for the Words writer mode, showing the word list and highlighting the current message

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
  };// Predefined word dictionary for the writer mode

  @override
  void initState() {
    super.initState();
    
    WordsDecoderService().clearMessage(); // Clear any previous message on start~
    GlobalMorseService().clearMessage(); // Clear Morse decoder as well since they share the same input
  }

  @override
  void dispose() {// Dispose the Words decoder for this device when the screen is disposed to free resources
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

    return Scaffold(// Visual layout for the words writer screen
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
                    
                    return AnimatedContainer(// Highlight the active word based on the recieved code from the Talky Buddy
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(16),
                      
                      decoration: BoxDecoration(
                        color: isActive
                            ? colors.primary.withOpacity(0.3)
                            : colors.surface,
                        borderRadius: BorderRadius.circular(12),
                      
                          // Glow effect
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
              setState(() {}); // Rebuild to reset currentPath display
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
