import 'package:flutter/material.dart';
import '../models/device.dart';
import '../widgets/sensor_tile.dart';
import '../data/device_data_source.dart';
import 'dart:async';

class DeviceScreen extends StatefulWidget {
  final Device device;
  final DeviceDataSource dataSource;

  const DeviceScreen({
    super.key,
    required this.device,
    required this.dataSource,
  });

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  int temperature = 20;
  int humidity = 50;

  StreamSubscription<int>? tempSub;
  StreamSubscription<int>? humiditySub;

  @override
  void initState() {
    super.initState();

    tempSub = widget.dataSource
        .getSensorValue(widget.device, "temperature")
        .listen((value) {
      setState(() => temperature = value);
    });

    humiditySub = widget.dataSource
        .getSensorValue(widget.device, "humidity")
        .listen((value) {
      setState(() => humidity = value);
    });
  }

  @override
  void dispose() {
    tempSub?.cancel();
    humiditySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.device.name)),
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