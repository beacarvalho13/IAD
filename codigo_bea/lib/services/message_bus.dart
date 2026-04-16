import 'dart:async';

class MessageBus {
  static final StreamController<String> _messageController =
      StreamController<String>.broadcast();
  static String _lastMessage = "";
  static Stream<String> get messageStream => _messageController.stream;
  static String get lastMessage => _lastMessage;

  static void updateMessage(String message) {
    if (!_messageController.isClosed) {
      _lastMessage = message;
      _messageController.add(message);
    }
  }

  static final StreamController<String> _currentPathController = 
      StreamController<String>.broadcast();
  static String _lastPath = "";
  static Stream<String> get currentPathStream => _currentPathController.stream;
  static String get lastPath => _lastPath;

  static void updateCurrentPath(String path) {
    if (!_currentPathController.isClosed) {
      _lastPath = path;
      _currentPathController.add(path);
    }
  }

  static void reset() {
    _lastMessage = "";
    _lastPath = "";
    if (!_messageController.isClosed) _messageController.add("");
    if (!_currentPathController.isClosed) _currentPathController.add("");
  }

  static void dispose() {
    _messageController.close();
    _currentPathController.close();
  }
}