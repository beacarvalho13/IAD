import 'dart:async';
import 'dart:math';
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
    final morseMap = {
      'H': ['.', '.', '.', '.'],
      'E': ['.'],
      'L': ['.', '-', '.', '.'],
      'O': ['-', '-', '-'],
    };

    final message = "HELLO";

    const int pressValue = 80; // above threshold
    const int idleValue = 0;   // below threshold

    const int dotTime = 500;     // short press
    const int dashTime = 1000;    // long press
    const int symbolGap = 500;   // between dots/dashes
    const int letterGap = 3000;   // between letters
    const int wordGap = 5000;    // between words

    while (true) {
      for (var letter in message.split('')) {
        final code = morseMap[letter] ?? [];

        for (var symbol in code) {

          yield pressValue;

          if (symbol == '.') {
            await Future.delayed(Duration(milliseconds: dotTime));
          } else {
            await Future.delayed(Duration(milliseconds: dashTime));
          }

          yield idleValue;
          await Future.delayed(Duration(milliseconds: symbolGap));
        }

        // Letter gap (longer release)
        await Future.delayed(Duration(milliseconds: letterGap));
      }

      // Word gap
      await Future.delayed(Duration(milliseconds: wordGap));
    }
  }
}