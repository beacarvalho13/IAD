import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert'; // Necessário para converter bytes em texto

void main() {
  runApp(const MaterialApp(
    home: BluetoothScanner(),
    debugShowCheckedModeBanner: false,
  ));
}

class BluetoothScanner extends StatefulWidget {
  const BluetoothScanner({super.key});

  @override
  State<BluetoothScanner> createState() => _BluetoothScannerState();
}

class _BluetoothScannerState extends State<BluetoothScanner> {
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  
  // Variável para guardar os dados do sensor
  String dadosSensor = "Aguardando conexão...";

  @override
  void initState() {
    super.initState();
    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        scanResults = results;
      });
    });

    FlutterBluePlus.isScanning.listen((scanning) {
      setState(() {
        isScanning = scanning;
      });
    });
  }

  // FUNÇÃO DE CONEXÃO E LEITURA (Dentro da classe para usar setState)
  void conectarEDescobrir(BluetoothDevice device) async {
    try {
      setState(() => dadosSensor = "A conectar...");
      await device.connect(autoConnect: false);
      
      List<BluetoothService> services = await device.discoverServices();

      for (BluetoothService service in services) {
        if (service.uuid.toString() == "4fafc201-1fb5-459e-8fcc-c5c9c331914b") {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString() == "beb5483e-36e1-4688-b7f5-ea07361b26a8") {
              
              await characteristic.setNotifyValue(true);
              
              characteristic.lastValueStream.listen((value) {
                if (value.isNotEmpty) {
                  String data = utf8.decode(value); 
                  setState(() {
                    dadosSensor = data; // Atualiza o texto no ecrã
                  });
                }
              });
            }
          }
        }
      }
    } catch (e) {
      setState(() => dadosSensor = "Erro: $e");
    }
  }

  void startScan() async {
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leitor Bluetooth IAD'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          // PAINEL DE DADOS DO SENSOR
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(10),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.blueAccent),
            ),
            child: Column(
              children: [
                const Text("Dados do BMP280:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(dadosSensor, style: const TextStyle(fontSize: 22, color: Colors.blue)),
              ],
            ),
          ),
          
          if (isScanning) const LinearProgressIndicator(),
          
          Expanded(
            child: ListView.builder(
              itemCount: scanResults.length,
              itemBuilder: (context, index) {
                final result = scanResults[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: const Icon(Icons.bluetooth),
                    title: Text(result.device.platformName.isEmpty 
                        ? 'Dispositivo Desconhecido' 
                        : result.device.platformName),
                    subtitle: Text(result.device.remoteId.toString()),
                    trailing: const Icon(Icons.link),
                    onTap: () => conectarEDescobrir(result.device), // CHAMA A CONEXÃO
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isScanning ? null : startScan,
        child: Icon(isScanning ? Icons.sync : Icons.search),
      ),
    );
  }
}