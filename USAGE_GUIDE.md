# Flutter Quran Tajweed Plugin - Usage Guide

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_quran_tajwid:
    git:
      url: https://github.com/ha-ar/flutter_quran_tajwid.git
```

## Quick Start

### 1. Initialize in `main()`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quran_tajwid/flutter_quran_tajwid.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables for Gemini API key
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: .env file not found.");
  }

  // Initialize Quran service (loads all 604 pages from JSON)
  await QuranJsonService().initialize();

  runApp(const ProviderScope(child: MyApp()));
}
```

### 2. Create `.env` File

In your app root or `example/` directory:

```
GEMINI_API_KEY=your_api_key_here
```

Get your key from [Google AI Studio](https://aistudio.google.com)

### 3. Use RecitationScreen with Page Number

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const RecitationScreen(pageNumber: 1), // Required parameter
      theme: ThemeData(useMaterial3: true),
    );
  }
}
```

## Key Features

### Page-Based Display
- **15-Line Layout**: Each page displays exactly 15 lines (standard Mushaf format)
- **Complete Quran**: All 604 pages available (Surah Al-Fatiha through Surah An-Nas)
- **Line Numbers**: Words are tracked by line number from the JSON data
- **Page Navigation**: Pass any page number from 1-604

### Real-Time Recitation Analysis
```dart
// User recites while audio is sent to Gemini Live API
// Words are matched against expected text
// Color-coded feedback:
//   🟢 Green  = Correctly recited
//   🟡 Yellow = Near miss (minor pronunciation error)
//   🔴 Red    = Tajweed error detected
//   ⚪ Gray   = Not yet recited
```

### Word Status Tracking

```dart
enum WordStatus {
  unrecited,           // Not yet said by user
  recitedCorrect,      // Correctly matched with transcription
  recitedNearMiss,     // Close pronunciation (>60% similarity)
  recitedTajweedError, // Error or not recognized (<60% similarity)
}
```

## Page Numbers Reference

Each page corresponds to the standard Quran pages:

```
Page 1   = Surah Al-Fatiha (Chapter 1)
Page 2   = Surah Al-Baqarah begins (Chapter 2)
...
Page 604 = End of Quran (Surah An-Nas, Chapter 114)
```

To find the page for a specific Surah:

```dart
final quranService = QuranJsonService();
await quranService.initialize();

final pageNumber = quranService.getPageForSurah(2); // Returns page for Surah Al-Baqarah
```

## Model Classes

### HighlightedWord

Represents a single word in the Quran with its metadata:

```dart
class HighlightedWord {
  final String text;           // Display text (with diacritics)
  final String simpleText;     // Clean text (for comparison)
  final WordStatus status;     // Recitation status
  final String? tajweedError;  // Error message if applicable
  final int verseNumber;       // Verse this word belongs to
  final int lineNumber;        // Line number on the page (1-15)
  final int wordIndex;         // Position in Surah
  final bool isVerseMarker;    // True if this is a verse number/marker
}
```

### QuranPage

Represents a complete page (contains multiple chapters/verses):

```dart
class QuranPage {
  final int pageNumber;        // Page number (1-604)
  final List<QuranChapter> chapters;

  // Get all words on this page
  List<QuranWord> getAllWords()

  // Get words organized by line number
  Map<int, List<QuranWord>> getWordsByLine()
}
```

## Services

### QuranJsonService

Singleton service that manages Quran data:

```dart
final quranService = QuranJsonService();

// Initialize once (loads JSON)
await quranService.initialize();

// Get a specific page
final page = quranService.getPage(1);

// Get all pages
final pages = quranService.getAllPages();

// Get a specific Surah
final surah = quranService.getSurah(1); // Surah Al-Fatiha

// Get page for a Surah
final pageNum = quranService.getPageForSurah(2);

// Get all Surahs with names
final surahs = quranService.getAllSurahs(); 
// Returns: [
//   {'number': 1, 'name': 'Al-Fatiha', 'pageNumber': 1},
//   {'number': 2, 'name': 'Al-Baqarah', 'pageNumber': 2},
//   ...
// ]

// Get words for a specific Surah
final words = quranService.getSurahWords(1);
```

### GeminiLiveService

Handles real-time transcription via Gemini Live API:

```dart
final geminiService = GeminiLiveService(apiKey: 'your-api-key');

// Connect to WebSocket
await geminiService.connect();

// Listen for transcriptions
geminiService.transcriptionStream.listen((message) {
  print('Transcribed: ${message.text}');
});

// Send audio chunk (PCM 16kHz)
await geminiService.sendAudioChunk(audioBytes);

// Disconnect
await geminiService.disconnect();
```

### AudioRecordingService

Records audio and sends to Gemini:

```dart
final audioRecorder = AudioRecordingService();

// Initialize
await audioRecorder.initialize();

// Start recording
await audioRecorder.startRecording(
  onAudioData: (chunk) {
    // Send chunk to Gemini
    geminiService.sendAudioChunk(Uint8List.fromList(chunk));
  },
  onError: (error) {
    print('Recording error: $error');
  },
);

// Stop recording
await audioRecorder.stopRecording();
```

## State Management (Riverpod)

The plugin uses Riverpod for state management. Key providers:

```dart
// Current page display data
final highlightedWordsProvider = StateProvider<List<HighlightedWord>>(...)

// Current recitation status
final isRecitingProvider = StateProvider<bool>(...)

// Status messages to show user
final statusMessageProvider = StateProvider<String>(...)

// Audio level visualization
final audioLevelProvider = StateProvider<double>(...)

// Quran service instance
final quranJsonServiceProvider = StateProvider<QuranJsonService>(...)

// Gemini service instance
final geminiLiveServiceProvider = StateProvider<GeminiLiveService?>(...)
```

## Example: Creating a Page Selector

```dart
class PageSelectorApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Page')),
      body: Consumer(
        builder: (context, ref, _) {
          final surahsAsync = ref.watch(surahNamesProvider);
          
          return surahsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => Center(child: Text('Error: $err')),
            data: (surahs) => ListView.builder(
              itemCount: surahs.length,
              itemBuilder: (context, index) {
                final surah = surahs[index];
                return ListTile(
                  title: Text(surah['name']),
                  subtitle: Text('Surah ${surah['number']} - Page ${surah['pageNumber']}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecitationScreen(
                          pageNumber: surah['pageNumber'] as int,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
```

## Testing

Run the example app:

```bash
cd example
flutter run
```

This will start with Page 1 (Surah Al-Fatiha). You can modify the page number in `example/lib/main.dart`:

```dart
home: const RecitationScreen(pageNumber: 1), // Change to any page 1-604
```

## File Structure

```
lib/
├── flutter_quran_tajwid.dart     # Public API exports
├── models/
│   ├── highlighted_word.dart     # Word display model
│   └── ...
├── screens/
│   └── recitation_screen.dart    # Main UI (requires pageNumber)
├── services/
│   ├── quran_json_service.dart   # Loads all 604 pages from JSON
│   ├── gemini_live_service.dart  # Real-time transcription
│   └── audio_recording_service.dart
├── providers/
│   └── app_state.dart            # Riverpod providers
└── utils/
    └── arabic_utils.dart         # Arabic text processing

example/
├── lib/main.dart                 # Example app entry point
├── pubspec.yaml                  # Example dependencies
└── .env                          # API key configuration
```

## Troubleshooting

### Asset Loading Error
If you get "Unable to load asset: lib/utils/quran_text.json", ensure:
1. The JSON file exists in `lib/utils/`
2. `pubspec.yaml` declares the asset
3. Run `flutter clean && flutter pub get`

### No Transcription
- Verify Gemini API key in `.env`
- Check internet connection
- Test microphone permissions
- Ensure audio is being recorded (check app logs)

### Page Not Found
- Verify page number is between 1-604
- Use `QuranJsonService().getPageForSurah(surahNumber)` to find the correct page

## Contributing

Issues and PRs welcome at [GitHub](https://github.com/ha-ar/flutter_quran_tajwid)

## License

MIT License
