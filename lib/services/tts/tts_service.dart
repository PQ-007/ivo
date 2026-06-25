// Text-to-speech for Japanese terms, wrapping flutter_tts. Lazy-initialized;
// degrades silently if a Japanese voice isn't available on the device.

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    try {
      await _tts.setLanguage('ja-JP');
      await _tts.setSpeechRate(0.45); // a touch slower for learners
      await _tts.setPitch(1.0);
      _initialized = true;
    } catch (e) {
      debugPrint('TTS init failed: $e');
    }
  }

  /// Speak [text] in Japanese. No-op on failure.
  Future<void> speak(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    await _init();
    try {
      await _tts.stop();
      await _tts.speak(t);
    } catch (e) {
      debugPrint('TTS speak failed: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
