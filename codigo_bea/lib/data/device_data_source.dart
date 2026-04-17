import '../models/device.dart';
import 'dart:async';

// Data source for providing BLE device information and sensor values, withouth implementation

abstract class DeviceDataSource {
  Stream<List<Device>> getDevices();
  Stream<int> getSensorValue(Device device, String sensor);
}
