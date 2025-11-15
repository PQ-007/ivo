// lib/services/flashcard_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ivo/data/models/flashcard_models.dart';

class FlashcardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user ID
  String? get _userId => _supabase.auth.currentUser?.id;

  // FOLDER OPERATIONS
  Future<List<FlashcardFolder>> getFolders() async {
    final response = await _supabase
        .from('flashcard_folders')
        .select()
        .eq('user_id', _userId!)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => FlashcardFolder.fromJson(json))
        .toList();
  }

  Future<FlashcardFolder> createFolder(String name, String? description) async {
    final response = await _supabase
        .from('flashcard_folders')
        .insert({
          'name': name,
          'description': description,
          'user_id': _userId,
        })
        .select()
        .single();

    return FlashcardFolder.fromJson(response);
  }

  Future<void> updateFolder(String folderId, String name, String? description) async {
    await _supabase
        .from('flashcard_folders')
        .update({
          'name': name,
          'description': description,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', folderId);
  }

  Future<void> deleteFolder(String folderId) async {
    await _supabase.from('flashcard_folders').delete().eq('id', folderId);
  }

  // DECK OPERATIONS
  Future<List<FlashcardDeck>> getDecks({String? folderId}) async {
    var query = _supabase
        .from('flashcard_decks')
        .select('*, flashcards(count)')
        .eq('user_id', _userId!);

    if (folderId != null) {
      query = query.eq('folder_id', folderId);
    } else {
      query = query.isFilter('folder_id', null);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List).map((json) {
      final cardCount = json['flashcards']?[0]?['count'] ?? 0;
      json['card_count'] = cardCount;
      return FlashcardDeck.fromJson(json);
    }).toList();
  }

  Future<FlashcardDeck> createDeck(
    String name,
    String? description,
    String? folderId,
  ) async {
    final response = await _supabase
        .from('flashcard_decks')
        .insert({
          'name': name,
          'description': description,
          'folder_id': folderId,
          'user_id': _userId,
        })
        .select()
        .single();

    return FlashcardDeck.fromJson(response);
  }

  Future<void> updateDeck(
    String deckId,
    String name,
    String? description,
    String? folderId,
  ) async {
    await _supabase
        .from('flashcard_decks')
        .update({
          'name': name,
          'description': description,
          'folder_id': folderId,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', deckId);
  }

  Future<void> deleteDeck(String deckId) async {
    await _supabase.from('flashcard_decks').delete().eq('id', deckId);
  }

  // FLASHCARD OPERATIONS
  Future<List<Flashcard>> getFlashcards(String deckId) async {
    final response = await _supabase
        .from('flashcards')
        .select()
        .eq('deck_id', deckId)
        .order('created_at', ascending: true);

    return (response as List).map((json) => Flashcard.fromJson(json)).toList();
  }

  Future<Flashcard> createFlashcard(
    String deckId,
    String front,
    String back,
    String? pronunciation,
    String? hint,
    FlashcardType type,
  ) async {
    final response = await _supabase
        .from('flashcards')
        .insert({
          'deck_id': deckId,
          'front': front,
          'back': back,
          'pronunciation': pronunciation,
          'hint': hint,
          'type': type.name,
        })
        .select()
        .single();

    return Flashcard.fromJson(response);
  }

  Future<void> updateFlashcard(
    String flashcardId,
    String front,
    String back,
    String? pronunciation,
    String? hint,
    FlashcardType type,
  ) async {
    await _supabase
        .from('flashcards')
        .update({
          'front': front,
          'back': back,
          'pronunciation': pronunciation,
          'hint': hint,
          'type': type.name,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', flashcardId);
  }

  Future<void> deleteFlashcard(String flashcardId) async {
    await _supabase.from('flashcards').delete().eq('id', flashcardId);
  }
}