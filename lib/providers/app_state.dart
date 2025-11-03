import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/highlighted_word.dart';
import '../models/recitation_summary.dart';
import '../models/surah.dart';
import '../services/gemini_live_service.dart';
import '../services/audio_recording_service.dart';
import '../services/quran_service.dart';
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

// Current Selected Surah
final currentSurahProvider = StateProvider<Surah?>((ref) {
  return null;
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
final surahNamesProvider = Provider<List<Surah>>((ref) {
  return QuranService.getAllSurahs();
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
    final currentSurah = ref.read(currentSurahProvider);
    if (currentSurah == null) return;

    final surahWords = splitIntoWords(currentSurah.text);
    var currentIndex = ref.read(nextWordIndexProvider);
    var queue = ref.read(transcribedWordsQueueProvider);
    var highlightedWords = ref.read(highlightedWordsProvider);

    final updatedWords = List<HighlightedWord>.from(highlightedWords);

    while (queue.isNotEmpty && currentIndex < surahWords.length) {
      final transcribedWord = normalizeArabic(queue.removeAt(0));
      final expectedWord = normalizeArabic(surahWords[currentIndex]);

      if (transcribedWord.isEmpty) {
        continue;
      }

      final isSimilar = FuzzyMatchingService.isSimilar(transcribedWord, expectedWord);

      if (isSimilar) {
        if (updatedWords[currentIndex].status != WordStatus.recitedCorrect) {
          updatedWords[currentIndex] = updatedWords[currentIndex].copyWith(
            status: WordStatus.recitedCorrect,
            tajweedError: null,
          );
        }
        currentIndex++;
      } else {
        if (updatedWords[currentIndex].status != WordStatus.recitedTajweedError) {
          updatedWords[currentIndex] = updatedWords[currentIndex].copyWith(
            status: WordStatus.recitedTajweedError,
            tajweedError:
                'Expected: "${surahWords[currentIndex]}", Heard: "$transcribedWord"',
          );
        }
        currentIndex++;
      }
    }

    ref.read(nextWordIndexProvider.notifier).state = currentIndex;
    ref.read(transcribedWordsQueueProvider.notifier).state = queue;
    ref.read(highlightedWordsProvider.notifier).state = updatedWords;
  }
}
