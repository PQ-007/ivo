// Offline handwriting recognition via KanjiVG stroke templates + DTW matching.
//
// Pure Dart, no native plugins and no neural net. Templates are built offline by
// tool/build_kanji_strokes.py from KanjiVG (CC BY-SA 3.0) into
// assets/kanji_strokes.bin. At runtime we normalize the drawn strokes the same
// way, then rank candidate characters by Dynamic Time Warping distance,
// pre-filtered by stroke count for speed.
//
// Output contract (consumed by drawing_keyboard.dart / dictionary page):
//   { 'kanji': String, 'confidence': double,
//     'top10': [ { 'kanji': String, 'confidence': double }, ... ] }

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/services.dart' show rootBundle;

const int _kPointsPerStroke = 16; // must match tool/build_kanji_strokes.py
const String _kAsset = 'assets/kanji_strokes.bin';

class _Template {
  final String char;
  final List<List<Offset>> strokes; // each stroke: _kPointsPerStroke points in [0,1]
  _Template(this.char, this.strokes);
}

class StrokeRecognizer {
  StrokeRecognizer._();
  static final StrokeRecognizer instance = StrokeRecognizer._();

  // Templates bucketed by stroke count for fast candidate filtering.
  final Map<int, List<_Template>> _byStrokeCount = {};
  bool _loaded = false;
  Future<void>? _loading;

  bool get isLoaded => _loaded;

  /// Parse the binary asset once. Safe to call repeatedly.
  Future<void> load() {
    if (_loaded) return Future.value();
    return _loading ??= _doLoad();
  }

  Future<void> _doLoad() async {
    final data = await rootBundle.load(_kAsset);
    final bytes = data.buffer.asByteData();
    int off = 0;

    // header: "KVG1" | N (u8) | recordCount (u32 BE)
    final magic = String.fromCharCodes(
      [for (var i = 0; i < 4; i++) bytes.getUint8(off + i)],
    );
    off += 4;
    if (magic != 'KVG1') {
      throw StateError('Bad stroke asset magic: $magic');
    }
    final n = bytes.getUint8(off);
    off += 1;
    final count = bytes.getUint32(off, Endian.big);
    off += 4;

    for (var r = 0; r < count; r++) {
      final cp = bytes.getUint32(off, Endian.big);
      off += 4;
      final strokeCount = bytes.getUint8(off);
      off += 1;
      final strokes = <List<Offset>>[];
      for (var s = 0; s < strokeCount; s++) {
        final pts = <Offset>[];
        for (var p = 0; p < n; p++) {
          final x = bytes.getUint8(off) / 255.0;
          final y = bytes.getUint8(off + 1) / 255.0;
          off += 2;
          pts.add(Offset(x, y));
        }
        strokes.add(pts);
      }
      _byStrokeCount
          .putIfAbsent(strokeCount, () => <_Template>[])
          .add(_Template(String.fromCharCode(cp), strokes));
    }
    _loaded = true;
  }

  /// Recognize a drawing. [points] is the draw-pad buffer: a flat list where
  /// `null` separates strokes (the format drawing_pad.dart already produces).
  Future<Map<String, dynamic>> recognize(List<Offset?> points) async {
    await load();

    final drawn = _normalize(_splitStrokes(points));
    if (drawn.isEmpty) {
      return {'kanji': '', 'confidence': 0.0, 'top10': <Map<String, dynamic>>[]};
    }

    final dn = drawn.length;
    // Primary candidates: same stroke count. Widen to +/-1 if too few.
    final candidates = <_Template>[...(_byStrokeCount[dn] ?? const [])];
    if (candidates.length < 20) {
      candidates.addAll(_byStrokeCount[dn - 1] ?? const []);
      candidates.addAll(_byStrokeCount[dn + 1] ?? const []);
    }

    final scored = <MapEntry<_Template, double>>[];
    for (final t in candidates) {
      scored.add(MapEntry(t, _score(drawn, t.strokes)));
    }
    scored.sort((a, b) => a.value.compareTo(b.value)); // ascending distance

    final top = scored.take(10).toList();
    // distance -> pseudo-confidence, normalized so the shown set sums to ~1.
    final weights = [for (final e in top) 1.0 / (1.0 + e.value)];
    final sum = weights.fold<double>(0.0, (a, b) => a + b);
    final top10 = <Map<String, dynamic>>[
      for (var i = 0; i < top.length; i++)
        {
          'kanji': top[i].key.char,
          'confidence': sum > 0 ? weights[i] / sum : 0.0,
        },
    ];

    return {
      'kanji': top10.isNotEmpty ? top10.first['kanji'] : '',
      'confidence': top10.isNotEmpty ? top10.first['confidence'] : 0.0,
      'top10': top10,
    };
  }

  /// Total match cost: average per-paired-stroke DTW plus a stroke-count penalty.
  double _score(List<List<Offset>> a, List<List<Offset>> b) {
    final pairs = math.min(a.length, b.length);
    var total = 0.0;
    for (var i = 0; i < pairs; i++) {
      total += _dtw(a[i], b[i]);
    }
    final avg = total / pairs;
    final countPenalty = (a.length - b.length).abs() * 0.5;
    return avg + countPenalty;
  }

  // ---- geometry helpers (mirror tool/build_kanji_strokes.py) ----

  List<List<Offset>> _splitStrokes(List<Offset?> points) {
    final strokes = <List<Offset>>[];
    var cur = <Offset>[];
    for (final p in points) {
      if (p == null) {
        if (cur.isNotEmpty) strokes.add(cur);
        cur = <Offset>[];
      } else {
        cur.add(p);
      }
    }
    if (cur.isNotEmpty) strokes.add(cur);
    return strokes;
  }

  /// Translate+uniform-scale all strokes into [0,1] (aspect preserved), then
  /// resample each stroke to _kPointsPerStroke arc-length-spaced points.
  List<List<Offset>> _normalize(List<List<Offset>> strokes) {
    if (strokes.isEmpty) return const [];
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final st in strokes) {
      for (final p in st) {
        minX = math.min(minX, p.dx);
        minY = math.min(minY, p.dy);
        maxX = math.max(maxX, p.dx);
        maxY = math.max(maxY, p.dy);
      }
    }
    final scale = 1.0 / math.max(math.max(maxX - minX, maxY - minY), 1e-6);
    return [
      for (final st in strokes)
        _resample([
          for (final p in st) Offset((p.dx - minX) * scale, (p.dy - minY) * scale),
        ]),
    ];
  }

  List<Offset> _resample(List<Offset> stroke) {
    if (stroke.isEmpty) {
      return List.filled(_kPointsPerStroke, Offset.zero);
    }
    // cumulative arc length
    final cum = <double>[0.0];
    for (var i = 1; i < stroke.length; i++) {
      cum.add(cum[i - 1] + (stroke[i] - stroke[i - 1]).distance);
    }
    final total = cum.last;
    if (total < 1e-6) {
      return List.filled(_kPointsPerStroke, stroke.first); // a dot
    }
    final out = <Offset>[];
    var seg = 0;
    for (var i = 0; i < _kPointsPerStroke; i++) {
      final target = total * (i / (_kPointsPerStroke - 1));
      while (seg < cum.length - 2 && cum[seg + 1] < target) {
        seg++;
      }
      final segLen = cum[seg + 1] - cum[seg];
      final t = segLen < 1e-9 ? 0.0 : (target - cum[seg]) / segLen;
      out.add(Offset.lerp(stroke[seg], stroke[seg + 1], t)!);
    }
    return out;
  }

  /// Dynamic Time Warping distance between two equal-length point sequences.
  double _dtw(List<Offset> a, List<Offset> b) {
    final n = a.length, m = b.length;
    final prev = List<double>.filled(m + 1, double.infinity);
    final cur = List<double>.filled(m + 1, double.infinity);
    prev[0] = 0.0;
    for (var i = 1; i <= n; i++) {
      cur[0] = double.infinity;
      for (var j = 1; j <= m; j++) {
        final cost = (a[i - 1] - b[j - 1]).distance;
        cur[j] = cost +
            math.min(prev[j], math.min(cur[j - 1], prev[j - 1]));
      }
      for (var j = 0; j <= m; j++) {
        prev[j] = cur[j];
      }
    }
    return prev[m] / (n + m); // normalize by path length
  }
}
