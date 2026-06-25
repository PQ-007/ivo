import '../srs.dart';

class Flashcard {
  final int? id;
  final int deckId;
  final String front; // Japanese term (kanji or reading)
  final String reading; // kana reading (may be empty)
  final String back; // meaning / translation
  final String source; // 'dictionary' | 'translate' | 'manual'
  final DateTime createdAt;

  // scheduling state
  final int reps;
  final double ease;
  final int intervalDays;
  final DateTime due;

  const Flashcard({
    this.id,
    required this.deckId,
    required this.front,
    this.reading = '',
    required this.back,
    this.source = 'manual',
    required this.createdAt,
    this.reps = 0,
    this.ease = 2.5,
    this.intervalDays = 0,
    required this.due,
  });

  SrsState get srsState =>
      SrsState(reps: reps, ease: ease, intervalDays: intervalDays);

  Map<String, Object?> toRow() => {
        if (id != null) 'id': id,
        'deck_id': deckId,
        'front': front,
        'reading': reading,
        'back': back,
        'source': source,
        'created_at': createdAt.millisecondsSinceEpoch,
        'reps': reps,
        'ease': ease,
        'interval_days': intervalDays,
        'due_at': due.millisecondsSinceEpoch,
      };

  factory Flashcard.fromRow(Map<String, Object?> row) => Flashcard(
        id: row['id'] as int?,
        deckId: row['deck_id'] as int,
        front: row['front'] as String,
        reading: (row['reading'] as String?) ?? '',
        back: row['back'] as String,
        source: (row['source'] as String?) ?? 'manual',
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
        reps: (row['reps'] as int?) ?? 0,
        ease: (row['ease'] as num?)?.toDouble() ?? 2.5,
        intervalDays: (row['interval_days'] as int?) ?? 0,
        due: DateTime.fromMillisecondsSinceEpoch(row['due_at'] as int),
      );
}
