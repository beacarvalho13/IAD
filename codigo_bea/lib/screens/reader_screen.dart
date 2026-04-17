import 'package:flutter/material.dart';
import 'package:meu_projeto/services/morse_decoder_service.dart';
import 'package:meu_projeto/services/words_decoder_service.dart';
import '../services/message_bus.dart';

// Main screen for the reader mode of the Morse code communication, shows the received message and highlights new characters

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  String receivedMessage = "";
  bool _isNewChar = false;

  @override
    void initState() {
      super.initState();

      WordsDecoderService().clearMessage(); 
      GlobalMorseService().clearMessage();// Clear any previous message on start   

      // Listen to the final decoded message from the data source
      MessageBus.messageStream.listen((newMessage) {
      if (newMessage != receivedMessage) {
        setState(() {
          receivedMessage = newMessage;
          _isNewChar = true;
        });

          // Flash highlight for new character
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) setState(() => _isNewChar = false);
          });
        }
      });
    }

  @override
  void dispose() {
    super.dispose(); // Dispose resources if needed
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Visual layout for the reader screen, showing the received message and a button to clear it
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
      onPressed: () { // Clear button to reset the received message
        GlobalMorseService().clearMessage(); // Clear global finalMessage
        setState(() => receivedMessage = "");
      },
      child: const Icon(Icons.delete_outline),
    ),
    );
  }
}