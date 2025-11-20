# Flutter Quran Tajweed - API Reference

## Overview

Flutter Quran Tajweed is a comprehensive package for real-time Quranic recitation analysis with AI-powered transcription and Tajweed error detection.

## Core Components

### RecitationScreen Widget

Main UI widget for recitation interaction.

**Parameters:**
```dart
RecitationScreen({
  required int pageNumber,  // Mandatory: Page to display (1-604)
  Key? key,
})
```

**Features:**
- Displays exactly 15 lines of Quran text
- Real-time word highlighting during recitation
- Verse grouping and organization
- Error detection and feedback
- Summary report generation

**Example:**
```dart
RecitationScreen(pageNumber: 1)
```

---

## Services

### QuranJsonService

Singleton service for Quran data management.

**Constructor:**
```dart
QuranJsonService() // Returns singleton instance
```

**Methods:**

#### `Future<void> initialize()`
Loads and caches all 604 pages from JSON file.

```dart
final service = QuranJsonService();
await service.initialize(); // Call once, then reuse
```

#### `QuranPage? getPage(int pageNumber)`
Retrieves a specific page.

**Parameters:**
- `pageNumber`: Page number (1-604)

**Returns:** `QuranPage` if exists, `null` otherwise

```dart
final page = service.getPage(1);
if (page != null) {
  print('Found ${page.chapters.length} chapters');
}
```

#### `List<QuranPage> getAllPages()`
Returns all loaded pages.

```dart
final allPages = service.getAllPages();
print('Total pages: ${allPages.length}');
```

#### `int getTotalPages()`
Returns total number of pages (always 604).

```dart
print(service.getTotalPages()); // 604
```

#### `QuranChapter? getSurah(int surahNumber)`
Gets a specific Surah (chapter).

**Parameters:**
- `surahNumber`: Surah number (1-114)

**Returns:** `QuranChapter` if exists, `null` otherwise

```dart
final surah = service.getSurah(1); // Al-Fatiha
print('Surah name: ${surah?.surahName}');
print('Verses: ${surah?.verses.length}');
```

#### `int? getPageForSurah(int surahNumber)`
Finds the page number where a Surah begins.

**Parameters:**
- `surahNumber`: Surah number (1-114)

**Returns:** Page number or `null` if not found

```dart
final pageNum = service.getPageForSurah(2); // Al-Baqarah
// Returns the page where Surah Al-Baqarah starts
```

#### `List<Map<String, dynamic>> getAllSurahs()`
Returns all Surahs with metadata.

**Returns:** List of maps with keys: `number`, `name`, `pageNumber`

```dart
final surahs = service.getAllSurahs();
// [
//   {'number': 1, 'name': 'Al-Fatiha', 'pageNumber': 1},
//   {'number': 2, 'name': 'Al-Baqarah', 'pageNumber': 2},
//   ...
// ]
for (final surah in surahs) {
  print('${surah['name']} on page ${surah['pageNumber']}');
}
```

#### `List<QuranWord> getSurahWords(int surahNumber)`
Gets all words in a Surah.

**Parameters:**
- `surahNumber`: Surah number (1-114)

**Returns:** List of `QuranWord` objects

```dart
final words = service.getSurahWords(1);
print('Al-Fatiha has ${words.length} words');
```

#### `static List<QuranWord> filterOutVerseMarkers(List<QuranWord> words)`
Filters verse numbers and markers from a word list.

**Parameters:**
- `words`: List of words to filter

**Returns:** Filtered list without verse markers

```dart
final allWords = service.getSurahWords(1);
final actualWords = QuranJsonService.filterOutVerseMarkers(allWords);
print('Actual words: ${actualWords.length}');
```

---

### GeminiLiveService

WebSocket-based real-time transcription service.

**Constructor:**
```dart
GeminiLiveService({required String apiKey})
```

**Properties:**
```dart
bool get isConnected          // Connection status
Stream<GeminiTranscriptionMessage> get transcriptionStream
Stream<String> get errorStream
Stream<bool> get connectionStream
```

**Methods:**

#### `Future<void> connect()`
Establishes WebSocket connection to Gemini.

```dart
final gemini = GeminiLiveService(apiKey: 'your-key');
try {
  await gemini.connect();
  print('Connected!');
} catch (e) {
  print('Connection failed: $e');
}
```

#### `Future<void> disconnect()`
Closes the WebSocket connection.

```dart
await gemini.disconnect();
```

#### `Future<void> sendAudioChunk(Uint8List audioData)`
Sends audio chunk for transcription.

**Parameters:**
- `audioData`: PCM audio at 16kHz, 16-bit mono

```dart
final audioBytes = Uint8List.fromList([...]);
await gemini.sendAudioChunk(audioBytes);
```

---

### AudioRecordingService

Handles audio recording from microphone.

**Methods:**

#### `Future<void> initialize()`
Initializes audio recording and requests permissions.

```dart
final recorder = AudioRecordingService();
await recorder.initialize();
```

#### `Future<void> startRecording({required Function(List<int>) onAudioData, required Function(String) onError})`
Starts recording audio chunks.

**Parameters:**
- `onAudioData`: Callback for each audio chunk
- `onError`: Callback for errors

```dart
await recorder.startRecording(
  onAudioData: (chunk) {
    print('Got ${chunk.length} bytes');
    // Send to Gemini
    geminiService.sendAudioChunk(Uint8List.fromList(chunk));
  },
  onError: (error) {
    print('Recording error: $error');
  },
);
```

#### `Future<void> stopRecording()`
Stops recording.

```dart
await recorder.stopRecording();
```

#### `Future<void> dispose()`
Cleans up recording resources.

```dart
await recorder.dispose();
```

---

## Models

### HighlightedWord

Represents a word with recitation status.

**Properties:**
```dart
class HighlightedWord {
  final String text;                // Display text (with diacritics)
  final String simpleText;          // Clean text for matching
  final WordStatus status;          // Recitation status
  final String? tajweedError;       // Error message
  final int verseNumber;            // Verse number (1+)
  final int lineNumber;             // Line on page (1-15)
  final int wordIndex;              // Position in surah
  final bool isVerseMarker;         // Is verse number/marker
}
```

**Enums:**
```dart
enum WordStatus {
  unrecited,              // Not yet recited
  recitedCorrect,         // Correctly matched
  recitedNearMiss,        // Close match (60-80% similarity)
  recitedTajweedError,    // Error or not recognized
}
```

**Methods:**
```dart
HighlightedWord copyWith({
  String? text,
  String? simpleText,
  WordStatus? status,
  String? tajweedError,
  int? verseNumber,
  int? lineNumber,
  int? wordIndex,
  bool? isVerseMarker,
})
```

---

### QuranWord

Low-level Quran word data.

**Properties:**
```dart
class QuranWord {
  final String id;              // Unique ID
  final int wordIndex;          // Global word index
  final String wordKey;         // Normalized key
  final String text;            // Display text
  final String simpleText;      // Clean text
  final int surahNumber;        // Surah (1-114)
  final int verseNumber;        // Verse in surah
  final int lineNumber;         // Line (1-15 per page)
  final bool firstword;         // Is first word of verse
  final bool lastword;          // Is last word of verse
}
```

---

### QuranChapter (Surah)

Represents a complete chapter.

**Properties:**
```dart
class QuranChapter {
  final String surahName;       // Chapter name (Arabic)
  final int surahNumber;        // Chapter number (1-114)
  final List<QuranVerse> verses;
}
```

**Example:**
```dart
final surah = quranService.getSurah(1);
print('${surah.surahName} (Surah ${surah.surahNumber})');
print('${surah.verses.length} verses');
```

---

### QuranPage

Represents a complete page.

**Properties:**
```dart
class QuranPage {
  final int pageNumber;                    // Page (1-604)
  final List<QuranChapter> chapters;       // Chapters on page

  List<QuranWord> getAllWords()           // All words on page
  Map<int, List<QuranWord>> getWordsByLine() // Organized by line
}
```

---

## Riverpod Providers

State management using Riverpod:

```dart
// Get Quran service
final quranService = ref.watch(quranJsonServiceProvider);

// Get Gemini service
final gemini = ref.watch(geminiLiveServiceProvider);

// Current highlighted words
final words = ref.watch(highlightedWordsProvider);

// Recitation status
final isReciting = ref.watch(isRecitingProvider);

// Status message
final status = ref.watch(statusMessageProvider);

// Audio level
final level = ref.watch(audioLevelProvider);

// All Surahs
final surahs = ref.watch(surahNamesProvider);
```

---

## Utilities

### Arabic Utils

**Functions:**
```dart
String normalizeArabic(String text)  // Remove diacritics, normalize
double arabicSimilarity(String a, String b)  // Calculate similarity
```

---

## Constants

```dart
const double kMinRecitationSimilarity = 0.75; // Threshold for correct match
const double kNearMissSimilarity = 0.60;       // Threshold for near-miss
```

---

## Error Handling

**Common Exceptions:**

```dart
try {
  await geminiService.connect();
} catch (e) {
  // Network error, invalid API key, etc.
  print('Error: $e');
}

// Listen to error stream
geminiService.errorStream.listen((error) {
  print('Gemini error: $error');
});
```

---

## Performance Notes

- **JSON Loading:** All 604 pages loaded once in memory (~10MB)
- **Word Matching:** Uses similarity scoring, ~80% accuracy threshold
- **Audio Processing:** 16kHz PCM, ~500ms segments
- **WebSocket:** Real-time with ~200ms latency

---

## Permissions Required

**Android:**
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
```

**iOS:**
```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for Quran recitation</string>
```

---

## License

MIT License
