import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class JishoDB {
  static Database? _wordDb;
  static Database? _kanjiDb;

  // Simple in-memory entry cache (capped at 200 entries)
  static final Map<int, Map<String, dynamic>> _entryCache = {};
  static const int _cacheMaxSize = 200;

  static Future<void> init() async {
    _wordDb = await _initDatabase('jmdict.db');
    _kanjiDb = await _initDatabase('kanji.db');
  }

  static Future<Database> _initDatabase(String dbName) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, dbName);
    final file = File(path);
    final exists = await file.exists();
    if (!exists) {
      final data = await rootBundle.load('assets/db/$dbName');
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await file.writeAsBytes(bytes, flush: true);
      print('Copied $dbName from assets');
    }
    final db = await openDatabase(path, readOnly: false);
    await _createIndexesAndFTS(db, dbName);
    return db;
  }

  /// Create indexes and FTS tables
  static Future<void> _createIndexesAndFTS(Database db, String dbName) async {
    try {
      if (dbName == 'jmdict.db') {
        // Indexes for exact/prefix matches
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_k_ele_keb ON k_ele(keb);
        ''');
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_r_ele_reb ON r_ele(reb);
        ''');
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_gloss_content ON gloss(content COLLATE NOCASE);
        ''');

        // FTS virtual table (regular, not external; multiple rows per entry for keb/reb/gloss)
        await db.execute('''
          CREATE VIRTUAL TABLE IF NOT EXISTS words_fts USING fts5(
            entry_id UNINDEXED, keb, reb, gloss,
            tokenize='unicode61'
          );
        ''');

        // Populate FTS if empty
        final count =
            Sqflite.firstIntValue(
              await db.rawQuery('SELECT count(*) FROM words_fts'),
            ) ??
            0;
        if (count == 0) {
          // Insert keb terms
          await db.execute('''
            INSERT INTO words_fts(entry_id, keb)
            SELECT entry.id, k_ele.keb
            FROM entry JOIN k_ele ON entry.id = k_ele.id_entry
          ''');
          // Insert reb terms
          await db.execute('''
            INSERT INTO words_fts(entry_id, reb)
            SELECT entry.id, r_ele.reb
            FROM entry JOIN r_ele ON entry.id = r_ele.id_entry
          ''');
          // Insert gloss terms
          await db.execute('''
            INSERT INTO words_fts(entry_id, gloss)
            SELECT sense.id_entry, gloss.content
            FROM sense JOIN gloss ON sense.id = gloss.id_sense
          ''');
          final newCount =
              Sqflite.firstIntValue(
                await db.rawQuery('SELECT count(*) FROM words_fts'),
              ) ??
              0;
          print('Populated words_fts with $newCount entries');
        }
      } else if (dbName == 'kanji.db') {
        // Simple index for kanji ID (TEXT primary key for exact lookups; FTS removed to avoid schema issues)
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_character_id ON character(id);',
        );
        print('Created index for kanji.db');
      }
    } catch (e) {
      print('Error creating indexes/FTS for $dbName: $e');
    }
  }

  /// Universal search (Takoboto-style)
  static Future<Map<String, dynamic>> search(String input) async {
    if (input.trim().isEmpty) return {'type': 'empty', 'result': []};
    final trimmed = input.trim();
    // Single kanji character lookup
    if (_isSingleKanji(trimmed)) {
      final kanji = await _searchKanji(trimmed);
      return {
        'type': 'kanji',
        'result': kanji != null ? [kanji] : [],
      };
    }
    // Convert romaji to hiragana if needed
    String searchQuery = trimmed;
    if (_shouldConvertRomaji(trimmed)) {
      searchQuery = _romajiToHiragana(trimmed);
      print('Converted "$trimmed" → "$searchQuery"');
    }
    // Determine search type and execute
    final words = await _searchWords(searchQuery, trimmed);
    return {'type': 'word', 'result': words};
  }

  /// Main word search with Takoboto-style prioritization (optimized with FTS and batching)
  static Future<List<Map<String, dynamic>>> _searchWords(
    String query,
    String originalQuery,
  ) async {
    final db = _wordDb!;
    final Set<int> seenIds = {};
    final List<Map<String, dynamic>> results = [];
    final List<int> candidateIds = []; // Collect IDs first for batching

    void addCandidates(List<Map<String, dynamic>> candidates) {
      for (var row in candidates) {
        final entryId = row['entry_id'] as int;
        if (!seenIds.contains(entryId) && candidateIds.length < 50) {
          // Cap candidates
          seenIds.add(entryId);
          candidateIds.add(entryId);
        }
      }
    }

    // For Japanese input (kanji, hiragana, katakana)
    if (_isJapanese(query)) {
      await _searchJapanese(db, query, addCandidates, seenIds);
    }
    // For English input
    if (!_isJapanese(originalQuery)) {
      await _searchEnglish(db, originalQuery, addCandidates, seenIds);
    }

    // Batch-fetch details for unique candidates (5 queries instead of N×7)
    if (candidateIds.isNotEmpty) {
      final details = await _batchGetEntryDetails(candidateIds.take(30).toList());
      results.addAll(details);
    }

    return results;
  }

  /// Search in Japanese (optimized: exact/indexed, prefix/contains via FTS)
  static Future<void> _searchJapanese(
    Database db,
    String query,
    Function(List<Map<String, dynamic>>)
    addCandidates, // Now takes list of rows
    Set<int> seenIds,
  ) async {
    try {
      // Priority 1: EXACT match (use indexes)
      final exactMatches = await db.rawQuery(
        '''
        SELECT DISTINCT entry.id AS entry_id
        FROM entry
        JOIN r_ele ON entry.id = r_ele.id_entry
        LEFT JOIN k_ele ON entry.id = k_ele.id_entry
        WHERE r_ele.reb = ? OR k_ele.keb = ?
        ORDER BY entry.id
        LIMIT 20
        ''',
        [query, query],
      );
      addCandidates(exactMatches);

      // Priority 2 & 3: Prefix and contains via FTS (combined for efficiency)
      if (seenIds.length < 30) {
        // FTS query: prefix with *, contains implicit (use OR for keb/reb)
        final ftsMatches = await db.rawQuery(
          '''
          SELECT DISTINCT entry_id
          FROM words_fts
          WHERE words_fts MATCH ?
          ORDER BY rank
          LIMIT 30
          ''',
          [
            'keb:$query* OR reb:$query*',
          ], // Focus on keb/reb for Japanese; prefix for starts-with, implicit for contains
        );
        addCandidates(ftsMatches);
      }
    } catch (e) {
      print('Error in Japanese search: $e');
    }
  }

  /// Search in English (optimized: exact/indexed, prefix/contains via FTS)
  static Future<void> _searchEnglish(
    Database db,
    String query,
    Function(List<Map<String, dynamic>>) addCandidates,
    Set<int> seenIds,
  ) async {
    try {
      final lowerQuery = query.toLowerCase();
      // Priority 1: Exact gloss match (use index)
      final exactGloss = await db.rawQuery(
        '''
        SELECT DISTINCT entry.id AS entry_id
        FROM entry
        JOIN sense ON entry.id = sense.id_entry
        JOIN gloss ON gloss.id_sense = sense.id
        WHERE LOWER(gloss.content) = ?
        ORDER BY entry.id
        LIMIT 20
        ''',
        [lowerQuery],
      );
      addCandidates(exactGloss);

      // Priority 2 & 3: Prefix and contains via FTS
      if (seenIds.length < 30) {
        final ftsMatches = await db.rawQuery(
          '''
          SELECT DISTINCT entry_id
          FROM words_fts
          WHERE words_fts MATCH ?
          ORDER BY rank
          LIMIT 30
          ''',
          [
            'gloss:$lowerQuery* OR gloss:$lowerQuery',
          ], // Prefix * and simple term for contains
        );
        addCandidates(ftsMatches);
      }
    } catch (e) {
      print('Error in English search: $e');
    }
  }

  /// Kanji lookup with radicals (reverted to direct indexed query for reliability)
  static Future<Map<String, dynamic>?> _searchKanji(String kanji) async {
    final db = _kanjiDb!;
    try {
      // Direct exact match on indexed id (TEXT primary key)
      final charList = await db.rawQuery(
        'SELECT * FROM character WHERE id = ? LIMIT 1',
        [kanji],
      );
      if (charList.isEmpty) return null;
      final char = charList.first;

      // Get radicals
      final radicals = await db.rawQuery(
        '''
        SELECT radical.*
        FROM radical
        JOIN character_radical ON character_radical.id_radical = radical.id
        WHERE character_radical.id_character = ?
        ORDER BY stroke_count
        ''',
        [kanji],
      );
      // Get readings
      final onYomi = await db.rawQuery(
        'SELECT reading FROM on_yomi WHERE id_character = ?',
        [kanji],
      );
      final kunYomi = await db.rawQuery(
        'SELECT reading FROM kun_yomi WHERE id_character = ?',
        [kanji],
      );
      // Get meanings
      final meanings = await db.rawQuery(
        'SELECT content FROM meaning WHERE id_character = ?',
        [kanji],
      );

      return {
        'character': kanji,
        'stroke_count': char['stroke_count'],
        'grade': char['grade'],
        'frequency': char['frequency'],
        'jlpt': char['jlpt'],
        'radicals':
            radicals
                .map(
                  (r) => {
                    'radical': r['id'],
                    'stroke_count': r['stroke_count'],
                  },
                )
                .toList(),
        'on_yomi': onYomi.map((r) => r['reading']).toList(),
        'kun_yomi': kunYomi.map((r) => r['reading']).toList(),
        'meanings': meanings.map((m) => m['content']).toList(),
      };
    } catch (e) {
      print('Error searching kanji: $e');
      return null;
    }
  }

  // Type detection helpers
  static bool _isSingleKanji(String s) =>
      s.length == 1 && RegExp(r'[\u4E00-\u9FFF]').hasMatch(s);

  static bool _isJapanese(String s) => RegExp(
    r'^[\u3000-\u303F\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF\uFF00-\uFFEF]+$',
  ).hasMatch(s);

  static bool _shouldConvertRomaji(String s) {
    // reject if it has Japanese chars
    if (_isJapanese(s)) return false;
    final lower = s.toLowerCase().trim();
    // If it contains spaces and looks like an English sentence, skip conversion
    if (RegExp(r'\s').hasMatch(lower) && lower.split(' ').length > 1) {
      return false;
    }
    // Common English words filter (keep it small)
    const englishWords = {
      'love',
      'like',
      'eat',
      'see',
      'thank',
      'apple',
      'book',
      'computer',
      'school',
      'good',
      'bad',
      'time',
      'when',
      'where',
      'who',
      'what',
      'how',
      'make',
      'go',
    };
    if (englishWords.contains(lower)) return false;
    // Romaji pattern check: only lowercase a-z and maybe apostrophes
    if (!RegExp(r"^[a-z']+$").hasMatch(lower)) return false;
    // Japanese romaji typically follow (C)V pattern: consonant + vowel
    // We'll check if the text is made mostly of such syllables. Updated to allow standalone 'n'
    final syllablePattern = RegExp(
      r'^(?:[kstnhmyrwgzdbpfcjv]*[aiueo]|n|nn)+$',
      caseSensitive: false,
    );
    if (syllablePattern.hasMatch(lower)) {
      return true; // looks like valid romaji
    }
    // Bonus: heuristic — short words (<=4 letters) are ambiguous,
    // but if they contain Japanese-like chunks, treat as romaji. Expanded for more romaji patterns
    if (lower.length <= 4 &&
        RegExp(
          r'(ka|ki|ku|ke|ko|ga|gi|gu|ge|go|sa|shi|su|se|so|za|ji|zu|ze|zo|ta|te|to|da|di|du|de|do|na|ni|nu|ne|no|ha|hi|fu|he|ho|ba|bi|bu|be|bo|pa|pi|pu|pe|po|ma|mi|mu|me|mo|ya|yu|yo|ra|ri|ru|re|ro|wa|wo|nn|ja|ju|jo|tsu|cha|chi|sha|shu|shi|nya|nyu|nyo|hya|hyu|hyo|mya|myu|myo|rya|ryu|ryo|kya|kyu|kyo|gya|gyu|gyo|bya|byu|byo|pya|pyu|pyo)',
        ).hasMatch(lower)) {
      return true;
    }
    return false;
  }

  /// Romaji to hiragana conversion (updated with missing 'ja', 'ju', 'jo' mappings)
  static String _romajiToHiragana(String romaji) {
    final map = {
      'kya': 'きゃ',
      'kyu': 'きゅ',
      'kyo': 'きょ',
      'sha': 'しゃ',
      'shu': 'しゅ',
      'sho': 'しょ',
      'shi': 'し',
      'cha': 'ちゃ',
      'chu': 'ちゅ',
      'cho': 'ちょ',
      'chi': 'ち',
      'nya': 'にゃ',
      'nyu': 'にゅ',
      'nyo': 'にょ',
      'hya': 'ひゃ',
      'hyu': 'ひゅ',
      'hyo': 'ひょ',
      'mya': 'みゃ',
      'myu': 'みゅ',
      'myo': 'みょ',
      'rya': 'りゃ',
      'ryu': 'りゅ',
      'ryo': 'りょ',
      'gya': 'ぎゃ',
      'gyu': 'ぎゅ',
      'gyo': 'ぎょ',
      'bya': 'びゃ',
      'byu': 'びゅ',
      'byo': 'びょ',
      'pya': 'ぴゃ',
      'pyu': 'ぴゅ',
      'pyo': 'ぴょ',
      'ja': 'じゃ', // Added for 'ja'
      'ju': 'じゅ', // Added for 'ju'
      'jo': 'じょ', // Added for 'jo'
      'tsu': 'つ',
      'ka': 'か',
      'ki': 'き',
      'ku': 'く',
      'ke': 'け',
      'ko': 'こ',
      'ga': 'が',
      'gi': 'ぎ',
      'gu': 'ぐ',
      'ge': 'げ',
      'go': 'ご',
      'sa': 'さ',
      'su': 'す',
      'se': 'せ',
      'so': 'そ',
      'za': 'ざ',
      'ji': 'じ',
      'zu': 'ず',
      'ze': 'ぜ',
      'zo': 'ぞ',
      'ta': 'た',
      'te': 'て',
      'to': 'と',
      'da': 'だ',
      'di': 'ぢ',
      'du': 'づ',
      'de': 'で',
      'do': 'ど',
      'na': 'な',
      'ni': 'に',
      'nu': 'ぬ',
      'ne': 'ね',
      'no': 'の',
      'ha': 'は',
      'hi': 'ひ',
      'fu': 'ふ',
      'he': 'へ',
      'ho': 'ほ',
      'ba': 'ば',
      'bi': 'び',
      'bu': 'ぶ',
      'be': 'べ',
      'bo': 'ぼ',
      'pa': 'ぱ',
      'pi': 'ぴ',
      'pu': 'ぷ',
      'pe': 'ぺ',
      'po': 'ぽ',
      'ma': 'ま',
      'mi': 'み',
      'mu': 'む',
      'me': 'め',
      'mo': 'も',
      'ya': 'や',
      'yu': 'ゆ',
      'yo': 'よ',
      'ra': 'ら',
      'ri': 'り',
      'ru': 'る',
      're': 'れ',
      'ro': 'ろ',
      'wa': 'わ',
      'wo': 'を',
      'nn': 'ん',
      'a': 'あ',
      'i': 'い',
      'u': 'う',
      'e': 'え',
      'o': 'お',
      'n': 'ん',
    };
    String result = romaji.toLowerCase();
    final sortedKeys =
        map.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
    for (var key in sortedKeys) {
      result = result.replaceAll(key, map[key]!);
    }
    return result;
  }

  static Future<void> close() async {
    await _wordDb?.close();
    await _kanjiDb?.close();
  }

  /// Returns a random dictionary entry for the "Word of the Day" widget.
  static Future<Map<String, dynamic>?> getRandomWord() async {
    final db = _wordDb;
    if (db == null) return null;
    try {
      // Pick a random entry that has both a kanji form and at least one gloss
      final rows = await db.rawQuery('''
        SELECT DISTINCT e.id
        FROM entry e
        JOIN k_ele k ON k.id_entry = e.id
        JOIN sense s ON s.id_entry = e.id
        JOIN gloss g ON g.id_sense = s.id
        ORDER BY RANDOM()
        LIMIT 1
      ''');
      if (rows.isEmpty) return null;
      final entryId = rows.first['id'] as int;
      final results = await _batchGetEntryDetails([entryId]);
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      return null;
    }
  }

  /// Batch-fetch full entry details for multiple IDs in 5 queries instead of N×7.
  /// Results are cached in [_entryCache].
  static Future<List<Map<String, dynamic>>> _batchGetEntryDetails(
      List<int> ids) async {
    final db = _wordDb!;
    if (ids.isEmpty) return [];

    // Serve from cache where possible
    final uncachedIds = <int>[];
    final fromCache = <int, Map<String, dynamic>>{};
    for (final id in ids) {
      if (_entryCache.containsKey(id)) {
        fromCache[id] = _entryCache[id]!;
      } else {
        uncachedIds.add(id);
      }
    }

    if (uncachedIds.isNotEmpty) {
      final ph = uncachedIds.map((_) => '?').join(',');

      // 1. Kanji forms
      final kanjiRows = await db.rawQuery(
        'SELECT id_entry, keb FROM k_ele WHERE id_entry IN ($ph) ORDER BY id',
        uncachedIds,
      );
      // 2. Reading forms
      final readingRows = await db.rawQuery(
        'SELECT id_entry, reb FROM r_ele WHERE id_entry IN ($ph) ORDER BY id',
        uncachedIds,
      );
      // 3. Sense IDs
      final senseRows = await db.rawQuery(
        'SELECT id, id_entry FROM sense WHERE id_entry IN ($ph) ORDER BY id_entry, id',
        uncachedIds,
      );

      final kanjiByEntry = <int, List<String>>{};
      for (final r in kanjiRows) {
        kanjiByEntry
            .putIfAbsent(r['id_entry'] as int, () => [])
            .add(r['keb'] as String);
      }
      final readingByEntry = <int, List<String>>{};
      for (final r in readingRows) {
        readingByEntry
            .putIfAbsent(r['id_entry'] as int, () => [])
            .add(r['reb'] as String);
      }

      final sensesByEntry = <int, List<Map<String, dynamic>>>{};

      if (senseRows.isNotEmpty) {
        final senseIds = senseRows.map((r) => r['id'] as int).toList();
        final sPh = senseIds.map((_) => '?').join(',');

        // 4. Glosses
        final glossRows = await db.rawQuery(
          'SELECT id_sense, content FROM gloss WHERE id_sense IN ($sPh)',
          senseIds,
        );
        // 5. POS
        final posRows = await db.rawQuery(
          '''SELECT sp.id_sense, p.name
             FROM sense_pos sp
             JOIN pos p ON p.id = sp.id_pos
             WHERE sp.id_sense IN ($sPh)''',
          senseIds,
        );

        final glossBySense = <int, List<String>>{};
        for (final r in glossRows) {
          glossBySense
              .putIfAbsent(r['id_sense'] as int, () => [])
              .add(r['content'] as String);
        }
        final posBySense = <int, List<String>>{};
        for (final r in posRows) {
          posBySense
              .putIfAbsent(r['id_sense'] as int, () => [])
              .add(r['name'] as String);
        }

        for (final r in senseRows) {
          final senseId = r['id'] as int;
          final entryId = r['id_entry'] as int;
          sensesByEntry.putIfAbsent(entryId, () => []).add({
            'pos': posBySense[senseId] ?? [],
            'glosses': glossBySense[senseId] ?? [],
            'misc': <String>[],
            'dial': <String>[],
          });
        }
      }

      // Cache and collect results
      for (final id in uncachedIds) {
        final k = kanjiByEntry[id] ?? [];
        final r = readingByEntry[id] ?? [];
        if (k.isEmpty && r.isEmpty) continue;
        final entry = {
          'id': id,
          'kanji': k,
          'reading': r,
          'senses': sensesByEntry[id] ?? [],
        };
        if (_entryCache.length >= _cacheMaxSize) {
          _entryCache.remove(_entryCache.keys.first);
        }
        _entryCache[id] = entry;
        fromCache[id] = entry;
      }
    }

    // Return in original order, skipping any that had no data
    return ids
        .map((id) => fromCache[id])
        .whereType<Map<String, dynamic>>()
        .toList();
  }
}
