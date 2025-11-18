# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Overview

Flutter Quran Tajweed is a real-time Quranic recitation assistant that uses Google Gemini's Live API for Arabic speech-to-text. Users select a Surah, recite it, and receive visual feedback through word-by-word highlighting (green for correct, red for errors) with Tajweed error detection.

## Common Commands

### Development
```bash
# Get dependencies
flutter pub get

# Run on device/emulator
flutter run

# Run on specific device
flutter run -d <device_id>

# Run tests
flutter test

# Analyze code for issues
flutter analyze

# Clean build artifacts
flutter clean
```

### Building
```bash
# Android APK
flutter build apk

# iOS
flutter build ios

# Web
flutter build web
```

### Setup
```bash
# Initial setup (fonts, dependencies, .env)
./setup.sh

# iOS pod install
cd ios && pod install && cd ..
```

### Python Scripts (in scripts/)
```bash
# Download and convert Quran audio to PCM format
python scripts/download_convert_quran_audio.py

# Check PCM audio files integrity
python scripts/check_pcm_files.py

# Migrate old 'ayah' naming to 'verse' naming
python scripts/migrate_ayah_to_verse.py
```

## Architecture

### Core Highlighting System

The app's main feature is audio-to-text matching with real-time visual feedback. Understanding this flow is critical:

1. **Audio Recording** → User recites into microphone (16kHz PCM mono)
2. **Audio Buffering** → 500ms segments collected by `AudioMatchingService`
3. **Verse Matching** → Audio waveform compared against reference PCM files in `assets/audio/surah_###/verse_##.pcm`
4. **Word Lookup** → Matched verse number → find all words from that verse in `QuranJsonService`
5. **Highlighting** → Update `HighlightedWord.status` → trigger UI rebuild → render colors

**Key Insight**: Matching happens at the **verse level**, not word-by-word. Once a verse is identified via audio comparison (similarity score ≥ 0.75), all words from that verse are highlighted. The verse number is the link between audio and text.

### State Management (Riverpod)

All app state is managed in `lib/providers/app_state.dart`:

- **Providers**: Define state containers (e.g., `highlightedWordsProvider`, `isRecitingProvider`)
- **StateNotifier**: `TranscriptionProcessor` handles transcription queue processing
- **Reactive UI**: Widgets use `ref.watch()` to rebuild on state changes

State flows: Service → Provider update → Widget rebuild

### Data Flow

```
User Speech → AudioRecordingService (16kHz PCM)
            ↓
AudioMatchingService (buffer + segment extraction)
            ↓
AudioAnalysisService (waveform comparison with reference files)
            ↓
Match found (verse number + confidence score)
            ↓
QuranJsonService.getSurahWords() → filter by verse number
            ↓
Update highlightedWordsProvider (mark words as recitedCorrect/recitedTajweedError)
            ↓
SurahDisplay widget rebuilds → renders colored boxes
```

### Key Services

#### GeminiLiveService (`lib/services/gemini_live_service.dart`)
- Manages WebSocket connection to Gemini API
- Sends audio chunks as base64-encoded PCM
- Receives Arabic transcriptions (both interim and final)
- Model: `gemini-2.0-flash-live-001`
- Configuration: 16kHz mono PCM audio, TEXT response modality

#### AudioMatchingService (`lib/services/audio_matching_service.dart`)
- Buffers incoming audio from microphone
- Extracts segments (default 500ms)
- Implements sliding window search (±5 verses around last match)
- Calls `AudioAnalysisService` for waveform comparison
- Returns best matches sorted by score

#### QuranJsonService (`lib/services/quran_json_service.dart`)
- Loads complete Quran text from `lib/utils/quran_text.json`
- Provides verse and word lookup by Surah/verse number
- All 114 Surahs cached locally

#### AudioRecordingService (`lib/services/audio_recording_service.dart`)
- Records at 16kHz PCM (optimal for Gemini speech recognition)
- Streams audio chunks to Gemini via WebSocket
- Handles microphone permissions

### Models

#### HighlightedWord (`lib/models/highlighted_word.dart`)
```dart
HighlightedWord {
  String text;          // Display text with diacritics (بِسْمِ)
  String simpleText;    // Clean text for matching (بسم)
  WordStatus status;    // unrecited | recitedCorrect | recitedTajweedError
  String? tajweedError; // Error message if applicable
  int verseNumber;      // 1-based verse number
  int wordIndex;        // Position within Surah
  bool isVerseMarker;   // True for verse number markers
}
```

**Color Mapping**:
- `unrecited` → Gray (#F3F4F6)
- `recitedCorrect` → Green (#D1F4E8)
- `recitedTajweedError` → Red (#FEE2E2)

### Arabic Text Processing

The app distinguishes between:
- **Display text** (`text`): Full Quranic text with diacritics/tajweed marks
- **Comparison text** (`simpleText`): Normalized for matching (no diacritics, normalized alif/yaa/ta-marbuta)

See `lib/utils/arabic_utils.dart` for normalization rules.

### Audio Format

All audio must be:
- **Format**: PCM 16-bit mono
- **Sample Rate**: 16kHz
- **Encoding**: Raw PCM bytes (no WAV header)

Reference audio stored in: `assets/audio/surah_###/verse_##.pcm`

## Configuration

### Environment Variables (.env)
```
GEMINI_API_KEY=your_api_key_here
```
Get API key from: https://aistudio.google.com

### Audio Processing Settings
- Sample Rate: 16kHz (`AudioMatchingService.sampleRate`)
- Check Interval: 500ms default for verse matching
- Confidence Threshold: 0.75 (75% similarity required for match)
- Search Window: ±5 verses around last match
- Similarity Threshold for words: 0.8 (80%) = correct, 0.6-0.8 = partial, <0.6 = error

### Fonts
- **Quranic Display**: UthmanTN_v2-0.ttf (family: Quranic)
- **Arabic UI**: NotoNaskhArabic-Regular.ttf, NotoNaskhArabic-Bold.ttf (family: ArabicUI)
- Fonts must be in `assets/fonts/` directory

### Platform Requirements
- **Android**: minSdkVersion 21, requires RECORD_AUDIO, INTERNET, ACCESS_NETWORK_STATE permissions
- **iOS**: iOS 12.0+, requires NSMicrophoneUsageDescription in Info.plist

## Development Guidelines

### When Adding New Features

1. **State changes**: Add providers to `lib/providers/app_state.dart`
2. **Business logic**: Create services in `lib/services/`
3. **UI components**: Place in `lib/widgets/` or `lib/screens/`
4. **Data models**: Define in `lib/models/`

### Testing the Highlighting System

Add debug prints in `TranscriptionProcessor.processQueue()` to trace:
```dart
print('Comparing: transcribed="$transcribedWord" vs expected="$expectedWord"');
print('Similarity score: $similarityScore');
```

Check logs for:
- "Recording started" → microphone working
- "Verse X: Y%" → verse matching working
- "✅ Match accepted" → word successfully matched
- Provider state changes → UI should update

### Working with Audio

- Always use `AudioMatchingService.sampleRate` (16kHz)
- Reference PCM files must match this sample rate
- Use `AudioAnalysisService.compareAudioWaveforms()` for similarity scoring
- Implement sliding window search to optimize verse lookup

### Arabic Text Handling

Always use `normalizeArabic()` from `arabic_utils.dart` for text comparison:
- Removes diacritics (ُ ِ َ etc.)
- Normalizes alif forms (أ إ آ → ا)
- Normalizes ى → ي and ة → ه

Never compare raw Quranic text directly—normalization is essential for accurate matching.

### Gemini API Integration

- WebSocket URL: `wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent`
- Send setup message first with model configuration
- Audio sent as base64-encoded PCM in `realtimeInput.mediaChunks`
- Transcriptions arrive in `inputTranscription` or `modelTurn.parts` format

## Troubleshooting

### No Highlighting
1. Check if audio recording started (look for "Recording started")
2. Verify verse matching (look for "Verse X: Y%" in logs)
3. Check if `highlightedWordsProvider` is being updated
4. Ensure `SurahDisplay` widget watches the provider with `ref.watch()`

### Audio Not Recording
1. Check microphone permissions (Android: RECORD_AUDIO, iOS: NSMicrophoneUsageDescription)
2. Verify `AudioRecordingService` initialization
3. Test microphone in device settings

### Gemini Connection Failed
1. Verify API key in `.env` file
2. Check internet connection
3. Test API key with curl: `curl "https://generativelanguage.googleapis.com/v1beta/models?key=YOUR_KEY"`

### Fonts Not Displaying
1. Ensure font files exist in `assets/fonts/`
2. Run `flutter clean && flutter pub get`
3. Check `pubspec.yaml` fonts configuration

## Documentation References

For detailed understanding of the highlighting system:
- `HIGHLIGHTING_QUICK_REFERENCE.md` - One-page overview of highlighting flow
- `HIGHLIGHTING_FLOW_EXPLAINED.md` - Detailed explanation of verse-to-word mapping
- `DEBUG_HIGHLIGHTING_CHECKLIST.md` - Step-by-step debugging guide
