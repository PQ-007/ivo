// lib/view/pages/flashcard/deck_preview_page.dart

import 'package:flutter/material.dart';
import 'package:ivo/data/models/flashcard_models.dart';
import 'package:ivo/services/flashcard_service.dart';

class DeckPreview extends StatefulWidget {
  final FlashcardDeck deck;

  const DeckPreview({super.key, required this.deck});

  @override
  State<DeckPreview> createState() => _DeckPreviewPageState();
}

class _DeckPreviewPageState extends State<DeckPreview> {
  final _flashcardService = FlashcardService();
  List<Flashcard> _flashcards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFlashcards();
  }

  Future<void> _loadFlashcards() async {
    setState(() => _isLoading = true);
    try {
      final flashcards = await _flashcardService.getFlashcards(widget.deck.id);
      setState(() {
        _flashcards = flashcards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading flashcards: $e')));
      }
    }
  }

  void _showAddCardDialog() {
    final frontController = TextEditingController();
    final backController = TextEditingController();
    final pronunciationController = TextEditingController();
    final hintController = TextEditingController();
    FlashcardType selectedType = FlashcardType.word;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Шинэ карт үүсгэх'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<FlashcardType>(
                          initialValue: selectedType,
                          decoration: const InputDecoration(labelText: 'Төрөл'),
                          items:
                              FlashcardType.values.map((type) {
                                String label;
                                switch (type) {
                                  case FlashcardType.word:
                                    label = 'Үг';
                                    break;
                                  case FlashcardType.kanji:
                                    label = 'Ханз';
                                    break;
                                  case FlashcardType.sentence:
                                    label = 'Өгүүлбэр';
                                    break;
                                  case FlashcardType.vocab:
                                    label = 'Vocabulary';
                                    break;
                                }
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(label),
                                );
                              }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => selectedType = value);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: frontController,
                          decoration: const InputDecoration(
                            labelText: 'Урд тал',
                            hintText: 'Японоор бичих',
                          ),
                          autofocus: true,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: backController,
                          decoration: const InputDecoration(
                            labelText: 'Ар тал',
                            hintText: 'Монголоор орчуулга',
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 8),
                        if (selectedType == FlashcardType.word ||
                            selectedType == FlashcardType.vocab)
                          TextField(
                            controller: pronunciationController,
                            decoration: const InputDecoration(
                              labelText: 'Дуудлага (optional)',
                              hintText: 'Хэрхэн дуудах',
                            ),
                          ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: hintController,
                          decoration: const InputDecoration(
                            labelText: 'Hint (optional)',
                            hintText: 'Нэмэлт тайлбар',
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Цуцлах'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (frontController.text.trim().isEmpty ||
                            backController.text.trim().isEmpty) {
                          return;
                        }
                        try {
                          await _flashcardService.createFlashcard(
                            widget.deck.id,
                            frontController.text.trim(),
                            backController.text.trim(),
                            pronunciationController.text.trim().isEmpty
                                ? null
                                : pronunciationController.text.trim(),
                            hintController.text.trim().isEmpty
                                ? null
                                : hintController.text.trim(),
                            selectedType,
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            _loadFlashcards();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      child: const Text('Үүсгэх'),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.deck.name),
            Text(
              '${_flashcards.length} карт',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddCardDialog,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _flashcards.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.style_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Энэ дэкт карт байхгүй байна',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _showAddCardDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Карт нэмэх'),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // Header with action buttons
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Column(
                      children: [
                        if (widget.deck.description != null) ...[
                          Text(
                            widget.deck.description!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // TODO: Navigate to practice mode
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Practice mode coming soon!',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Дасгал хийх'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                // TODO: Navigate to study mode
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Study mode coming soon!'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.school),
                              label: const Text('Суралцах'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Flashcard list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _flashcards.length,
                      itemBuilder: (context, index) {
                        final card = _flashcards[index];
                        return _FlashcardPreviewCard(
                          flashcard: card,
                          index: index + 1,
                          onDelete: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text('Карт устгах'),
                                    content: const Text(
                                      'Энэ картыг устгах уу?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, false),
                                        child: const Text('Цуцлах'),
                                      ),
                                      ElevatedButton(
                                        onPressed:
                                            () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        child: const Text('Устгах'),
                                      ),
                                    ],
                                  ),
                            );
                            if (confirm == true) {
                              try {
                                await _flashcardService.deleteFlashcard(
                                  card.id,
                                );
                                _loadFlashcards();
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
      floatingActionButton:
          _flashcards.isNotEmpty
              ? FloatingActionButton(
                onPressed: _showAddCardDialog,
                child: const Icon(Icons.add),
              )
              : null,
    );
  }
}

class _FlashcardPreviewCard extends StatefulWidget {
  final Flashcard flashcard;
  final int index;
  final VoidCallback onDelete;

  const _FlashcardPreviewCard({
    required this.flashcard,
    required this.index,
    required this.onDelete,
  });

  @override
  State<_FlashcardPreviewCard> createState() => _FlashcardPreviewCardState();
}

class _FlashcardPreviewCardState extends State<_FlashcardPreviewCard> {
  bool _showBack = false;

  String _getTypeLabel(FlashcardType type) {
    switch (type) {
      case FlashcardType.word:
        return 'Үг';
      case FlashcardType.kanji:
        return 'Ханз';
      case FlashcardType.sentence:
        return 'Өгүүлбэр';
      case FlashcardType.vocab:
        return 'Vocab';
    }
  }

  Color _getTypeColor(FlashcardType type) {
    switch (type) {
      case FlashcardType.word:
        return Colors.blue;
      case FlashcardType.kanji:
        return Colors.red;
      case FlashcardType.sentence:
        return Colors.green;
      case FlashcardType.vocab:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '${widget.index}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getTypeColor(
                      widget.flashcard.type,
                    ).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getTypeLabel(widget.flashcard.type),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getTypeColor(widget.flashcard.type),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: widget.onDelete,
                  color: Colors.red,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Content
          InkWell(
            onTap: () => setState(() => _showBack = !_showBack),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _showBack ? 'Ар тал' : 'Урд тал',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _showBack ? Icons.flip_to_front : Icons.flip_to_back,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _showBack ? widget.flashcard.back : widget.flashcard.front,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!_showBack && widget.flashcard.pronunciation != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.flashcard.pronunciation!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  if (widget.flashcard.hint != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 16,
                            color: Colors.amber.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.flashcard.hint!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Дарж эргүүлэх',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
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
