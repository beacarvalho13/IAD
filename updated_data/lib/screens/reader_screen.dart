import 'package:flutter/material.dart';
import '../models/device.dart';
import '../data/device_data_source.dart';

class ReaderScreen extends StatefulWidget {
  final Device device;
  final DeviceDataSource dataSource;

  const ReaderScreen({super.key, required this.device, required this.dataSource});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  String receivedMessage = "";
  bool _isNewChar = false;

  void _onDataReceived(int value) {
    // Aqui assumimos que o Arduino já envia o ASCII da letra traduzida
    // Se enviar sinais, precisarias da lógica de tradução aqui também
    if (value >= 65 && value <= 90 || value == 32) { // A-Z ou Espaço
      setState(() {
        receivedMessage += String.fromCharCode(value);
        _isNewChar = true;
      });
      // Efeito visual de piscar
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) setState(() => _isNewChar = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isNewChar ? Colors.blueAccent.withOpacity(0.1) : Colors.white,
      appBar: AppBar(title: const Text("Morse Reader")),
      body: StreamBuilder<int>(
        stream: widget.dataSource.getSensorValue(widget.device, "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Future.microtask(() => _onDataReceived(snapshot.data!));
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("MESSAGE RECEIVED", style: TextStyle(letterSpacing: 2, color: Colors.grey)),
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => receivedMessage = ""),
        child: const Icon(Icons.delete_outline),
      ),
    );
  }
}