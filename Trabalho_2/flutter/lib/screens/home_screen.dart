import 'package:flutter/material.dart';
import '../models/device.dart';
import '../widgets/device_card.dart';
import 'device_screen.dart';
import '../data/fake_device_data_source.dart';
import '../data/device_data_source.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Device> devices = [];
  bool isScanning = false;

  // Choose which source to use
  final DeviceDataSource dataSource = FakeDeviceDataSource();
  // final DeviceDataSource dataSource = BleDeviceDataSource();

  void startScan() {
    setState(() => isScanning = true);

    dataSource.getDevices().listen((foundDevices) {
      setState(() {
        devices = foundDevices;
        isScanning = false;
      });
    });
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DeviceScreen(
                          device: device,
                          dataSource: dataSource,
                        ),
                      ),
                    );
                  },
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