import 'package:flutter/material.dart';
import 'package:ivo/services/study/card_repository.dart';

/// Bottom sheet to pick (or create) a deck and save a card into it.
/// Reused from dictionary results and translate results.
Future<void> showSaveToDeckSheet(
  BuildContext context, {
  required String front,
  String reading = '',
  required String back,
  String source = 'dictionary',
}) async {
  final repo = await CardRepository.open();
  var decks = await repo.listDecks();
  if (!context.mounted) return;

  await showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (sheetCtx) {
      return StatefulBuilder(
        builder: (sheetCtx, setSheet) {
          Future<void> saveTo(int deckId) async {
            await repo.addCard(
                deckId: deckId,
                front: front,
                reading: reading,
                back: back,
                source: source);
            if (sheetCtx.mounted) Navigator.pop(sheetCtx);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('"$front" нэмэгдлээ')),
              );
            }
          }

          Future<void> createAndMaybeSave() async {
            final controller = TextEditingController();
            final name = await showDialog<String>(
              context: sheetCtx,
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
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Болих')),
                  FilledButton(
                      onPressed: () =>
                          Navigator.pop(ctx, controller.text.trim()),
                      child: const Text('Үүсгэх')),
                ],
              ),
            );
            if (name != null && name.isNotEmpty) {
              final id = await repo.createDeck(name);
              await saveTo(id); // create then save straight into it
            }
          }

          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Багцад нэмэх',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                ...decks.map((d) => ListTile(
                      leading: const Icon(Icons.style),
                      title: Text(d.name),
                      subtitle: Text('${d.cardCount} карт'),
                      onTap: () => saveTo(d.id!),
                    )),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Шинэ багц үүсгэх'),
                  onTap: createAndMaybeSave,
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      );
    },
  );
}
