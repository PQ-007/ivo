import 'package:flutter/material.dart';

class SessionCompletePage extends StatelessWidget {
  final int total;
  final int kept;
  final int missed;
  final String timeString;
  final List<(String front, String back)> missedWords;

  const SessionCompletePage({
    super.key,
    required this.total,
    required this.kept,
    required this.missed,
    this.timeString = '6:12',
    this.missedWords = const [],
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final dateLabel = '${_monthAbbr(now.month)} ${now.day}';

    final stats = [
      ('cards', '$total'),
      ('kept', '$kept'),
      ('missed', '$missed'),
      ('time', timeString),
    ];

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 14),

            // Header row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Monolabel('fin · $timeString', scheme: scheme),
                  _Monolabel(dateLabel, scheme: scheme),
                ],
              ),
            ),

            const SizedBox(height: 36),

            // Check icon + heading
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                    child: Icon(Icons.check_rounded, color: scheme.onPrimary, size: 28),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Session done.\nSee you tomorrow.',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.9,
                      color: scheme.onSurface,
                      height: 1.05,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Stats grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _StatCell(label: stats[0].$1, value: stats[0].$2, scheme: scheme),
                        const SizedBox(width: 1),
                        _StatCell(label: stats[1].$1, value: stats[1].$2, scheme: scheme),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        _StatCell(label: stats[2].$1, value: stats[2].$2, accent: true, scheme: scheme),
                        const SizedBox(width: 1),
                        _StatCell(label: stats[3].$1, value: stats[3].$2, scheme: scheme),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Missed cards
            if (missedWords.isNotEmpty || missed > 0) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: _Monolabel('missed — returning tomorrow', scheme: scheme),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: (missedWords.isNotEmpty
                      ? missedWords
                      : const [('難しい', 'difficult'), ('気候', 'climate')]
                  ).map((w) => _MissedCard(front: w.$1, back: w.$2, scheme: scheme)).toList(),
                ),
              ),
            ],

            const Spacer(),

            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 30),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.onSurface,
                          side: BorderSide(color: scheme.outlineVariant),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('REVIEW', style: TextStyle(fontSize: 13, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.onSurface,
                          foregroundColor: scheme.surface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('CLOSE APP', style: TextStyle(fontSize: 13, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthAbbr(int month) {
    const months = ['jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec'];
    return months[month - 1].toUpperCase();
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final bool accent;
  final ColorScheme scheme;

  const _StatCell({required this.label, required this.value, this.accent = false, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: scheme.surfaceContainerLow,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Monolabel(label, scheme: scheme),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: accent ? scheme.primary : scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissedCard extends StatelessWidget {
  final String front;
  final String back;
  final ColorScheme scheme;

  const _MissedCard({required this.front, required this.back, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(front, style: TextStyle(fontSize: 26, color: scheme.onSurface)),
          const SizedBox(width: 14),
          Expanded(child: Text(back, style: TextStyle(fontSize: 13, color: scheme.onSurface))),
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
          ),
        ],
      ),
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
