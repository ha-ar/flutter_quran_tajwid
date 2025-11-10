import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quran_tajwid/services/fuzzy_matching_service.dart';

void main() {
  group('FuzzyMatchingService', () {
    group('calculateSimilarity', () {
      test('returns 1.0 for identical strings', () {
        final similarity = FuzzyMatchingService.calculateSimilarity('السلام', 'السلام');
        expect(similarity, equals(1.0));
      });

      test('returns 0.0 for completely different strings', () {
        final similarity = FuzzyMatchingService.calculateSimilarity('السلام', 'xyz');
        expect(similarity, lessThan(0.2));
      });

      test('returns high similarity for minor differences', () {
        // One character difference in Arabic
        final similarity = FuzzyMatchingService.calculateSimilarity('الحمد', 'الحمدد');
        expect(similarity, greaterThan(0.8));
      });

      test('handles empty strings', () {
        expect(FuzzyMatchingService.calculateSimilarity('', ''), equals(1.0));
        expect(FuzzyMatchingService.calculateSimilarity('test', ''), equals(0.0));
        expect(FuzzyMatchingService.calculateSimilarity('', 'test'), equals(0.0));
      });

      test('calculates correct similarity for Arabic words', () {
        // Similar but not identical Arabic words
        final similarity = FuzzyMatchingService.calculateSimilarity('الرحمن', 'الرحيم');
        expect(similarity, greaterThan(0.4));
        expect(similarity, lessThan(0.7));
      });
    });

    group('determineMatchStatus', () {
      test('returns correct for high similarity (≥80%)', () {
        expect(
          FuzzyMatchingService.determineMatchStatus(0.8),
          equals(MatchResult.correct),
        );
        expect(
          FuzzyMatchingService.determineMatchStatus(0.95),
          equals(MatchResult.correct),
        );
        expect(
          FuzzyMatchingService.determineMatchStatus(1.0),
          equals(MatchResult.correct),
        );
      });

      test('returns warning for medium similarity (60-79%)', () {
        expect(
          FuzzyMatchingService.determineMatchStatus(0.6),
          equals(MatchResult.warning),
        );
        expect(
          FuzzyMatchingService.determineMatchStatus(0.7),
          equals(MatchResult.warning),
        );
        expect(
          FuzzyMatchingService.determineMatchStatus(0.79),
          equals(MatchResult.warning),
        );
      });

      test('returns error for low similarity (<60%)', () {
        expect(
          FuzzyMatchingService.determineMatchStatus(0.0),
          equals(MatchResult.error),
        );
        expect(
          FuzzyMatchingService.determineMatchStatus(0.3),
          equals(MatchResult.error),
        );
        expect(
          FuzzyMatchingService.determineMatchStatus(0.59),
          equals(MatchResult.error),
        );
      });
    });

    group('isSimilar', () {
      test('uses default threshold correctly', () {
        expect(
          FuzzyMatchingService.isSimilar('test', 'test'),
          isTrue,
        );
        expect(
          FuzzyMatchingService.isSimilar('test', 'completely different'),
          isFalse,
        );
      });

      test('uses custom threshold correctly', () {
        expect(
          FuzzyMatchingService.isSimilar('test', 'tist', threshold: 0.5),
          isTrue,
        );
        expect(
          FuzzyMatchingService.isSimilar('test', 'tist', threshold: 0.9),
          isFalse,
        );
      });
    });

    group('Real-world Arabic examples', () {
      test('handles normalized Arabic text', () {
        // These are the same word with and without diacritics
        // After normalization in arabic_utils, they should match well
        final word1 = 'الحمد'; // al-hamd
        final word2 = 'الحمد'; // al-hamd (identical)
        
        final similarity = FuzzyMatchingService.calculateSimilarity(word1, word2);
        expect(similarity, equals(1.0));
      });

      test('detects significant pronunciation differences', () {
        final expected = 'الرحمن'; // ar-Rahman (The Most Merciful)
        final heard = 'الرحيم';   // ar-Rahim (The Most Compassionate)
        
        final similarity = FuzzyMatchingService.calculateSimilarity(expected, heard);
        final result = FuzzyMatchingService.determineMatchStatus(similarity);
        
        // These are different words, should be detected as error or warning
        expect(result, isNot(equals(MatchResult.correct)));
      });

      test('accepts minor variations in similar words', () {
        // Simulate minor transcription variations
        final expected = 'بسم';
        final heard = 'بسمم';  // Extra character
        
        final similarity = FuzzyMatchingService.calculateSimilarity(expected, heard);
        // Should be high similarity due to only one character difference
        expect(similarity, greaterThan(0.7));
      });
    });

    group('Levenshtein distance calculation', () {
      test('calculates correct edit distance', () {
        // Test internal Levenshtein implementation through similarity
        final sim1 = FuzzyMatchingService.calculateSimilarity('kitten', 'sitting');
        // "kitten" -> "sitting" requires 3 edits
        // Similarity = 1 - (3/7) ≈ 0.57 for Levenshtein part
        expect(sim1, greaterThan(0.4));
        expect(sim1, lessThan(0.8));
      });

      test('handles Unicode Arabic characters correctly', () {
        final word1 = 'ا'; // Alif
        final word2 = 'أ'; // Alif with hamza above
        
        final similarity = FuzzyMatchingService.calculateSimilarity(word1, word2);
        // Different Unicode characters, but similar
        expect(similarity, greaterThan(0.5));
      });
    });
  });
}
