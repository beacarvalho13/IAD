import 'package:flutter/material.dart';

// Enum representing the communication modes of the app, either Morse code or Words

enum CommunicationMode {
  morse,
  words,
}

ValueNotifier<CommunicationMode> appMode =
    ValueNotifier(CommunicationMode.morse);