class Surah {
  final int number;
  final String name;
  final String englishName;
  final int numberOfAyahs;
  final String text;

  Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.numberOfAyahs,
    required this.text,
  });

  String get displayName => '$englishName ($name)';
}
