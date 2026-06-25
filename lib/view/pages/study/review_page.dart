import 'package:flutter/material.dart';
import 'package:ivo/services/study/card_repository.dart';
import 'package:ivo/services/study/models/flashcard.dart';
import 'package:ivo/services/study/srs.dart';
import 'package:ivo/services/tts/tts_service.dart';

/// Anki-style review session for one deck: show front → reveal → grade.
class ReviewPage extends StatefulWidget {
  final int deckId;
  final String deckName;
  const ReviewPage({super.key, required this.deckId, required this.deckName});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  CardRepository? _repo;
  final List<Flashcard> _queue = [];
  bool _loading = true;
  bool _revealed = false;
  int _reviewed = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = await CardRepository.open();
    final due = await repo.dueCards(widget.deckId);
    if (!mounted) return;
    setState(() {
      _repo = repo;
      _queue
        ..clear()
        ..addAll(due);
      _loading = false;
    });
  }

  Future<void> _grade(Grade g) async {
    final card = _queue.removeAt(0);
    final updated = await _repo!.recordReview(card, g);
    _reviewed++;
    // "Again" cards stay due today → re-queue at the end of this session.
    if (g == Grade.again) _queue.add(updated);
    if (!mounted) return;
    setState(() => _revealed = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.deckName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _queue.isEmpty
              ? _buildDone()
              : _buildCard(_queue.first),
    );
  }

  Widget _buildDone() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          const Text('Дууслаа!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('$_reviewed карт давтлаа'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Буцах'),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Flashcard card) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Text('Үлдсэн: ${_queue.length}',
                  style: TextStyle(color: Colors.grey[600])),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      card.front,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 48, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up),
                      tooltip: 'Сонсох',
                      onPressed: () => TtsService.instance.speak(
                          card.reading.isNotEmpty ? card.reading : card.front),
                    ),
                    if (_revealed) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      if (card.reading.isNotEmpty)
                        Text(card.reading,
                            style: TextStyle(
                                fontSize: 22, color: Colors.grey[600])),
                      const SizedBox(height: 12),
                      Text(card.back,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20)),
                    ],
                  ],
                ),
              ),
            ),
            if (!_revealed)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => setState(() => _revealed = true),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Харах', style: TextStyle(fontSize: 16)),
                  ),
                ),
              )
            else
              Row(
                children: [
                  _gradeButton('Дахин', Grade.again, Colors.red),
                  _gradeButton('Хэцүү', Grade.hard, Colors.orange),
                  _gradeButton('Сайн', Grade.good, Colors.blue),
                  _gradeButton('Амар', Grade.easy, Colors.green),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _gradeButton(String label, Grade grade, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () => _grade(grade),
          child: Text(label, style: const TextStyle(fontSize: 14)),
        ),
      ),
    );
  }
}
