import 'dart:async';
import 'dart:math';
import '../models/device.dart';
import 'device_data_source.dart';

class FakeDeviceDataSource implements DeviceDataSource {
  @override
  Stream<List<Device>> getDevices() async* {
    // Only emit devices after getDevices() is called
    await Future.delayed(const Duration(seconds: 2));
    yield [
      Device(name: "Fake Sensor A", id: "FAKE_01", rssi: -40, nativeDevice: null),
      Device(name: "Fake Sensor B", id: "FAKE_02", rssi: -60, nativeDevice: null),
    ];
  }

  @override
  Stream<int> getSensorValue(Device device, String sensor) async* {
    final random = Random();
    while (true) {
      await Future.delayed(const Duration(seconds: 1));
      if (sensor.contains("force")) {
        yield 30 + random.nextInt(5);
      } else {
        yield 20 + random.nextInt(3);
      }
    }
  }
}