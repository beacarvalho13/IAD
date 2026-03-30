import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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

  @override
  void initState() {
    super.initState();
    // Escuta os resultados do scan continuamente
    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        scanResults = results;
      });
    });

    // Escuta se o scan está a decorrer ou não
    FlutterBluePlus.isScanning.listen((scanning) {
      setState(() {
        isScanning = scanning;
      });
    });
  }

  void startScan() async {
    // Inicia o scan por 5 segundos
    // Nota: Em Android, precisa de Localização ligada!
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
          const SizedBox(height: 10),
          if (isScanning)
            const LinearProgressIndicator()
          else
            const Text("Clica na lupa para procurar"),
          
          Expanded(
            child: ListView.builder(
              itemCount: scanResults.length,
              itemBuilder: (context, index) {
                final data = scanResults[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: const Icon(Icons.bluetooth),
                    title: Text(data.device.platformName.isEmpty 
                        ? 'Dispositivo Desconhecido' 
                        : data.device.platformName),
                    subtitle: Text(data.device.remoteId.toString()),
                    trailing: Text('${data.rssi} dBm'), // Força do sinal
                    onTap: () async {
  try {
    // Agora é obrigatório passar este parâmetro autoConnect
    await data.device.connect(
  autoConnect: false,
);
    print('Conectado a ${data.device.remoteId}');
  } catch (e) {
    print('Erro ao conectar: $e');
  }
},
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