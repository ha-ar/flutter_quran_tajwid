# معلم التجويد - Flutter Quran Tajweed Recitation Assistant# معلم التجويد - Flutter Quran Tajweed Recitation Assistant



A Flutter package for real-time Quranic recitation analysis using Google Gemini's Live API for Arabic transcription.A modern Flutter application for real-time Quranic recitation analysis using Google Gemini's Live API for Arabic transcription.



## 🎯 Key Features## 🎯 Key Features



- **Real-time Transcription**: Uses Gemini Live API for instant Arabic speech-to-text- **Real-time Transcription**: Uses Gemini Live API for instant Arabic speech-to-text

- **Complete Quran Data**: All 114 Surahs with local caching- **Complete Quran Data**: All 114 Surahs with local caching

- **Word-by-Word Highlighting**: Visual feedback as you recite with color-coded accuracy- **Word-by-Word Highlighting**: Visual feedback as you recite with color-coded accuracy

- **Tajweed Error Detection**: Identifies pronunciation mismatches- **Tajweed Error Detection**: Identifies pronunciation mismatches

- **Quranic Typography**: Authentic Uthmanic Hafs font for Quran verses- **Quranic Typography**: Authentic Uthmanic Hafs font for Quran verses

- **Clean UI**: Modern Material Design 3 with Arabic language support- **Clean UI**: Modern Material Design 3 with Arabic language support

- **Default Microphone**: Automatically uses device default microphone- **Default Microphone**: Automatically uses device default microphone

- **Recitation Statistics**: Accuracy metrics and detailed error summary- **Recitation Statistics**: Accuracy metrics and detailed error summary

- **Cross-Platform**: iOS, Android, Web support- **Cross-Platform**: iOS, Android, Web support



## 📦 Installation## � What's New



Add this to your package's `pubspec.yaml` file:✅ **Full Quran Integration** - All 114 Surahs cached locally  

✅ **Arabic Quranic Fonts** - Uthmanic Hafs for authentic display  

```yaml✅ **Default Microphone** - No mic selection UI needed  

dependencies:✅ **Arabic UI** - Complete Arabic language interface  

  flutter_quran_tajwid:✅ **Enhanced UI** - Clean, modern Material Design 3  

    git:

      url: https://github.com/ha-ar/flutter_quran_tajwid.git## �🚀 Getting Started

```

### Prerequisites

## 🚀 Usage

- Flutter SDK (3.0+)

Import the package:- Dart SDK

- Google Gemini API Key

```dart- XCode (for iOS)

import 'package:flutter_quran_tajwid/flutter_quran_tajwid.dart';- Android Studio (for Android)

```

### Installation

Initialize the Quran service in your `main()`:

1. **Clone and install dependencies**:

```dart```bash

void main() async {cd flutter_quran_tajwid

  WidgetsFlutterBinding.ensureInitialized();flutter pub get

  await QuranJsonService().initialize();```

  

  runApp(const ProviderScope(child: MyApp()));2. **Set up fonts** (see [FONTS_SETUP.md](FONTS_SETUP.md)):

}```bash

```# Create fonts directory

mkdir -p assets/fonts

Use the `RecitationScreen` widget:

# Download and place fonts:

```dart# - UthmanicHafs.ttf (Quranic font)

class MyApp extends StatelessWidget {# - NotoNaskhArabic-Regular.ttf (UI font)

  const MyApp({super.key});# - NotoNaskhArabic-Bold.ttf (UI font)

```

  @override

  Widget build(BuildContext context) {3. **Configure API Key**:

    return MaterialApp(Create a `.env` file in the root directory:

      home: const RecitationScreen(),```

    );GEMINI_API_KEY=your_api_key_here

  }```

}

```Get your Gemini API Key from [Google AI Studio](https://aistudio.google.com)



## 📱 Running the Example### Building & Running



The `example` folder contains a complete sample application.```bash

# Run on connected device/emulator

1. Go to the example directory:flutter run

   ```bash

   cd example# Run on specific device

   ```flutter run -d <device_id>



2. Create a `.env` file in `example/` with your Gemini API key:# Build release

   ```flutter build apk    # Android

   GEMINI_API_KEY=your_api_key_hereflutter build ios    # iOS

   ```flutter build web    # Web

```

3. Run the app:

   ```bash## 📱 Platform Setup

   flutter run

   ```### Android

- Minimum SDK: 21

## 🏗️ Project Structure- Permissions configured in `AndroidManifest.xml`

- Requires microphone permission (requested on first use)

- `lib/`: Core library code (Services, Models, Widgets).

- `example/`: Complete example application demonstrating usage.### iOS

- Minimum Deployment Target: 12.0

## 📄 License- Permissions configured in `Info.plist`

- Microphone and network permissions required

MIT License

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
