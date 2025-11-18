enum WordStatus {
  unrecited,
  recitedCorrect,
  recitedNearMiss,
  recitedTajweedError,
}

class HighlightedWord {
  final String text; // Rendered text for display (with diacritics, markers)
  final String
      simpleText; // Clean text for comparison (no diacritics, no markers)
  final WordStatus status;
  final String? tajweedError;
  final int verseNumber; // Verse the word belongs to (1-based)
  final int wordIndex; // Position of the word within the Surah
  final bool
      isVerseMarker; // True when this entry represents a verse marker/number

  HighlightedWord({
    required this.text,
    required this.simpleText,
    required this.status,
    this.tajweedError,
    required this.verseNumber,
    required this.wordIndex,
    this.isVerseMarker = false,
  });

  HighlightedWord copyWith({
    String? text,
    String? simpleText,
    WordStatus? status,
    String? tajweedError,
    int? verseNumber,
    int? wordIndex,
    bool? isVerseMarker,
  }) {
    return HighlightedWord(
      text: text ?? this.text,
      simpleText: simpleText ?? this.simpleText,
      status: status ?? this.status,
      tajweedError: tajweedError ?? this.tajweedError,
      verseNumber: verseNumber ?? this.verseNumber,
      wordIndex: wordIndex ?? this.wordIndex,
      isVerseMarker: isVerseMarker ?? this.isVerseMarker,
    );
  }
}
