import 'dart:async';
import '../models/device.dart';
import 'device_data_source.dart';

class FakeDeviceDataSource implements DeviceDataSource {
  @override
  Stream<List<Device>> getDevices() async* {
    await Future.delayed(const Duration(seconds: 2));
    yield [
      Device(name: "Fake Sensor A", id: "FAKE_01", rssi: -40),
      Device(name: "Fake Sensor B", id: "FAKE_02", rssi: -60),
    ];
  }

  @override
  Stream<int> getSensorValue(Device device, String sensor) async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 1));
      yield 20 + (DateTime.now().second % 10); // fake dynamic value
    }
  }
}