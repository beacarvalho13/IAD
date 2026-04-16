import 'dart:async';
import '../models/device.dart';
import '../data/device_data_source.dart';
import 'message_bus.dart';

// Service to decode Morse code signals from the Talky Buddy's beacon mode sensor

class GlobalMorseService {
  static final GlobalMorseService _instance = GlobalMorseService._internal();
  factory GlobalMorseService() => _instance;
  GlobalMorseService._internal();

  final Map<String, DeviceMorseDecoder> _decoders = {};

  void initDecoder(Device device, DeviceDataSource dataSource) {
    if (!_decoders.containsKey(device.id)) {
      _decoders[device.id] = DeviceMorseDecoder(
        device: device,
        dataSource: dataSource,
      );
    }
  }// Initializes a decoder for the given device if it doesn't already exist

  void clearMessage() {// Clears the current message and path for all decoders and updates the message bus
    for (var decoder in _decoders.values) {
      decoder.finalMessage = "";
      decoder.currentPath = "";
    }
    MessageBus.updateMessage("");
    MessageBus.updateCurrentPath("");// Clears the current message and path for all decoders and updates the message bus
  }

  DeviceMorseDecoder? getDecoder(String deviceId) => _decoders[deviceId];

  void dispose() {
    for (var decoder in _decoders.values) {
      decoder.dispose();
    }
    _decoders.clear();
  }
}

class DeviceMorseDecoder {
  final Device device;
  final DeviceDataSource dataSource;

  String currentPath = "";
  String finalMessage = "";// Internal state for building the current letter and word

  final Map<String, String> morseMap = {
    '.-': 'A', '-...': 'B', '-.-.': 'C', '-..': 'D', '.': 'E',
    '..-.': 'F', '--.': 'G', '....': 'H', '..': 'I', '.---': 'J',
    '-.-': 'K', '.-..': 'L', '--': 'M', '-.': 'N', '---': 'O',
    '.--.': 'P', '--.-': 'Q', '.-.': 'R', '...': 'S', '-': 'T',
    '..-': 'U', '...-': 'V', '.--': 'W', '-..-': 'X', '-.--': 'Y',
    '--..': 'Z',
  };// Morse code mapping for letters A-Z

  StreamSubscription<int>? _subscription;

  DeviceMorseDecoder({required this.device, required this.dataSource}) {
    _subscription = dataSource
        .getSensorValue(device, "beacon_mode")
        .listen(_processInput);
  }

  void _processInput(int value) {
    const dot = 1;
    const dash = 2;
    const endOfChar = 3;
    const endOfWord = 4;// Signals expected from the Talky Buddy

    if (value == dot || value == dash) {// Append dot or dash to the current path and update the message bus
      currentPath += (value == dot ? '.' : '-');
      MessageBus.updateCurrentPath(currentPath);
    } 
    else if (value == endOfChar) {// End of character signal, decode current path and update message
      _flushCharacter();
    } 
    else if (value == endOfWord) {// End of word signal, flush character and add space
      _flushCharacter();
      if (finalMessage.isNotEmpty && !finalMessage.endsWith(" ")) {
        finalMessage += " ";
        MessageBus.updateMessage(finalMessage);
      }
    }
  }

  void _flushCharacter() {// Helper method to decode the current character and update the message bus
    if (currentPath.isEmpty) return;
    final decoded = morseMap[currentPath] ?? "?";
    finalMessage += decoded;
    currentPath = "";
    MessageBus.updateCurrentPath(currentPath);
    MessageBus.updateMessage(finalMessage);
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}