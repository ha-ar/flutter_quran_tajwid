/// Normalize Arabic text for better word matching
String normalizeArabic(String text) {
  return text
      .replaceAll(RegExp(r'[\u064B-\u0652]'), '') // Remove diacritics
      .replaceAll(RegExp(r'[\u0670]'), '') // Remove dagger alif
      .replaceAll(RegExp(r'[\u0671]'), '') // Remove alif wasla
      .replaceAll(RegExp(r'[\u0640]'), '') // Remove tatweel (kashida)
      .replaceAll(RegExp(r'[۪۬۟۫۠ۡ۝۞ۣۖۗۘۙۚۛۜۢۤۥۦۧۨ]'), '') // Remove other marks
      .replaceAll(RegExp(r'[.،؛؟!]'), '') // Remove punctuation
      .replaceAll(RegExp(r'[ٱأإآ]'), 'ا') // Normalize alif forms
      .replaceAll('ى', 'ي') // Normalize alif maqsurah to yaa
      .replaceAll('ة', 'ه') // Normalize ta marbuta to ha
      .trim();
}

/// Minimum similarity (0-1) required to accept a fuzzy match as correct.
/// Increase to make matching stricter; decrease to be more lenient.
const double kMinRecitationSimilarity = 0.80; // 80%

/// Compute a Levenshtein-based similarity between two Arabic words after normalization.
/// Returns a value in [0,1]. 1.0 means exact match.
double arabicSimilarity(String a, String b) {
  final s1 = normalizeArabic(a);
  final s2 = normalizeArabic(b);
  if (s1.isEmpty || s2.isEmpty) return 0.0;
  if (s1 == s2) return 1.0;
  final len1 = s1.length;
  final len2 = s2.length;
  // Initialize DP matrix
  final dp = List.generate(len1 + 1, (_) => List<int>.filled(len2 + 1, 0));
  for (var i = 0; i <= len1; i++) dp[i][0] = i;
  for (var j = 0; j <= len2; j++) dp[0][j] = j;
  for (var i = 1; i <= len1; i++) {
    for (var j = 1; j <= len2; j++) {
      final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
      dp[i][j] = [
        dp[i - 1][j] + 1, // deletion
        dp[i][j - 1] + 1, // insertion
        dp[i - 1][j - 1] + cost, // substitution
      ].reduce((a, b) => a < b ? a : b);
    }
  }
  final distance = dp[len1][len2];
  final maxLen = len1 > len2 ? len1 : len2;
  return 1.0 - distance / maxLen;
}

/// Split text into words and filter out Ayah numbers
List<String> splitIntoWords(String text) {
  final words = text.split(RegExp(r'\s+'));
  // Filter out Ayah numbers (Arabic numerals ٠-٩ and English numerals 0-9)
  return words.where((word) => !RegExp(r'^[\d٠-٩]+$').hasMatch(word)).toList();
}

/// Match transcribed words with Surah words
bool wordsMatch(String word1, String word2) {
  return normalizeArabic(word1).toLowerCase() ==
      normalizeArabic(word2).toLowerCase();
}
