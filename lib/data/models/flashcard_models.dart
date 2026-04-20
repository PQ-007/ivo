// lib/models/flashcard_models.dart

class FlashcardFolder {
  final String id;
  final String name;
  final String? description;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  FlashcardFolder({
    required this.id,
    required this.name,
    this.description,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });
}

class FlashcardDeck {
  final int id;
  final String ownerId;
  final String name;
  final String slug;
  final String? description;
  final bool isPublic;
  final int? clonedFromDeckId;
  final int cardCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  FlashcardDeck({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.slug,
    this.description,
    this.isPublic = false,
    this.clonedFromDeckId,
    this.cardCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FlashcardDeck.fromJson(Map<String, dynamic> json) {
    return FlashcardDeck(
      id: json['id'] as int,
      ownerId: (json['owner_id'] ?? json['user_id'] ?? '') as String,
      name: json['name'] as String,
      slug: (json['slug'] ?? '') as String,
      description: json['description'] as String?,
      isPublic: json['is_public'] as bool? ?? false,
      clonedFromDeckId: json['cloned_from_deck_id'] as int?,
      cardCount: json['card_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'owner_id': ownerId,
    'name': name,
    'slug': slug,
    'description': description,
    'is_public': isPublic,
  };
}

enum FlashcardType { word, kanji, sentence, vocab }

class Flashcard {
  final int id;
  final String userId;
  final int deckId;
  final String front;
  final String back;
  final String? pronunciation;
  final String? hint;
  final FlashcardType type;
  final int sm2Interval;
  final int sm2Repetition;
  final double sm2Ease;
  final DateTime sm2DueAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Flashcard({
    required this.id,
    required this.userId,
    required this.deckId,
    required this.front,
    required this.back,
    this.pronunciation,
    this.hint,
    this.type = FlashcardType.word,
    this.sm2Interval = 1,
    this.sm2Repetition = 0,
    this.sm2Ease = 2.5,
    DateTime? sm2DueAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : sm2DueAt = sm2DueAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isDue => sm2DueAt.isBefore(DateTime.now());

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    final frontRaw = json['front'];
    final backRaw = json['back'];

    String frontText;
    String backText;
    String? pronunciation;
    String? hint;
    String? typeStr;

    if (frontRaw is Map) {
      // Try all plausible text keys — different insert paths used different keys
      frontText = _extractText(frontRaw, ['text', 'value', 'word', 'kanji', 'content', 'term', 'front', 'expression']);
      typeStr = frontRaw['type'] as String?;
    } else {
      frontText = frontRaw?.toString() ?? '';
    }

    if (backRaw is Map) {
      backText = _extractText(backRaw, ['text', 'value', 'meaning', 'definition', 'content', 'back', 'translation']);
      pronunciation = _firstString(backRaw, ['reading', 'pronunciation', 'furigana', 'kana', 'yomi']);
      hint = _firstString(backRaw, ['hint', 'note', 'notes', 'example']);
    } else {
      backText = backRaw?.toString() ?? '';
    }

    return Flashcard(
      id: json['id'] as int,
      userId: (json['user_id'] ?? '') as String,
      deckId: json['deck_id'] as int,
      front: frontText,
      back: backText,
      pronunciation: pronunciation,
      hint: hint,
      type: FlashcardType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => FlashcardType.word,
      ),
      sm2Interval: json['sm2_interval'] as int? ?? 1,
      sm2Repetition: json['sm2_repetition'] as int? ?? 0,
      sm2Ease: (json['sm2_ease'] as num?)?.toDouble() ?? 2.5,
      sm2DueAt: json['sm2_due_at'] != null
          ? DateTime.parse(json['sm2_due_at'] as String)
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Tries each key in [keys] and returns the first non-empty String value.
  /// Falls back to the first non-empty String value anywhere in the Map,
  /// then to the raw Map toString as a last resort.
  static String _extractText(Map raw, List<String> keys) {
    for (final k in keys) {
      final v = raw[k];
      if (v is String && v.isNotEmpty) return v;
    }
    // Fallback: any non-empty string value in the map
    for (final v in raw.values) {
      if (v is String && v.isNotEmpty) return v;
    }
    return raw.toString();
  }

  /// Like [_extractText] but returns null instead of a fallback.
  static String? _firstString(Map raw, List<String> keys) {
    for (final k in keys) {
      final v = raw[k];
      if (v is String && v.isNotEmpty) return v;
    }
    return null;
  }

  Map<String, dynamic> toInsertJson() => {
    'user_id': userId,
    'deck_id': deckId,
    'front': {'text': front, 'type': type.name},
    'back': {'text': back, 'reading': pronunciation, 'hint': hint},
  };
}

class FlashcardReview {
  final int id;
  final int cardId;
  final String userId;
  final int quality;
  final DateTime reviewedAt;

  FlashcardReview({
    required this.id,
    required this.cardId,
    required this.userId,
    required this.quality,
    required this.reviewedAt,
  });

  factory FlashcardReview.fromJson(Map<String, dynamic> json) {
    return FlashcardReview(
      id: json['id'] as int,
      cardId: json['card_id'] as int,
      userId: json['user_id'] as String,
      quality: json['quality'] as int,
      reviewedAt: DateTime.parse(json['reviewed_at'] as String),
    );
  }
}
