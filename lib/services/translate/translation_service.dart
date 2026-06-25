// Hybrid translation engine (Japanese-centric).
//
// - JP→English: fully offline via ML Kit on-device translation (models
//   downloaded once when online, then offline) — mirrors HandwritingService.
// - JP→Mongolian: online via Google Cloud Translation (ML Kit has no Mongolian
//   model). Requires an API key; degrades gracefully to English offline when
//   there's no key / no connection.

import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:http/http.dart' as http;

enum TranslateTarget { english, mongolian }

class TranslationResult {
  final String source; // BCP-47, e.g. 'ja'
  final String target; // 'en' | 'mn'
  final String text; // translated text ('' on failure)
  final bool online; // whether the online engine was used

  const TranslationResult({
    required this.source,
    required this.target,
    required this.text,
    required this.online,
  });

  bool get ok => text.isNotEmpty;
}

class TranslationService {
  TranslationService._();
  static final TranslationService instance = TranslationService._();

  final OnDeviceTranslatorModelManager _models =
      OnDeviceTranslatorModelManager();
  final LanguageIdentifier _langId =
      LanguageIdentifier(confidenceThreshold: 0.5);
  OnDeviceTranslator? _jaEn;
  bool _offlineReady = false;

  /// API key for online JP→Mongolian (Google Cloud Translation). Set from a
  /// settings screen; never commit a key. When null/empty, Mongolian falls
  /// back to offline English.
  String? cloudApiKey;

  /// Warm up: download EN+JA models if online so the first translation is fast.
  Future<void> warmUp() async {
    if (await _online()) await _ensureOffline(online: true);
  }

  Future<TranslationResult> translate(
    String text, {
    TranslateTarget target = TranslateTarget.english,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const TranslationResult(
          source: 'ja', target: 'en', text: '', online: false);
    }
    final online = await _online();

    // JP→Mongolian: online only; otherwise degrade to English below.
    if (target == TranslateTarget.mongolian &&
        online &&
        (cloudApiKey?.isNotEmpty ?? false)) {
      try {
        final mn = await _cloudTranslate(trimmed, source: 'ja', target: 'mn');
        return TranslationResult(
            source: 'ja', target: 'mn', text: mn, online: true);
      } catch (e) {
        debugPrint('Cloud (mn) translate failed, falling back to EN: $e');
      }
    }

    // JP→English offline.
    if (await _ensureOffline(online: online)) {
      _jaEn ??= OnDeviceTranslator(
        sourceLanguage: TranslateLanguage.japanese,
        targetLanguage: TranslateLanguage.english,
      );
      final en = await _jaEn!.translateText(trimmed);
      return TranslationResult(
          source: 'ja', target: 'en', text: en, online: false);
    }

    return TranslationResult(
      source: 'ja',
      target: target == TranslateTarget.mongolian ? 'mn' : 'en',
      text: '',
      online: false,
    );
  }

  /// Best-effort source language detection (BCP-47, or 'und').
  Future<String> detectLanguage(String text) =>
      _langId.identifyLanguage(text);

  // ---- internals ----

  Future<bool> _ensureOffline({required bool online}) async {
    if (_offlineReady) return true;
    try {
      final en = await _have(TranslateLanguage.english, online);
      final ja = await _have(TranslateLanguage.japanese, online);
      _offlineReady = en && ja;
      return _offlineReady;
    } catch (e) {
      debugPrint('ensure offline models failed: $e');
      return false;
    }
  }

  Future<bool> _have(TranslateLanguage lang, bool online) async {
    final code = lang.bcpCode;
    if (await _models.isModelDownloaded(code)) return true;
    if (!online) return false;
    return _models.downloadModel(code, isWifiRequired: false);
  }

  Future<String> _cloudTranslate(String text,
      {required String source, required String target}) async {
    final uri = Uri.parse(
        'https://translation.googleapis.com/language/translate/v2?key=$cloudApiKey');
    final resp = await http.post(uri, body: {
      'q': text,
      'source': source,
      'target': target,
      'format': 'text',
    });
    if (resp.statusCode != 200) {
      throw Exception('Cloud Translation HTTP ${resp.statusCode}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return (data['data']['translations'][0]['translatedText'] as String);
  }

  Future<bool> _online() async {
    try {
      final r = await Connectivity().checkConnectivity();
      return r.any((x) => x != ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }
}
