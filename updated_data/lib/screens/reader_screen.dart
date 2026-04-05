import 'package:flutter/material.dart';
import 'package:meu_projeto/data/fake_device_data_source.dart';
import 'package:meu_projeto/services/morse_decoder_service.dart';
import '../services/message_bus.dart';



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

      GlobalMorseService().clearMessage();    

      // Listen to the final decoded message from the data source / Writer
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isNewChar ? Colors.blueAccent.withOpacity(0.1) : Colors.white,
      appBar: AppBar(title: const Text("Morse Reader")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "MESSAGE RECEIVED",
                style: TextStyle(letterSpacing: 2, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Text(
                receivedMessage.isEmpty ? "Waiting..." : receivedMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: _isNewChar ? Colors.blueAccent : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
      onPressed: () {
        GlobalMorseService().clearMessage(); // Clear global finalMessage
        setState(() => receivedMessage = "");
      },
      child: const Icon(Icons.delete_outline),
    ),
    );
  }
}