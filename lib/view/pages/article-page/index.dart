import 'package:flutter/material.dart';
import 'package:ivo/components/buttons/dark_mode_button.dart';
import 'package:ivo/components/common/app_bar.dart';
import 'package:ivo/data/l10n.dart';
import 'package:ivo/services/article_service.dart';
import 'package:ivo/view/pages/article-detail-page/index.dart';

class ArticlePage extends StatefulWidget {
  const ArticlePage({super.key});

  @override
  State<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends State<ArticlePage> {
  final _service = ArticleService();
  String _selectedLevel = 'All';
  final _levels = ['All', 'N5', 'N4', 'N3', 'N2', 'N1'];

  List<Article> get _filtered => _service.getArticles(level: _selectedLevel);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: MyAppBar(
        titleText: t('articles_title'),
        button1: DarkModeButton(),
        button2: const SizedBox.shrink(),
      ),
      body: Column(
        children: [
          // ── Filter chips ────────────────────────────────────────────────
          SizedBox(
            height: 50,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              scrollDirection: Axis.horizontal,
              itemCount: _levels.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final level = _levels[i];
                final selected = _selectedLevel == level;
                final label = level == 'All' ? t('articles_filter_all') : level;
                return GestureDetector(
                  onTap: () => setState(() => _selectedLevel = level),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? scheme.primary : scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? scheme.onPrimary : scheme.onSurface,
                        )),
                  ),
                );
              },
            ),
          ),

          // ── Article list ────────────────────────────────────────────────
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(t('articles_empty'),
                        style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.4), fontSize: 16)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _ArticleCard(
                      article: _filtered[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ArticleDetailPage(article: _filtered[i])),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;
  const _ArticleCard({required this.article, required this.onTap});

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
    final color = _levelColor(article.level);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: scheme.shadow.withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level + read time
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(article.level,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color, letterSpacing: 1)),
              ),
              const Spacer(),
              Icon(Icons.access_time_rounded, size: 13, color: scheme.onSurface.withValues(alpha: 0.4)),
              const SizedBox(width: 3),
              Text('${article.readMinutes} ${t('articles_read_min')}',
                  style: TextStyle(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.5))),
            ]),
            const SizedBox(height: 8),

            // Title
            Text(article.title,
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: scheme.onSurface)),
            const SizedBox(height: 6),

            // Excerpt
            Text(article.excerpt,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, height: 1.5, color: scheme.onSurface.withValues(alpha: 0.65))),
          ],
        ),
      ),
    );
  }
}
