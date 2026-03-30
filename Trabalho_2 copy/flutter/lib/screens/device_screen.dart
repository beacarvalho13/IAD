import 'package:flutter/material.dart';
import '../models/device.dart';
import '../data/device_data_source.dart';

class DeviceScreen extends StatelessWidget {
  final Device device;
  final DeviceDataSource dataSource;

  const DeviceScreen({super.key, required this.device, required this.dataSource});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(device.name)),
      body: Center(
        child: StreamBuilder<int>(
          stream: dataSource.getSensorValue(device, "temperature"),
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