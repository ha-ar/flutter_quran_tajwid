import 'package:flutter/foundation.dart';
import '../models/highlighted_word.dart';

/// Service to debug the highlighting flow
class DebugHighlightingService {
  
  /// Log the entire highlighting flow
  static void logHighlightingFlow(String stage, Map<String, dynamic> data) {
    final timestamp = DateTime.now().toIso8601String();
    
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 HIGHLIGHTING DEBUG - $stage @ $timestamp');
    debugPrint('═══════════════════════════════════════════════════════');
    
    data.forEach((key, value) {
      debugPrint('  $key: $value');
    });
    
    debugPrint('───────────────────────────────────────────────────────\n');
  }
  
  /// Log verse matching results
  static void logVerseMatch(
    int verseNumber,
    double score,
    int surahNumber,
  ) {
    if (score >= 0.75) {
      debugPrint('✅ VERSE MATCH - Surah $surahNumber, Verse $verseNumber, Score: ${(score * 100).toStringAsFixed(1)}%');
    } else {
      debugPrint('❌ LOW SCORE - Verse $verseNumber: ${(score * 100).toStringAsFixed(1)}%');
    }
  }
  
  /// Log word matching details
  static void logWordMatching(
    int verseNumber,
    List<({String simpleText, bool matched})> wordMatches,
  ) {
    debugPrint('📝 WORD MATCHING for Verse $verseNumber:');
    for (int i = 0; i < wordMatches.length; i++) {
      final match = wordMatches[i];
      final status = match.matched ? '✅' : '❌';
      debugPrint('  $status Word ${i + 1}: "${match.simpleText}"');
    }
  }
  
  /// Log highlighted words state before and after update
  static void logHighlightedWordsUpdate(
    List<HighlightedWord> before,
    List<HighlightedWord> after,
    String reason,
  ) {
    debugPrint('🎨 HIGHLIGHTED WORDS UPDATE - Reason: $reason');
    debugPrint('  Before: ${before.length} words');
    
    // Count statuses before
    int recitedCorrectBefore = before.where((w) => w.status == WordStatus.recitedCorrect).length;
    int errorBefore = before.where((w) => w.status == WordStatus.recitedTajweedError).length;
    debugPrint('    - Recited Correct: $recitedCorrectBefore');
    debugPrint('    - Tajweed Errors: $errorBefore');
    debugPrint('    - Unrecited: ${before.length - recitedCorrectBefore - errorBefore}');
    
    debugPrint('  After: ${after.length} words');
    
    // Count statuses after
    int recitedCorrectAfter = after.where((w) => w.status == WordStatus.recitedCorrect).length;
    int errorAfter = after.where((w) => w.status == WordStatus.recitedTajweedError).length;
    debugPrint('    - Recited Correct: $recitedCorrectAfter');
    debugPrint('    - Tajweed Errors: $errorAfter');
    debugPrint('    - Unrecited: ${after.length - recitedCorrectAfter - errorAfter}');
    
    if (recitedCorrectAfter > recitedCorrectBefore) {
      debugPrint('  Δ Change: +${recitedCorrectAfter - recitedCorrectBefore} correct words 🎉');
    }
  }
  
  /// Log audio segment info
  static void logAudioSegment(
    int bufferSize,
    int segmentSize,
    int duration,
  ) {
    debugPrint('🔊 AUDIO SEGMENT:');
    debugPrint('  Buffer size: $bufferSize bytes');
    debugPrint('  Segment size: $segmentSize bytes');
    debugPrint('  Duration: ${duration}ms');
  }
  
  /// Log reference verse data
  static void logReferseData(
    int surahNumber,
    int verseNumber,
    List<({String text, String simpleText})> words,
  ) {
    debugPrint('📖 REFERENCE DATA - Surah $surahNumber, Verse $verseNumber:');
    debugPrint('  Total words in reference: ${words.length}');
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      debugPrint('    ${i + 1}. "${word.text}" (simple: "${word.simpleText}")');
    }
  }
  
  /// Log provider state
  static void logProviderState(
    String providerName,
    dynamic state,
  ) {
    debugPrint('📊 PROVIDER STATE - $providerName:');
    if (state is List<HighlightedWord>) {
      debugPrint('  Type: List<HighlightedWord>');
      debugPrint('  Length: ${state.length}');
      int correct = state.where((w) => w.status == WordStatus.recitedCorrect).length;
      debugPrint('  Recited Correct: $correct');
    } else if (state is int) {
      debugPrint('  Type: int');
      debugPrint('  Value: $state');
    } else {
      debugPrint('  Type: ${state.runtimeType}');
      debugPrint('  Value: $state');
    }
  }
  
  /// Create a comprehensive status report
  static String createStatusReport(Map<String, dynamic> context) {
    final buffer = StringBuffer();
    buffer.writeln('╔════════════════════════════════════════════════════════╗');
    buffer.writeln('║         HIGHLIGHTING SYSTEM STATUS REPORT              ║');
    buffer.writeln('╚════════════════════════════════════════════════════════╝');
    buffer.writeln('');
    
    context.forEach((key, value) {
      buffer.writeln('  $key: $value');
    });
    
    return buffer.toString();
  }
}
