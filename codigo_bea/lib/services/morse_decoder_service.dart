import 'dart:async';
import '../models/device.dart';
import '../data/device_data_source.dart';
import 'message_bus.dart';

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
  }

  void clearMessage() {
    for (var decoder in _decoders.values) {
      decoder.finalMessage = "";
      decoder.currentPath = "";
    }
    MessageBus.updateMessage("");
    MessageBus.updateCurrentPath("");
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
  String finalMessage = "";

  final Map<String, String> morseMap = {
    '.-': 'A', '-...': 'B', '-.-.': 'C', '-..': 'D', '.': 'E',
    '..-.': 'F', '--.': 'G', '....': 'H', '..': 'I', '.---': 'J',
    '-.-': 'K', '.-..': 'L', '--': 'M', '-.': 'N', '---': 'O',
    '.--.': 'P', '--.-': 'Q', '.-.': 'R', '...': 'S', '-': 'T',
    '..-': 'U', '...-': 'V', '.--': 'W', '-..-': 'X', '-.--': 'Y',
    '--..': 'Z',
  };

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
    const endOfWord = 4;

    if (value == dot || value == dash) {
      currentPath += (value == dot ? '.' : '-');
      MessageBus.updateCurrentPath(currentPath);
    } 
    else if (value == endOfChar) {
      _flushCharacter();
    } 
    else if (value == endOfWord) {
      _flushCharacter();
      if (finalMessage.isNotEmpty && !finalMessage.endsWith(" ")) {
        finalMessage += " ";
        MessageBus.updateMessage(finalMessage);
      }
    }
  }

  void _flushCharacter() {
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