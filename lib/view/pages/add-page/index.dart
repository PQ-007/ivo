import 'package:flutter/material.dart';
import 'package:ivo/components/flashcard/deck_preview.dart';
import 'package:ivo/data/l10n.dart';
import 'package:ivo/services/flashcard_service.dart';

class AddDeckPage extends StatefulWidget {
  const AddDeckPage({super.key});

  @override
  State<AddDeckPage> createState() => _AddDeckPageState();
}

class _AddDeckPageState extends State<AddDeckPage> {
  final _service = FlashcardService();
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isPublic = false;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _loading = true);
    try {
      final deck = await _service.createDeck(
        _nameCtrl.text.trim(),
        _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DeckPreview(deck: deck)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(t('add_deck_title'), style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 40),
          children: [
            _Label(t('add_deck_name')),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameCtrl,
              autofocus: true,
              style: TextStyle(fontSize: 18, color: scheme.onSurface),
              decoration: InputDecoration(
                hintText: t('add_deck_name_hint'),
                filled: true,
                fillColor: scheme.surfaceContainerLow,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? t('add_deck_required') : null,
            ),
            const SizedBox(height: 20),
            _Label(t('add_deck_description')),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              style: TextStyle(fontSize: 16, color: scheme.onSurface),
              decoration: InputDecoration(
                hintText: t('add_deck_description_hint'),
                filled: true,
                fillColor: scheme.surfaceContainerLow,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: BorderRadius.circular(14)),
              child: SwitchListTile(
                title: Text(t('add_deck_public')),
                value: _isPublic,
                onChanged: (v) => setState(() => _isPublic = v),
                activeThumbColor: scheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _loading ? null : _create,
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: scheme.onPrimary, strokeWidth: 2))
                    : Text(t('add_deck_create'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      text.toUpperCase(),
      style: TextStyle(fontSize: 11, letterSpacing: 2.5, fontWeight: FontWeight.w600, color: scheme.onSurface.withValues(alpha: 0.5)),
    );
  }
}
