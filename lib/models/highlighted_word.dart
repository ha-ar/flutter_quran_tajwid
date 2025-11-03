enum WordStatus {
  unrecited,
  recitedCorrect,
  recitedTajweedError,
}

class HighlightedWord {
  final String text;
  final WordStatus status;
  final String? tajweedError;

  HighlightedWord({
    required this.text,
    required this.status,
    this.tajweedError,
  });

  HighlightedWord copyWith({
    String? text,
    WordStatus? status,
    String? tajweedError,
  }) {
    return HighlightedWord(
      text: text ?? this.text,
      status: status ?? this.status,
      tajweedError: tajweedError ?? this.tajweedError,
    );
  }
}
