import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:ivo/data/l10n.dart';
import 'package:ivo/data/models/flashcard_models.dart';
import 'package:ivo/services/flashcard_service.dart';
import 'package:ivo/view/pages/session-complete-page/index.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudySessionPage extends StatefulWidget {
  final FlashcardDeck deck;
  const StudySessionPage({super.key, required this.deck});

  @override
  State<StudySessionPage> createState() => _StudySessionState();
}

class _StudySessionState extends State<StudySessionPage> {
  final _service = FlashcardService();
  final _stopwatch = Stopwatch();
  final _headerController = ScrollController();

  List<Flashcard> _queue = [];
  int _current = 0;
  bool _revealed = false;
  bool _loading = true;

  int _again = 0;
  int _good = 0;
  int _easy = 0;

  // Width of each dot slot in the carousel
  static const double _dotSlotWidth = 36.0;

  @override
  void initState() {
    super.initState();
    _load();
    _stopwatch.start();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _headerController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      List<Flashcard> cards = [];
      if (uid != null) {
        cards = await _service.getDueCards(widget.deck.id);
        if (cards.isEmpty) {
          cards = await _service.getFlashcards(widget.deck.id);
        }
      }
      if (!mounted) return;
      setState(() {
        _queue = cards.isNotEmpty ? cards : _mockCards();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _queue = _mockCards();
        _loading = false;
      });
    }
  }

  List<Flashcard> _mockCards() {
    final now = DateTime.now();
    final did = widget.deck.id;
    return [
      Flashcard(id: -1, userId: '', deckId: did, front: '東京', back: 'Tokyo', pronunciation: 'とうきょう · tōkyō', hint: '東京に行くことになっています。\nI am supposed to go to Tokyo.', type: FlashcardType.word, createdAt: now, updatedAt: now),
      Flashcard(id: -2, userId: '', deckId: did, front: '時間', back: 'time', pronunciation: 'じかん · jikan', hint: '時間がありますか？\nDo you have time?', type: FlashcardType.word, createdAt: now, updatedAt: now),
      Flashcard(id: -3, userId: '', deckId: did, front: '日本', back: 'Japan', pronunciation: 'にほん · nihon', hint: '日本の文化が好きです。\nI like Japanese culture.', type: FlashcardType.word, createdAt: now, updatedAt: now),
      Flashcard(id: -4, userId: '', deckId: did, front: '午前', back: 'morning / AM', pronunciation: 'ごぜん · gozen', hint: '午前中に会いましょう。\nLet\'s meet in the morning.', type: FlashcardType.word, createdAt: now, updatedAt: now),
      Flashcard(id: -5, userId: '', deckId: did, front: '来月', back: 'next month', pronunciation: 'らいげつ · raigetsu', hint: '来月から始めます。\nI\'ll start next month.', type: FlashcardType.word, createdAt: now, updatedAt: now),
      Flashcard(id: -6, userId: '', deckId: did, front: '今日', back: 'today', pronunciation: 'きょう · kyō', hint: '今日はいい天気ですね。\nThe weather is nice today.', type: FlashcardType.word, createdAt: now, updatedAt: now),
    ];
  }

  void _reveal() {
    setState(() => _revealed = true);
  }

  void _grade(String rating) {
    final quality = switch (rating) {
      'again' => 1,
      'hard'  => 2,
      'good'  => 4,
      'easy'  => 5,
      _       => 3,
    };

    if (rating == 'again') {
      _again++;
    } else if (rating == 'good') _good++;
    else if (rating == 'easy') _easy++;

    final card = _queue[_current];
    if (card.id > 0) {
      _service.gradeCard(
        card.id,
        quality,
        currentInterval: card.sm2Interval,
        currentRepetition: card.sm2Repetition,
        currentEase: card.sm2Ease,
      ).catchError((_) {});
    }

    final elapsed = _stopwatch.elapsed;
    final timeStr = '${elapsed.inMinutes}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';

    if (_current < _queue.length - 1) {
      setState(() {
        _current++;
        _revealed = false;
      });
      // Scroll carousel to keep current card centered
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollCarouselToCurrent());
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SessionCompletePage(
            total: _queue.length,
            kept: _good + _easy,
            missed: _again,
            timeString: timeStr,
          ),
        ),
      );
    }
  }

  void _scrollCarouselToCurrent() {
    if (!_headerController.hasClients) return;
    final screenWidth = MediaQuery.of(context).size.width;
    // Usable list width: screen minus close button (~48) minus count badge (~48)
    final listWidth = screenWidth - 96;
    final targetOffset = (_current * _dotSlotWidth) - (listWidth / 2) + (_dotSlotWidth / 2);
    _headerController.animateTo(
      targetOffset.clamp(0.0, _headerController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_loading) {
      return Scaffold(
        backgroundColor: scheme.surface,
        body: Center(child: CircularProgressIndicator(color: scheme.primary)),
      );
    }

    if (_queue.isEmpty) {
      return Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: Center(
          child: Text('No cards to study',
              style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.5))),
        ),
      );
    }

    final card = _queue[_current];

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildCarouselHeader(scheme),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _FlipCard(
                  key: ValueKey(_current),
                  card: card,
                  revealed: _revealed,
                  scheme: scheme,
                  onTap: _revealed ? null : _reveal,
                ),
              ),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _revealed
                  ? _buildRatingButtons(scheme, key: const ValueKey('rating'))
                  : _buildShowAnswer(scheme, key: const ValueKey('show')),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── Carousel header ──────────────────────────────────────────────────────

  Widget _buildCarouselHeader(ColorScheme scheme) {
    final remaining = _queue.length - _current;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Close button
          IconButton(
            icon: Icon(Icons.close_rounded,
                color: scheme.onSurface.withValues(alpha: 0.5)),
            onPressed: () => Navigator.pop(context),
          ),

          // Scrollable dot carousel
          Expanded(
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                controller: _headerController,
                scrollDirection: Axis.horizontal,
                itemCount: _queue.length,
                itemExtent: _dotSlotWidth,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (_, i) => _CarouselDot(
                  index: i,
                  current: _current,
                  total: _queue.length,
                  scheme: scheme,
                ),
              ),
            ),
          ),

          // Remaining count badge
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '• $remaining',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom controls ──────────────────────────────────────────────────────

  Widget _buildShowAnswer(ColorScheme scheme, {Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: _reveal,
          style: OutlinedButton.styleFrom(
            foregroundColor: scheme.onSurface,
            side: BorderSide(color: scheme.outlineVariant, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(t('session_show_answer'),
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
        ),
      ),
    );
  }

  Widget _buildRatingButtons(ColorScheme scheme, {Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Row(
            children: [
              _intervalLabel('<1m', scheme),
              _intervalLabel('~10m', scheme),
              _intervalLabel('1d', scheme),
              _intervalLabel('4d', scheme),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _RatingBtn(label: t('session_again'), color: scheme.error, textColor: scheme.onError, onTap: () => _grade('again')),
              const SizedBox(width: 6),
              _RatingBtn(label: t('session_hard'), color: scheme.secondaryContainer, textColor: scheme.onSecondaryContainer, onTap: () => _grade('hard')),
              const SizedBox(width: 6),
              _RatingBtn(label: t('session_good'), color: scheme.primary, textColor: scheme.onPrimary, onTap: () => _grade('good')),
              const SizedBox(width: 6),
              _RatingBtn(label: t('session_easy'), color: scheme.secondary, textColor: scheme.onSecondary, onTap: () => _grade('easy')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _intervalLabel(String text, ColorScheme scheme) {
    return Expanded(
      child: Center(
        child: Text(text,
            style: TextStyle(
                fontSize: 10,
                color: scheme.onSurface.withValues(alpha: 0.4),
                letterSpacing: 0.5)),
      ),
    );
  }
}

// ─── Carousel dot ─────────────────────────────────────────────────────────────

class _CarouselDot extends StatelessWidget {
  final int index;
  final int current;
  final int total;
  final ColorScheme scheme;

  const _CarouselDot({
    required this.index,
    required this.current,
    required this.total,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = index == current;
    final isDone = index < current;

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: isCurrent ? 30 : (isDone ? 18 : 14),
        height: isCurrent ? 30 : (isDone ? 18 : 14),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCurrent
              ? scheme.primary
              : isDone
                  ? scheme.primary.withValues(alpha: 0.35)
                  : scheme.surfaceContainerHighest,
          border: isCurrent
              ? null
              : Border.all(
                  color: isDone
                      ? scheme.primary.withValues(alpha: 0.5)
                      : scheme.outlineVariant,
                  width: 1.5,
                ),
        ),
        child: isCurrent
            ? Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: scheme.onPrimary,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

// ─── Flip card ────────────────────────────────────────────────────────────────

class _FlipCard extends StatelessWidget {
  final Flashcard card;
  final bool revealed;
  final ColorScheme scheme;
  final VoidCallback? onTap;

  const _FlipCard({
    super.key,
    required this.card,
    required this.revealed,
    required this.scheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          final rotate = Tween(begin: pi / 2, end: 0.0)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
          return AnimatedBuilder(
            animation: rotate,
            child: child,
            builder: (_, c) => Transform(
              transform: Matrix4.rotationY(rotate.value),
              alignment: Alignment.center,
              child: c,
            ),
          );
        },
        child: revealed
            ? _CardBack(key: const ValueKey('back'), card: card, scheme: scheme)
            : _CardFront(key: const ValueKey('front'), card: card, scheme: scheme),
      ),
    );
  }
}

// ─── Card front ───────────────────────────────────────────────────────────────

class _CardFront extends StatelessWidget {
  final Flashcard card;
  final ColorScheme scheme;

  const _CardFront({super.key, required this.card, required this.scheme});

  /// Adaptive font size: large for short glyphs, smaller for long sentences.
  double _fontSize(String text) {
    final n = text.runes.length;
    if (n == 0) return 48;
    if (n == 1) return 120;
    if (n == 2) return 100;
    if (n <= 4) return 84;
    if (n <= 6) return 68;
    if (n <= 8) return 56;
    if (n <= 12) return 44;
    if (n <= 20) return 34;
    return 26;
  }

  @override
  Widget build(BuildContext context) {
    final fs = _fontSize(card.front);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge, // prevent any overflow escaping
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, 10))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
        child: Column(
          children: [
            // ── Main glyph / text ──
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    return SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth,
                          maxHeight: constraints.maxHeight,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: constraints.maxWidth,
                            child: Text(
                              card.front,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: fs,
                                fontWeight: FontWeight.w500,
                                height: 1.15,
                                letterSpacing: -1.5,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ── Hint label ──
            const SizedBox(height: 16),
            Text(
              'TAP TO REVEAL',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 3.5,
                color: scheme.onSurface.withValues(alpha: 0.3),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Card back ────────────────────────────────────────────────────────────────

class _CardBack extends StatelessWidget {
  final Flashcard card;
  final ColorScheme scheme;

  const _CardBack({super.key, required this.card, required this.scheme});

  double _frontFontSize(String text) {
    final n = text.runes.length;
    if (n <= 2) return 72;
    if (n <= 4) return 60;
    if (n <= 6) return 50;
    if (n <= 8) return 42;
    if (n <= 12) return 34;
    return 26;
  }

  @override
  Widget build(BuildContext context) {
    final lines =
        (card.hint ?? '').split('\n').where((l) => l.trim().isNotEmpty).toList();
    final jpLines = lines.where(_isJapanese).toList();
    final enLines = lines.where((l) => !_isJapanese(l)).toList();

    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, 10))
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Front (compact) ──
            Center(
              child: Text(
                card.front,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: _frontFontSize(card.front),
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                  letterSpacing: -1.0,
                  color: scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Divider(color: scheme.outlineVariant, height: 1),
            const SizedBox(height: 18),

            // ── Back / meaning ──
            Text(
              card.back,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: scheme.onSurface),
            ),
            if (card.pronunciation != null && card.pronunciation!.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(card.pronunciation!,
                  style: TextStyle(
                      fontSize: 14,
                      color: scheme.onSurface.withValues(alpha: 0.5))),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                card.type.name.toUpperCase(),
                style: TextStyle(
                    fontSize: 10,
                    color: scheme.onPrimaryContainer,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700),
              ),
            ),

            // ── Example sentences ──
            if (jpLines.isNotEmpty) ...[
              const SizedBox(height: 20),
              Divider(color: scheme.outlineVariant, height: 1),
              const SizedBox(height: 14),
              ...List.generate(
                jpLines.length.clamp(0, 2),
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                        border: Border(
                            left:
                                BorderSide(color: scheme.primary, width: 2))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(jpLines[i],
                            style: TextStyle(
                                fontSize: 14,
                                color: scheme.onSurface,
                                height: 1.5)),
                        if (i < enLines.length)
                          Text(enLines[i],
                              style: TextStyle(
                                  fontSize: 11,
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.5),
                                  fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isJapanese(String s) => s.runes.any((r) =>
      (r >= 0x3040 && r <= 0x309F) ||
      (r >= 0x30A0 && r <= 0x30FF) ||
      (r >= 0x4E00 && r <= 0x9FFF));
}

// ─── Rating button ────────────────────────────────────────────────────────────

class _RatingBtn extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _RatingBtn(
      {required this.label,
      required this.color,
      required this.textColor,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 48,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: textColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding: EdgeInsets.zero,
          ),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3)),
        ),
      ),
    );
  }
}
