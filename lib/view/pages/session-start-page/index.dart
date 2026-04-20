import 'package:flutter/material.dart';
import 'package:ivo/data/models/flashcard_models.dart';
import 'package:ivo/view/pages/study-session/index.dart';

class SessionStartPage extends StatelessWidget {
  final FlashcardDeck deck;

  const SessionStartPage({super.key, required this.deck});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = deck.cardCount > 0 ? deck.cardCount : 18;
    final newCount = (total * 0.33).round().clamp(1, 12);
    final reviewCount = (total * 0.67).round().clamp(1, 20);

    final upNext = [
      ('東京', 'Tokyo', 'day 1'),
      ('時間', 'time', 'new'),
      ('日本', 'Japan', 'day 3'),
      ('午前', 'morning', 'day 7'),
    ];

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 14),

            // Chrome header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: _Hamburger(color: scheme.onSurface),
                  ),
                  const Spacer(),
                  _ProgressCounter(idx: 6, total: 6, label: 'minutes today', scheme: scheme),
                ],
              ),
            ),

            const SizedBox(height: 34),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Monolabel("today's session", scheme: scheme),
                  const SizedBox(height: 8),
                  Text(
                    '$total cards.\nSix minutes.',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.9,
                      color: scheme.onSurface,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'A small, calm batch. Finish it, close the app, come back tomorrow.',
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurface.withOpacity(0.5),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Stats row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  _StatBox(label: 'new', value: '$newCount', scheme: scheme),
                  const SizedBox(width: 10),
                  _StatBox(label: 'review', value: '$reviewCount', accent: true, scheme: scheme),
                  const SizedBox(width: 10),
                  _StatBox(label: 'due', value: '0', scheme: scheme),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Up next
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: _Monolabel('up next', scheme: scheme),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                children: upNext.map((item) => _UpNextRow(
                  jp: item.$1,
                  en: item.$2,
                  label: item.$3,
                  scheme: scheme,
                )).toList(),
              ),
            ),

            const Spacer(),

            // Begin button
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 30),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => StudySessionPage(deck: deck)),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Begin session', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 10),
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(color: scheme.onPrimary, shape: BoxShape.circle),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final bool accent;
  final ColorScheme scheme;

  const _StatBox({required this.label, required this.value, this.accent = false, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Monolabel(label, scheme: scheme),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
                color: accent ? scheme.primary : scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpNextRow extends StatelessWidget {
  final String jp;
  final String en;
  final String label;
  final ColorScheme scheme;

  const _UpNextRow({required this.jp, required this.en, required this.label, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant, width: 1)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(jp, style: TextStyle(fontSize: 22, color: scheme.onSurface)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(en, style: TextStyle(fontSize: 14, color: scheme.onSurface))),
          _Monolabel(label, scheme: scheme),
        ],
      ),
    );
  }
}

// ─── Shared primitives ───────────────────────────────────────────────────────

class _Hamburger extends StatelessWidget {
  final Color color;
  const _Hamburger({required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 22, height: 2, color: color.withOpacity(0.9)),
        const SizedBox(height: 4),
        Container(width: 16, height: 2, color: color.withOpacity(0.9)),
        const SizedBox(height: 4),
        Container(width: 22, height: 2, color: color.withOpacity(0.9)),
      ],
    );
  }
}

class _ProgressCounter extends StatelessWidget {
  final int idx;
  final int total;
  final String label;
  final ColorScheme scheme;

  const _ProgressCounter({required this.idx, required this.total, required this.label, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7, height: 7,
              decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              '$idx',
              style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.w700,
                letterSpacing: -0.5, color: scheme.onSurface, height: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          '/$total · $label',
          style: TextStyle(fontSize: 11, color: scheme.onSurface.withOpacity(0.5), letterSpacing: 0.6),
        ),
      ],
    );
  }
}

class _Monolabel extends StatelessWidget {
  final String text;
  final ColorScheme scheme;

  const _Monolabel(this.text, {required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        letterSpacing: 2.8,
        color: scheme.onSurface.withOpacity(0.5),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
