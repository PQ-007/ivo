import 'package:flutter/material.dart';
import 'package:ivo/components/buttons/dark_mode_button.dart';
import 'package:ivo/components/buttons/settings_nav_button.dart';
import 'package:ivo/components/common/app_bar.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final bars = [4, 8, 6, 12, 18, 14, 22, 28, 16, 20, 24, 18, 26, 30];
    const maxBar = 30;

    final stats = [
      ('streak', '14 days'),
      ('retention', '92%'),
      ('avg session', '6:08'),
      ('this week', '+37'),
    ];

    return Scaffold(
      appBar: MyAppBar(
        titleText: 'Stats',
        button1: DarkModeButton(),
        button2: SettingsNavButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _Monolabel('progress · 14d', scheme: scheme),
            const SizedBox(height: 6),
            Text(
              '248 learned.',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.8, color: scheme.onSurface),
            ),
            const SizedBox(height: 16),

            // Legend
            Row(
              children: [
                _LegendDot(color: scheme.onSurface, label: 'retained', scheme: scheme),
                const SizedBox(width: 16),
                _LegendDot(color: scheme.primary, label: 'added', scheme: scheme),
              ],
            ),

            const SizedBox(height: 20),

            // Bar chart
            SizedBox(
              height: 130,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(bars.length, (i) {
                  final v = bars[i];
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: (v / maxBar) * 90,
                            decoration: BoxDecoration(color: scheme.onSurface, borderRadius: BorderRadius.circular(2)),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            height: (v / maxBar) * 26,
                            decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(2)),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['APR 05', 'APR 12', 'APR 19'].map((l) => Text(
                l,
                style: TextStyle(fontSize: 10, letterSpacing: 1.2, color: scheme.onSurface.withOpacity(0.5)),
              )).toList(),
            ),

            const SizedBox(height: 26),

            // Stat grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: stats.map((s) => _StatCard(label: s.$1, value: s.$2, scheme: scheme)).toList(),
            ),

            const SizedBox(height: 26),

            // Streak calendar
            _Monolabel('streak · 14 days in a row', scheme: scheme),
            const SizedBox(height: 16),
            _StreakCalendar(scheme: scheme),
          ],
        ),
      ),
    );
  }
}

// ─── Streak calendar ──────────────────────────────────────────────────────────

class _StreakCalendar extends StatelessWidget {
  final ColorScheme scheme;
  const _StreakCalendar({required this.scheme});

  @override
  Widget build(BuildContext context) {
    final days = [2,3,1,2,3,0,0, 3,3,3,2,3,3,1, 3,3,3,3,3,3,3, 3,3,3,3,3,3,3, 3,3,3,0,0,0,0];

    Color cellColor(int v) {
      if (v == 0) return scheme.outlineVariant.withOpacity(0.4);
      if (v == 1) return scheme.primary.withOpacity(0.3);
      if (v == 2) return scheme.primary.withOpacity(0.6);
      return scheme.primary;
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('MAR 17', style: TextStyle(fontSize: 10, letterSpacing: 1.2, color: scheme.onSurface.withOpacity(0.5))),
            Text('APR 19', style: TextStyle(fontSize: 10, letterSpacing: 1.2, color: scheme.onSurface.withOpacity(0.5))),
          ],
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          children: List.generate(days.length, (i) => Container(
            decoration: BoxDecoration(color: cellColor(days[i]), borderRadius: BorderRadius.circular(4)),
          )),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('LESS', style: TextStyle(fontSize: 10, letterSpacing: 1, color: scheme.onSurface.withOpacity(0.4))),
            const SizedBox(width: 6),
            ...[0, 1, 2, 3].map((v) => Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Container(width: 10, height: 10, decoration: BoxDecoration(color: cellColor(v), borderRadius: BorderRadius.circular(3))),
            )),
            const SizedBox(width: 6),
            Text('MORE', style: TextStyle(fontSize: 10, letterSpacing: 1, color: scheme.onSurface.withOpacity(0.4))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _StatCard(label: 'longest', value: '31 days', scheme: scheme)),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(label: 'total days', value: '127', scheme: scheme)),
          ],
        ),
      ],
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme scheme;
  const _StatCard({required this.label, required this.value, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Monolabel(label, scheme: scheme),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: scheme.onSurface)),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final ColorScheme scheme;
  const _LegendDot({required this.color, required this.label, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11, color: scheme.onSurface.withOpacity(0.5))),
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
      style: TextStyle(fontSize: 10, letterSpacing: 2.8, color: scheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.w600),
    );
  }
}
