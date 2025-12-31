import 'dart:convert';
import 'highlighted_word.dart';

/// Result of a single word's recitation analysis
class WordResult {
  final String text;
  final String simpleText;
  final int verseNumber;
  final int surahNumber;
  final String status; // 'correct', 'near_miss', 'error', 'unrecited'
  final String? error;

  WordResult({
    required this.text,
    required this.simpleText,
    required this.verseNumber,
    required this.surahNumber,
    required this.status,
    this.error,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'simple_text': simpleText,
        'verse_number': verseNumber,
        'surah_number': surahNumber,
        'status': status,
        if (error != null) 'error': error,
      };

  factory WordResult.fromHighlightedWord(HighlightedWord word) {
    String status;
    switch (word.status) {
      case WordStatus.recitedCorrect:
        status = 'correct';
        break;
      case WordStatus.recitedNearMiss:
        status = 'near_miss';
        break;
      case WordStatus.recitedTajweedError:
        status = 'error';
        break;
      case WordStatus.unrecited:
        status = 'unrecited';
        break;
    }
    return WordResult(
      text: word.text,
      simpleText: word.simpleText,
      verseNumber: word.verseNumber,
      surahNumber: word.surahNumber,
      status: status,
      error: word.tajweedError,
    );
  }
}

/// Statistics for a single verse
class VerseStats {
  final int verseNumber;
  final int totalWords;
  final int correctWords;
  final int nearMissWords;
  final int errorWords;
  final int unrecitedWords;
  final double accuracy;

  VerseStats({
    required this.verseNumber,
    required this.totalWords,
    required this.correctWords,
    required this.nearMissWords,
    required this.errorWords,
    required this.unrecitedWords,
  }) : accuracy = totalWords > 0 ? (correctWords / totalWords * 100) : 0.0;

  Map<String, dynamic> toJson() => {
        'verse_number': verseNumber,
        'total_words': totalWords,
        'correct_words': correctWords,
        'near_miss_words': nearMissWords,
        'error_words': errorWords,
        'unrecited_words': unrecitedWords,
        'accuracy_percent': double.parse(accuracy.toStringAsFixed(1)),
      };
}

/// Complete recitation result with all analysis data
class RecitationResult {
  final int pageNumber;
  final int surahNumber;
  final String surahName;
  final DateTime timestamp;
  final int totalWords;
  final int correctWords;
  final int nearMissWords;
  final int errorWords;
  final int unrecitedWords;
  final double accuracy;
  final List<VerseStats> verseStats;
  final List<WordResult> words;
  final List<WordResult> errorWordsList;
  final List<WordResult> nearMissWordsList;

  RecitationResult({
    required this.pageNumber,
    required this.surahNumber,
    required this.surahName,
    required this.timestamp,
    required this.totalWords,
    required this.correctWords,
    required this.nearMissWords,
    required this.errorWords,
    required this.unrecitedWords,
    required this.verseStats,
    required this.words,
    required this.errorWordsList,
    required this.nearMissWordsList,
  }) : accuracy = totalWords > 0 ? (correctWords / totalWords * 100) : 0.0;

  Map<String, dynamic> toJson() => {
        'page_number': pageNumber,
        'surah_number': surahNumber,
        'surah_name': surahName,
        'timestamp': timestamp.toIso8601String(),
        'summary': {
          'total_words': totalWords,
          'correct_words': correctWords,
          'near_miss_words': nearMissWords,
          'error_words': errorWords,
          'unrecited_words': unrecitedWords,
          'accuracy_percent': double.parse(accuracy.toStringAsFixed(1)),
        },
        'verse_stats': verseStats.map((v) => v.toJson()).toList(),
        'words': words.map((w) => w.toJson()).toList(),
        'errors': errorWordsList.map((w) => w.toJson()).toList(),
        'near_misses': nearMissWordsList.map((w) => w.toJson()).toList(),
      };

  String toJsonString({bool pretty = false}) {
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(toJson());
    }
    return jsonEncode(toJson());
  }

  /// Create a RecitationResult from highlighted words list
  factory RecitationResult.fromHighlightedWords({
    required List<HighlightedWord> words,
    required int pageNumber,
    required int surahNumber,
    required String surahName,
  }) {
    int totalWords = 0;
    int correctWords = 0;
    int errorWords = 0;
    int unrecitedWords = 0;
    int nearMissWords = 0;
    final verseStatsMap = <int, Map<String, int>>{};
    final wordResults = <WordResult>[];
    final errorWordsList = <WordResult>[];
    final nearMissWordsList = <WordResult>[];

    for (final word in words) {
      // Skip verse markers
      if (word.isVerseMarker) continue;

      totalWords++;

      // Initialize verse stats
      verseStatsMap.putIfAbsent(
          word.verseNumber,
          () => {
                'total': 0,
                'correct': 0,
                'nearMiss': 0,
                'errors': 0,
                'unrecited': 0,
              });

      verseStatsMap[word.verseNumber]!['total'] =
          verseStatsMap[word.verseNumber]!['total']! + 1;

      final wordResult = WordResult.fromHighlightedWord(word);
      wordResults.add(wordResult);

      switch (word.status) {
        case WordStatus.recitedCorrect:
          correctWords++;
          verseStatsMap[word.verseNumber]!['correct'] =
              verseStatsMap[word.verseNumber]!['correct']! + 1;
          break;
        case WordStatus.recitedNearMiss:
          nearMissWords++;
          verseStatsMap[word.verseNumber]!['nearMiss'] =
              verseStatsMap[word.verseNumber]!['nearMiss']! + 1;
          nearMissWordsList.add(wordResult);
          break;
        case WordStatus.recitedTajweedError:
          errorWords++;
          verseStatsMap[word.verseNumber]!['errors'] =
              verseStatsMap[word.verseNumber]!['errors']! + 1;
          errorWordsList.add(wordResult);
          break;
        case WordStatus.unrecited:
          unrecitedWords++;
          verseStatsMap[word.verseNumber]!['unrecited'] =
              verseStatsMap[word.verseNumber]!['unrecited']! + 1;
          break;
      }
    }

    // Convert verse stats map to list
    final verseStatsList = verseStatsMap.entries.map((entry) {
      final stats = entry.value;
      return VerseStats(
        verseNumber: entry.key,
        totalWords: stats['total']!,
        correctWords: stats['correct']!,
        nearMissWords: stats['nearMiss']!,
        errorWords: stats['errors']!,
        unrecitedWords: stats['unrecited']!,
      );
    }).toList();

    // Sort by verse number
    verseStatsList.sort((a, b) => a.verseNumber.compareTo(b.verseNumber));

    return RecitationResult(
      pageNumber: pageNumber,
      surahNumber: surahNumber,
      surahName: surahName,
      timestamp: DateTime.now(),
      totalWords: totalWords,
      correctWords: correctWords,
      nearMissWords: nearMissWords,
      errorWords: errorWords,
      unrecitedWords: unrecitedWords,
      verseStats: verseStatsList,
      words: wordResults,
      errorWordsList: errorWordsList,
      nearMissWordsList: nearMissWordsList,
    );
  }
}
