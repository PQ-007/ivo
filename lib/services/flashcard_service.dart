// lib/services/flashcard_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ivo/data/models/flashcard_models.dart';

class FlashcardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get _userId => _supabase.auth.currentUser?.id;

  // ── Deck CRUD ──────────────────────────────────────────────────────────────

  Future<List<FlashcardDeck>> getDecks() async {
    final uid = _userId;
    if (uid == null) return [];

    final response = await _supabase
        .from('decks')
        .select('*, flashcards(count)')
        .eq('owner_id', uid)
        .order('created_at', ascending: false);

    return (response as List).map((json) {
      final count = (json['flashcards'] as List?)?.firstOrNull?['count'] ?? 0;
      return FlashcardDeck.fromJson({...json, 'card_count': count});
    }).toList();
  }

  Future<FlashcardDeck> createDeck(String name, String? description) async {
    final uid = _userId!;
    final slug = _toSlug(name);

    final response = await _supabase
        .from('decks')
        .insert({
          'owner_id': uid,
          'name': name,
          'slug': slug,
          'description': description,
          'is_public': false,
        })
        .select()
        .single();

    return FlashcardDeck.fromJson({...response, 'card_count': 0});
  }

  Future<void> updateDeck(int deckId, String name, String? description) async {
    await _supabase.from('decks').update({
      'name': name,
      'slug': _toSlug(name),
      'description': description,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', deckId);
  }

  Future<void> deleteDeck(int deckId) async {
    await _supabase.from('decks').delete().eq('id', deckId);
  }

  // ── Flashcard CRUD ─────────────────────────────────────────────────────────

  Future<List<Flashcard>> getFlashcards(int deckId) async {
    final response = await _supabase
        .from('flashcards')
        .select()
        .eq('deck_id', deckId)
        .order('id', ascending: true);

    return (response as List).map((j) => Flashcard.fromJson(j)).toList();
  }

  Future<List<Flashcard>> getDueCards(int deckId) async {
    final now = DateTime.now().toIso8601String();
    final response = await _supabase
        .from('flashcards')
        .select()
        .eq('deck_id', deckId)
        .lte('sm2_due_at', now)
        .order('sm2_due_at', ascending: true);

    return (response as List).map((j) => Flashcard.fromJson(j)).toList();
  }

  Future<Flashcard> createFlashcard(
    int deckId,
    String front,
    String back,
    String? pronunciation,
    String? hint,
    FlashcardType type,
  ) async {
    final uid = _userId!;
    final response = await _supabase
        .from('flashcards')
        .insert({
          'user_id': uid,
          'deck_id': deckId,
          'front': {'text': front, 'type': type.name},
          'back': {'text': back, 'reading': pronunciation, 'hint': hint},
        })
        .select()
        .single();

    return Flashcard.fromJson(response);
  }

  Future<void> deleteFlashcard(int flashcardId) async {
    await _supabase.from('flashcards').delete().eq('id', flashcardId);
  }

  // ── SM-2 Spaced Repetition ─────────────────────────────────────────────────

  /// Grade a card (quality 0-5) using the SM-2 algorithm.
  /// Updates sm2_* fields on the flashcard and inserts a review record.
  Future<void> gradeCard(
    int cardId,
    int quality, {
    required int currentInterval,
    required int currentRepetition,
    required double currentEase,
  }) async {
    final uid = _userId;
    if (uid == null) return;

    final updated = _sm2(currentInterval, currentRepetition, currentEase, quality);

    await Future.wait([
      _supabase.from('flashcards').update(updated).eq('id', cardId),
      _supabase.from('flashcard_reviews').insert({
        'card_id': cardId,
        'user_id': uid,
        'quality': quality,
      }),
    ]);
  }

  // SM-2 algorithm — returns the fields to write back to `flashcards`
  static Map<String, dynamic> _sm2(
    int interval,
    int repetition,
    double ease,
    int quality,
  ) {
    int newInterval;
    int newRepetition;
    double newEase;

    if (quality >= 3) {
      if (repetition == 0) {
        newInterval = 1;
      } else if (repetition == 1) {
        newInterval = 6;
      } else {
        newInterval = (interval * ease).round();
      }
      newRepetition = repetition + 1;
    } else {
      newInterval = 1;
      newRepetition = 0;
    }

    newEase = ease + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (newEase < 1.3) newEase = 1.3;

    return {
      'sm2_interval': newInterval,
      'sm2_repetition': newRepetition,
      'sm2_ease': newEase,
      'sm2_due_at': DateTime.now()
          .add(Duration(days: newInterval))
          .toIso8601String(),
    };
  }

  // ── Home Page helpers ──────────────────────────────────────────────────────

  Future<int> getTotalDueCount() async {
    final uid = _userId;
    if (uid == null) return 0;
    final now = DateTime.now().toIso8601String();
    final response = await _supabase
        .from('flashcards')
        .select('id')
        .eq('user_id', uid)
        .lte('sm2_due_at', now);
    return (response as List).length;
  }

  Future<FlashcardDeck?> getLastStudiedDeck() async {
    final uid = _userId;
    if (uid == null) return null;
    try {
      final review = await _supabase
          .from('flashcard_reviews')
          .select('card_id')
          .eq('user_id', uid)
          .order('reviewed_at', ascending: false)
          .limit(1)
          .single();

      final cardId = review['card_id'] as int;
      final card = await _supabase
          .from('flashcards')
          .select('deck_id')
          .eq('id', cardId)
          .single();

      final deckId = card['deck_id'] as int;
      final deck = await _supabase
          .from('decks')
          .select('*, flashcards(count)')
          .eq('id', deckId)
          .single();

      final count = (deck['flashcards'] as List?)?.firstOrNull?['count'] ?? 0;
      return FlashcardDeck.fromJson({...deck, 'card_count': count});
    } catch (_) {
      return null;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _toSlug(String name) => name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), '-');
}
