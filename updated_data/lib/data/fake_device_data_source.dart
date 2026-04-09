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

    const message = "E";
    const int symbolTime = 400; // time each dot/dash is active
    const int symbolGap = 500;  // gap between symbols
    const int letterGap = 1000;  // gap between letters
    const int wordGap = 2000;   // gap between words
    const int idleStep = 100;   // how often to send idle during gaps

    while(true){
      for (var char in message.split('')) {
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