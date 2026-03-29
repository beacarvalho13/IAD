import 'package:flutter/material.dart';
import '../models/device.dart';
import '../widgets/device_card.dart';
import 'device_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Device> devices = [];
  bool isScanning = false;

  void startScan() async {
    setState(() => isScanning = true);

    // simulate scanning delay
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      isScanning = false;
      devices = [
        Device(name: "Sensor A", id: "00:11", rssi: -40),
        Device(name: "Sensor B", id: "22:33", rssi: -60),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bluetooth Devices"),
      ),
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
                        builder: (_) => DeviceScreen(device: device),
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