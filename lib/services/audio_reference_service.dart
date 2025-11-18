import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'audio_analysis_service.dart';

/// Service for managing reference audio files and comparing user recitation
class AudioReferenceService {
  // Cache for loaded reference audio files
  // Key: surah_number:verse_number or word_key
  static final Map<String, Uint8List> _audioCache = {};
  // In-flight load futures to deduplicate concurrent loads
  static final Map<String, Future<Uint8List?>> _loadingFutures = {};

  /// Load reference audio for a specific surah and verse
  /// Audio files should be stored in: assets/audio/surah_XXX/verse_YYY.pcm
  static Future<Uint8List?> loadReferenceAudio(
    int surahNumber,
    int verseNumber,
  ) async {
    final cacheKey = '${surahNumber}_$verseNumber';

    // Return from cache if available
    if (_audioCache.containsKey(cacheKey)) {
      return _audioCache[cacheKey];
    }

    // If another caller is already loading this asset, await that future
    if (_loadingFutures.containsKey(cacheKey)) {
      try {
        return await _loadingFutures[cacheKey];
      } catch (_) {
        // fallthrough to attempt reload
      }
    }

    final path =
        'assets/audio/surah_${surahNumber.toString().padLeft(3, '0')}/verse_${verseNumber.toString().padLeft(3, '0')}.pcm';

    final future = () async {
      try {
        final data = await rootBundle.load(path);
        final audioBytes = data.buffer.asUint8List();
        _audioCache[cacheKey] = audioBytes;
        // Single debug print when freshly loaded
        debugPrint(
            'Loaded reference audio: $path (${audioBytes.length} bytes)');
        return audioBytes;
      } catch (e) {
        debugPrint(
            'Failed to load reference audio for S$surahNumber:V$verseNumber: $e');
        return null;
      } finally {
        // remove in-flight marker
        _loadingFutures.remove(cacheKey);
      }
    }();

    _loadingFutures[cacheKey] = future;
    return await future;
  }

  /// Load reference audio for a word
  /// Audio files should be stored in: assets/audio/words/{word_key}.pcm
  static Future<Uint8List?> loadWordAudio(String wordKey) async {
    if (_audioCache.containsKey(wordKey)) {
      return _audioCache[wordKey];
    }

    try {
      final path = 'assets/audio/words/$wordKey.pcm';
      final data = await rootBundle.load(path);
      final audioBytes = data.buffer.asUint8List();

      _audioCache[wordKey] = audioBytes;
      debugPrint('Loaded word audio: $path (${audioBytes.length} bytes)');

      return audioBytes;
    } catch (e) {
      debugPrint('Failed to load word audio for $wordKey: $e');
      return null;
    }
  }

  /// Compare user's recorded audio segment with reference audio
  /// Returns similarity score (0.0 to 1.0)
  /// Uses ultra-fast comparison with aggressive downsampling for real-time performance
  static double compareRecitationWithReference(
    Uint8List userAudio,
    Uint8List referenceAudio,
  ) {
    return AudioAnalysisService.compareAudioWaveformsUltraFast(
        userAudio, referenceAudio);
  }

  /// Find best matching reference audio segment for user audio
  /// Tries all verses in a surah and returns the best match
  static Future<({int verseNumber, double score})?> findBestVerseMatch(
    int surahNumber,
    Uint8List userAudio, {
    int maxVerses = 286, // Maximum verses in Quran
  }) async {
    double bestScore = 0.0;
    int bestVerse = 0;

    for (int verse = 1; verse <= maxVerses; verse++) {
      final refAudio = await loadReferenceAudio(surahNumber, verse);
      if (refAudio == null) continue;

      final score = compareRecitationWithReference(userAudio, refAudio);
      debugPrint('Verse $verse: $score');

      if (score > bestScore) {
        bestScore = score;
        bestVerse = verse;
      }
    }

    if (bestVerse == 0) return null;

    return (verseNumber: bestVerse, score: bestScore);
  }

  /// Clear audio cache to free memory
  static void clearCache() {
    _audioCache.clear();
    debugPrint('Audio cache cleared');
  }

  /// Get cache statistics
  static String getCacheStats() {
    int totalBytes = 0;
    for (final audio in _audioCache.values) {
      totalBytes += audio.length;
    }
    return 'Cached ${_audioCache.length} files (${(totalBytes / 1024 / 1024).toStringAsFixed(2)} MB)';
  }
}
