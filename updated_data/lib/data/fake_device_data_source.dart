import 'dart:async';
import '../models/device.dart';
import 'device_data_source.dart';

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
    // 1 = dot, 2 = dash, 0 = idle (gap)
    const int dotSignal = 1;
    const int dashSignal = 2;
    const int idle = 0;

    final morseMap = {
      'H': [dotSignal, dotSignal, dotSignal, dotSignal],
      'E': [dotSignal],
      'L': [dotSignal, dashSignal, dotSignal, dotSignal],
      'O': [dashSignal, dashSignal, dashSignal],
    };

    const message = "HELLO";

    const int symbolTime = 300; // time each dot/dash is active
    const int symbolGap = 200;  // gap between symbols
    const int letterGap = 800;  // gap between letters
    const int wordGap = 1500;   // gap between words
    const int idleStep = 100;   // how often to send idle during gaps

    while (true) {
      for (var char in message.split('')) {
        final code = morseMap[char.toUpperCase()] ?? [];

        // Send each dot/dash
        for (var symbol in code) {
          yield symbol;
          await Future.delayed(Duration(milliseconds: symbolTime));

          // Send idle during symbol gap
          for (int i = 0; i < symbolGap ~/ idleStep; i++) {
            yield idle;
            await Future.delayed(Duration(milliseconds: idleStep));
          }
        }

        // Letter gap (continuous idle)
        for (int i = 0; i < letterGap ~/ idleStep; i++) {
          yield idle;
          await Future.delayed(Duration(milliseconds: idleStep));
        }
      }

      // Word gap (continuous idle)
      for (int i = 0; i < wordGap ~/ idleStep; i++) {
        yield idle;
        await Future.delayed(Duration(milliseconds: idleStep));
      }
    }
  }
}