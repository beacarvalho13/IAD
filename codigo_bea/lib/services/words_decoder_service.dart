import 'dart:async';
import '../models/device.dart';
import '../data/device_data_source.dart';
import 'message_bus.dart';



class WordsDecoderService {
  static final WordsDecoderService _instance = WordsDecoderService._internal();
  factory WordsDecoderService() => _instance;
  WordsDecoderService._internal();

  final Map<String, DeviceWordsDecoder> _decoders = {};

  void initDecoder(Device device, DeviceDataSource dataSource) {
    if (!_decoders.containsKey(device.id)) {
      _decoders[device.id] = DeviceWordsDecoder(
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
  
  DeviceWordsDecoder? getDecoder(String deviceId) => _decoders[deviceId];
  
  void dispose() {
    for (var decoder in _decoders.values) {
      decoder.dispose();
    }
    _decoders.clear();
  }
}

class DeviceWordsDecoder {
  final Device device;
  final DeviceDataSource dataSource;

  String currentPath = "";
  String finalMessage = "";

  static const int letterGapThreshold = 1000;
  static const int wordGapThreshold = 2000;


  static const Map<String, String> wordMap = {
    ".": "YES",
    "..": "NO",
    "-": "HELLO",
    "--": "GOODBYE",
    "-.": "MORE",
    "-..": "LESS",
    "..-": "PLEASE",
    ".-": "THANK YOU",
    "...": "GOOD",
    "---": "BAD"}
  ;

  late final StreamSubscription<int> _subscription;

  DeviceWordsDecoder({required this.device, required this.dataSource}) {
    _subscription = dataSource
        .getSensorValue(device, "signal")
        .listen(_processInput);
  }

  void _processInput(int value) {
    const dot = 1;
    const dash = 2;
    const endOfChar = 3;
    const endOfWord = 4;

    if (value == dot || value == dash) {
      // Build current letter
      currentPath += (value == dot ? '.' : '-');
      MessageBus.updateCurrentPath(currentPath);
    } 
    else if (value == endOfChar) {
      _flushCharacter();
    } 
    else if (value == endOfWord) {
      _flushCharacter();
      if (finalMessage.isNotEmpty && !finalMessage.endsWith(" ")) {
        finalMessage += " "; // separate words
        MessageBus.updateMessage(finalMessage);
      }
    }
  }

  void _flushCharacter() {
    if (currentPath.isEmpty) return;
    final decoded = wordMap[currentPath] ?? "?";
    finalMessage += decoded;
    currentPath = "";
    MessageBus.updateCurrentPath(currentPath);
    MessageBus.updateMessage(finalMessage);
  }

  void dispose() {
    _subscription.cancel();
  }
}