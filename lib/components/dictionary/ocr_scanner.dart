import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrScanner extends StatefulWidget {
  final Function(String) onTextRecognized;

  const OcrScanner({super.key, required this.onTextRecognized});

  @override
  State<OcrScanner> createState() => _OcrScannerState();
}

class _OcrScannerState extends State<OcrScanner> {
  File? _image;
  String _recognizedText = '';
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();

  // Created lazily in _processImage so it never blocks widget construction
  TextRecognizer? _textRecognizer;

  TextRecognizer _getRecognizer() {
    _textRecognizer ??=
        TextRecognizer(script: TextRecognitionScript.japanese);
    return _textRecognizer!;
  }

  @override
  void dispose() {
    _textRecognizer?.close();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1920,
      );
      if (pickedFile == null) return;

      final imageFile = File(pickedFile.path);
      setState(() {
        _image = imageFile;
        _isProcessing = true;
        _recognizedText = '';
      });

      await _processImage(imageFile);
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot open ${source == ImageSource.camera ? "camera" : "gallery"}: $e')),
      );
    }
  }

  Future<void> _processImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizer = _getRecognizer();
      final RecognizedText result = await recognizer.processImage(inputImage);

      if (!mounted) return;
      setState(() {
        _recognizedText = result.text;
        _isProcessing = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Text recognition failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── Image preview ──
          GestureDetector(
            onTap: () => _pickImage(ImageSource.gallery),
            child: Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: scheme.outlineVariant, width: 1.5),
                color: scheme.surfaceContainerLow,
              ),
              clipBehavior: Clip.hardEdge,
              child: _image != null
                  ? Image.file(_image!, fit: BoxFit.contain)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_search_rounded,
                            size: 56,
                            color: scheme.onSurface.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text('Tap to pick from gallery',
                            style: TextStyle(
                                fontSize: 14,
                                color: scheme.onSurface
                                    .withValues(alpha: 0.5))),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Buttons ──
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_rounded, size: 20),
                  label: const Text('Camera'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_rounded, size: 20),
                  label: const Text('Gallery'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Processing indicator ──
          if (_isProcessing)
            Column(
              children: [
                CircularProgressIndicator(color: scheme.primary),
                const SizedBox(height: 12),
                Text('Recognizing text…',
                    style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurface.withValues(alpha: 0.6))),
              ],
            ),

          // ── Result ──
          if (_recognizedText.isNotEmpty && !_isProcessing) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: scheme.outlineVariant),
                color: scheme.surfaceContainerLow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recognized text',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color:
                              scheme.onSurface.withValues(alpha: 0.5))),
                  const SizedBox(height: 8),
                  SelectableText(
                    _recognizedText,
                    style: TextStyle(
                        fontSize: 17,
                        height: 1.7,
                        color: scheme.onSurface),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: () =>
                    widget.onTextRecognized(_recognizedText.trim()),
                icon: const Icon(Icons.search_rounded),
                label: const Text('Search this text'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],

          // ── Empty hint ──
          if (_image == null && !_isProcessing) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: scheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Point your camera at Japanese text or pick an image from your gallery.',
                      style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurface.withValues(alpha: 0.75)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
