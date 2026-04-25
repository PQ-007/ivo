import 'package:flutter/material.dart';
import 'package:ivo/data/l10n.dart';
import 'package:ivo/services/article_service.dart';
import 'package:ivo/services/db_helper.dart';

class ArticleDetailPage extends StatefulWidget {
  final Article article;
  const ArticleDetailPage({super.key, required this.article});

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  final _service = ArticleService();
  bool _saved = false;
  bool _savedLoading = false;

  @override
  void initState() {
    super.initState();
    _initSaved();
  }

  Future<void> _initSaved() async {
    final id = widget.article.supabaseId;
    if (id == null) return;
    final saved = await _service.isArticleSaved(id);
    if (mounted) setState(() => _saved = saved);
  }

  Future<void> _toggleSaved() async {
    final id = widget.article.supabaseId;
    // No Supabase id — just toggle locally (hardcoded fallback article)
    if (id == null) {
      setState(() => _saved = !_saved);
      return;
    }
    setState(() => _savedLoading = true);
    try {
      if (_saved) {
        await _service.unsaveArticle(id);
      } else {
        await _service.saveArticle(id);
      }
      if (mounted) setState(() { _saved = !_saved; _savedLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _savedLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final a = widget.article;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: scheme.surface,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              _savedLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2)))
                  : IconButton(
                      icon: Icon(
                          _saved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: _saved ? scheme.primary : scheme.onSurface),
                      onPressed: _toggleSaved,
                    ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              title: Text(a.title,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface)),
              collapseMode: CollapseMode.parallax,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Level + read time row
                  Row(children: [
                    if (a.level.isNotEmpty) ...[
                      _LevelBadge(a.level, scheme: scheme),
                      const SizedBox(width: 10),
                    ],
                    Icon(Icons.access_time_rounded,
                        size: 14,
                        color: scheme.onSurface.withValues(alpha: 0.45)),
                    const SizedBox(width: 4),
                    Text('${a.readMinutes} ${t('articles_read_min')}',
                        style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurface.withValues(alpha: 0.55))),
                  ]),
                  const SizedBox(height: 20),
                  Divider(color: scheme.outlineVariant),
                  const SizedBox(height: 16),

                  // Content — tappable words
                  _TappableJapaneseText(text: a.content, scheme: scheme),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _savedLoading ? null : _toggleSaved,
                      icon: Icon(_saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded),
                      label: Text(
                          _saved ? t('articles_saved') : t('articles_save')),
                      style: FilledButton.styleFrom(
                        backgroundColor: _saved
                            ? scheme.primary
                            : scheme.surfaceContainerHigh,
                        foregroundColor:
                            _saved ? scheme.onPrimary : scheme.onSurface,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders Japanese text as inline tappable character groups.
class _TappableJapaneseText extends StatelessWidget {
  final String text;
  final ColorScheme scheme;
  const _TappableJapaneseText({required this.text, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final paragraphs = text.split('\n\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((p) {
        final lines = p.split('\n');
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: lines
                .map((line) => GestureDetector(
                      onLongPress: () => _showDefinition(context, line.trim()),
                      child: Text(
                        line,
                        style: TextStyle(
                            fontSize: 17,
                            height: 1.9,
                            color: scheme.onSurface,
                            letterSpacing: 0.2),
                      ),
                    ))
                .toList(),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _showDefinition(BuildContext context, String word) async {
    if (word.isEmpty) return;
    final scheme = Theme.of(context).colorScheme;
    final result =
        await JishoDB.search(word.length > 4 ? word.substring(0, 4) : word);
    final entries = result['result'] as List? ?? [];
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(word,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface)),
              const SizedBox(height: 12),
              if (entries.isEmpty)
                Text(t('common_error'),
                    style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.5)))
              else ...[
                for (final entry in entries.take(3)) ...[
                  if ((entry['kanji'] as List?)?.isNotEmpty == true)
                    Text((entry['kanji'] as List).first.toString(),
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface)),
                  if ((entry['reading'] as List?)?.isNotEmpty == true)
                    Text((entry['reading'] as List).first.toString(),
                        style: TextStyle(
                            fontSize: 14,
                            color:
                                scheme.onSurface.withValues(alpha: 0.55))),
                  if ((entry['senses'] as List?)?.isNotEmpty == true)
                    ...(((entry['senses'] as List).first['glosses'] as List?)
                                ?.take(2) ??
                            [])
                        .map((g) => Text('• $g',
                            style: TextStyle(
                                fontSize: 14,
                                color: scheme.onSurface
                                    .withValues(alpha: 0.8)))),
                  const SizedBox(height: 8),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final String level;
  final ColorScheme scheme;
  const _LevelBadge(this.level, {required this.scheme});

  Color get _color => switch (level) {
        'N5' => const Color(0xFF4CAF50),
        'N4' => const Color(0xFF2196F3),
        'N3' => const Color(0xFFFF9800),
        'N2' => const Color(0xFFF44336),
        'N1' => const Color(0xFF9C27B0),
        _ => const Color(0xFF607D8B),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(99)),
      child: Text(level,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _color,
              letterSpacing: 1)),
    );
  }
}
