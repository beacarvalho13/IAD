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

  StreamSubscription<List<Device>>? _bleSub;
  StreamSubscription<List<Device>>? _fakeSub;

  // Keep separate lists to merge
  List<Device> _bleDevices = [];
  List<Device> _fakeDevices = [];

  // -------------------- SCAN LOGIC --------------------
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
    builder: (context) {
      // O segredo está aqui:
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setSheetState) {
          
          // Criamos um Timer para forçar o Sheet a redesenhar 
          // sempre que a lista global 'devices' mudar
          Timer.periodic(const Duration(milliseconds: 500), (timer) {
            if (context.mounted) {
              setSheetState(() {}); // Atualiza o interior do BottomSheet
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

    // Merge fake first, then BLE (or vice versa)
    for (var d in _fakeDevices) {
      all[d.id] = d;
    }
    for (var d in _bleDevices) {
      all[d.id] = d;
    }

    setState(() {
      devices = all.values.toList();
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
  void dispose() {
    _bleSub?.cancel();
    _fakeSub?.cancel();
    super.dispose();
  }

  // -------------------- SCAN RESULT WIDGET --------------------
  Widget _buildScanResults() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 10),
          if (isScanning) const LinearProgressIndicator(),
          const SizedBox(height: 10),
          Expanded(
            child: devices.isEmpty
                ? const Center(child: Text("No devices found"))
                : ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return DeviceCard(
                        device: device,
                        onTap: () {
                          openDevice(device);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // -------------------- MAIN SCREEN --------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        title: const Text("Talky Buddy"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            const Text(
              "Welcome!",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // CONTENT CARD
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(child: Text("Podemos meter aqui a live translation em simplified language e embaixo em braile, por exemplo")),
            ),

            // Add more content here as needed
          ],
        ),
      ),

      // FAB triggers scan
      floatingActionButton: FloatingActionButton(
        onPressed: isScanning ? null : startScan,
        backgroundColor: Colors.black,
        child: AnimatedRotation(
          turns: isScanning ? 1 : 0,
          duration: const Duration(seconds: 1),
          child: Icon(isScanning ? Icons.sync : Icons.bluetooth),
        ),
      ),
    );
  }
}