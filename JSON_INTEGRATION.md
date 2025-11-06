# Quran JSON Integration

## Overview
The app now uses a page-based Quran JSON file (`lib/utils/quran_text.json`) instead of the old `QuranService`. This provides:
- **Accurate word boundaries** - Each word is precisely defined
- **Line-based layout** - Words are organized by line numbers (matching traditional Quran pages)
- **Diacritic preservation** - Full Arabic diacritics (`harakat`) are maintained
- **Simplified text** - Normalized version without diacritics for matching

## Architecture

### QuranJsonService (`lib/services/quran_json_service.dart`)
Main service for loading and accessing Quran data:

```dart
class QuranJsonService {
  // Get a specific page (1-604)
  QuranPage? getPage(int pageNumber);
  
  // Get a specific surah
  QuranChapter? getSurah(int surahNumber);
  
  // Get all words in a surah (filtered, no verse markers)
  List<QuranWord> getSurahWords(int surahNumber);
  
  // Get all surahs with metadata
  List<Map<String, dynamic>> getAllSurahs();
}
```

### Data Models

#### QuranWord
```dart
class QuranWord {
  String text;              // Full text with diacritics
  String simpleText;        // Normalized text without diacritics
  int surahNumber;          // Chapter number
  int verseNumber;          // Verse number
  int lineNumber;           // Line on page
  bool firstword;           // First word of verse?
  bool lastword;            // Last word of verse (often verse number)?
}
```

#### QuranPage
```dart
class QuranPage {
  int pageNumber;           // Page 1-604
  List<QuranChapter> chapters;
  
  // Get all words organized by line number
  Map<int, List<QuranWord>> getWordsByLine();
}
```

## JSON Structure

```json
{
  "data": [
    {
      "page_number": 1,
      "chapters": [
        {
          "surah_name": "الفاتحة",
          "surah_number": 1,
          "verses": [
            {
              "verse_number": 1,
              "words": [
                {
                  "_id": "...",
                  "word_index": 1,
                  "word_key": "1:1:1",
                  "text": "بِسْمِ",
                  "simple_text": "بسم",
                  "surah_number": 1,
                  "verse_number": 1,
                  "line_number": 2,
                  "firstword": true,
                  "lastword": false
                },
                ...
              ]
            },
            ...
          ]
        }
      ]
    },
    ...
  ]
}
```

## Integration Points

### RecitationScreen
1. **Load Surahs**: Uses `getAllSurahs()` to populate dropdown
2. **Select Surah**: Gets words via `getSurahWords(surahNumber)`
3. **Filter Verse Markers**: Removes verse number words using `filterOutVerseMarkers()`
4. **Create Highlighted Words**: Converts `QuranWord` to `HighlightedWord` for display

### Word Matching (processQueue)
- Compares transcribed words with highlighted word text
- Uses fuzzy matching (Levenshtein distance) for flexibility
- 80% similarity = correct, 60-80% = warning, <60% = error

### Display (SurahDisplay)
- Shows words organized in lines (matching traditional page layout)
- Words are colored based on recitation status
- Scrollable view for longer surahs

## Key Features

✅ **Word-level accuracy** - Each word precisely defined  
✅ **Line-based layout** - Follows traditional Quran page format  
✅ **Diacritic preservation** - Full Arabic marks retained  
✅ **Simplified matching** - Can compare without diacritics  
✅ **604 pages** - Complete Quran coverage  

## Migration from QuranService

### Old Approach
- Manual surah data entry
- Text split by spaces only
- No line information

### New Approach
- JSON file with complete metadata
- Word-level data with diacritics
- Line numbers for layout
- Verse markers clearly identified

## Usage Example

```dart
// Initialize service
final quranService = QuranJsonService();
await quranService.initialize();

// Get a surah
final surah = quranService.getSurah(1); // Al-Fatiha
print(surah?.surahName); // الفاتحة

// Get words for recitation
final words = quranService.getSurahWords(1);
final filtered = QuranJsonService.filterOutVerseMarkers(words);

// Get page
final page = quranService.getPage(1);
final wordsByLine = page?.getWordsByLine();
```

## File Removal

Once fully migrated, these files can be removed:
- ✂️ `lib/services/quran_service.dart` (old service)
- ✂️ `lib/models/surah.dart` (old model, if no longer used)
- ✂️ `lib/services/fuzzy_matching_service.dart` (replaced by inline logic)

## Performance Notes

- JSON file is loaded once at app startup
- All data is cached in memory
- Fast lookups by surah or page number
- Typical load time: <500ms for entire Quran
