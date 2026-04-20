// lib/view/pages/flashcard/flashcard_list_page.dart

import 'package:flutter/material.dart';
import 'package:ivo/components/flashcard/deck_preview.dart';
import 'package:ivo/data/models/flashcard_models.dart';
import 'package:ivo/services/flashcard_service.dart';

class FlashcardList extends StatefulWidget {
  const FlashcardList({super.key});

  @override
  State<FlashcardList> createState() => _FlashcardListState();
}

class _FlashcardListState extends State<FlashcardList> {
  final _service = FlashcardService();
  List<FlashcardFolder> _folders = [];
  List<FlashcardDeck> _rootDecks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final decks = await _service.getDecks();
      if (!mounted) return;
      if (decks.isNotEmpty) {
        setState(() {
          _folders = [];
          _rootDecks = decks;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    final now = DateTime.now();
    final mockDecks = <FlashcardDeck>[
      FlashcardDeck(id: -1, ownerId: '', slug: 'jlpt-n5-core', name: 'JLPT N5 · Core', description: 'Essentials', cardCount: 800, createdAt: now, updatedAt: now),
      FlashcardDeck(id: -2, ownerId: '', slug: 'travel-japan', name: 'Travel Japan', description: 'Phrases', cardCount: 120, createdAt: now, updatedAt: now),
      FlashcardDeck(id: -3, ownerId: '', slug: 'food-eating', name: 'Food & Eating', description: 'Vocab', cardCount: 140, createdAt: now, updatedAt: now),
      FlashcardDeck(id: -4, ownerId: '', slug: 'everyday-body', name: 'Everyday Body', description: 'Starter', cardCount: 90, createdAt: now, updatedAt: now),
      FlashcardDeck(id: -5, ownerId: '', slug: 'business-japanese', name: 'Business Japanese', description: 'Advanced', cardCount: 60, createdAt: now, updatedAt: now),
    ];

    if (!mounted) return;
    setState(() {
      _folders = [];
      _rootDecks = mockDecks;
      _isLoading = false;
    });
  }

  void _showCreateFolderDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Шинэ хавтас үүсгэх'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Нэр'),
                  autofocus: true,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Тайлбар (optional)',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Цуцлах'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) return;
                  final now = DateTime.now();
                  final folder = FlashcardFolder(
                    id: 'folder-${now.microsecondsSinceEpoch}',
                    name: nameController.text.trim(),
                    description:
                        descController.text.trim().isEmpty
                            ? null
                            : descController.text.trim(),
                    userId: 'ui-preview',
                    createdAt: now,
                    updatedAt: now,
                  );
                  if (!mounted) return;
                  setState(() {
                    _folders = [folder, ..._folders];
                  });
                  Navigator.pop(context);
                },
                child: const Text('Үүсгэх'),
              ),
            ],
          ),
    );
  }

  void _showCreateDeckDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Шинэ дэк үүсгэх'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Нэр'),
                  autofocus: true,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Тайлбар (optional)',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Цуцлах'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) return;
                  final now = DateTime.now();
                  final name = nameController.text.trim();
                  final deck = FlashcardDeck(
                    id: -now.microsecondsSinceEpoch,
                    ownerId: '',
                    name: name,
                    slug: name.toLowerCase().replaceAll(RegExp(r'\s+'), '-'),
                    description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                    cardCount: 0,
                    createdAt: now,
                    updatedAt: now,
                  );
                  if (!mounted) return;
                  setState(() {
                    _rootDecks = [deck, ..._rootDecks];
                  });
                  Navigator.pop(context);
                },
                child: const Text('Үүсгэх'),
              ),
            ],
          ),
    );
  }

  void _showCreateMenu() {
    final palette = _DeckListPalette.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: palette.sheetBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create',
                    style: TextStyle(
                      color: palette.primaryText,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    tileColor: palette.surfaceRaised,
                    leading: Icon(Icons.style_outlined, color: palette.primaryText),
                    title: Text(
                      'Шинэ дэк',
                      style: TextStyle(color: palette.primaryText),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showCreateDeckDialog();
                    },
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    tileColor: palette.surfaceRaised,
                    leading: Icon(Icons.folder_outlined, color: palette.primaryText),
                    title: Text(
                      'Шинэ хавтас',
                      style: TextStyle(color: palette.primaryText),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showCreateFolderDialog();
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _DeckListPalette.of(context);

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: palette.accent),
      );
    }

    if (_folders.isEmpty && _rootDecks.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [palette.backgroundTop, palette.backgroundBottom],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.style_outlined,
                  size: 42,
                  color: palette.primaryText,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Deck байхгүй байна',
                style: TextStyle(
                  color: palette.primaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Эхний deck-ээ үүсгээд эхлээрэй.',
                style: TextStyle(color: palette.secondaryText, fontSize: 14),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _showCreateDeckDialog,
                icon: const Icon(Icons.add),
                style: FilledButton.styleFrom(
                  backgroundColor: palette.accent,
                  foregroundColor: palette.onAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                label: const Text('Дэк үүсгэх'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.backgroundTop, palette.backgroundBottom],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: palette.accent,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 130),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LIBRARY',
                        style: TextStyle(
                          color: palette.tertiaryText,
                          letterSpacing: 3,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your decks.',
                        style: TextStyle(
                          color: palette.primaryText,
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          height: 0.95,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _showCreateMenu,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: palette.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add, color: palette.onAccent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ..._rootDecks.map(
              (deck) => _DeckCard(
                deck: deck,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DeckPreview(deck: deck)),
                  );
                  if (mounted) {
                    _loadData();
                  }
                },
                onDelete: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Дэк устгах'),
                          content: const Text(
                            'Энэ дэк болон бүх картууд устах болно. Та итгэлтэй байна уу?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Цуцлах'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.error,
                              ),
                              child: const Text('Устгах'),
                            ),
                          ],
                        ),
                  );
                  if (confirm == true) {
                    if (!mounted) return;
                    setState(() {
                      _rootDecks =
                          _rootDecks.where((item) => item.id != deck.id).toList();
                    });
                  }
                },
              ),
            ),
            if (_folders.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Folders',
                style: TextStyle(
                  color: palette.tertiaryText,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              ..._folders.map(
                (folder) => _FolderCard(
                  folder: folder,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Folder preview is disabled in UI-only mode.'),
                      ),
                    );
                  },
                  onDelete: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Хавтас устгах'),
                            content: const Text(
                              'Энэ хавтас болон доторх бүх дэк устах болно. Та итгэлтэй байна уу?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Цуцлах'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                ),
                                child: const Text('Устгах'),
                              ),
                            ],
                          ),
                    );
                    if (confirm == true) {
                      if (!mounted) return;
                      setState(() {
                        _folders =
                            _folders.where((item) => item.id != folder.id).toList();
                      });
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final FlashcardFolder folder;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FolderCard({
    required this.folder,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _DeckListPalette.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: palette.surfaceRaised,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.folder_outlined, color: palette.primaryText),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        folder.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.primaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (folder.description ?? 'COLLECTION').toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.tertiaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: onDelete,
                  color: palette.delete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeckCard extends StatelessWidget {
  final FlashcardDeck deck;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DeckCard({
    required this.deck,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _DeckListPalette.of(context);
    final total = deck.cardCount;
    final learned = total == 0 ? 0 : ((total * 0.43).round()).clamp(1, total);
    final progress = total == 0 ? 0.0 : learned / total;
    final glyph = _deckGlyph(deck.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.surface, palette.surfaceRaised],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.22),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: palette.surfaceRaised,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      glyph,
                      style: TextStyle(
                        fontSize: 34,
                        color: palette.primaryText,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deck.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.primaryText,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          height: 0.95,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        (deck.description ?? 'ESSENTIALS').toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.tertiaryText,
                          letterSpacing: 2,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          backgroundColor: palette.progressTrack,
                          valueColor: AlwaysStoppedAnimation(palette.progressFill),
                          value: progress,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            '$learned / $total',
                            style: TextStyle(
                              color: palette.secondaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(progress * 100).round()}%',
                            style: TextStyle(
                              color: palette.tertiaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: onDelete,
                  color: palette.delete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _deckGlyph(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '語';
    final first = trimmed.substring(0, 1);
    final code = first.codeUnitAt(0);
    final isAscii = code <= 127;
    return isAscii ? '語' : first;
  }
}

class _DeckListPalette {
  final Color backgroundTop;
  final Color backgroundBottom;
  final Color sheetBackground;
  final Color surface;
  final Color surfaceRaised;
  final Color primaryText;
  final Color secondaryText;
  final Color tertiaryText;
  final Color accent;
  final Color onAccent;
  final Color delete;
  final Color progressTrack;
  final Color progressFill;

  const _DeckListPalette({
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.sheetBackground,
    required this.surface,
    required this.surfaceRaised,
    required this.primaryText,
    required this.secondaryText,
    required this.tertiaryText,
    required this.accent,
    required this.onAccent,
    required this.delete,
    required this.progressTrack,
    required this.progressFill,
  });

  factory _DeckListPalette.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _DeckListPalette(
      backgroundTop: scheme.surfaceContainerHighest,
      backgroundBottom: scheme.surfaceContainerLow,
      sheetBackground: scheme.surface,
      surface: scheme.surfaceContainer,
      surfaceRaised: scheme.surfaceContainerHigh,
      primaryText: scheme.onSurface,
      secondaryText: scheme.onSurface.withOpacity(0.74),
      tertiaryText: scheme.onSurface.withOpacity(0.58),
      accent: scheme.primary,
      onAccent: scheme.onPrimary,
      delete: scheme.error,
      progressTrack: scheme.outlineVariant,
      progressFill: scheme.primary,
    );
  }
}
