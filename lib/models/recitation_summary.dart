class TajweedError {
  final String word;
  final String error;

  TajweedError({
    required this.word,
    required this.error,
  });
}

class RecitationSummary {
  final String surahName;
  final int totalWords;
  final int correctWords;
  final int errorWords;
  final List<TajweedError> tajweedErrors;

  RecitationSummary({
    required this.surahName,
    required this.totalWords,
    required this.correctWords,
    required this.errorWords,
    required this.tajweedErrors,
  });
}
