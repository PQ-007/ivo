import 'package:flutter_test/flutter_test.dart';
import 'package:ivo/services/study/card_repository.dart';
import 'package:ivo/services/study/srs.dart';
import 'package:ivo/services/study/study_db.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  final now = DateTime(2026, 1, 1);

  test('create deck, add cards, due counts, good review reschedules', () async {
    final db = await StudyDB.openInMemory();
    final repo = CardRepository(db);

    final deckId = await repo.createDeck('JLPT N5');
    await repo.addCard(
        deckId: deckId,
        front: '水',
        reading: 'みず',
        back: 'water',
        source: 'dictionary',
        now: now);
    await repo.addCard(deckId: deckId, front: '火', back: 'fire', now: now);

    final decks = await repo.listDecks(now: now);
    expect(decks.length, 1);
    expect(decks.first.cardCount, 2);
    expect(decks.first.dueCount, 2); // both due immediately

    final due = await repo.dueCards(deckId, now: now);
    expect(due.length, 2);

    final updated = await repo.recordReview(due.first, Grade.good, now: now);
    expect(updated.intervalDays, 1);
    expect(updated.reps, 1);
    expect(await repo.dueCount(deckId, now: now), 1); // reviewed one not due now
    expect(await repo.dueCount(deckId, now: now.add(const Duration(days: 1))),
        2); // due again next day

    await db.close();
  });

  test('again keeps the card due the same day', () async {
    final db = await StudyDB.openInMemory();
    final repo = CardRepository(db);
    final deckId = await repo.createDeck('d');
    await repo.addCard(deckId: deckId, front: 'a', back: 'b', now: now);
    final due = await repo.dueCards(deckId, now: now);
    await repo.recordReview(due.first, Grade.again, now: now);
    expect(await repo.dueCount(deckId, now: now), 1);
    await db.close();
  });

  test('deleting a deck cascades its cards', () async {
    final db = await StudyDB.openInMemory();
    final repo = CardRepository(db);
    final deckId = await repo.createDeck('d');
    await repo.addCard(deckId: deckId, front: 'a', back: 'b');
    await repo.deleteDeck(deckId);
    expect((await repo.listDecks()).length, 0);
    expect((await db.query('card')).length, 0);
    await db.close();
  });
}
