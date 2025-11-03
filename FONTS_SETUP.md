# Font Setup Guide

This app uses custom Arabic fonts for authentic Quranic display.

## Required Fonts

### 1. Quranic Font (for Quran text)
- **File**: `UthmanicHafs.ttf`
- **Source**: Download from [fonts.qurancomplex.gov.sa](https://fonts.qurancomplex.gov.sa)
- **Save Location**: `assets/fonts/UthmanicHafs.ttf`

### 2. Arabic UI Font (for UI elements)
- **File**: `NotoNaskhArabic-Regular.ttf` and `NotoNaskhArabic-Bold.ttf`
- **Source**: Download from [Google Fonts - Noto Naskh Arabic](https://fonts.google.com/noto/specimen/Noto+Naskh+Arabic)
- **Save Location**: 
  - `assets/fonts/NotoNaskhArabic-Regular.ttf`
  - `assets/fonts/NotoNaskhArabic-Bold.ttf`

## Setup Steps

1. Create the fonts directory:
```bash
mkdir -p assets/fonts
```

2. Download and place the fonts in `assets/fonts/`

3. The fonts are already configured in `pubspec.yaml`

4. Run:
```bash
flutter pub get
flutter clean
flutter pub get
```

5. Run the app:
```bash
flutter run
```

## Alternative Font Sources

If the above sources are unavailable:

- **Quranic Fonts**: 
  - [Quran.com fonts](https://github.com/quran/fonts)
  - [Islamic Network fonts](https://github.com/islamic-network/quran-fonts)

- **Arabic UI Fonts**:
  - [Segoe UI Historic](https://docs.microsoft.com/en-us/typography/font-list/segoe-ui-historic)
  - [Cairo Font](https://fonts.google.com/specimen/Cairo)
  - [Droid Arabic Naskh](https://fonts.google.com/specimen/Droid+Arabic+Naskh)

## Font Characteristics

### Uthmanic Hafs
- Professional Quranic typography
- Follows traditional Islamic calligraphy standards
- Perfect for displaying Quran verses

### Noto Naskh Arabic
- Modern, clear, and readable
- Great for UI elements and labels
- Supports full Arabic character set
