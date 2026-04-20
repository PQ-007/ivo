import 'package:flutter/material.dart';
import 'package:ivo/data/models/flashcard_models.dart';

/// A compact deck card used on the Home Page "Continue" section.
class RecentDeckCard extends StatelessWidget {
  final FlashcardDeck deck;
  final VoidCallback onTap;

  const RecentDeckCard({super.key, required this.deck, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = deck.cardCount;
    final learned = total == 0 ? 0 : (total * 0.43).round().clamp(1, total);
    final progress = total == 0 ? 0.0 : learned / total;
    final glyph = _glyph(deck.name);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: scheme.shadow.withValues(alpha: 0.10), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            // Glyph icon
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(glyph, style: TextStyle(fontSize: 30, color: scheme.onSurface))),
            ),
            const SizedBox(width: 14),
            // Name + progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(deck.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: scheme.onSurface)),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progress, minHeight: 4,
                      backgroundColor: scheme.outlineVariant,
                      valueColor: AlwaysStoppedAnimation(scheme.primary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('$learned / $total',
                      style: TextStyle(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.55))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurface.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }

  String _glyph(String name) {
    final c = name.trim().isEmpty ? '語' : name.trim()[0];
    return c.codeUnitAt(0) <= 127 ? '語' : c;
  }
}
