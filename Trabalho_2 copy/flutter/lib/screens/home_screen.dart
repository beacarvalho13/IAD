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

  void startScan() {
    setState(() => isScanning = true);

    // Cancel previous subscription
    _bleSub?.cancel();
    _fakeSub?.cancel();

    _bleSub = bleDataSource.getDevices().listen((foundDevices) {
      setState(() {
        _bleDevices = foundDevices;
        devices = [..._bleDevices, ..._fakeDevices];
        isScanning = false;
      });
    });

    _fakeSub = fakedataSource.getDevices().listen((foundDevices) {
      setState(() {
        _fakeDevices = foundDevices;
        devices = [..._bleDevices, ..._fakeDevices];
        isScanning = false;
      });
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
    for (var d in [..._bleDevices, ..._fakeDevices]) {
      all[d.id] = d;
    }
    
    setState(() {
      devices = all.values.toList();
      if (_bleDevices.isNotEmpty || _fakeDevices.isNotEmpty) {
        isScanning = false; // stop progress bar once we have any results
      }
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
      appBar: AppBar(title: const Text("Bluetooth Devices")),
      body: Column(
        children: [
          if (isScanning) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return DeviceCard(
                  device: device,
                  onTap: () => openDevice(device),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isScanning ? null : startScan,
        child: const Icon(Icons.search),
      ),
    );
  }
}