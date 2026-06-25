// Local SQLite store for the Anki/SRS side (decks, cards, review history).
// Unlike JishoDB (which copies a bundled read-only asset), this DB is created
// empty on first run and written to as the user studies.

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class StudyDB {
  StudyDB._();

  static Database? _db;

  /// Open (creating if needed) the study database. Idempotent.
  static Future<Database> instance() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'study.db');
    _db = await openDatabase(
      path,
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createSchema,
    );
    return _db!;
  }

  static Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE deck (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE card (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        deck_id INTEGER NOT NULL REFERENCES deck(id) ON DELETE CASCADE,
        front TEXT NOT NULL,
        reading TEXT NOT NULL DEFAULT '',
        back TEXT NOT NULL,
        source TEXT NOT NULL DEFAULT 'manual',
        created_at INTEGER NOT NULL,
        reps INTEGER NOT NULL DEFAULT 0,
        ease REAL NOT NULL DEFAULT 2.5,
        interval_days INTEGER NOT NULL DEFAULT 0,
        due_at INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_card_deck ON card(deck_id)');
    await db.execute('CREATE INDEX idx_card_due ON card(due_at)');
    await db.execute('''
      CREATE TABLE review_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_id INTEGER NOT NULL REFERENCES card(id) ON DELETE CASCADE,
        grade INTEGER NOT NULL,
        interval_days INTEGER NOT NULL,
        reviewed_at INTEGER NOT NULL
      )
    ''');
  }

  /// For tests: open an in-memory database with the same schema.
  static Future<Database> openInMemory() async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createSchema,
    );
    return db;
  }

  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
