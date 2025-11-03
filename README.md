# معلم التجويد - Flutter Quran Tajweed Recitation Assistant

A modern Flutter application for real-time Quranic recitation analysis using Google Gemini's Live API for Arabic transcription.

## 🎯 Key Features

- **Real-time Transcription**: Uses Gemini Live API for instant Arabic speech-to-text
- **Complete Quran Data**: All 114 Surahs with local caching
- **Word-by-Word Highlighting**: Visual feedback as you recite with color-coded accuracy
- **Tajweed Error Detection**: Identifies pronunciation mismatches
- **Quranic Typography**: Authentic Uthmanic Hafs font for Quran verses
- **Clean UI**: Modern Material Design 3 with Arabic language support
- **Default Microphone**: Automatically uses device default microphone
- **Recitation Statistics**: Accuracy metrics and detailed error summary
- **Cross-Platform**: iOS, Android, Web support

## � What's New

✅ **Full Quran Integration** - All 114 Surahs cached locally  
✅ **Arabic Quranic Fonts** - Uthmanic Hafs for authentic display  
✅ **Default Microphone** - No mic selection UI needed  
✅ **Arabic UI** - Complete Arabic language interface  
✅ **Enhanced UI** - Clean, modern Material Design 3  

## �🚀 Getting Started

### Prerequisites

- Flutter SDK (3.0+)
- Dart SDK
- Google Gemini API Key
- XCode (for iOS)
- Android Studio (for Android)

### Installation

1. **Clone and install dependencies**:
```bash
cd flutter_quran_tajwid
flutter pub get
```

2. **Set up fonts** (see [FONTS_SETUP.md](FONTS_SETUP.md)):
```bash
# Create fonts directory
mkdir -p assets/fonts

# Download and place fonts:
# - UthmanicHafs.ttf (Quranic font)
# - NotoNaskhArabic-Regular.ttf (UI font)
# - NotoNaskhArabic-Bold.ttf (UI font)
```

3. **Configure API Key**:
Create a `.env` file in the root directory:
```
GEMINI_API_KEY=your_api_key_here
```

Get your Gemini API Key from [Google AI Studio](https://aistudio.google.com)

### Building & Running

```bash
# Run on connected device/emulator
flutter run

# Run on specific device
flutter run -d <device_id>

# Build release
flutter build apk    # Android
flutter build ios    # iOS
flutter build web    # Web
```

## 📱 Platform Setup

### Android
- Minimum SDK: 21
- Permissions configured in `AndroidManifest.xml`
- Requires microphone permission (requested on first use)

### iOS
- Minimum Deployment Target: 12.0
- Permissions configured in `Info.plist`
- Microphone and network permissions required

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
