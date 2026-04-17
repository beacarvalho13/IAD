import 'package:flutter/material.dart';
import '../models/device.dart';
import '../data/device_data_source.dart';

// Screen that connects to a BLE device and displays a live-updating connection value from it

class DeviceScreen extends StatelessWidget {// Receives the selected device and data source to fetch sensor values
  final Device device;
  final DeviceDataSource dataSource;

  const DeviceScreen({super.key, required this.device, required this.dataSource});

  @override
  Widget build(BuildContext context) {// Visual layout
    return Scaffold(
      appBar: AppBar(title: Text(device.name)),
      body: Center(
        child: StreamBuilder<int>(
          stream: dataSource.getSensorValue(device, "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            return Text(
              "Sensor value: ${snapshot.data}",
              style: const TextStyle(fontSize: 24),
            );
          },
        ),
      ),
    );
  }
}