import 'package:flutter/material.dart';
import 'package:meu_projeto/services/morse_decoder_service.dart';
import 'package:meu_projeto/services/words_decoder_service.dart';
import '../services/message_bus.dart';
import '../services/tts_service.dart';


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

    TtsService().init(); // 👈 initialize once

    WordsDecoderService().clearMessage();
    GlobalMorseService().clearMessage();

    MessageBus.messageStream.listen((newMessage) {
      if (newMessage != receivedMessage) {
        setState(() {
          receivedMessage = newMessage;
          _isNewChar = true;
        });

        // 🧠 Extract only the LAST word
        final words = newMessage.trim().split(" ");
        final lastWord = words.isNotEmpty ? words.last : "";

        if (lastWord.isNotEmpty) {
          TtsService().speak(lastWord); // 🔊 speak only new word
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
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
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
      onPressed: () {
        WordsDecoderService().clearMessage(); // Clear global finalMessage
        setState(() => receivedMessage = "");
      },
      child: const Icon(Icons.delete_outline),
    ),
    );
  }
}