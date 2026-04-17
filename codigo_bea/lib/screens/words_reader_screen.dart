import 'package:flutter/material.dart';
import 'package:meu_projeto/services/morse_decoder_service.dart';
import 'package:meu_projeto/services/words_decoder_service.dart';
import '../services/message_bus.dart';
import '../services/tts_service.dart';

// Main screen for the reader mode of the words communication, shows the selected word and reads it aloud using TTS

class WordsReaderScreen extends StatefulWidget {
  const WordsReaderScreen({super.key});

  @override
  State<WordsReaderScreen> createState() => _WordsReaderScreenState();
}

class _WordsReaderScreenState extends State<WordsReaderScreen> {
  String receivedMessage = "";
  bool _isNewChar = false;

  @override
  void initState() {
    super.initState();

    TtsService().init(); // Initialize TTS service

    WordsDecoderService().clearMessage();
    GlobalMorseService().clearMessage();// Clear any previous message on start

    MessageBus.messageStream.listen((newMessage) {
      if (newMessage != receivedMessage) {
        setState(() {
          receivedMessage = newMessage;
          _isNewChar = true;
        });

        // Extract the last word from the received message to speak it
        final words = newMessage.trim().split(" ");
        final lastWord = words.isNotEmpty ? words.last : "";

        if (lastWord.isNotEmpty) {
          TtsService().speak(lastWord); // Speak the last received word using TTS
        }

        // Flash highlight
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _isNewChar = false);
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();// Dispose resources if needed
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(// Visual layout for the reader screen, showing the received word and a button to clear it
      backgroundColor: _isNewChar ? colors.primary.withOpacity(0.1) : theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("Morse Reader")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "MESSAGE RECEIVED",
                style: TextStyle(letterSpacing: 2, color: colors.outline),
              ),
              const SizedBox(height: 20),
              Text(
                receivedMessage.isEmpty ? "Waiting..." : receivedMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: _isNewChar ? colors.primary : colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
      onPressed: () {// Clear button to reset the received message
        WordsDecoderService().clearMessage(); // Clear global finalMessage
        setState(() => receivedMessage = "");
      },
      child: const Icon(Icons.delete_outline),
    ),
    );
  }
}