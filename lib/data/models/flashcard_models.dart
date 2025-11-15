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

  factory FlashcardFolder.fromJson(Map<String, dynamic> json) {
    return FlashcardFolder(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      userId: json['user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'user_id': userId,
    };
  }
}

class FlashcardDeck {
  final String id;
  final String name;
  final String? description;
  final String? folderId;
  final String userId;
  final int cardCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  FlashcardDeck({
    required this.id,
    required this.name,
    this.description,
    this.folderId,
    required this.userId,
    this.cardCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FlashcardDeck.fromJson(Map<String, dynamic> json) {
    return FlashcardDeck(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      folderId: json['folder_id'] as String?,
      userId: json['user_id'] as String,
      cardCount: json['card_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'folder_id': folderId,
      'user_id': userId,
    };
  }
}

enum FlashcardType {
  word, // Word with meaning and pronunciation
  kanji, // Kanji character for drawing practice
  sentence, // Sentence translation
  vocab, // General vocabulary
}

class Flashcard {
  final String id;
  final String deckId;
  final String front;
  final String back;
  final String? pronunciation;
  final String? hint;
  final FlashcardType type;
  final DateTime createdAt;
  final DateTime updatedAt;

  Flashcard({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    this.pronunciation,
    this.hint,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'] as String,
      deckId: json['deck_id'] as String,
      front: json['front'] as String,
      back: json['back'] as String,
      pronunciation: json['pronunciation'] as String?,
      hint: json['hint'] as String?,
      type: FlashcardType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FlashcardType.word,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deck_id': deckId,
      'front': front,
      'back': back,
      'pronunciation': pronunciation,
      'hint': hint,
      'type': type.name,
    };
  }
}