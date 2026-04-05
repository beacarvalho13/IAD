import '../models/device.dart';
import 'dart:async';

abstract class DeviceDataSource {
  Stream<List<Device>> getDevices();
  Stream<int> getSensorValue(Device device, String sensor);
}


class MessageBus {
  // Broadcast stream so multiple listeners can receive updates
  static final StreamController<String> _messageController = StreamController<String>.broadcast();

  static Stream<String> get messageStream => _messageController.stream;

  static void updateMessage(String message) {
    _messageController.add(message);
  }
}