import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ivo/data/notifiers.dart';

class Article {
  final String id;
  final int? supabaseId; // articles.id — needed for bookmarking
  final String title;
  final String excerpt;
  final String level; // 'N5' | 'N4' | 'N3' | 'N2' | 'N1' | ''
  final String content;
  final int readMinutes;
  final List<String> tags;
  final String? langCode;

  const Article({
    required this.id,
    this.supabaseId,
    required this.title,
    required this.excerpt,
    this.level = '',
    required this.content,
    required this.readMinutes,
    this.tags = const [],
    this.langCode,
  });

  factory Article.fromSupabase(Map<String, dynamic> json) {
    final body = json['body'] as String? ?? '';
    final subTitle = json['sub_title'] as String?;
    final excerpt = (subTitle != null && subTitle.isNotEmpty)
        ? subTitle
        : (body.length > 100 ? '${body.substring(0, 100)}…' : body);
    final readMins = ((body.length / 600).ceil()).clamp(1, 99);

    final articles = json['articles'] as Map<String, dynamic>?;
    final articleTagsList = articles?['article_tags'] as List? ?? [];
    final tags = articleTagsList
        .map((at) => (at['tags'] as Map?)?['name'] as String? ?? '')
        .where((t) => t.isNotEmpty)
        .toList();

    final levelTag = tags.firstWhere(
      (t) => RegExp(r'^N[1-5]$').hasMatch(t),
      orElse: () => '',
    );

    return Article(
      id: json['id'].toString(),
      supabaseId: articles?['id'] as int? ?? json['article_id'] as int?,
      title: json['title'] as String? ?? '',
      excerpt: excerpt,
      level: levelTag,
      content: body,
      readMinutes: readMins,
      tags: List<String>.from(tags),
      langCode: json['language_code'] as String?,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class ArticleService {
  final _supabase = Supabase.instance.client;
  String? get _userId => _supabase.auth.currentUser?.id;

  /// Map app language code → DB language_code
  String get _lang {
    final l = languageNotifier.value;
    if (l == 'jp') return 'ja';
    return l; // 'mn' | 'en'
  }

  // ── Published articles ──────────────────────────────────────────────────────

  Future<List<Article>> getArticles({String? level}) async {
    try {
      final rows = await _supabase
          .from('article_translations')
          .select('*, articles!inner(id, status, article_tags(tags(name)))')
          .eq('articles.status', 'published')
          .eq('language_code', _lang)
          .not('published_at', 'is', null)
          .order('published_at', ascending: false)
          .limit(50);

      var articles = (rows as List)
          .map((j) => Article.fromSupabase(j as Map<String, dynamic>))
          .where((a) => a.title.isNotEmpty)
          .toList();

      if (articles.isEmpty) return _hardcodedArticles(level);

      if (level != null &&
          level != 'All' &&
          level != 'Бүх' &&
          level != 'すべて') {
        articles = articles.where((a) => a.level == level).toList();
      }
      return articles;
    } catch (_) {
      return _hardcodedArticles(level);
    }
  }

  // ── Bookmarking ─────────────────────────────────────────────────────────────

  Future<void> saveArticle(int articleId) async {
    final uid = _userId;
    if (uid == null) return;
    await _supabase.from('bookmarked_articles').upsert({
      'user_id': uid,
      'article_id': articleId,
    });
  }

  Future<void> unsaveArticle(int articleId) async {
    final uid = _userId;
    if (uid == null) return;
    await _supabase
        .from('bookmarked_articles')
        .delete()
        .eq('user_id', uid)
        .eq('article_id', articleId);
  }

  Future<bool> isArticleSaved(int articleId) async {
    final uid = _userId;
    if (uid == null) return false;
    try {
      final result = await _supabase
          .from('bookmarked_articles')
          .select('article_id')
          .eq('user_id', uid)
          .eq('article_id', articleId)
          .maybeSingle();
      return result != null;
    } catch (_) {
      return false;
    }
  }

  Future<List<Article>> getSavedArticles() async {
    final uid = _userId;
    if (uid == null) return [];
    try {
      // Step 1: get bookmarked article IDs
      final bookmarks = await _supabase
          .from('bookmarked_articles')
          .select('article_id')
          .eq('user_id', uid);

      final ids = (bookmarks as List)
          .map((b) => b['article_id'] as int)
          .toList();

      if (ids.isEmpty) return [];

      // Step 2: fetch translations for those articles
      final rows = await _supabase
          .from('article_translations')
          .select('*, articles!inner(id, status, article_tags(tags(name)))')
          .inFilter('article_id', ids)
          .eq('language_code', _lang)
          .eq('articles.status', 'published');

      return (rows as List)
          .map((j) => Article.fromSupabase(j as Map<String, dynamic>))
          .where((a) => a.title.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Hardcoded fallback ───────────────────────────────────────────────────────

  List<Article> _hardcodedArticles(String? level) {
    if (level == null ||
        level == 'All' ||
        level == 'Бүх' ||
        level == 'すべて') {
      return _fallback;
    }
    return _fallback.where((a) => a.level == level).toList();
  }

  static const _fallback = [
    Article(
      id: 'f1',
      level: 'N5',
      title: '私の家族',
      excerpt: '私には父、母、そして妹がいます。みんな仲良しです。',
      content:
          '私には父、母、そして妹がいます。みんな仲良しです。\n\n'
          '父は会社員です。毎朝早く起きて、電車で会社に行きます。\n\n'
          '母は主婦です。料理がとても上手で、毎日おいしいご飯を作ってくれます。\n\n'
          '妹は小学生です。スポーツが好きで、週末はサッカーをします。\n\n'
          '私たちは週末に一緒に公園に行ったり、映画を見たりします。\n'
          '家族みんなで過ごす時間がとても好きです。',
      readMinutes: 2,
    ),
    Article(
      id: 'f2',
      level: 'N5',
      title: '東京の天気',
      excerpt: '東京の春はとても好きです。桜の花がきれいです。',
      content:
          '東京の春はとても好きです。桜の花がきれいです。\n\n'
          '三月になると、気温が少しずつ上がります。\n\n'
          '四月には桜が満開になります。公園はお花見をする人でいっぱいです。\n\n'
          '夏は暑くて、冬は寒いです。でも、春と秋はちょうどいい気候です。\n'
          '私は春が一番好きな季節です。',
      readMinutes: 2,
    ),
    Article(
      id: 'f3',
      level: 'N4',
      title: 'アルバイト探し',
      excerpt: '大学生になって初めてアルバイトを探すことにしました。',
      content:
          '大学生になって初めてアルバイトを探すことにしました。\n\n'
          'インターネットで求人情報を調べると、カフェやコンビニなど、色々な仕事がありました。\n\n'
          '駅前のカフェに履歴書を持って面接に行きました。\n\n'
          '「週三日なら大丈夫です」と答えると、採用してもらえました。\n'
          '初めて自分でお金を稼いだとき、とてもうれしかったです。',
      readMinutes: 3,
    ),
    Article(
      id: 'f4',
      level: 'N4',
      title: '日本の食文化',
      excerpt: '日本の食文化は非常に多様で、地域によって様々な料理があります。',
      content:
          '日本の食文化は非常に多様で、地域によって様々な料理があります。\n\n'
          '東京では寿司や天ぷらが有名ですが、大阪ではたこ焼きやお好み焼きなどが人気です。\n\n'
          '日本の食事マナーも独特です。食事の前に「いただきます」、\n'
          '食事の後に「ごちそうさまでした」と言います。',
      readMinutes: 3,
    ),
    Article(
      id: 'f5',
      level: 'N3',
      title: '環境問題と私たちの生活',
      excerpt: '近年、地球温暖化や環境汚染などの問題が深刻になっています。',
      content:
          '近年、地球温暖化や環境汚染などの問題が深刻になっています。\n\n'
          '二酸化炭素の排出量が増え続けることで、地球の平均気温が上昇し、\n'
          '異常気象や海面上昇などの問題が起きています。\n\n'
          '日本では「もったいない」という言葉があります。\n'
          'ひとりひとりが意識を変えることが、大きな変化につながります。',
      readMinutes: 4,
    ),
    Article(
      id: 'f6',
      level: 'N2',
      title: '人工知能と未来社会',
      excerpt: 'AIの急速な発展は、私たちの社会を根本から変えつつあります。',
      content:
          '人工知能（AI）技術の急速な発展は、私たちの社会を根本から変えつつあります。\n\n'
          '医療分野では、AIが画像診断や新薬開発に活用されています。\n\n'
          '一方で、AIの普及によって多くの職業が自動化される懸念もあります。\n\n'
          '重要なのは、変化に適応し、AIと共存していく能力を身につけることです。',
      readMinutes: 4,
    ),
    Article(
      id: 'f7',
      level: 'N1',
      title: '少子高齢化社会の課題',
      excerpt: '日本は世界でも有数の少子高齢化社会であり、様々な社会的課題に直面しています。',
      content:
          '日本は世界でも有数の少子高齢化社会であり、様々な社会的課題に直面しています。\n\n'
          '現在、日本の総人口に占める65歳以上の高齢者の割合は約29％に達しています。\n\n'
          '政府は少子化対策として保育所の拡充や育児休業の取得促進を進めていますが、\n'
          '抜本的な解決策には至っていません。',
      readMinutes: 5,
    ),
  ];
}
