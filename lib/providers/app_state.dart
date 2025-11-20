import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import '../models/highlighted_word.dart';
import '../models/recitation_summary.dart';
import '../models/surah.dart';
import '../services/gemini_live_service.dart';
import '../services/audio_recording_service.dart';
import '../services/audio_matching_service.dart';
import '../services/quran_json_service.dart';
import '../utils/arabic_utils.dart';

// Gemini Live Service Provider
final geminiLiveServiceProvider = StateProvider<GeminiLiveService?>((ref) {
  final apiKey = dotenv.env['GEMINI_API_KEY'];
  if (apiKey == null) {
    return null;
  }
  return GeminiLiveService(apiKey: apiKey);
});

// Audio Recording Service Provider
final audioRecordingServiceProvider =
    StateProvider<AudioRecordingService>((ref) {
  return AudioRecordingService();
});

// Audio Matching Service Provider
final audioMatchingServiceProvider = StateProvider<AudioMatchingService>((ref) {
  return AudioMatchingService();
});

// Quran JSON Service Provider
final quranJsonServiceProvider = StateProvider<QuranJsonService>((ref) {
  return QuranJsonService();
});

// Current Selected Surah
final currentSurahProvider = StateProvider<Surah?>((ref) {
  return null;
});

// Current Selected Surah Name (from JSON)
final currentSurahNameProvider = StateProvider<String>((ref) {
  return '';
});

// Current Selected Surah Number (from JSON)
final currentSurahNumberProvider = StateProvider<int>((ref) {
  return 1;
});

// Highlighted Words for display
final highlightedWordsProvider = StateProvider<List<HighlightedWord>>((ref) {
  return [];
});

// Recitation Summary
final recitationSummaryProvider = StateProvider<RecitationSummary?>((ref) {
  return null;
});

// Recitation Status
final isRecitingProvider = StateProvider<bool>((ref) {
  return false;
});

// Status Message
final statusMessageProvider = StateProvider<String>((ref) {
  return 'Loading Surah Al-Fatiha...';
});

// Audio Level for visualization
final audioLevelProvider = StateProvider<double>((ref) {
  return 0.0;
});

// Transcribed Text
final recitedTextProvider = StateProvider<String>((ref) {
  return '';
});

// Track next word to match index
final nextWordIndexProvider = StateProvider<int>((ref) {
  return 0;
});

// Track transcribed words queue
final transcribedWordsQueueProvider = StateProvider<List<String>>((ref) {
  return [];
});

// Surah names list
final surahNamesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final quranService = ref.watch(quranJsonServiceProvider);
  try {
    await quranService.initialize();
    final surahs = quranService.getAllSurahs();
    return surahs;
  } catch (e, st) {
    // Log error and return empty list so UI can show a friendly state
    // (Avoid rethrowing to prevent uncaught provider errors from breaking UI)
    // Print for debugging in logs
    debugPrint('surahNamesProvider: failed to load Quran JSON: $e\n$st');
    return <Map<String, dynamic>>[];
  }
});

// Process transcribed words and update highlighted words
final processTranscriptionProvider =
    StateNotifierProvider<TranscriptionProcessor, void>((ref) {
  return TranscriptionProcessor(ref);
});

class TranscriptionProcessor extends StateNotifier<void> {
  final Ref ref;

  TranscriptionProcessor(this.ref) : super(null);

  void processQueue() {
    var currentIndex = ref.read(nextWordIndexProvider);
    var queue = ref.read(transcribedWordsQueueProvider);
    var highlightedWords = ref.read(highlightedWordsProvider);

    if (highlightedWords.isEmpty) return;

    final updatedWords = List<HighlightedWord>.from(highlightedWords);
    debugPrint(
        'processQueue: currentIndex=$currentIndex, queue.length=${queue.length}, totalWords=${highlightedWords.length}');

    while (queue.isNotEmpty && currentIndex < highlightedWords.length) {
      final currentWord = highlightedWords[currentIndex];

      if (currentWord.isVerseMarker) {
        debugPrint(
            '⏭️ Skipping verse marker at index $currentIndex: text="${currentWord.text}"');
        currentIndex++;
        continue;
      }

      // Use simpleText for comparison (clean text without diacritics/markers)
      final expectedWord = normalizeArabic(currentWord.simpleText);

      // Skip any remaining non-pronounceable markers
      if (expectedWord.isEmpty ||
          RegExp(r'^[\d٠-٩]+$').hasMatch(expectedWord)) {
        debugPrint(
            '⏭️ Skipping non-recitable token at index $currentIndex: text="${currentWord.text}", simpleText="$expectedWord"');
        currentIndex++;
        continue;
      }

      final transcribedWord = normalizeArabic(queue.removeAt(0));
      debugPrint(
          'Comparing: transcribed="$transcribedWord" vs expected="$expectedWord" (simpleText, index=$currentIndex, verse=${currentWord.verseNumber})');
      debugPrint('Display text: "${currentWord.text}"');

      if (transcribedWord.isEmpty) {
        continue;
      }

      // Use fuzzy matching for more lenient error detection
      final similarityScore =
          _calculateSimilarity(transcribedWord, expectedWord);
      debugPrint('Similarity score: $similarityScore');

      // Mark as correct if similarity is high enough (>= 80%)
      // This accounts for minor pronunciation variations in Tajweed
      if (similarityScore >= 0.8) {
        debugPrint('✅ Match accepted (similarity >= 0.8)');
        if (updatedWords[currentIndex].status != WordStatus.recitedCorrect) {
          updatedWords[currentIndex] = updatedWords[currentIndex].copyWith(
            status: WordStatus.recitedCorrect,
            tajweedError: null,
          );
        }
        currentIndex++;
      }
      // Mark as partial match (pronunciation close but not exact)
      else if (similarityScore >= 0.6) {
        debugPrint('⚠️ Partial match (similarity 0.6-0.8)');
        if (updatedWords[currentIndex].status != WordStatus.recitedCorrect) {
          updatedWords[currentIndex] = updatedWords[currentIndex].copyWith(
            status: WordStatus.recitedTajweedError,
            tajweedError:
                'Pronunciation similar but not exact. Check Tajweed rules.',
          );
        }
        currentIndex++;
      }
      // Mark as error (significant mismatch)
      else {
        debugPrint('❌ Match failed (similarity < 0.6)');
        if (updatedWords[currentIndex].status !=
            WordStatus.recitedTajweedError) {
          updatedWords[currentIndex] = updatedWords[currentIndex].copyWith(
            status: WordStatus.recitedTajweedError,
            tajweedError:
                'Expected: "${currentWord.simpleText}", Heard: "$transcribedWord"',
          );
        }
        currentIndex++;
      }
    }

    debugPrint('processQueue complete: newIndex=$currentIndex');
    ref.read(nextWordIndexProvider.notifier).state = currentIndex;
    ref.read(transcribedWordsQueueProvider.notifier).state = queue;
    ref.read(highlightedWordsProvider.notifier).state = updatedWords;
  }

  /// Calculate string similarity using Levenshtein distance
  double _calculateSimilarity(String word1, String word2) {
    final distance = _levenshteinDistance(word1, word2);
    final maxLength = word1.length > word2.length ? word1.length : word2.length;
    if (maxLength == 0) return 1.0;
    return 1.0 - (distance / maxLength);
  }

  /// Levenshtein distance algorithm for string similarity
  int _levenshteinDistance(String a, String b) {
    final aLength = a.length;
    final bLength = b.length;

    if (aLength == 0) return bLength;
    if (bLength == 0) return aLength;

    final matrix = List.generate(
      aLength + 1,
      (i) => List.filled(bLength + 1, 0),
    );

    for (var i = 0; i <= aLength; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= bLength; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i <= aLength; i++) {
      for (var j = 1; j <= bLength; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[aLength][bLength];
  }
}
