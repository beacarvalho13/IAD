import '../models/device.dart';
import 'dart:async';

abstract class DeviceDataSource {
  Stream<List<Device>> getDevices();
  Stream<int> getSensorValue(Device device, String sensor);
}
