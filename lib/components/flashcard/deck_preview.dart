import 'package:flutter/material.dart';
import 'package:ivo/data/l10n.dart';
import 'package:ivo/data/models/flashcard_models.dart';
import 'package:ivo/services/flashcard_service.dart';
import 'package:ivo/view/pages/session-start-page/index.dart';

class DeckPreview extends StatefulWidget {
  final FlashcardDeck deck;
  const DeckPreview({super.key, required this.deck});

  @override
  State<DeckPreview> createState() => _DeckPreviewState();
}

class _DeckPreviewState extends State<DeckPreview> {
  final _service = FlashcardService();
  final _pageController = PageController();
  List<Flashcard> _cards = [];
  int _current = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final cards = await _service.getFlashcards(widget.deck.id);
      if (!mounted) return;
      setState(() {
        _cards = cards.isNotEmpty ? cards : _mockCards();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cards = _mockCards();
        _loading = false;
      });
    }
  }

  List<Flashcard> _mockCards() {
    final now = DateTime.now();
    final did = widget.deck.id;
    return [
      Flashcard(id: -1, userId: '', deckId: did, front: '東京', back: 'Tokyo', pronunciation: 'とうきょう · tōkyō', hint: '東京に行くことになっています。\nI am supposed to go to Tokyo.\n来週私は仕事で東京にいます。\nI\'ll be in Tokyo on business next week.', type: FlashcardType.word, createdAt: now, updatedAt: now),
      Flashcard(id: -2, userId: '', deckId: did, front: '時間', back: 'time', pronunciation: 'じかん · jikan', hint: '時間がありますか？\nDo you have time?\n時間を大切にしてください。\nPlease value your time.', type: FlashcardType.word, createdAt: now, updatedAt: now),
      Flashcard(id: -3, userId: '', deckId: did, front: '日本', back: 'Japan', pronunciation: 'にほん · nihon', hint: '日本の文化が好きです。\nI like Japanese culture.', type: FlashcardType.word, createdAt: now, updatedAt: now),
      Flashcard(id: -4, userId: '', deckId: did, front: '午前', back: 'morning / AM', pronunciation: 'ごぜん · gozen', hint: '午前中に会いましょう。\nLet\'s meet in the morning.', type: FlashcardType.word, createdAt: now, updatedAt: now),
      Flashcard(id: -5, userId: '', deckId: did, front: '来月', back: 'next month', pronunciation: 'らいげつ · raigetsu', hint: '来月から始めます。\nI\'ll start next month.', type: FlashcardType.word, createdAt: now, updatedAt: now),
      Flashcard(id: -6, userId: '', deckId: did, front: '今日', back: 'today', pronunciation: 'きょう · kyō', hint: '今日はいい天気ですね。\nThe weather is nice today.', type: FlashcardType.word, createdAt: now, updatedAt: now),
      Flashcard(id: -7, userId: '', deckId: did, front: '午後', back: 'afternoon / PM', pronunciation: 'ごご · gogo', hint: '午後から雨が降ります。\nIt will rain from the afternoon.', type: FlashcardType.word, createdAt: now, updatedAt: now),
    ];
  }

  void _showAddCardDialog() {
    final frontCtrl = TextEditingController();
    final backCtrl = TextEditingController();
    final pronCtrl = TextEditingController();
    final hintCtrl = TextEditingController();
    var selectedType = FlashcardType.word;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Create card'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<FlashcardType>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: FlashcardType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                    onChanged: (v) { if (v != null) setDialog(() => selectedType = v); },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(controller: frontCtrl, autofocus: true, decoration: const InputDecoration(labelText: 'Front'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                  const SizedBox(height: 12),
                  TextFormField(controller: backCtrl, decoration: const InputDecoration(labelText: 'Back'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                  const SizedBox(height: 12),
                  TextFormField(controller: pronCtrl, decoration: const InputDecoration(labelText: 'Pronunciation')),
                  const SizedBox(height: 12),
                  TextFormField(controller: hintCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Examples (one per line)')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('common_cancel'))),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() != true) return;
                try {
                  await _service.createFlashcard(widget.deck.id, frontCtrl.text.trim(), backCtrl.text.trim(), pronCtrl.text.trim().isEmpty ? null : pronCtrl.text.trim(), hintCtrl.text.trim().isEmpty ? null : hintCtrl.text.trim(), selectedType);
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  _load();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                }
              },
              child: Text(t('common_create')),
            ),
          ],
        ),
      ),
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

    return Scaffold(
      backgroundColor: scheme.surface,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => SessionStartPage(deck: widget.deck))),
        backgroundColor: scheme.tertiary,
        foregroundColor: scheme.onTertiary,
        elevation: 2,
        shape: const CircleBorder(),
        child: const Icon(Icons.play_arrow_rounded, size: 28),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 14),
            _buildChrome(scheme),
            _buildTicker(scheme),
            Expanded(
              child: _cards.isEmpty
                  ? _buildEmpty(scheme)
                  : PageView.builder(
                      controller: _pageController,
                      itemCount: _cards.length,
                      onPageChanged: (i) => setState(() => _current = i),
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                        child: GestureDetector(
                          onLongPress: _showAddCardDialog,
                          child: _KotobaCardView(card: _cards[i], scheme: scheme),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChrome(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 22, height: 2, color: scheme.onSurface.withValues(alpha:0.9)),
                const SizedBox(height: 4),
                Container(width: 16, height: 2, color: scheme.onSurface.withValues(alpha:0.9)),
                const SizedBox(height: 4),
                Container(width: 22, height: 2, color: scheme.onSurface.withValues(alpha:0.9)),
              ],
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 7, height: 7, decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('${_current + 1}', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: scheme.onSurface, height: 1)),
                ],
              ),
              const SizedBox(height: 3),
              Text('/${_cards.length}', style: TextStyle(fontSize: 11, color: scheme.onSurface.withValues(alpha:0.5), letterSpacing: 0.6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTicker(ColorScheme scheme) {
    return SizedBox(
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_cards.length, (i) {
                final active = i == _current;
                final front = _cards[i].front;
                final label = front.length > 4 ? front.substring(0, 4) : front;
                return GestureDetector(
                  onTap: () => _pageController.animateToPage(i, duration: const Duration(milliseconds: 280), curve: Curves.easeInOut),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    child: Text(label, style: TextStyle(fontSize: 14, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? scheme.onSurface : scheme.onSurface.withValues(alpha:0.22))),
                  ),
                );
              }),
            ),
          ),
          Positioned(bottom: 2, child: Container(width: 3, height: 3, decoration: BoxDecoration(color: scheme.onSurface, shape: BoxShape.circle))),
          Positioned(left: 0, top: 0, bottom: 0, child: IgnorePointer(child: Container(width: 48, decoration: BoxDecoration(gradient: LinearGradient(colors: [scheme.surface, scheme.surface.withValues(alpha:0)]))))),
          Positioned(right: 0, top: 0, bottom: 0, child: IgnorePointer(child: Container(width: 48, decoration: BoxDecoration(gradient: LinearGradient(colors: [scheme.surface.withValues(alpha:0), scheme.surface]))))),
        ],
      ),
    );
  }

  Widget _buildEmpty(ColorScheme scheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.style_outlined, size: 56, color: scheme.onSurface.withValues(alpha:0.3)),
          const SizedBox(height: 16),
          Text('No cards yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: scheme.onSurface.withValues(alpha:0.5))),
          const SizedBox(height: 20),
          FilledButton.icon(onPressed: _showAddCardDialog, icon: const Icon(Icons.add), label: Text(t('deck_add_card'))),
        ],
      ),
    );
  }
}

// ─── Full card view (both front + back visible) ───────────────────────────────

class _KotobaCardView extends StatelessWidget {
  final Flashcard card;
  final ColorScheme scheme;

  const _KotobaCardView({required this.card, required this.scheme});

  /// Adaptive font size for the back / meaning text.
  double _backFontSize(String text) {
    final n = text.runes.length;
    if (n <= 10) return 28;
    if (n <= 20) return 22;
    if (n <= 40) return 18;
    return 15;
  }

  @override
  Widget build(BuildContext context) {
    final lines = (card.hint ?? '').split('\n').where((l) => l.trim().isNotEmpty).toList();
    final jpLines = lines.where(_isJapanese).toList();
    final enLines = lines.where((l) => !_isJapanese(l)).toList();
    final backFs = _backFontSize(card.back);

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.15),
              blurRadius: 28,
              offset: const Offset(0, 14))
        ],
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 52),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Front glyph: fixed 200dp tall, FittedBox fills it for
                //    short words (東京 → huge) and scales down for long text ──
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    child: Text(
                      card.front,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 160,
                        fontWeight: FontWeight.w500,
                        height: 0.95,
                        letterSpacing: -3.0,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Back / meaning ──
                Text(
                  card.back,
                  style: TextStyle(
                    fontSize: backFs,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: scheme.onSurface,
                  ),
                ),
                if (card.pronunciation != null && card.pronunciation!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(card.pronunciation!,
                      style: TextStyle(
                          fontSize: 14,
                          color: scheme.onSurface.withValues(alpha: 0.5))),
                ],
                const SizedBox(height: 6),
                Text(
                  card.type.name.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurface.withValues(alpha: 0.45),
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w700),
                ),

                // ── Example sentences ──
                if (jpLines.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Divider(color: scheme.outlineVariant, height: 1),
                  const SizedBox(height: 14),
                  ...List.generate(
                    jpLines.length.clamp(0, 3),
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(jpLines[i],
                              style: TextStyle(
                                  fontSize: 15, color: scheme.onSurface)),
                          if (i < enLines.length)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(enLines[i],
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: scheme.onSurface
                                          .withValues(alpha: 0.5),
                                      fontStyle: FontStyle.italic)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Accent dot
          Positioned(
            right: 18,
            bottom: 18,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: scheme.tertiary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: scheme.tertiary.withValues(alpha: 0.45),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isJapanese(String s) => s.runes.any((r) =>
      (r >= 0x3040 && r <= 0x309F) ||
      (r >= 0x30A0 && r <= 0x30FF) ||
      (r >= 0x4E00 && r <= 0x9FFF));
}
