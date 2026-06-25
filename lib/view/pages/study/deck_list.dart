import 'package:flutter/material.dart';
import 'package:ivo/services/study/card_repository.dart';
import 'package:ivo/services/study/models/deck.dart';
import 'package:ivo/view/pages/study/review_page.dart';

/// Deck list shown in the Library "Флаш карт" tab: decks with due counts,
/// create a deck, tap to review.
class DeckListView extends StatefulWidget {
  const DeckListView({super.key});

  @override
  State<DeckListView> createState() => _DeckListViewState();
}

class _DeckListViewState extends State<DeckListView> {
  CardRepository? _repo;
  List<Deck> _decks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = _repo ?? await CardRepository.open();
    final decks = await repo.listDecks();
    if (!mounted) return;
    setState(() {
      _repo = repo;
      _decks = decks;
      _loading = false;
    });
  }

  Future<void> _createDeck() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Шинэ багц'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Багцын нэр'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Болих')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Үүсгэх')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await _repo!.createDeck(name);
      await _load();
    }
  }

  Future<void> _openDeck(Deck deck) async {
    if (deck.dueCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Өнөөдөр давтах карт алга')),
      );
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReviewPage(deckId: deck.id!, deckName: deck.name),
    ));
    await _load(); // refresh due counts after reviewing
  }

  Future<void> _deleteDeck(Deck deck) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('"${deck.name}" устгах уу?'),
        content: const Text('Багц доторх бүх карт устана.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Болих')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Устгах')),
        ],
      ),
    );
    if (ok == true) {
      await _repo!.deleteDeck(deck.id!);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _createDeck,
              icon: const Icon(Icons.add),
              label: const Text('Шинэ багц'),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _decks.isEmpty
                  ? const Center(child: Text('Багц алга. Шинээр үүсгэнэ үү.'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        itemCount: _decks.length,
                        itemBuilder: (context, i) {
                          final d = _decks[i];
                          return ListTile(
                            title: Text(d.name),
                            subtitle: Text(
                                '${d.dueCount} давтах • ${d.cardCount} карт'),
                            trailing: d.dueCount > 0
                                ? CircleAvatar(
                                    radius: 14,
                                    child: Text('${d.dueCount}',
                                        style: const TextStyle(fontSize: 12)),
                                  )
                                : null,
                            onTap: () => _openDeck(d),
                            onLongPress: () => _deleteDeck(d),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
