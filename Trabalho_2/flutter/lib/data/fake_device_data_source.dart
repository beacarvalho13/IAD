import 'dart:async';
import '../models/device.dart';
import 'device_data_source.dart';
import 'dart:math';

class FakeDeviceDataSource implements DeviceDataSource {
  @override
  Stream<List<Device>> getDevices() async* {
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
      if (sensor.contains("pressure")) { 
        yield 30 + random.nextInt(5); // Simulação Pressão
      } else {
        yield 20 + random.nextInt(3);
      }
    }
  }
}