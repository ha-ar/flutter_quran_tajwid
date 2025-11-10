import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/highlighted_word.dart';
import '../models/recitation_summary.dart';
import '../models/surah.dart';
import '../services/gemini_live_service.dart';
import '../services/audio_recording_service.dart';
import '../services/quran_json_service.dart';
import '../services/fuzzy_matching_service.dart';
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
final audioRecordingServiceProvider = StateProvider<AudioRecordingService>((ref) {
  return AudioRecordingService();
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
  return 0;
});
                                                                                                                                                                                                                                                                                               
// Highlighted Words for display
final highlightedWordsProvider =
    StateProvider<List<HighlightedWord>>((ref) {
  return [];
});

// Recitation Summary
final recitationSummaryProvider =
    StateProvider<RecitationSummary?>((ref) {
  return null;
});

// Recitation Status
final isRecitingProvider = StateProvider<bool>((ref) {
  return false;
});

// Status Message
final statusMessageProvider = StateProvider<String>((ref) {
  return 'Please select a Surah to begin.';
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
final surahNamesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final quranService = ref.watch(quranJsonServiceProvider);
  try {
    await quranService.initialize();
  final surahs = quranService.getAllSurahs();
  return surahs;
  } catch (e, st) {
    // Log error and return empty list so UI can show a friendly state
    // (Avoid rethrowing to prevent uncaught provider errors from breaking UI)
    // Print for debugging in logs
    // ignore: avoid_print
    print('surahNamesProvider: failed to load Quran JSON: $e\n$st');
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
    print('processQueue: currentIndex=$currentIndex, queue.length=${queue.length}, totalWords=${highlightedWords.length}');

    while (queue.isNotEmpty && currentIndex < highlightedWords.length) {
      // Use simpleText for comparison (clean text without diacritics/markers)
      final expectedWord = normalizeArabic(highlightedWords[currentIndex].simpleText);
      
      // Skip verse markers (they have empty or numeric simpleText)
      if (expectedWord.isEmpty || RegExp(r'^[\d٠-٩]+$').hasMatch(expectedWord)) {
        print('⏭️ Skipping verse marker at index $currentIndex: text="${highlightedWords[currentIndex].text}", simpleText="$expectedWord"');
        // Mark as unrecited but visible (not part of recitation matching)
        currentIndex++;
        continue;
      }

      final transcribedWord = normalizeArabic(queue.removeAt(0));
      print('Comparing: transcribed="$transcribedWord" vs expected="$expectedWord" (simpleText, index=$currentIndex)');
      print('Display text: "${highlightedWords[currentIndex].text}"');

      if (transcribedWord.isEmpty) {
        continue;
      }

      // Use FuzzyMatchingService for more lenient error detection
      final similarityScore = FuzzyMatchingService.calculateSimilarity(transcribedWord, expectedWord);
      print('Similarity score: $similarityScore');

      // Determine match status using FuzzyMatchingService thresholds
      final matchResult = FuzzyMatchingService.determineMatchStatus(similarityScore);
      
      switch (matchResult) {
        case MatchResult.correct:
          // Mark as correct if similarity is high enough (>= 80%)
          // This accounts for minor pronunciation variations in Tajweed
          print('✅ Match accepted (similarity >= 0.8)');
          if (updatedWords[currentIndex].status != WordStatus.recitedCorrect) {
            updatedWords[currentIndex] = updatedWords[currentIndex].copyWith(
              status: WordStatus.recitedCorrect,
              tajweedError: null,
            );
          }
          currentIndex++;
          
        case MatchResult.warning:
          // Mark as partial match (pronunciation close but not exact)
          print('⚠️ Partial match (similarity 0.6-0.8)');
          if (updatedWords[currentIndex].status != WordStatus.recitedCorrect) {
            updatedWords[currentIndex] = updatedWords[currentIndex].copyWith(
              status: WordStatus.recitedTajweedError,
              tajweedError:
                  'Pronunciation similar but not exact. Check Tajweed rules.',
            );
          }
          currentIndex++;
          
        case MatchResult.error:
          // Mark as error (significant mismatch)
          print('❌ Match failed (similarity < 0.6)');
          if (updatedWords[currentIndex].status != WordStatus.recitedTajweedError) {
            updatedWords[currentIndex] = updatedWords[currentIndex].copyWith(
              status: WordStatus.recitedTajweedError,
              tajweedError:
                  'Expected: "${highlightedWords[currentIndex].simpleText}", Heard: "$transcribedWord"',
            );
          }
          currentIndex++;
      }
    }

    print('processQueue complete: newIndex=$currentIndex');
    ref.read(nextWordIndexProvider.notifier).state = currentIndex;
    ref.read(transcribedWordsQueueProvider.notifier).state = queue;
    ref.read(highlightedWordsProvider.notifier).state = updatedWords;
  }
}
