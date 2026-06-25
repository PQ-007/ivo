// Data access for decks, cards and reviews. Pure DB logic (no UI), so it can be
// unit-tested against an in-memory database.

import 'package:sqflite/sqflite.dart';

import 'models/deck.dart';
import 'models/flashcard.dart';
import 'srs.dart';
import 'study_db.dart';

class CardRepository {
  final Database db;
  CardRepository(this.db);

  /// Default instance backed by the on-device study.db.
  static Future<CardRepository> open() async =>
      CardRepository(await StudyDB.instance());

  // ---- decks ----

  Future<int> createDeck(String name) => db.insert('deck', {
        'name': name,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });

  Future<void> renameDeck(int id, String name) =>
      db.update('deck', {'name': name}, where: 'id = ?', whereArgs: [id]);

  Future<void> deleteDeck(int id) =>
      db.delete('deck', where: 'id = ?', whereArgs: [id]);

  /// Decks with card counts and how many are due as of [now].
  Future<List<Deck>> listDecks({DateTime? now}) async {
    final t = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final rows = await db.rawQuery(
      '''
      SELECT d.id, d.name, d.created_at,
        (SELECT COUNT(*) FROM card c WHERE c.deck_id = d.id) AS card_count,
        (SELECT COUNT(*) FROM card c WHERE c.deck_id = d.id AND c.due_at <= ?)
          AS due_count
      FROM deck d
      ORDER BY d.created_at DESC
      ''',
      [t],
    );
    return rows.map(Deck.fromRow).toList();
  }

  // ---- cards ----

  /// Add a new card; it becomes due immediately (first study session).
  Future<int> addCard({
    required int deckId,
    required String front,
    String reading = '',
    required String back,
    String source = 'manual',
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final card = Flashcard(
      deckId: deckId,
      front: front,
      reading: reading,
      back: back,
      source: source,
      createdAt: t,
      due: t,
    );
    return db.insert('card', card.toRow());
  }

  Future<int> dueCount(int deckId, {DateTime? now}) async {
    final t = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final c = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM card WHERE deck_id = ? AND due_at <= ?',
      [deckId, t],
    ));
    return c ?? 0;
  }

  /// Cards due for review in [deckId], soonest first.
  Future<List<Flashcard>> dueCards(int deckId, {DateTime? now, int? limit}) async {
    final t = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final rows = await db.query(
      'card',
      where: 'deck_id = ? AND due_at <= ?',
      whereArgs: [deckId, t],
      orderBy: 'due_at ASC',
      limit: limit,
    );
    return rows.map(Flashcard.fromRow).toList();
  }

  /// Apply a review grade: reschedule the card and log it.
  Future<Flashcard> recordReview(Flashcard card, Grade grade,
      {DateTime? now}) async {
    final res = schedule(card.srsState, grade, now: now);
    await db.update(
      'card',
      {
        'reps': res.reps,
        'ease': res.ease,
        'interval_days': res.intervalDays,
        'due_at': res.due.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [card.id],
    );
    await db.insert('review_log', {
      'card_id': card.id,
      'grade': grade.index,
      'interval_days': res.intervalDays,
      'reviewed_at': (now ?? DateTime.now()).millisecondsSinceEpoch,
    });
    return Flashcard.fromRow(
      (await db.query('card', where: 'id = ?', whereArgs: [card.id])).first,
    );
  }
}
