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
      decoder.reset();
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

  static const int dot = 1;
  static const int dash = 2;
  static const int endOfChar = 3;
  static const int endOfWord = 4;

  /// Your custom "symbol → word" dictionary
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
    "---": "BAD",
  };

  late final StreamSubscription<int> _subscription;

  DeviceWordsDecoder({
    required this.device,
    required this.dataSource,
  }) {
    _subscription = dataSource
        .getSensorValue(device, "signal")
        .listen(_processInput);
  }

  void _processInput(int value) {
    switch (value) {
      case dot:
        currentPath += '.';
        MessageBus.updateCurrentPath(currentPath);
        break;

      case dash:
        currentPath += '-';
        MessageBus.updateCurrentPath(currentPath);
        break;

      case endOfChar:
        _flushCharacter();
        break;

      case endOfWord:
        _flushCharacter();
        _addWordSeparator();
        break;

      default:
        // Ignore unknown values
        break;
    }
  }

  void _flushCharacter() {
    if (currentPath.isEmpty) return;

    final decoded = wordMap[currentPath] ?? "?";

    // Add space if needed (avoid merging words accidentally)
    if (finalMessage.isNotEmpty && !finalMessage.endsWith(" ")) {
      finalMessage += " ";
    }

    finalMessage += decoded;
    currentPath = "";

    MessageBus.updateCurrentPath(currentPath);
    MessageBus.updateMessage(finalMessage);
  }

  void _addWordSeparator() {
    if (finalMessage.isNotEmpty && !finalMessage.endsWith(" ")) {
      finalMessage += " ";
      MessageBus.updateMessage(finalMessage);
    }
  }

  void reset() {
    currentPath = "";
    finalMessage = "";
  }

  void dispose() {
    _subscription.cancel();
  }
}