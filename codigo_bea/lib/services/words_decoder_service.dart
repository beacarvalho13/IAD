import 'dart:async';
import '../models/device.dart';
import '../data/device_data_source.dart';
import 'message_bus.dart';

// Service to decode pre-defined words from sensor signals on the Talky Buddy

class WordsDecoderService {
  static final WordsDecoderService _instance = WordsDecoderService._internal();
  factory WordsDecoderService() => _instance;
  WordsDecoderService._internal();

  final Map<String, DeviceWordsDecoder> _decoders = {};// Map to hold decoders for each device by their ID

  void initDecoder(Device device, DeviceDataSource dataSource) {// Initializes a decoder for the given device if it doesn't already exist
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
    MessageBus.updateCurrentPath("");// Clears the current message and path for all decoders and updates the message bus
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
  static const int endOfWord = 4;// Expected commands from the Talky Buddy

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
  };// Predefined word dictionary for the writer mode

  late final StreamSubscription<int> _subscription;

  DeviceWordsDecoder({// Constructor that initializes the decoder and subscribes to the sensor value stream for the device
    required this.device,
    required this.dataSource,
  }) {
    _subscription = dataSource
        .getSensorValue(device, "signal")
        .listen(_processInput);
  }

  void _processInput(int value) {// Processes incoming signals and updates the current path and final message accordingly
    switch (value) {
      case dot:// Adds a dot to the current path and updates the message bus for live preview
        currentPath += '.';
        MessageBus.updateCurrentPath(currentPath);
        break;

      case dash:// Adds a dash to the current path and updates the message bus for live preview
        currentPath += '-';
        MessageBus.updateCurrentPath(currentPath);
        break;

      case endOfChar:// Flushes the current character to the final message
        _flushCharacter();
        break;

      case endOfWord:// Flushes the current character and adds a word separator
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
    currentPath = "";// Clear current path after decoding a character

    MessageBus.updateCurrentPath(currentPath);
    MessageBus.updateMessage(finalMessage);// Update the final message in the message bus after decoding a character
  }

  void _addWordSeparator() {// Adds a space to separate words if the final message is not empty and doesn't already end with a space
    if (finalMessage.isNotEmpty && !finalMessage.endsWith(" ")) {
      finalMessage += " ";
      MessageBus.updateMessage(finalMessage);
    }
  }

  void reset() {
    currentPath = "";
    finalMessage = "";
  }// Resets the current path and final message for the decoder, used when clearing messages

  void dispose() {
    _subscription.cancel();
  }
}