import 'dart:async';
import 'package:flutter/material.dart';
import '../models/device.dart';
import '../widgets/sensor_tile.dart';

class DeviceScreen extends StatefulWidget {
  final Device device;

  const DeviceScreen({super.key, required this.device});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  int temperature = 20;
  int humidity = 50;

  @override
  void initState() {
    super.initState();
    startFakeStream();
  }

  void startFakeStream() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        temperature = 20 + (DateTime.now().second % 10);
        humidity = 50 + (DateTime.now().second % 20);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SensorTile(
              title: "Temperature",
              value: "$temperature °C",
              icon: Icons.thermostat,
            ),
            const SizedBox(height: 20),
            SensorTile(
              title: "Humidity",
              value: "$humidity %",
              icon: Icons.water_drop,
            ),
          ],
        ),
      ),
    );
  }
}