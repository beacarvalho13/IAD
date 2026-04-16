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
    return _fakeSensorGenerator(device.id);
  }

  Stream<int> _fakeSensorGenerator(String deviceId) async* {
    const int dotSignal = 1;
    const int dashSignal = 2;
    const int endOfChar = 3;
    const int endOfWord = 4;

    final morseMap = {
      'H': [dotSignal, dotSignal, dotSignal, dotSignal],
      'E': [dotSignal],
      'L': [dotSignal, dashSignal, dotSignal, dotSignal],
      'O': [dashSignal, dashSignal, dashSignal],
      'A': [dotSignal, dashSignal],
      'B': [dashSignal, dotSignal, dotSignal, dotSignal],
      'C': [dashSignal, dotSignal, dashSignal, dotSignal],
      'D': [dashSignal, dotSignal, dotSignal],
      'S': [dotSignal, dotSignal, dotSignal],
      'T': [dashSignal],
      'U': [dotSignal, dotSignal, dashSignal],
      'V': [dotSignal, dotSignal, dotSignal, dashSignal],
      'W': [dotSignal, dashSignal, dashSignal],
      'X': [dashSignal, dotSignal, dotSignal, dashSignal],
      'Y': [dashSignal, dotSignal, dashSignal, dashSignal],
      'Z': [dashSignal, dashSignal, dotSignal, dotSignal],
      'M': [dashSignal, dashSignal],
      'N': [dashSignal, dotSignal],
      'F': [dotSignal, dotSignal, dashSignal, dotSignal],
      'G': [dashSignal, dashSignal, dotSignal],
      'J': [dotSignal, dashSignal, dashSignal, dashSignal],
      'K': [dashSignal, dotSignal, dashSignal], 
      'P': [dotSignal, dashSignal, dashSignal, dotSignal],
      'Q': [dashSignal, dashSignal, dotSignal, dashSignal],
      'R': [dotSignal, dashSignal, dotSignal],
      'V': [dotSignal, dotSignal, dotSignal, dashSignal],
    };

    final possibleMessages = ["HELLO", "SOS", "TEST", "ABC"];

    final String message;
      if (deviceId == "FAKE_01") {
        message = "HELLO";
      } else if (deviceId == "FAKE_02") {
        message = "E";
      } else {
        message = "HELLO";
      }
      
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