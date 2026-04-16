import 'package:flutter_tts/flutter_tts.dart';

// Text-to-speech service using the native flutter_tts package

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();// Instance of the FlutterTts class to handle text-to-speech functionality

  Future<void> init() async {// Convigures the TTS voice and settings, can be altered
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);

    await _configureVoice();
  }

  Future<void> _configureVoice() async {
    final dynamic result = await _tts.getVoices;

    if (result == null) return;

    final List voices = result as List;
    if (voices.isEmpty) return;

    Map? selectedVoice;

    try {
      selectedVoice = voices.cast<Map?>().firstWhere(
            (v) =>
                v != null &&
                (v["locale"] ?? "").toString().toLowerCase().startsWith("en"),
          );
    } catch (_) {
      selectedVoice = voices.first as Map?;
    }// If no English voice is found, just use the first available voice (safeguard for devices without English voices)

    if (selectedVoice == null) return;

    final name = selectedVoice["name"];
    final locale = selectedVoice["locale"];

    if (name == null || locale == null) return;

    await _tts.setVoice({
      "name": name.toString(),
      "locale": locale.toString(),
    });
  }

  Future<void> speak(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    await _tts.stop();
    await _tts.speak(cleanText);
  }// Speaks the given text

  Future<void> stop() async {
    await _tts.stop();// Stops any ongoing speech
  }
}