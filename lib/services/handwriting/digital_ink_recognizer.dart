// Google ML Kit Digital Ink handwriting recognition (online-first engine).
//
// The Japanese model is downloaded once over the network and cached on-device;
// after that ML Kit works offline too. Used as the preferred engine by
// HandwritingService, which falls back to the offline KanjiVG+DTW recognizer
// when this model isn't available and there's no connection.
//
// Output contract matches StrokeRecognizer:
//   { 'kanji': String, 'confidence': double,
//     'top10': [ { 'kanji': String, 'confidence': double }, ... ] }

import 'dart:ui';

import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';

const String _kLang = 'ja';

class InkRecognizerService {
  InkRecognizerService._();
  static final InkRecognizerService instance = InkRecognizerService._();

  final DigitalInkRecognizerModelManager _modelManager =
      DigitalInkRecognizerModelManager();
  DigitalInkRecognizer? _recognizer;
  bool _modelReady = false;

  bool get isModelReady => _modelReady;

  /// Ensure the JP model is usable. Returns true if recognition can run now.
  /// [online] gates the one-time download; an already-cached model works offline.
  Future<bool> ensureModel({required bool online}) async {
    if (_modelReady) return true;
    try {
      if (await _modelManager.isModelDownloaded(_kLang)) {
        _modelReady = true;
        return true;
      }
      if (!online) return false;
      final ok = await _modelManager.downloadModel(_kLang, isWifiRequired: false);
      _modelReady = ok;
      return ok;
    } catch (_) {
      return false;
    }
  }

  /// Recognize a drawing. [points] is the draw-pad buffer (null separates strokes).
  Future<Map<String, dynamic>> recognize(List<Offset?> points) async {
    _recognizer ??= DigitalInkRecognizer(languageCode: _kLang);

    final ink = Ink()..strokes = _toStrokes(points);
    if (ink.strokes.isEmpty) {
      return {'kanji': '', 'confidence': 0.0, 'top10': <Map<String, dynamic>>[]};
    }

    final candidates = await _recognizer!.recognize(ink);
    // Keep only Japanese candidates (kanji + kana); drop romaji/latin letters,
    // digits and stray symbols the 'ja' model can emit.
    final filtered = candidates.where((c) => _isJapanese(c.text)).toList();
    // ML Kit returns candidates best-first; map to rank-based confidence.
    final top = filtered.take(10).toList();
    final weights = [for (var i = 0; i < top.length; i++) 1.0 / (i + 1)];
    final sum = weights.fold<double>(0.0, (a, b) => a + b);
    final top10 = <Map<String, dynamic>>[
      for (var i = 0; i < top.length; i++)
        {'kanji': top[i].text, 'confidence': sum > 0 ? weights[i] / sum : 0.0},
    ];

    return {
      'kanji': top10.isNotEmpty ? top10.first['kanji'] : '',
      'confidence': top10.isNotEmpty ? top10.first['confidence'] : 0.0,
      'top10': top10,
    };
  }

  // Hiragana, katakana (incl. ー), CJK ideographs (+ Ext A) and the iteration
  // mark 々. Excludes latin letters, digits and symbols.
  static final _jp =
      RegExp('^[々぀-ヿ㐀-䶿一-鿿]+\$');

  bool _isJapanese(String s) => s.isNotEmpty && _jp.hasMatch(s);

  /// Convert the draw-pad buffer to ML Kit strokes, synthesizing monotonic
  /// timestamps (we don't capture real ones; uniform spacing is sufficient).
  List<Stroke> _toStrokes(List<Offset?> points) {
    final strokes = <Stroke>[];
    var t = 0;
    var cur = <StrokePoint>[];
    for (final p in points) {
      if (p == null) {
        if (cur.isNotEmpty) strokes.add(Stroke()..points = cur);
        cur = <StrokePoint>[];
      } else {
        cur.add(StrokePoint(x: p.dx, y: p.dy, t: t));
        t += 10;
      }
    }
    if (cur.isNotEmpty) strokes.add(Stroke()..points = cur);
    return strokes;
  }
}
