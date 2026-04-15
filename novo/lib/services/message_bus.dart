import 'dart:async';

class MessageBus {
  static final StreamController<String> _messageController =
      StreamController<String>.broadcast();

  static Stream<String> get messageStream => _messageController.stream;

  static String lastMessage = "";

  static void updateMessage(String message) {
    lastMessage = message;
    _messageController.add(message);
  }

  // Current Morse path for tree updates
  static final _currentPathController = StreamController<String>.broadcast();
  static Stream<String> get currentPathStream => _currentPathController.stream;
  static void updateCurrentPath(String path) => _currentPathController.add(path);
}