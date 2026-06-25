class Deck {
  final int? id;
  final String name;
  final DateTime createdAt;

  /// Populated by list queries; not stored on the row.
  final int cardCount;
  final int dueCount;

  const Deck({
    this.id,
    required this.name,
    required this.createdAt,
    this.cardCount = 0,
    this.dueCount = 0,
  });

  factory Deck.fromRow(Map<String, Object?> row) => Deck(
        id: row['id'] as int?,
        name: row['name'] as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
        cardCount: (row['card_count'] as int?) ?? 0,
        dueCount: (row['due_count'] as int?) ?? 0,
      );
}
