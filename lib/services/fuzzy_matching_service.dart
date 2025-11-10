import 'package:string_similarity/string_similarity.dart';

/// Service for fuzzy string matching optimized for Arabic text comparison
class FuzzyMatchingService {
  /// Default similarity threshold for basic matching (40%)
  static const double _defaultThreshold = 0.4;
  
  /// High similarity threshold for correct recitation (80%)
  static const double correctThreshold = 0.8;
  
  /// Medium similarity threshold for partial match (60%)
  static const double warningThreshold = 0.6;

  /// Check if two strings are similar using default threshold
  static bool isSimilar(String s1, String s2, {double? threshold}) {
    final similarity = calculateSimilarity(s1, s2);
    return similarity >= (threshold ?? _defaultThreshold);
  }

  /// Calculate similarity score between two strings (0.0 to 1.0)
  /// Uses both Levenshtein distance and string_similarity for robustness
  static double calculateSimilarity(String word1, String word2) {
    if (word1 == word2) return 1.0;
    if (word1.isEmpty || word2.isEmpty) return 0.0;

    // Use string_similarity package for initial comparison
    final stringSimilarity = StringSimilarity.compareTwoStrings(word1, word2);
    
    // Also calculate Levenshtein-based similarity
    final levenshteinSimilarity = _calculateLevenshteinSimilarity(word1, word2);
    
    // Return the average of both methods for better accuracy
    return (stringSimilarity + levenshteinSimilarity) / 2.0;
  }

  /// Calculate similarity using Levenshtein distance
  static double _calculateLevenshteinSimilarity(String word1, String word2) {
    final distance = _levenshteinDistance(word1, word2);
    final maxLength = word1.length > word2.length ? word1.length : word2.length;
    if (maxLength == 0) return 1.0;
    return 1.0 - (distance / maxLength);
  }

  /// Levenshtein distance algorithm for string similarity
  static int _levenshteinDistance(String a, String b) {
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
          matrix[i - 1][j] + 1,      // deletion
          matrix[i][j - 1] + 1,      // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[aLength][bLength];
  }
  
  /// Determine match status based on similarity score
  static MatchResult determineMatchStatus(double similarityScore) {
    if (similarityScore >= correctThreshold) {
      return MatchResult.correct;
    } else if (similarityScore >= warningThreshold) {
      return MatchResult.warning;
    } else {
      return MatchResult.error;
    }
  }
}

/// Result of fuzzy matching comparison
enum MatchResult {
  /// Perfect or near-perfect match (≥80%)
  correct,
  /// Partial match, pronunciation similar (60-80%)
  warning,
  /// Significant mismatch (<60%)
  error,
}
