# Copilot Instructions for flutter_quran_tajwid

## Project Overview

This is a Flutter package for real-time Quranic recitation analysis. It uses Google Gemini's Live API for Arabic speech-to-text transcription, provides word-by-word highlighting, and detects Tajweed (pronunciation) errors.

## Tech Stack

- **Framework**: Flutter/Dart (SDK >=3.0.0 <4.0.0)
- **State Management**: Riverpod (`flutter_riverpod`)
- **Local Storage**: Hive (`hive_flutter`)
- **Audio Recording**: `record` package
- **Real-time Communication**: WebSocket (`web_socket_channel`)
- **Environment Config**: `flutter_dotenv`
- **UI Scaling**: `flutter_screenutil`

## Project Structure

```
lib/
├── flutter_quran_tajwid.dart  # Package exports
├── models/                    # Data models (HighlightedWord, RecitationSummary, Surah)
├── providers/                 # Riverpod providers (app_state.dart)
├── screens/                   # UI screens (RecitationScreen)
├── services/                  # Business logic services
│   ├── gemini_live_service.dart      # Gemini API WebSocket integration
│   ├── audio_recording_service.dart  # Audio capture
│   ├── quran_json_service.dart       # Quran data loading
│   └── ...
├── widgets/                   # Reusable UI components
└── utils/                     # Utilities (arabic_utils.dart)
```

## Build and Test Commands

```bash
# Install dependencies
flutter pub get

# Run static analysis
flutter analyze

# Run tests
flutter test

# Format code
dart format lib test

# Run the example app
cd example && flutter run
```

## Code Style Guidelines

- Follow the rules defined in `analysis_options.yaml` (includes `package:flutter_lints/flutter.yaml`)
- Use `dart format` for consistent formatting
- Prefer `const` constructors where possible
- Use meaningful variable names in English, but Arabic strings are acceptable for Quran-related content
- Add documentation comments for public APIs

## Riverpod Patterns

This project uses Riverpod for state management. Follow these patterns:

- Use `StateProvider` for simple state
- Use `StateNotifierProvider` for complex state with business logic
- Use `FutureProvider` for async operations
- Access providers with `ref.watch()` for reactive updates or `ref.read()` for one-time access

## Arabic Text Handling

When working with Arabic/Quranic text:

- Use the `arabic_utils.dart` utilities for text normalization
- Be aware of diacritics (tashkeel) and their handling
- The `simpleText` field in `HighlightedWord` contains text without diacritics for comparison
- Use the `Quranic` font family for Quran display text
- Use the `ArabicUI` font family for UI elements

## Key Services

### GeminiLiveService
Handles WebSocket connection to Gemini Live API for real-time Arabic transcription. Audio format: PCM 16-bit mono at 16kHz.

### QuranJsonService
Loads and provides access to Quran data (604 pages, 114 surahs). Must be initialized before use with `await QuranJsonService().initialize()`.

### AudioRecordingService
Manages microphone recording with proper permissions handling.

## Environment Variables

The package requires a `GEMINI_API_KEY` environment variable. In the example app, this is loaded from a `.env` file using `flutter_dotenv`.

## Important Notes

- Audio files are NOT included in the package due to size constraints
- The package focuses on live transcription, not audio playback
- Always handle the case where Gemini API key might be null
- Quran pages are numbered 1-604 following the traditional Mushaf format
