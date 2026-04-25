// File: lib/pages/dictionary_page.dart
import 'package:flutter/material.dart';
import 'package:ivo/components/common/app_bar.dart';
import 'package:ivo/components/buttons/dark_mode_button.dart';
import 'package:ivo/components/buttons/settings_nav_button.dart';
import 'package:ivo/components/dictionary/ocr_scanner.dart';
import 'package:ivo/components/dictionary/result_list.dart';
import 'package:ivo/components/dictionary/save_to_deck_sheet.dart';
import 'package:ivo/components/dictionary/search_bar.dart';
import 'package:ivo/components/dictionary/drawing_keyboard.dart';
import 'package:ivo/components/dictionary/empty_state.dart';
import 'package:ivo/services/db_helper.dart';

class DictionaryPage extends StatefulWidget {
  const DictionaryPage({super.key});

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool isKeyboardOpen(BuildContext context) {
    final bottomInsets = MediaQuery.of(context).viewInsets.bottom;
    return bottomInsets != 0.0;
  }

  String _searchQuery = '';
  List<Map<String, dynamic>> _searchResults = [];
  String _resultType = 'empty';
  bool _isLoading = false;
  bool _showDrawPad = false;
  List<Map<String, dynamic>> _recognitionResults = [];
  bool _showOcrScanner = false;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeDatabase() async {
    try {
      await JishoDB.init();
      print('Database initialized successfully');
    } catch (e) {
      print('Error initializing database: $e');
    }
  }

  void _toggleDrawPad() {
    // 1. Unfocus the search bar to dismiss the system keyboard
    // This is the key change to ensure the system keyboard closes.
    if (_showDrawPad) {
      // If closing the drawing pad, let the focus go back to the search bar
      // if the user tapped the text field previously.
      _searchFocusNode.requestFocus();
    } else {
      // If opening the drawing pad, dismiss the system keyboard.
      _searchFocusNode.unfocus();
    }
    setState(() {
      _showDrawPad = !_showDrawPad;
      if (!_showDrawPad) {
        _recognitionResults = [];
      }
    });
  }

  Future<void> _performSearch([String? query]) async {
    final searchText = query ?? _searchController.text;

    setState(() {
      _showDrawPad = false;
      _searchQuery = searchText;
      _isLoading = true;
    });

    try {
      if (searchText.trim().isEmpty) {
        setState(() {
          _searchResults = [];
          _resultType = 'empty';
          _isLoading = false;
        });
        return;
      }

      final result = await JishoDB.search(searchText);
      setState(() {
        _resultType = result['type'];
        _searchResults = List<Map<String, dynamic>>.from(
          result['result'] ?? [],
        );
        _isLoading = false;
      });
    } catch (e) {
      print('Search error: $e');
      setState(() {
        _searchResults = [];
        _resultType = 'error';
        _isLoading = false;
      });
    }
  }

  // OCR mentioned
  void _handleRecognitionResult(Map<String, dynamic> result) {
    setState(() {
      _recognitionResults = result['top10'] as List<Map<String, dynamic>>;
    });
  }

  void _onKanjiTap(String kanji) {
    _searchController.text = _searchController.text + kanji;
  }

  void _onOcrResult(String text) {
    if (text.isNotEmpty) {
      _searchController.text = text;
      _performSearch(text);
      setState(() {
        _showOcrScanner = false;
      });
    }
  }

  void _clearDrawPad() {
    setState(() {
      _recognitionResults = [];
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchResults = [];
      _resultType = 'empty';
    });
  }

  void _openOcrScanner() {
    setState(() {
      _showOcrScanner = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showOcrScanner) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _showOcrScanner = false;
              });
            },
          ),
          title: const Text('Зураг таних'),
        ),
        body: OcrScanner(onTextRecognized: _onOcrResult),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: MyAppBar(
        titleText: "Толь бичиг",
        button1: DarkModeButton(),
        button2: SettingsNavButton(),
      ),
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          children: [
            Column(
              children: [
                // Search Bar Component
                DictionarySearchBar(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onSearch: _performSearch,
                  onClear: _clearSearch,
                  onOpenOcr: _openOcrScanner,
                ),

                // Results Section
                Expanded(child: _buildResults()),
              ],
            ),

            // Drawing Keyboard Component (MediaQuery.of(context).viewInsets.bottom prevents keyboard push)
            if (_showDrawPad)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  ignoring: MediaQuery.of(context).viewInsets.bottom > 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    transform: Matrix4.translationValues(
                      0,
                      MediaQuery.of(context).viewInsets.bottom > 0
                          ? MediaQuery.of(context).size.height
                          : 0,
                      0,
                    ),
                    child: DrawingKeyboard(
                      recognitionResults: _recognitionResults,
                      onRecognitionComplete: _handleRecognitionResult,
                      onKanjiTap: _onKanjiTap,
                      onClear: _clearDrawPad,
                      onClose: _toggleDrawPad,
                    ),
                  ),
                ),
              ),

            // Floating action button
            if (!_showDrawPad)
              Positioned(
                right: 16,
                bottom: 16,
                child: InkWell(
                  onTap: _toggleDrawPad,
                  customBorder:
                      const CircleBorder(), // Optional: for a circular ripple effect
                  child: Container(
                    width:
                        48, // Standard FAB size is ~56, mini is ~40. Choose your size.
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        // Optional: Add shadow to mimic elevation
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.draw,
                        color: Colors.white, // Set icon color
                        size: 24, // Set icon size
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty && _searchQuery.isNotEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'Үр дүн олдсонгүй',
        subtitle: '"$_searchQuery"',
      );
    }

    if (_searchResults.isEmpty) {
      return const EmptyState(
        icon: Icons.book_outlined,
        title: 'Хайлт хийнэ үү',
        subtitle: 'Зурж хайхыг оролдоно уу',
      );
    }

    return DictionaryResultsList(
      results: _searchResults,
      resultType: _resultType,
      onSave: (entry) => showSaveToDeckSheet(context, entry),
    );
  }
}
