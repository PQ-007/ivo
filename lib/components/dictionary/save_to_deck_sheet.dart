import 'package:flutter/material.dart';
import 'package:ivo/data/models/flashcard_models.dart';
import 'package:ivo/services/flashcard_service.dart';

/// Shows a bottom sheet letting the user pick a deck to save a JMDict entry to.
Future<void> showSaveToDeckSheet(
    BuildContext context, Map<String, dynamic> entry) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _SaveToDeckSheet(entry: entry),
  );
}

class _SaveToDeckSheet extends StatefulWidget {
  final Map<String, dynamic> entry;
  const _SaveToDeckSheet({required this.entry});

  @override
  State<_SaveToDeckSheet> createState() => _SaveToDeckSheetState();
}

class _SaveToDeckSheetState extends State<_SaveToDeckSheet> {
  final _service = FlashcardService();
  List<FlashcardDeck>? _decks;
  int? _savingDeckId;

  @override
  void initState() {
    super.initState();
    _service.getDecks().then((d) {
      if (mounted) setState(() => _decks = d);
    });
  }

  String get _front {
    final kanji = (widget.entry['kanji'] as List?)?.firstOrNull?.toString() ?? '';
    final reading =
        (widget.entry['reading'] as List?)?.firstOrNull?.toString() ?? '';
    return kanji.isNotEmpty ? kanji : reading;
  }

  String get _back {
    final senses = widget.entry['senses'] as List? ?? [];
    if (senses.isEmpty) return '';
    return (senses.first['glosses'] as List?)?.take(2).join(', ') ?? '';
  }

  String? get _reading {
    final kanji = (widget.entry['kanji'] as List?)?.firstOrNull?.toString() ?? '';
    if (kanji.isEmpty) return null; // front IS the reading already
    return (widget.entry['reading'] as List?)?.firstOrNull?.toString();
  }

  Future<void> _saveToDeck(FlashcardDeck deck) async {
    setState(() => _savingDeckId = deck.id);
    try {
      await _service.createFlashcard(
        deck.id,
        _front,
        _back,
        _reading,
        null,
        FlashcardType.word,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Saved to "${deck.name}"'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (_) {
      if (mounted) setState(() => _savingDeckId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final kanji =
        (widget.entry['kanji'] as List?)?.firstOrNull?.toString() ?? '';
    final reading =
        (widget.entry['reading'] as List?)?.firstOrNull?.toString() ?? '';
    final senses = widget.entry['senses'] as List? ?? [];
    final gloss = senses.isNotEmpty
        ? (senses.first['glosses'] as List?)?.take(2).join(', ') ?? ''
        : '';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (kanji.isNotEmpty)
                        Text(kanji,
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface)),
                      if (reading.isNotEmpty)
                        Text(reading,
                            style: TextStyle(
                                fontSize: 14,
                                color:
                                    scheme.onSurface.withValues(alpha: 0.55))),
                      if (gloss.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(gloss,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 14,
                                color:
                                    scheme.onSurface.withValues(alpha: 0.7))),
                      ],
                    ],
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: scheme.outlineVariant),
            const SizedBox(height: 12),

            // ── Deck label ──
            Text('Save to deck',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                    letterSpacing: 1.2)),
            const SizedBox(height: 10),

            // ── Deck list ──
            if (_decks == null)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator()))
            else if (_decks!.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('No decks yet — create one in Library first',
                      style: TextStyle(
                          fontSize: 14,
                          color: scheme.onSurface.withValues(alpha: 0.5))),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _decks!.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: scheme.outlineVariant),
                  itemBuilder: (_, i) {
                    final deck = _decks![i];
                    final saving = _savingDeckId == deck.id;
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 4),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.style_rounded,
                            color: scheme.onPrimaryContainer, size: 20),
                      ),
                      title: Text(deck.name,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface)),
                      subtitle: Text('${deck.cardCount} cards',
                          style: TextStyle(
                              fontSize: 12,
                              color:
                                  scheme.onSurface.withValues(alpha: 0.5))),
                      trailing: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.chevron_right,
                              color: scheme.onSurface.withValues(alpha: 0.4)),
                      onTap: _savingDeckId != null
                          ? null
                          : () => _saveToDeck(deck),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
