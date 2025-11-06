import 'dart:convert';
import 'package:flutter/services.dart';

class QuranWord {
  final String id;
  final int wordIndex;
  final String wordKey;
  final String text;
  final String simpleText;
  final int surahNumber;
  final int verseNumber;
  final int lineNumber;
  final bool firstword;
  final bool lastword;

  QuranWord({
    required this.id,
    required this.wordIndex,
    required this.wordKey,
    required this.text,
    required this.simpleText,
    required this.surahNumber,
    required this.verseNumber,
    required this.lineNumber,
    required this.firstword,
    required this.lastword,
  });

  factory QuranWord.fromJson(Map<String, dynamic> json) {
    return QuranWord(
      id: json['_id'] ?? '',
      wordIndex: json['word_index'] ?? 0,
      wordKey: json['word_key'] ?? '',
      text: json['text'] ?? '',
      simpleText: json['simple_text'] ?? '',
      surahNumber: json['surah_number'] ?? 0,
      verseNumber: json['verse_number'] ?? 0,
      lineNumber: json['line_number'] ?? 0,
      firstword: json['firstword'] ?? false,
      lastword: json['lastword'] ?? false,
    );
  }
}

class QuranVerse {
  final int verseNumber;
  final List<QuranWord> words;

  QuranVerse({
    required this.verseNumber,
    required this.words,
  });

  factory QuranVerse.fromJson(Map<String, dynamic> json) {
    final words = (json['words'] as List<dynamic>?)
            ?.map((w) => QuranWord.fromJson(w as Map<String, dynamic>))
            .toList() ??
        [];
    return QuranVerse(
      verseNumber: json['verse_number'] ?? 0,
      words: words,
    );
  }
}

class QuranChapter {
  final String surahName;
  final int surahNumber;
  final List<QuranVerse> verses;

  QuranChapter({
    required this.surahName,
    required this.surahNumber,
    required this.verses,
  });

  factory QuranChapter.fromJson(Map<String, dynamic> json) {
    final verses = (json['verses'] as List<dynamic>?)
            ?.map((v) => QuranVerse.fromJson(v as Map<String, dynamic>))
            .toList() ??
        [];
    return QuranChapter(
      surahName: json['surah_name'] ?? '',
      surahNumber: json['surah_number'] ?? 0,
      verses: verses,
    );
  }
}

class QuranPage {
  final int pageNumber;
  final List<QuranChapter> chapters;

  QuranPage({
    required this.pageNumber,
    required this.chapters,
  });

  factory QuranPage.fromJson(Map<String, dynamic> json) {
    final chapters = (json['chapters'] as List<dynamic>?)
            ?.map((c) => QuranChapter.fromJson(c as Map<String, dynamic>))
            .toList() ??
        [];
    return QuranPage(
      pageNumber: json['page_number'] ?? 0,
      chapters: chapters,
    );
  }

  /// Get all words in this page
  List<QuranWord> getAllWords() {
    final allWords = <QuranWord>[];
    for (final chapter in chapters) {
      for (final verse in chapter.verses) {
        allWords.addAll(verse.words);
      }
    }
    return allWords;
  }

  /// Get all words organized by line number
  Map<int, List<QuranWord>> getWordsByLine() {
    final wordsByLine = <int, List<QuranWord>>{};
    for (final word in getAllWords()) {
      if (!wordsByLine.containsKey(word.lineNumber)) {
        wordsByLine[word.lineNumber] = [];
      }
      wordsByLine[word.lineNumber]!.add(word);
    }
    return wordsByLine;
  }
}

class QuranJsonService {
  static final QuranJsonService _instance = QuranJsonService._internal();
  late List<QuranPage> _allPages;
  bool _isInitialized = false;

  factory QuranJsonService() {
    return _instance;
  }

  QuranJsonService._internal();

  /// Initialize by loading the JSON file
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('Loading Quran JSON...');
      final jsonString = await rootBundle.loadString('lib/utils/quran_text.json');
      print('JSON loaded, length: ${jsonString.length}');
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>?;

      if (data != null) {
        print('Parsing ${data.length} pages...');
        _allPages = data
            .map((p) => QuranPage.fromJson(p as Map<String, dynamic>))
            .toList();
        _isInitialized = true;
        print('Successfully loaded ${_allPages.length} pages');
      } else {
        print('Error: data field is null in JSON');
        _allPages = [];
      }
    } catch (e, stackTrace) {
      print('Error loading Quran JSON: $e');
      print('Stack trace: $stackTrace');
      _allPages = [];
      rethrow; // Re-throw to let the FutureProvider handle the error
    }
  }

  /// Get a specific page by page number (1-604)
  QuranPage? getPage(int pageNumber) {
    if (pageNumber < 1 || pageNumber > _allPages.length) return null;
    return _allPages[pageNumber - 1];
  }

  /// Get all pages
  List<QuranPage> getAllPages() {
    return _allPages;
  }

  /// Get total number of pages
  int getTotalPages() {
    return _allPages.length;
  }

  /// Get a specific surah by surah number
  QuranChapter? getSurah(int surahNumber) {
    for (final page in _allPages) {
      for (final chapter in page.chapters) {
        if (chapter.surahNumber == surahNumber) {
          return chapter;
        }
      }
    }
    return null;
  }

  /// Get page number for a specific surah
  int? getPageForSurah(int surahNumber) {
    for (final page in _allPages) {
      for (final chapter in page.chapters) {
        if (chapter.surahNumber == surahNumber) {
          return page.pageNumber;
        }
      }
    }
    return null;
  }

  /// Get all surahs with their names and numbers
  List<Map<String, dynamic>> getAllSurahs() {
    print('getAllSurahs called, _allPages.length: ${_allPages.length}, initialized: $_isInitialized');
    final surahs = <Map<String, dynamic>>[];
    final seenSurahs = <int>{};

    for (final page in _allPages) {
      for (final chapter in page.chapters) {
        if (!seenSurahs.contains(chapter.surahNumber)) {
          surahs.add({
            'number': chapter.surahNumber,
            'name': chapter.surahName,
            'pageNumber': page.pageNumber,
          });
          seenSurahs.add(chapter.surahNumber);
        }
      }
    }
    print('Found ${surahs.length} unique surahs');
    return surahs;
  }

  /// Get words for a specific surah
  List<QuranWord> getSurahWords(int surahNumber) {
    final surah = getSurah(surahNumber);
    if (surah == null) return [];

    final words = <QuranWord>[];
    for (final verse in surah.verses) {
      words.addAll(verse.words);
    }
    return words;
  }

  /// Filter out verse markers (verse numbers, endings, and special marks)
  /// Uses simpleText for more reliable detection
  static List<QuranWord> filterOutVerseMarkers(List<QuranWord> words) {
    final filtered = words.where((word) {
      // Check simpleText for verse numbers (more reliable than text)
      final cleanText = word.simpleText.trim();
      final displayText = word.text.trim();
      
      // Filter out verse numbers (Arabic numerals ٠-٩ or English 0-9)
      if (RegExp(r'^[\d٠-٩]+$').hasMatch(cleanText)) {
        print('Filtering out verse number: simpleText="$cleanText", text="$displayText"');
        return false;
      }
      
      // Filter out verse ending marks and special symbols
      if (RegExp(r'^[۟۞۝﴾﴿\s]*$').hasMatch(displayText)) {
        print('Filtering out verse marker: text="$displayText"');
        return false;
      }
      
      // Keep all actual words
      return true;
    }).toList();
    
    print('Filtered ${words.length - filtered.length} verse markers, kept ${filtered.length} actual words');
    return filtered;
  }
}
