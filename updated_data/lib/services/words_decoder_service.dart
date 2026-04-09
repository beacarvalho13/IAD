import 'dart:async';
import '../models/device.dart';
import '../data/device_data_source.dart';
import 'message_bus.dart';



class WordsDecoderService {
  static final WordsDecoderService _instance = WordsDecoderService._internal();
  factory WordsDecoderService() => _instance;
  WordsDecoderService._internal();

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
  Timer? _letterTimer;
  DateTime? _lastInputTime;

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

  DeviceMorseDecoder({required this.device, required this.dataSource}) {
    dataSource
        .getSensorValue(device, "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
        .listen(_processInput);
  }

  void _processInput(int value) {
    final now = DateTime.now();

    if (value == 1 || value == 2) {
      currentPath += (value == 1 ? '.' : '-');
      _lastInputTime = now;

      MessageBus.updateCurrentPath(currentPath);

      _letterTimer?.cancel();
      _letterTimer = Timer(Duration(milliseconds: letterGapThreshold), () {
        if (currentPath.isNotEmpty) {
          finalMessage += "${wordMap[currentPath] ?? "?"} ";
          currentPath = "";
          
          MessageBus.updateMessage(finalMessage);
          MessageBus.updateCurrentPath(currentPath);
        }
      });
          } else if (value == 0) {
            // Check if it's time to insert a space for word gap
            if (_lastInputTime != null &&
                DateTime.now().difference(_lastInputTime!).inMilliseconds >=
                    wordGapThreshold) {
              if (finalMessage.isNotEmpty && !finalMessage.endsWith(" ")) {
                finalMessage += " "; // add space after word
                MessageBus.updateMessage(finalMessage);
              }
              _lastInputTime = null;
            }
          }
        }
  void dispose() {
    _letterTimer?.cancel();
  }
}