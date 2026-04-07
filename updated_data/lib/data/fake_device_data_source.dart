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
  Stream<int> getSensorValue(Device device, String sensor) {
    return _fakeSensorGenerator();
  }

  Stream<int> _fakeSensorGenerator() async* {
    const int dotSignal = 1;
    const int dashSignal = 2;
    const int endOfChar = 3;
    const int endOfWord = 4;

    final morseMap = {
      'H': [dotSignal, dotSignal, dotSignal, dotSignal],
      'E': [dotSignal],
      'L': [dotSignal, dashSignal, dotSignal, dotSignal],
      'O': [dashSignal, dashSignal, dashSignal],
    };

    const message = "HELLO";
    const int symbolTime = 400; // duration of dot/dash
    const int gapTime = 200;    // short pause between symbols, letters, or words

    while (true) {
      final words = message.split(' ');
      for (int w = 0; w < words.length; w++) {
        final word = words[w];
        for (var char in word.split('')) {
          final code = morseMap[char.toUpperCase()] ?? [];

          // Emit dots/dashes
          for (var symbol in code) {
            yield symbol;
            await Future.delayed(Duration(milliseconds: symbolTime + gapTime));
          }

          // End of character
          yield endOfChar;
          await Future.delayed(Duration(milliseconds: gapTime));
        }

        // End of word
        yield endOfWord;
        await Future.delayed(Duration(milliseconds: gapTime));
      }
    }
  }
}