import 'dart:async';
import 'dart:math';
import '../models/device.dart';
import 'device_data_source.dart';

class FakeDeviceDataSource implements DeviceDataSource {
  final Random _random = Random();

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
    // Map letters to simplified Morse (dot = 83, dash = 76, end-of-letter = 32)
    final morseMap = {
      'A': [83, 76, 32], // .-
      'B': [76, 83, 83, 83, 32], // -...
      'C': [76, 83, 76, 83, 32], // -.-.
      'H': [83, 83, 83, 83, 32], // ....
      'E': [83, 32], // .
      'L': [83, 76, 83, 83, 32], // .-..
      'O': [76, 76, 76, 32], // ---
    };

    // Example message to simulate
    final message = "HELLO";

    // Flatten message into a Morse sequence
    List<int> morseSequence = [];
    for (var letter in message.split('')) {
      if (morseMap.containsKey(letter)) {
        morseSequence.addAll(morseMap[letter]!);
      } else {
        morseSequence.add(32); // unknown letter -> just space
      }
    }

    int index = 0;

    while (true) {
      int signal = morseSequence[index];
      yield signal;

      // Dot = short pause, Dash = longer, End-of-letter = slightly longer
      int delay;
      if (signal == 83) {
        delay = 300 + _random.nextInt(200); // dot
      } else if (signal == 76) {
        delay = 700 + _random.nextInt(200); // dash
      } else {
        delay = 500 + _random.nextInt(200); // end-of-letter
      }

      await Future.delayed(Duration(milliseconds: delay));

      index++;
      if (index >= morseSequence.length) {
        index = 0; // loop message
        await Future.delayed(Duration(milliseconds: 1000)); // pause between messages
      }
    }
  }
}