// File: lib/components/dictionary/MyDrawingPad.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ivo/services/handwriting/handwriting_service.dart';

class DrawingPad extends StatefulWidget {
  final Function(Map<String, dynamic>)? onRecognitionComplete;
  final Function onClear;
  const DrawingPad({
    super.key,
    required this.onClear,
    this.onRecognitionComplete,
  });

  @override
  State<DrawingPad> createState() => _DrawingPadState();
}

class _DrawingPadState extends State<DrawingPad> {
  List<Offset?> _drawingPoints = [];
  bool _showGrid = true;
  bool _isProcessing = false;
  bool _pending = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Warm up engines: offline templates always, plus the ink model if online.
    HandwritingService.instance.warmUp();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // Recognize automatically a short moment after the last stroke, so fast
  // multi-stroke writing doesn't fire the recognizer on every stroke.
  void _scheduleRecognition() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _recognize);
  }

  Future<void> _recognize() async {
    if (_drawingPoints.isEmpty) return;
    // Guard against overlapping calls; re-run once if strokes changed meanwhile.
    if (_isProcessing) {
      _pending = true;
      return;
    }
    _isProcessing = true;
    try {
      final result =
          await HandwritingService.instance.recognize(_drawingPoints);
      widget.onRecognitionComplete?.call(result);
    } catch (e) {
      debugPrint('Handwriting recognition error: $e');
    } finally {
      _isProcessing = false;
      if (_pending) {
        _pending = false;
        _scheduleRecognition();
      }
    }
  }

  void _clearDrawing() {
    _debounce?.cancel();
    setState(() {
      _drawingPoints = [];
    });
    widget.onClear(); // also clear the recognition carousel
  }

  void _toggleGrid() {
    setState(() {
      _showGrid = !_showGrid;
    });
  }

  int _countStrokes() {
    int count = 0;
    for (int i = 0; i < _drawingPoints.length; i++) {
      if (i == 0 && _drawingPoints[i] != null) {
        count++;
      } else if (i > 0 &&
          _drawingPoints[i] != null &&
          _drawingPoints[i - 1] == null) {
        count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                width: 1,
                color: isDark ? Colors.white : Colors.black12,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                children: [
                  if (_showGrid)
                    CustomPaint(
                      painter: _QuadraticGridPainter(isDark: isDark),
                      size: Size.infinite,
                    ),

                  // Drawing area
                  Listener(
                    onPointerDown: (event) {
                      setState(() {
                        _drawingPoints = List.from(_drawingPoints)
                          ..add(event.localPosition);
                      });
                    },
                    onPointerMove: (event) {
                      setState(() {
                        _drawingPoints = List.from(_drawingPoints)
                          ..add(event.localPosition);
                      });
                    },
                    onPointerUp: (event) {
                      setState(() {
                        _drawingPoints = List.from(_drawingPoints)..add(null);
                      });
                      _scheduleRecognition();
                    },
                    child: CustomPaint(
                      painter: _DrawingPainter(_drawingPoints, isDark: isDark),
                      size: Size.infinite,
                    ),
                  ),

                  if (_drawingPoints.isEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.draw_outlined, size: 56),
                          const SizedBox(height: 12),
                          Text(
                            'Хайх ханзаа зурна уу',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Дөрвөлжинг дүүргэж зураарай!',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),

                  Positioned(top: 8, left: 8, child: _buildGridToggle()),

                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: _buildActionButton(
                      icon: Icons.refresh,
                      label: 'Устгах',
                      onPressed: _clearDrawing,
                      isPrimary: false,
                    ),
                  ),

                  if (_drawingPoints.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.gesture, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              '${_countStrokes()} зурлага',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridToggle() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: _toggleGrid,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(_showGrid ? Icons.grid_4x4 : Icons.grid_off, size: 20),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required bool isPrimary,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _QuadraticGridPainter extends CustomPainter {
  final bool isDark;
  _QuadraticGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final plusPaint =
        Paint()
          ..color = isDark ? Colors.white12 : Colors.black12
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      plusPaint,
    );
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), plusPaint);
  }

  @override
  bool shouldRepaint(_QuadraticGridPainter oldDelegate) => false;
}

class _DrawingPainter extends CustomPainter {
  final List<Offset?> points;
  final bool isDark;

  _DrawingPainter(this.points, {required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint =
        Paint()
          ..color = isDark ? Colors.white : Colors.black
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 5.0
          ..style = PaintingStyle.stroke;

    for (int i = 1; i < points.length; i++) {
      final current = points[i];
      final previous = points[i - 1];
      if (current != null && previous != null) {
        canvas.drawLine(previous, current, linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(_DrawingPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.isDark != isDark;
}
