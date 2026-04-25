import 'package:flutter/material.dart';
import 'package:ivo/components/buttons/profile_nav_button.dart';
import 'package:ivo/components/buttons/settings_nav_button.dart';
import 'package:ivo/components/common/app_bar.dart';
import 'package:ivo/components/flashcard/flashcard-list.dart';
import 'package:ivo/data/l10n.dart';
import 'package:ivo/services/article_service.dart';
import 'package:ivo/view/pages/article-detail-page/index.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: MyAppBar(
          button1: SettingsNavButton(),
          button2: ProfileNavButton(),
          titleText: t('library_title'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  _buildTab(t('library_tab_articles'), 0),
                  _buildTab(t('library_tab_flashcards'), 1),
                  _buildTab(t('library_tab_audio'), 2),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: const [
                  _SavedArticlesTab(),
                  FlashcardList(),
                  Center(child: Placeholder()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _currentIndex == index;
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? scheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                color:
                    isSelected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SavedArticlesTab extends StatefulWidget {
  const _SavedArticlesTab();

  @override
  State<_SavedArticlesTab> createState() => _SavedArticlesTabState();
}

class _SavedArticlesTabState extends State<_SavedArticlesTab> {
  final _service = ArticleService();
  List<Article>? _articles;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final articles = await _service.getSavedArticles();
    if (mounted) setState(() { _articles = articles; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: scheme.primary));
    }

    final articles = _articles ?? [];

    if (articles.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        color: scheme.primary,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Icon(Icons.bookmark_border_rounded,
                size: 64, color: scheme.onSurface.withValues(alpha: 0.25)),
            const SizedBox(height: 16),
            Text(
              t('library_tab_articles'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                t('library_no_saved_articles'),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: scheme.onSurface.withValues(alpha: 0.5)),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: scheme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
        itemCount: articles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final a = articles[i];
          return _SavedArticleCard(
            article: a,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ArticleDetailPage(article: a)),
              );
              _load(); // refresh in case user un-saved from detail page
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SavedArticleCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;
  const _SavedArticleCard({required this.article, required this.onTap});

  Color _levelColor(String level) => switch (level) {
        'N5' => const Color(0xFF4CAF50),
        'N4' => const Color(0xFF2196F3),
        'N3' => const Color(0xFFFF9800),
        'N2' => const Color(0xFFF44336),
        'N1' => const Color(0xFF9C27B0),
        _ => const Color(0xFF607D8B),
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final a = article;
    final color = _levelColor(a.level);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.07),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              if (a.level.isNotEmpty) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(a.level,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: 1)),
                ),
                const SizedBox(width: 8),
              ],
              const Spacer(),
              Icon(Icons.bookmark_rounded,
                  size: 14, color: scheme.primary.withValues(alpha: 0.7)),
              const SizedBox(width: 4),
              Icon(Icons.access_time_rounded,
                  size: 13,
                  color: scheme.onSurface.withValues(alpha: 0.4)),
              const SizedBox(width: 3),
              Text('${a.readMinutes} ${t('articles_read_min')}',
                  style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withValues(alpha: 0.5))),
            ]),
            const SizedBox(height: 8),
            Text(a.title,
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface)),
            const SizedBox(height: 6),
            Text(a.excerpt,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: scheme.onSurface.withValues(alpha: 0.65))),
          ],
        ),
      ),
    );
  }
}
