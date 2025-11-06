enum WordStatus {
  unrecited,
  recitedCorrect,
  recitedTajweedError,
}

class HighlightedWord {
  final String text; // Rendered text for display (with diacritics, markers)
  final String simpleText; // Clean text for comparison (no diacritics, no markers)
  final WordStatus status;
  final String? tajweedError;

  HighlightedWord({
    required this.text,
    required this.simpleText,
    required this.status,
    this.tajweedError,
  });

  HighlightedWord copyWith({
    String? text,
    String? simpleText,
    WordStatus? status,
    String? tajweedError,
  }) {
    return HighlightedWord(
      text: text ?? this.text,
      simpleText: simpleText ?? this.simpleText,
      status: status ?? this.status,
      tajweedError: tajweedError ?? this.tajweedError,
    );
  }
}
