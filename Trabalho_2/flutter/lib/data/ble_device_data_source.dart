import '../models/device.dart';
import 'device_data_source.dart';

class BleDeviceDataSource implements DeviceDataSource {
  @override
  Stream<List<Device>> getDevices() {
    // TODO: implement real BLE scanning
    throw UnimplementedError();
  }

  @override
  Stream<int> getSensorValue(Device device, String sensor) {
    // TODO: implement reading BLE characteristic
    throw UnimplementedError();
  }
}