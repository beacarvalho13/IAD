import 'package:flutter/material.dart';

enum CommunicationMode {
  morse,
  words,
}

ValueNotifier<CommunicationMode> appMode =
    ValueNotifier(CommunicationMode.morse);