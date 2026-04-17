import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// Model class representing a BLE device, containing its name, ID and RSSI

class Device {
  final String name;
  final String id;
  final int rssi;
  final BluetoothDevice? nativeDevice;

  Device({
    required this.name,
    required this.id,
    required this.rssi,
    required this.nativeDevice,
  });
}