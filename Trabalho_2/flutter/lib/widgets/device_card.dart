import 'package:flutter/material.dart';
import '../models/device.dart';

class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onTap;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: ListTile(
        leading: const Icon(Icons.bluetooth),
        title: Text(device.name),
        subtitle: Text(device.id),
        trailing: Text("${device.rssi} dBm"),
        onTap: onTap,
      ),
    );
  }
}