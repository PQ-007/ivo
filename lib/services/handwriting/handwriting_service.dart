// Hybrid handwriting recognition orchestrator.
//
// Strategy: prefer Google ML Kit Digital Ink (higher accuracy) whenever its
// Japanese model can run — i.e. it's already cached, or we're online and can
// download it. Otherwise fall back to the fully-offline KanjiVG + DTW engine.
// Once the ink model is cached it keeps being used (it works offline too); the
// DTW engine is the safety net for "no model AND no connection" and for any
// ink-recognition error.

import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'digital_ink_recognizer.dart';
import 'stroke_recognizer.dart';

enum HandwritingEngine { ink, stroke }

class HandwritingService {
  HandwritingService._();
  static final HandwritingService instance = HandwritingService._();

  final _ink = InkRecognizerService.instance;
  final _stroke = StrokeRecognizer.instance;

  /// Which engine produced the most recent result (for debugging/telemetry).
  HandwritingEngine? lastEngineUsed;

  /// Warm up the offline templates, and try to make the ink model ready if the
  /// device is online. Safe to call repeatedly (e.g. when the draw pad opens).
  Future<void> warmUp() async {
    _stroke.load(); // fire-and-forget; offline fallback always available
    if (await _online()) {
      await _ink.ensureModel(online: true);
    }
  }

  Future<Map<String, dynamic>> recognize(List<Offset?> points) async {
    // Use ink if its model is ready, or if we're online and can fetch it.
    final canUseInk =
        _ink.isModelReady || await _ink.ensureModel(online: await _online());
    if (canUseInk) {
      try {
        final result = await _ink.recognize(points);
        if ((result['top10'] as List).isNotEmpty) {
          lastEngineUsed = HandwritingEngine.ink;
          return result;
        }
      } catch (e) {
        debugPrint('Ink recognition failed, falling back to DTW: $e');
      }
    }

    lastEngineUsed = HandwritingEngine.stroke;
    return _stroke.recognize(points);
  }

  Future<bool> _online() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }
}
