import 'dart:async';
import 'package:flutter/material.dart';
import 'package:meu_projeto/models/app_mode.dart';
import 'package:meu_projeto/services/morse_decoder_service.dart';
import 'package:meu_projeto/services/words_decoder_service.dart';
import '../models/device.dart';
import '../widgets/device_card.dart';
import 'writer_screen.dart'; // Importa o novo ecrã
import 'reader_screen.dart'; // Importa o novo ecrã
import '../data/fake_device_data_source.dart';
import '../data/ble_device_data_source.dart';
import '../data/device_data_source.dart';
import 'words_writer_screen.dart';
import 'words_reader_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CommunicationMode currentMode = CommunicationMode.morse;
  List<Device> devices = [];
  bool isScanning = false;
  Device? connectedDevice; // Guarda o dispositivo selecionado

  final DeviceDataSource fakedataSource = FakeDeviceDataSource();
  final DeviceDataSource bleDataSource = BleDeviceDataSource();

  StreamSubscription<List<Device>>? _bleSub;
  StreamSubscription<List<Device>>? _fakeSub;

  List<Device> _bleDevices = [];
  List<Device> _fakeDevices = [];

  // -------------------- LÓGICA DE SCAN --------------------
  void startScan() {
    setState(() {
      isScanning = true;
      _bleDevices = [];
      _fakeDevices = [];
      devices = [];
    });

    _bleSub?.cancel();
    _fakeSub?.cancel();

    _bleSub = bleDataSource.getDevices().listen((found) {
      _bleDevices = found;
      _updateDevices();
    });

    _fakeSub = fakedataSource.getDevices().listen((found) {
      _fakeDevices = found;
      _updateDevices();
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => isScanning = false);
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            // Timer para forçar o refresh do BottomSheet enquanto a lista 'devices' cresce
            Timer.periodic(const Duration(milliseconds: 500), (timer) {
              if (context.mounted) {
                setSheetState(() {});
              } else {
                timer.cancel();
              }
            });

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: _buildScanResults(),
            );
          },
        );
      },
    );
  }

  void _updateDevices() {
    final Map<String, Device> all = {};
    for (var d in _fakeDevices) { all[d.id] = d; }
    for (var d in _bleDevices) { all[d.id] = d; }
    if (mounted) {
      setState(() {
        devices = all.values.toList();
      });
    }
  }

  // -------------------- NAVEGAÇÃO --------------------
  
  void selectDevice(Device device) {
    setState(() {
      connectedDevice = device;
    });
    Navigator.pop(context); // Fecha o BottomSheet
  }

  void openWriter(Device device) {
    final dataSource = device.nativeDevice == null ? fakedataSource : bleDataSource;

    if (appMode.value == CommunicationMode.morse) {
      GlobalMorseService().initDecoder(device, dataSource);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WriterScreen(deviceId: device.id),
        ),
      );
    } else {
      GlobalMorseService().dispose();
      WordsDecoderService().initDecoder(device, dataSource);
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WordsWriterScreen(
            deviceId: device.id,
          ),
        ),
      );
    }
  }

  void openReader(Device device) {
  final dataSource = device.nativeDevice == null ? fakedataSource : bleDataSource;

  if (appMode.value == CommunicationMode.morse) {
    GlobalMorseService().initDecoder(device, dataSource);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderScreen(),
      ),
    );
  } else {
    GlobalMorseService().dispose();
    WordsDecoderService().initDecoder(device, dataSource);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WordsReaderScreen(
        ),
      ),
    );
  }
}

  @override
  void dispose() {
    _bleSub?.cancel();
    _fakeSub?.cancel();
    super.dispose();
  }

  // -------------------- UI COMPONENTS --------------------
  Widget _buildScanResults() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text("Searching for Devices", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (isScanning) const LinearProgressIndicator(),
          const SizedBox(height: 10),
          Expanded(
            child: devices.isEmpty
                ? const Center(child: Text("No devices found yet..."))
                : ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return DeviceCard(
                        device: device,
                        onTap: () => selectDevice(device),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text("Talky Buddy", style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Welcome!", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // CARD DE STATUS
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                children: [
                  Icon(
                    connectedDevice == null ? Icons.bluetooth_disabled : Icons.bluetooth_connected,
                    size: 40,
                    color: connectedDevice == null ? Colors.grey : colors.primary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    connectedDevice == null ? "No device connected" : "Connected to: ${connectedDevice!.name}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Center(
              child: ToggleButtons(
                borderRadius: BorderRadius.circular(12),
                isSelected: [
                  appMode.value == CommunicationMode.morse,
                  appMode.value == CommunicationMode.words,
                ],
                onPressed: (index) {
                  appMode.value = index == 0
                      ? CommunicationMode.morse
                      : CommunicationMode.words;
                },
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text("Morse"),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text("Words"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            const Text("Modes", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // LISTA DE MODOS (Só ativa se houver um device selecionado)
            Opacity(
              opacity: connectedDevice == null ? 0.5 : 1.0,
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.edit, color: colors.primary),
                      title: const Text("Writer Mode"),
                      subtitle: const Text("Morse Binary Tree Guide"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: connectedDevice == null ? null : () => openWriter(connectedDevice!),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.visibility, color: colors.primary),
                      title: const Text("Reader Mode"),
                      subtitle: const Text("View incoming messages"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: connectedDevice == null ? null : () => openReader(connectedDevice!),
                    ),
                  ],
                ),
              ),
            ),
            
            if (connectedDevice == null)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Center(child: Text("Connect to a device to unlock modes", style: TextStyle(color: Colors.grey))),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isScanning ? null : startScan,
        label: Text(isScanning ? "Scanning..." : "Search Devices"),
        icon: Icon(isScanning ? Icons.sync : Icons.search),
      ),
    );
  }
}