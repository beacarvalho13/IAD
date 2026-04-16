import 'dart:async';
import 'package:flutter/material.dart';
import '../models/device.dart';
import '../widgets/device_card.dart';
import 'device_screen.dart';
import '../data/fake_device_data_source.dart';
import '../data/ble_device_data_source.dart';
import '../data/device_data_source.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Device> devices = [];
  bool isScanning = false;

  // Choose your data source (Fake or BLE)
  final DeviceDataSource fakedataSource = FakeDeviceDataSource();
  final DeviceDataSource bleDataSource = BleDeviceDataSource();
  StreamSubscription<bool>? _scanStatusSub;
  
  StreamSubscription<List<Device>>? _bleSub;
  StreamSubscription<List<Device>>? _fakeSub;

  // Keep separate lists to merge
  List<Device> _bleDevices = [];
  List<Device> _fakeDevices = [];


  void startScan() {
  setState(() {
    isScanning = true;
    _bleDevices = [];
    _fakeDevices = [];
    devices = [];
  });

  _bleSub?.cancel();
  _fakeSub?.cancel();

  // Escutar BLE
  _bleSub = bleDataSource.getDevices().listen((foundDevices) {
    _bleDevices = foundDevices;
    _updateDevices(); // Usa a tua função de merge
  });

  // Escutar Fake
  _fakeSub = fakedataSource.getDevices().listen((foundDevices) {
    _fakeDevices = foundDevices;
    _updateDevices(); // Usa a tua função de merge
  });

  // Timer para parar o loading após o timeout do scan (5 seg)
  Future.delayed(const Duration(seconds: 5), () {
    if (mounted) setState(() => isScanning = false);
  });
  }

  @override
  void dispose() {
    _bleSub?.cancel();
    _fakeSub?.cancel();
    super.dispose();
  }

  void _updateDevices() {
  final Map<String, Device> all = {};
  
  // Adiciona primeiro os fakes, depois os BLE (ou vice-versa)
  for (var d in _fakeDevices) { all[d.id] = d; }
  for (var d in _bleDevices) { all[d.id] = d; }
  
  setState(() {
    devices = all.values.toList();
    // Não coloques isScanning = false aqui, deixa para o Timer do scan
  });
  }

  void openDevice(Device device) {

    final dataSource = device.nativeDevice == null ? fakedataSource : bleDataSource;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeviceScreen(device: device, dataSource: dataSource),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bluetooth Devices"),
        backgroundColor: const Color.fromARGB(255, 255, 68, 233),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          if (isScanning)
            const LinearProgressIndicator()
          else
            const Text("Tap the search icon to scan for devices"),
          Expanded(
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return DeviceCard(
                  device: device,
                  onTap: () async {
                    try {
                      // Try connecting immediately like your friend did
                      if (device.nativeDevice != null) {
                        await device.nativeDevice!.connect(autoConnect: false);
                        print("Connected to ${device.nativeDevice!.remoteId}");
                      }
                    } catch (e) {
                      print("Error connecting: $e");
                    }

                    openDevice(device);
                  },
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