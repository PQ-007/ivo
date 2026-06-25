import 'package:flutter/material.dart';
import 'package:ivo/components/study/save_to_deck.dart';
import 'package:ivo/services/tts/tts_service.dart';

class DictionaryResultsList extends StatelessWidget {
  final List<Map<String, dynamic>> results;
  final String resultType;

  const DictionaryResultsList({
    super.key,
    required this.results,
    required this.resultType,
  });

  @override
  Widget build(BuildContext context) {
    // Single Kanji page
    if (resultType == 'kanji' && results.isNotEmpty) {
      return _buildKanjiResult(context, results.first);
    }

    // Compact Takoboto-style list
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = results[index];
        final kanji = List<String>.from(entry['kanji'] ?? []);
        final reading = List<String>.from(entry['reading'] ?? []);
        final senses = List<Map<String, dynamic>>.from(entry['senses'] ?? []);
        final meaning =
            senses.isNotEmpty
                ? List<String>.from(senses.first['glosses'] ?? []).join('; ')
                : '';

        final front = kanji.isNotEmpty
            ? kanji.first
            : (reading.isNotEmpty ? reading.first : '');

        return Container(
          color: index < 3 ? Colors.blue.withOpacity(0.05) : null,
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DictionaryEntryDetailPage(entry: entry),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.end,
                          spacing: 8,
                          children: [
                            if (kanji.isNotEmpty)
                              Text(
                                kanji.first,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (reading.isNotEmpty)
                              Text(
                                '【${reading.first}】',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                        if (meaning.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              meaning,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14, height: 1.4),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up_outlined),
                tooltip: 'Сонсох',
                onPressed: front.isEmpty
                    ? null
                    : () => TtsService.instance.speak(
                          reading.isNotEmpty ? reading.first : front,
                        ),
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_add_outlined),
                tooltip: 'Багцад нэмэх',
                onPressed: front.isEmpty
                    ? null
                    : () => showSaveToDeckSheet(
                          context,
                          front: front,
                          reading: reading.isNotEmpty ? reading.first : '',
                          back: meaning,
                        ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKanjiResult(BuildContext context, Map<String, dynamic> kanji) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  kanji['character'] ?? '',
                  style: const TextStyle(
                    fontSize: 120,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoChip(
                    'Зураг',
                    kanji['stroke_count']?.toString() ?? '-',
                  ),
                  if (kanji['grade'] != null)
                    _buildInfoChip('Түвшин', kanji['grade'].toString()),
                  if (kanji['jlpt'] != null)
                    _buildInfoChip('JLPT', 'N${kanji['jlpt']}'),
                  if (kanji['frequency'] != null)
                    _buildInfoChip('Давтамж', '#${kanji['frequency']}'),
                ],
              ),
              const Divider(height: 32),
              _buildKanjiSection(
                'Он дуудлага',
                List<String>.from(kanji['on_yomi'] ?? []),
                Icons.volume_up,
              ),
              const Divider(height: 32),
              _buildKanjiSection(
                'Күн дуудлага',
                List<String>.from(kanji['kun_yomi'] ?? []),
                Icons.speaker_notes,
              ),
              const Divider(height: 32),
              _buildKanjiSection(
                'Утга',
                List<String>.from(kanji['meanings'] ?? []),
                Icons.translate,
              ),
              if (kanji['radicals'] != null &&
                  (kanji['radicals'] as List).isNotEmpty) ...[
                const Divider(height: 32),
                _buildRadicalsSection(
                  'Радикал',
                  List<Map<String, dynamic>>.from(kanji['radicals'] ?? []),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildRadicalsSection(
    String title,
    List<Map<String, dynamic>> radicals,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.grid_view, size: 20, color: Colors.blue[700]),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              radicals.map((rad) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple[200]!),
                  ),
                  child: Text(
                    '${rad['radical']} (${rad['stroke_count']})',
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildKanjiSection(String title, List<String> items, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue[700]),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text(
            'Мэдээлэл байхгүй',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                items.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Text(item, style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
          ),
      ],
    );
  }
}

/// Detail Page (reuses your `_buildWordCard`)
class DictionaryEntryDetailPage extends StatelessWidget {
  final Map<String, dynamic> entry;

  const DictionaryEntryDetailPage({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final kanji = List<String>.from(entry['kanji'] ?? []);
    final reading = List<String>.from(entry['reading'] ?? []);
    final senses = List<Map<String, dynamic>>.from(entry['senses'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          kanji.isNotEmpty
              ? kanji.first
              : (reading.isNotEmpty ? reading.first : 'Дэлгэрэнгүй'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 12,
                  children: [
                    if (kanji.isNotEmpty)
                      Text(
                        kanji.first,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (reading.isNotEmpty)
                      Text(
                        '【${reading.first}】',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
                const Divider(height: 24),
                ...senses.asMap().entries.map((entry) {
                  final sense = entry.value;
                  final glosses = List<String>.from(sense['glosses'] ?? []);
                  final pos = List<String>.from(sense['pos'] ?? []);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (pos.isNotEmpty)
                          Wrap(
                            spacing: 6,
                            children:
                                pos.map((p) {
                                  return Chip(
                                    label: Text(
                                      p,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: Colors.orange[50],
                                    visualDensity: VisualDensity.compact,
                                  );
                                }).toList(),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          glosses.join('; '),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
