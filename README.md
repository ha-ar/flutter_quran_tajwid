# معلم التجويد - Flutter Quran Tajweed Recitation Assistant

A Flutter package for real-time Quranic recitation analysis using Google Gemini's Live API for Arabic transcription.

## 🎯 Key Features

- **Real-time Transcription**: Uses Gemini Live API for instant Arabic speech-to-text
- **Page-Based Display**: 15-line layout matching traditional Mushaf format (604 pages)
- **Complete Quran Data**: All 604 pages with surah and verse metadata
- **Word-by-Word Highlighting**: Visual feedback as you recite with color-coded accuracy
- **Tajweed Error Detection**: Identifies pronunciation mismatches
- **Quranic Typography**: Authentic Uthmanic Hafs font for Quran verses
- **Clean UI**: Modern Material Design 3 with Arabic language support
- **Recitation Statistics**: Accuracy metrics and detailed error summary
- **Cross-Platform**: iOS, Android support

## 📦 Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_quran_tajwid: ^1.0.2
```

Then run:
```bash
flutter pub get
```

## 🚀 Usage

Import the package:

```dart
import 'package:flutter_quran_tajwid/flutter_quran_tajwid.dart';
```

Initialize in your `main()`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await QuranJsonService().initialize();
  
  runApp(const ProviderScope(child: MyApp()));
}
```

Use the `RecitationScreen` widget with a page number (1-604):

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const RecitationScreen(pageNumber: 1), // Specify page number
    );
  }
}
```

## ⚠️ Important Notes

### Audio Files
**Audio reference files are NOT included in this package** due to size constraints. The package focuses on recitation analysis via live transcription. If you need audio playback features:

1. Host audio files on your own CDN/cloud storage
2. Download them separately in your app
3. Use the `audio_reference_service.dart` as a template for integration

The example app in the repository includes sample audio files for development/testing purposes, but these won't be available in the published package.

### API Key Required
You need a Google Gemini API key for transcription to work:

1. Get your key from [Google AI Studio](https://aistudio.google.com)
2. Configure it in your app (see example for `.env` setup)

## 📱 Example App

The `example` folder contains a complete demonstration. To run it:

```bash
cd example
flutter pub get

# Create .env file with your API key
echo "GEMINI_API_KEY=your_api_key_here" > .env

flutter run
```

## 🏗️ Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── highlighted_word.dart
│   ├── recitation_summary.dart
│   └── surah.dart
├── services/                 # Business logic
│   ├── gemini_live_service.dart   # Gemini API integration
│   ├── audio_recording_service.dart
│   └── quran_service.dart    # Quran data (114 Surahs)
├── providers/                # Riverpod state management
│   └── app_state.dart
├── screens/                  # UI screens
│   └── recitation_screen.dart
├── widgets/                  # Reusable widgets
│   ├── audio_visualizer.dart
│   ├── surah_display.dart
│   └── recitation_summary_widget.dart
└── utils/                    # Utilities
    └── arabic_utils.dart
```

## 🔑 Key Components

### Gemini Live Service
- WebSocket connection to `wss://generativelanguage.googleapis.com`
- PCM audio at 16kHz mono format
- Real-time Arabic transcriptions
- Connection state and error handling

### Quran Service
- **114 Complete Surahs** with full text
- Local Hive-based caching
- Fast surah lookup and search
- Automatic cache management

### Audio Recording
- Records at 16kHz PCM (optimal for speech recognition)
- Real-time streaming to Gemini
- Automatic microphone selection
- Permission handling

### State Management (Riverpod)
- Centralized state for all app data
- Reactive UI updates
- Word matching and error detection logic
- Transcription queue processing

## 🎤 How It Works

1. Select a Surah from the dropdown (Arabic interface)
2. Press "ابدأ الترتيل" (Start Reciting)
3. App automatically connects to Gemini Live API
4. Speak the Quranic text
5. Words are transcribed in real-time
6. **Color Coding**:
   - 🟢 **Green** - Correctly recited words
   - 🔴 **Red** - Tajweed errors detected
   - ⚪ **Gray** - Not yet recited
7. Press "إيقاف" (Stop) to end and view detailed summary

## ⚙️ Configuration

### Audio Quality
- Sample Rate: 16kHz (optimal for speech recognition)
- Format: PCM 16-bit mono
- Bit Rate: 128 kbps

### Gemini Model
- Model: `gemini-2.0-flash-exp`
- Language: Arabic (ar)
- WebSocket: Multimodal Live API
- Input Transcription: Enabled

### Fonts
- **Quran Display**: Uthmanic Hafs (traditional Islamic calligraphy)
- **UI Elements**: Noto Naskh Arabic (modern, readable)

## 🐛 Troubleshooting

### Fonts Not Displaying
- Ensure all font files are in `assets/fonts/`
- Run `flutter clean && flutter pub get`
- Restart the app

### Microphone permission denied
- iOS: Settings > Privacy > Microphone > Allow
- Android: App Settings > Permissions > Microphone

### No transcription received
- Verify API key is correct in `.env`
- Check internet connection
- Test microphone in device settings
- Ensure audio is being recorded (check visualizer)

### WebSocket connection failed
- Validate API key with simple test request
- Check network connectivity
- Try disabling VPN/proxy

## 📦 Dependencies

- **riverpod**: State management
- **record**: Audio recording
- **web_socket_channel**: WebSocket communication
- **hive**: Local data caching
- **flutter_dotenv**: Environment variables

## 🔄 Future Enhancements

- [ ] Offline Quran data with full text (currently summary)
- [ ] Multiple reciter reference styles
- [ ] Detailed Tajweed rules explanation
- [ ] Progress tracking and history
- [ ] Adjustable recitation speed
- [ ] Audio playback with synchronized highlighting
- [ ] Export recitation results as PDF
- [ ] Leaderboard and achievements
- [ ] Multi-language UI support

## 📄 License

Apache 2.0

## 👤 Support

For issues or questions:
- [Google Gemini API Docs](https://ai.google.dev)
- [Flutter Documentation](https://flutter.dev/docs)
- [Quran.com Fonts](https://github.com/quran/fonts)
