// Verifies the offline KanjiVG + DTW handwriting recognizer end-to-end:
// asset parsing -> normalization -> resampling -> DTW ranking.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ivo/services/handwriting/stroke_recognizer.dart';

/// Parse a single character's normalized strokes directly from the .bin so we
/// can feed them back through the public recognizer and expect a top match.
List<List<Offset>>? _templateStrokes(String targetChar) {
  final bytes = File('assets/kanji_strokes.bin').readAsBytesSync();
  final bd = ByteData.sublistView(Uint8List.fromList(bytes));
  var off = 4; // skip "KVG1"
  final n = bd.getUint8(off);
  off += 1;
  final count = bd.getUint32(off, Endian.big);
  off += 4;
  for (var r = 0; r < count; r++) {
    final cp = bd.getUint32(off, Endian.big);
    off += 4;
    final sc = bd.getUint8(off);
    off += 1;
    final strokes = <List<Offset>>[];
    for (var s = 0; s < sc; s++) {
      final pts = <Offset>[];
      for (var p = 0; p < n; p++) {
        pts.add(Offset(bd.getUint8(off) / 255.0, bd.getUint8(off + 1) / 255.0));
        off += 2;
      }
      strokes.add(pts);
    }
    if (String.fromCharCode(cp) == targetChar) return strokes;
  }
  return null;
}

/// Flatten normalized strokes into the draw-pad buffer format (pixel-ish scale,
/// null between strokes) to simulate a real drawing.
List<Offset?> _asDrawing(List<List<Offset>> strokes, {double scale = 300}) {
  final out = <Offset?>[];
  for (final st in strokes) {
    for (final p in st) {
      out.add(Offset(p.dx * scale + 20, p.dy * scale + 20));
    }
    out.add(null);
  }
  return out;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('feeding a template back ranks that character #1', () async {
    for (final ch in ['水', '日', '愛', '一']) {
      final strokes = _templateStrokes(ch);
      expect(strokes, isNotNull, reason: '$ch missing from asset');
      final result =
          await StrokeRecognizer.instance.recognize(_asDrawing(strokes!));
      expect(result['kanji'], ch, reason: 'expected $ch as top match');
      expect((result['confidence'] as double), greaterThan(0.0));
    }
  });

  test('a hand-drawn horizontal line recognizes 一 in the top results',
      () async {
    // single left-to-right stroke
    final points = <Offset?>[
      const Offset(20, 160),
      const Offset(100, 158),
      const Offset(180, 159),
      const Offset(260, 160),
      const Offset(320, 161),
      null,
    ];
    final result = await StrokeRecognizer.instance.recognize(points);
    final top = (result['top10'] as List)
        .map((e) => (e as Map)['kanji'] as String)
        .toList();
    expect(top.contains('一'), isTrue, reason: 'top10 was $top');
  });

  test('empty input returns an empty result', () async {
    final result = await StrokeRecognizer.instance.recognize(<Offset?>[]);
    expect(result['kanji'], '');
    expect((result['top10'] as List), isEmpty);
  });
}
