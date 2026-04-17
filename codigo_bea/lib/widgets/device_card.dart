import 'package:flutter/material.dart';
import '../models/device.dart';

// Widget that represents a card for a BLE device, showing its name, ID and RSSI, and allowing the user to tap on it to connect

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
        leading: const Icon(Icons.bluetooth),// Shows a Bluetooth icon on the left of the card
        title: Text(device.name),// Shows the device name as the title of the card
        subtitle: Text(device.id),// Shows the device ID as the subtitle of the card
        trailing: Text("${device.rssi} dBm"),// Shows the device RSSI as the trailing text of the card
        onTap: onTap,
      ),
    );
  }
}