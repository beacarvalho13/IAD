import '../models/device.dart';

abstract class DeviceDataSource {
  Stream<List<Device>> getDevices();
  Stream<int> getSensorValue(Device device, String sensor);
}