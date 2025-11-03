/// Normalize Arabic text for better word matching
String normalizeArabic(String text) {
  return text
      .replaceAll(RegExp(r'[\u064B-\u0652]'), '') // Remove diacritics
      .replaceAll(RegExp(r'[\u0670]'), '') // Remove dagger alif
      .replaceAll(RegExp(r'[\u0671]'), '') // Remove alif wasla
      .replaceAll(RegExp(r'[ٱأإآ]'), 'ا') // Normalize alif forms
      .replaceAll('ى', 'ي') // Normalize alif maqsurah to yaa
      .replaceAll('ة', 'ه'); // Normalize ta marbuta to ha
}

/// Split text into words and filter out Ayah numbers
List<String> splitIntoWords(String text) {
  final words = text.split(RegExp(r'\s+'));
  // Filter out Ayah numbers (Arabic numerals ٠-٩ and English numerals 0-9)
  return words
      .where((word) => !RegExp(r'^[\d٠-٩]+$').hasMatch(word))
      .toList();
}

/// Match transcribed words with Surah words
bool wordsMatch(String word1, String word2) {
  return normalizeArabic(word1).toLowerCase() ==
      normalizeArabic(word2).toLowerCase();
}
