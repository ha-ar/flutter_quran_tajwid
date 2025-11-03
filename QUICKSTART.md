# ⚡ Quick Start Guide

## 1. Download Fonts (5 minutes)

### Option A: Automated Download (if you have curl/wget)
```bash
# Create fonts directory
mkdir -p assets/fonts

# Download Uthmanic Hafs (Quranic font)
# From: https://fonts.qurancomplex.gov.sa
# Save to: assets/fonts/UthmanicHafs.ttf

# Download Noto Naskh Arabic (UI font)
# From: https://fonts.google.com/noto/specimen/Noto+Naskh+Arabic
# Save to: assets/fonts/NotoNaskhArabic-Regular.ttf
# Save to: assets/fonts/NotoNaskhArabic-Bold.ttf
```

### Option B: Manual Download
1. Visit: https://fonts.qurancomplex.gov.sa
   - Download: `UthmanicHafs.ttf`
   - Save to: `assets/fonts/`

2. Visit: https://fonts.google.com/noto/specimen/Noto+Naskh+Arabic
   - Download: `NotoNaskhArabic-Regular.ttf`
   - Download: `NotoNaskhArabic-Bold.ttf`
   - Save both to: `assets/fonts/`

**Verify:**
```bash
ls -la assets/fonts/
# Should show:
# UthmanicHafs.ttf
# NotoNaskhArabic-Regular.ttf
# NotoNaskhArabic-Bold.ttf
```

## 2. Setup Environment (2 minutes)

### Get Gemini API Key
1. Go to: https://aistudio.google.com
2. Click "Get API Key"
3. Create a new key
4. Copy the key

### Create .env File
```bash
# In project root directory:
echo "GEMINI_API_KEY=your_key_here" > .env
```

### Paste Your API Key
```
GEMINI_API_KEY=AIzaSyD... (your actual key)
```

## 3. Install & Run (3 minutes)

```bash
# Get dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# For iOS (first time):
cd ios
pod install
cd ..
flutter run
```

## 4. Test the App

1. **Select Surah**: Choose any Surah from the dropdown (Arabic: "اختر السورة")
2. **Start Recording**: Tap "ابدأ الترتيل" (Start Reciting)
3. **Recite**: Speak Quranic text
4. **Watch**: Words highlight as you recite
5. **Stop**: Tap "إيقاف" (Stop)
6. **Review**: See accuracy and errors

## Features at a Glance

| Feature | Arabic | Status |
|---------|--------|--------|
| All 114 Surahs | كل ١١٤ سورة | ✅ |
| Quranic Fonts | خطوط قرآنية | ✅ |
| Arabic UI | واجهة عربية | ✅ |
| Auto Microphone | ميكروفون تلقائي | ✅ |
| Real-time Transcription | نسخ فوري | ✅ |
| Error Detection | كشف الأخطاء | ✅ |
| Caching | ذاكرة التخزين | ✅ |

## Troubleshooting

### Problem: Fonts not showing
```bash
# Solution:
flutter clean
flutter pub get
flutter run
```

### Problem: API Key error
- Check `.env` file exists
- Verify API key is valid
- No spaces or quotes around key

### Problem: Microphone permission denied
- **iOS**: Settings > Privacy > Microphone > Enable
- **Android**: App Info > Permissions > Microphone > Allow

### Problem: No transcription
1. Check internet connection
2. Verify API key works
3. Test microphone in settings
4. Wait 2-3 seconds after "Start" button

## File Locations

```
📦 Project Root
 ├── 📄 .env (your API key) ← UPDATE THIS
 ├── 📁 assets/
 │   └── 📁 fonts/ (download fonts here)
 │       ├── UthmanicHafs.ttf ← DOWNLOAD
 │       ├── NotoNaskhArabic-Regular.ttf ← DOWNLOAD
 │       └── NotoNaskhArabic-Bold.ttf ← DOWNLOAD
 ├── 📁 lib/
 │   ├── main.dart
 │   ├── screens/
 │   ├── services/
 │   ├── widgets/
 │   └── providers/
 └── 📄 pubspec.yaml
```

## Command Reference

```bash
# Get dependencies
flutter pub get

# Run app
flutter run

# Run on specific device
flutter run -d <device_id>

# Clean
flutter clean

# Build APK (Android)
flutter build apk

# Build iOS
flutter build ios

# Check device list
flutter devices
```

## Color Reference

- 🟢 **Green** (#10B981) = Correct word
- 🔴 **Red** (#DC2626) = Error detected
- ⚪ **Gray** (#F3F4F6) = Not yet recited
- 🟦 **Teal** (#064E3B) = Primary color

## Tips & Tricks

1. **Slow Speech**: Speak slowly for better recognition
2. **Clear Audio**: Use in quiet environment
3. **Pause Between Words**: Small pauses help recognition
4. **Test Microphone**: Test in device settings first
5. **Check Internet**: Ensure stable connection
6. **First Run**: First load takes time (caching)

## Support Resources

- 📖 Gemini Docs: https://ai.google.dev
- 🦋 Flutter Docs: https://flutter.dev
- 📱 Device Troubleshoot: https://support.google.com

## What's Inside

```
✅ 114 Quranic Surahs
✅ Real-time Arabic transcription
✅ Tajweed error detection
✅ Word-by-word highlighting
✅ Detailed recitation summary
✅ Local data caching
✅ Beautiful Arabic fonts
✅ 100% Arabic interface
```

---

**You're ready! 🚀**

Need help? Check `README.md` for more details.
