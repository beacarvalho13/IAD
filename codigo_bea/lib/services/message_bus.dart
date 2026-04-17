import 'dart:async';

// Message bus using StreamControllers to allow different parts of the app to listen for updates

// Broadcast stream to allow multiple listeners (UI, TTS, etc.)
class MessageBus { 
  static final StreamController<String> _messageController =
      StreamController<String>.broadcast();
  static String _lastMessage = "";
  static Stream<String> get messageStream => _messageController.stream;
  static String get lastMessage => _lastMessage;

  // Updates the current message and notifies all listeners with the new message
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
  static String get lastPath => _lastPath;// Current Morse path for tree updates

  // Updates the current path and notifies listeners with the new path
  static void updateCurrentPath(String path) {
    if (!_currentPathController.isClosed) {
      _lastPath = path;
      _currentPathController.add(path);
    }
  }

  // Resets the message bus state and notifies listeners with empty values
  static void reset() {
    _lastMessage = "";
    _lastPath = "";
    if (!_messageController.isClosed) _messageController.add("");
    if (!_currentPathController.isClosed) _currentPathController.add("");
  }

  // Closes the stream controllers when the app is disposed to free resources
  static void dispose() {
    _messageController.close();
    _currentPathController.close();
  }
}