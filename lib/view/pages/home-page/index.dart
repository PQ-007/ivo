import 'package:flutter/material.dart';
import 'package:ivo/components/buttons/dark_mode_button.dart';
import 'package:ivo/components/buttons/settings_nav_button.dart';
import 'package:ivo/components/common/app_bar.dart';
import 'package:ivo/components/flashcard/deck_preview.dart';
import 'package:ivo/components/my_recent.dart';
import 'package:ivo/data/l10n.dart';
import 'package:ivo/data/models/flashcard_models.dart';
import 'package:ivo/services/db_helper.dart';
import 'package:ivo/services/flashcard_service.dart';
import 'package:ivo/view/pages/study-session/index.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _service = FlashcardService();

  int _dueCount = 0;
  FlashcardDeck? _lastDeck;
  Map<String, dynamic>? _wordOfDay;
  bool _loading = true;

  // Fake 7-day activity (1 = light, 2 = medium, 3 = strong, 0 = none)
  final _weekActivity = [3, 3, 2, 3, 1, 3, 3];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _service.getTotalDueCount(),
        _service.getLastStudiedDeck(),
        JishoDB.getRandomWord(),
      ]);
      if (!mounted) return;
      setState(() {
        _dueCount = results[0] as int? ?? 0;
        _lastDeck = results[1] as FlashcardDeck?;
        _wordOfDay = results[2] as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: MyAppBar(
        titleText: t('home_title'),
        button1: DarkModeButton(),
        button2: SettingsNavButton(),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: scheme.primary,
        child: _loading
            ? Center(child: CircularProgressIndicator(color: scheme.primary))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                children: [
                  _buildStreakRow(scheme),
                  const SizedBox(height: 16),
                  _buildHeroCard(scheme),
                  const SizedBox(height: 28),
                  if (_lastDeck != null) ...[
                    _Monolabel(t('home_continue')),
                    const SizedBox(height: 10),
                    RecentDeckCard(
                      deck: _lastDeck!,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => DeckPreview(deck: _lastDeck!))),
                    ),
                    const SizedBox(height: 28),
                  ],
                  if (_wordOfDay != null) ...[
                    _Monolabel(t('home_word_of_day')),
                    const SizedBox(height: 10),
                    _buildWordCard(scheme, _wordOfDay!),
                    const SizedBox(height: 28),
                  ],
                  _Monolabel(t('home_streak')),
                  const SizedBox(height: 10),
                  _buildStreakDots(scheme),
                ],
              ),
      ),
    );
  }

  Widget _buildStreakRow(ColorScheme scheme) {
    final streak = _weekActivity.where((v) => v > 0).length;
    return Row(
      children: [
        Expanded(
          child: Text(
            '$_dueCount ${t('home_due_cards')}',
            style: TextStyle(fontSize: 14, color: scheme.onSurface.withValues(alpha: 0.6)),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(99)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('🔥', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text('$streak ${t('home_days')}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: scheme.onPrimary)),
          ]),
        ),
      ],
    );
  }

  Widget _buildHeroCard(ColorScheme scheme) {
    final allDone = _dueCount == 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: scheme.shadow.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (allDone)
            Text(t('home_all_done'),
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: scheme.primary))
          else ...[
            Text('$_dueCount',
                style: TextStyle(fontSize: 72, fontWeight: FontWeight.w800, height: 0.9, color: scheme.onSurface)),
            const SizedBox(height: 6),
            Text(t('home_due_cards'),
                style: TextStyle(fontSize: 16, color: scheme.onSurface.withValues(alpha: 0.55))),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _lastDeck == null
                  ? null
                  : () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => StudySessionPage(deck: _lastDeck!))),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(t('home_study_now'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordCard(ColorScheme scheme, Map<String, dynamic> entry) {
    final kanji = (entry['kanji'] as List?)?.firstOrNull?.toString() ?? '';
    final reading = (entry['reading'] as List?)?.firstOrNull?.toString() ?? '';
    final senses = entry['senses'] as List? ?? [];
    final glosses = senses.isNotEmpty
        ? (senses.first['glosses'] as List?)?.take(2).join(', ') ?? ''
        : '';
    final pos = senses.isNotEmpty
        ? (senses.first['pos'] as List?)?.firstOrNull?.toString() ?? ''
        : '';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: scheme.shadow.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Text(kanji,
              style: TextStyle(fontSize: 56, fontWeight: FontWeight.w500, height: 1.0, color: scheme.onSurface)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (glosses.isNotEmpty)
                  Text(glosses,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: scheme.onSurface)),
                if (reading.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(reading,
                      style: TextStyle(fontSize: 13, color: scheme.onSurface.withValues(alpha: 0.55))),
                ],
                if (pos.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(pos.toUpperCase(),
                        style: TextStyle(fontSize: 9, color: scheme.onPrimaryContainer,
                            letterSpacing: 1.5, fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakDots(ColorScheme scheme) {
    final days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final v = _weekActivity[i];
        final color = v == 0
            ? scheme.outlineVariant.withValues(alpha: 0.4)
            : v == 1
                ? scheme.primary.withValues(alpha: 0.3)
                : v == 2
                    ? scheme.primary.withValues(alpha: 0.6)
                    : scheme.primary;
        return Column(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(height: 5),
            Text(days[i],
                style: TextStyle(fontSize: 10, color: scheme.onSurface.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w600)),
          ],
        );
      }),
    );
  }
}

class _Monolabel extends StatelessWidget {
  final String text;
  const _Monolabel(this.text);
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(text.toUpperCase(),
        style: TextStyle(fontSize: 11, letterSpacing: 2.5, fontWeight: FontWeight.w600,
            color: scheme.onSurface.withValues(alpha: 0.5)));
  }
}
