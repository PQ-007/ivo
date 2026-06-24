// File: lib/components/dictionary/drawing_keyboard.dart
import 'package:flutter/material.dart';
import 'package:ivo/components/dictionary/drawing_pad.dart';

class DrawingKeyboard extends StatelessWidget {
  final List<Map<String, dynamic>> recognitionResults;
  final Function(Map<String, dynamic>) onRecognitionComplete;
  final Function(String) onKanjiTap;
  final VoidCallback onClear;
  final VoidCallback onClose;

  const DrawingKeyboard({
    super.key,

    required this.onRecognitionComplete,
    required this.onKanjiTap,
    required this.onClear,
    required this.onClose,
    required this.recognitionResults,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DrawingHeader(onClose: onClose),
            // Recognition results carousel
            if (recognitionResults.isNotEmpty)
              _RecognitionCarousel(
                results: recognitionResults,
                onKanjiTap: onKanjiTap,
              ),

            // Drawing pad header

            // Drawing pad content
            Padding(
              padding: const EdgeInsets.all(16),
              child: DrawingPad(
                onRecognitionComplete: onRecognitionComplete,
                onClear: onClear,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecognitionCarousel extends StatelessWidget {
  final List<Map<String, dynamic>> results;
  final Function(String) onKanjiTap;

  const _RecognitionCarousel({required this.results, required this.onKanjiTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 72,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: results.length,
              itemBuilder: (context, index) {
                final result = results[index];

                return GestureDetector(
                  onTap: () => onKanjiTap(result['kanji']),
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        width: 2,
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                    ),
                    // Scale down so multi-character candidates (e.g. イ休)
                    // fit on one line without overflowing the chip.
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          result['kanji'],
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawingHeader extends StatelessWidget {
  final VoidCallback onClose;

  const _DrawingHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Зурж хайх',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, size: 28),
            onPressed: onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Хаах',
          ),
        ],
      ),
    );
  }
}
