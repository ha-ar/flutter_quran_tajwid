# Package Size Information

## Published Package Size

The published package on pub.dev is approximately **2 MB** (compressed).

### What's Included

✅ **Quran Text Data** (53 MB uncompressed → ~2 MB compressed)
- Complete 604-page Quran JSON with all surahs, verses, and words
- Line-by-line layout information
- Verse and surah metadata

✅ **Fonts** (~524 KB)
- UthmanTN_v2-0.ttf (136 KB) - Quranic text
- NotoNaskhArabic-Regular.ttf (194 KB) - UI text
- NotoNaskhArabic-Bold.ttf (194 KB) - UI text

✅ **Source Code** (~100 KB)
- All services, models, widgets, and utilities

### What's Excluded (via .pubignore)

❌ **Audio Files** - Not included due to size constraints
- Reference audio files should be hosted separately
- Users can integrate their own audio sources if needed

❌ **Build Artifacts**
- build/, .dart_tool/ directories

❌ **Development Files**
- Debug documentation
- Scripts directory
- Chrome test app

❌ **Example Build Outputs**
- example/build/, example/.dart_tool/

## Why Audio Files Are Not Included

Audio files for the complete Quran would add **several GB** to the package, exceeding pub.dev's 100 MB upload limit. The package focuses on:

1. **Real-time transcription** via Gemini Live API
2. **Text-based recitation analysis**
3. **Word-by-word highlighting**

If you need audio playback features, you can:
- Host audio files on your own CDN/cloud storage
- Download them separately in your app
- Use the `audio_reference_service.dart` as a template

## Verification

Run this command to check what will be published:

```bash
flutter pub publish --dry-run
```

This will show the complete file tree and total compressed size.
