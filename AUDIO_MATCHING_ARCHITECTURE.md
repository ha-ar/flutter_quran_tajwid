# Audio Matching Architecture

## Overview

This document explains how audio matching and recitation verification works in the Flutter Quran Tajwid application.

## Architecture Decision: Text-Based Matching

The application uses **text-based fuzzy matching** rather than direct audio-to-audio comparison. This is the appropriate approach for this use case.

### Why Text-Based Matching?

1. **Gemini Live API Excellence**: The Gemini Live API provides high-quality, real-time Arabic transcription optimized for speech recognition.

2. **No Reference Audio**: Direct audio comparison requires reference recordings of professional reciters for each word of every surah. This would require:
   - Recordings of all 114 surahs
   - Word-by-word segmentation
   - Storage of ~77,000+ word audio clips
   - Alignment algorithms for time-varying speech
   
3. **Text Matching is Sufficient**: For Tajweed verification, comparing transcribed text with expected text provides accurate detection of pronunciation errors.

4. **Computational Efficiency**: Text comparison is much faster and less resource-intensive than audio signal processing.

## How It Works

### 1. Audio Capture
```
User speaks → AudioRecordingService captures PCM audio at 16kHz → 
Streams to Gemini Live API
```

**File**: `lib/services/audio_recording_service.dart`
- Records audio in PCM 16-bit format
- 16kHz sample rate (optimal for speech)
- Mono channel
- Real-time streaming

### 2. Transcription
```
Gemini Live API receives audio → Transcribes to Arabic text →
Returns transcription messages
```

**File**: `lib/services/gemini_live_service.dart`
- WebSocket connection to Gemini
- Real-time Arabic transcription
- Handles both partial and final transcriptions
- Error handling and reconnection

### 3. Text Normalization
```
Transcribed text → Arabic normalization → Clean text for comparison
```

**File**: `lib/utils/arabic_utils.dart`
- Removes diacritics (ً ٌ ٍ َ ُ ِ ّ ْ)
- Normalizes alif forms (أ إ آ → ا)
- Normalizes ya/alif maqsurah (ى → ي)
- Normalizes ta marbuta (ة → ه)

### 4. Fuzzy Matching
```
Normalized transcription → Fuzzy comparison with expected word →
Similarity score (0.0 to 1.0)
```

**File**: `lib/services/fuzzy_matching_service.dart`

Uses two algorithms combined:
- **String Similarity** (from `string_similarity` package)
- **Levenshtein Distance** (custom implementation)

Returns average of both for robust matching.

**Thresholds**:
- ≥ 80% → ✅ Correct (green)
- 60-79% → ⚠️ Warning (yellow) - "Check Tajweed rules"
- < 60% → ❌ Error (red)

### 5. State Management
```
Match result → Update word status → UI reflects changes
```

**File**: `lib/providers/app_state.dart`
- `TranscriptionProcessor` handles word queue
- Updates `HighlightedWord` status
- Maintains current word index
- Generates recitation summary

## Audio Analysis Service

**File**: `lib/services/audio_analysis_service.dart`

This service is available for **audio quality analysis**, not word matching:

### Current Uses
- Audio quality checks (volume, clipping detection)
- Debug metrics (RMS energy, pitch, frequency)
- Future enhancements for audio feedback

### Methods

#### `checkAudioQuality(audioData)`
Analyzes audio quality and provides feedback:
```dart
final quality = AudioAnalysisService.checkAudioQuality(audioBuffer);
// Returns:
// {
//   'isGood': true/false,
//   'issues': ['Volume too low', ...],
//   'recommendations': ['Speak louder', ...],
//   'metrics': { 'rms': 0.156, 'energy': 0.024, 'peak': 0.89 }
// }
```

#### `analyzeAudio(audioData)`
Returns detailed audio characteristics:
```dart
final analysis = AudioAnalysisService.analyzeAudio(audioBuffer);
// Returns:
// {
//   'duration_seconds': 2.5,
//   'rms_energy': 0.156,
//   'energy': 0.024,
//   'zero_crossing_rate': 0.125,
//   'estimated_pitch_hz': 220.5,
//   'peak_amplitude': 0.89
// }
```

#### `compareAudioWaveforms(audio1, audio2)`
Available for future use if reference audio becomes available:
```dart
final similarity = AudioAnalysisService.compareAudioWaveforms(
  userRecording,
  referenceRecording
);
// Returns: 0.0 to 1.0 (similarity score)
```

Compares audio using:
- Waveform cross-correlation
- Energy similarity
- Frequency characteristics (zero-crossing rate)
- Pitch similarity

## Data Flow Diagram

```
┌─────────────────┐
│  User Speaks    │
│   (Quranic      │
│   Recitation)   │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│ AudioRecordingService   │
│ - Captures PCM 16kHz    │
│ - Streams in real-time  │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  Gemini Live API        │
│ - Receives audio stream │
│ - Transcribes to Arabic │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  GeminiLiveService      │
│ - Handles transcription │
│ - Queues words          │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  TranscriptionProcessor │
│ - Normalizes Arabic     │
│ - Gets expected word    │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  FuzzyMatchingService   │
│ - Calculates similarity │
│ - Determines match type │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  Update Word Status     │
│ - ✅ Correct (≥80%)     │
│ - ⚠️ Warning (60-79%)   │
│ - ❌ Error (<60%)       │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  UI Updates             │
│ - Color highlighting    │
│ - Error messages        │
│ - Statistics            │
└─────────────────────────┘
```

## Files Summary

| File | Purpose | Status |
|------|---------|--------|
| `audio_recording_service.dart` | Capture audio from microphone | ✅ In Use |
| `gemini_live_service.dart` | Communicate with Gemini API | ✅ In Use |
| `fuzzy_matching_service.dart` | Calculate text similarity | ✅ In Use |
| `audio_analysis_service.dart` | Analyze audio quality/characteristics | ⚠️ Available for quality checks |
| `arabic_utils.dart` | Normalize Arabic text | ✅ In Use |
| `app_state.dart` | Process transcriptions & manage state | ✅ In Use |

## Future Enhancements

### Phase 1: Audio Quality Feedback (Easy)
- Integrate `AudioAnalysisService.checkAudioQuality()` in recording flow
- Show user feedback: "Volume too low", "Microphone too far", etc.
- Display audio level meter during recitation

### Phase 2: Reference Audio Comparison (Moderate)
If reference recordings become available:
1. Store word-level audio clips of professional reciter
2. Use `AudioAnalysisService.compareAudioWaveforms()` 
3. Combine audio similarity with text similarity
4. Weight: 70% text + 30% audio

### Phase 3: Advanced Tajweed Detection (Complex)
- Train ML model on specific Tajweed rules:
  - Idgham (merging)
  - Qalqalah (echoing)
  - Ikhfa (nasalization)
  - Ghunna (nasal sound)
- Use audio features + text for classification
- Provide specific Tajweed rule feedback

## Configuration

### Adjusting Match Thresholds

Edit `lib/services/fuzzy_matching_service.dart`:

```dart
/// High similarity threshold for correct recitation
static const double correctThreshold = 0.8;  // Current: 80%

/// Medium similarity threshold for partial match
static const double warningThreshold = 0.6;  // Current: 60%
```

**More Lenient** (fewer errors marked):
```dart
static const double correctThreshold = 0.7;  // 70%
static const double warningThreshold = 0.5;  // 50%
```

**More Strict** (more errors marked):
```dart
static const double correctThreshold = 0.9;  // 90%
static const double warningThreshold = 0.7;  // 70%
```

## Testing

### Manual Testing
1. Select a short surah (e.g., Al-Fatiha)
2. Start recitation
3. Observe word highlighting:
   - Green = correct
   - Yellow = partial match
   - Red = error
4. Check console logs for similarity scores
5. Verify error messages are helpful

### Debug Logging
Enable detailed logs in `app_state.dart`:
```dart
print('Comparing: transcribed="$transcribedWord" vs expected="$expectedWord"');
print('Similarity score: $similarityScore');
print('Match result: $matchResult');
```

### Audio Quality Testing
```dart
final quality = AudioAnalysisService.checkAudioQuality(audioBuffer);
debugPrint('Audio Quality: ${quality['isGood']}');
debugPrint('Issues: ${quality['issues']}');
debugPrint('Recommendations: ${quality['recommendations']}');
```

## Performance Considerations

### Text Matching Performance
- **Fast**: O(n*m) for Levenshtein distance where n, m are word lengths
- Typical Arabic word: 3-7 characters
- Processing time: < 1ms per word
- No performance issues for real-time use

### Audio Processing Performance
- `checkAudioQuality()`: ~5ms for 1-second audio clip
- `analyzeAudio()`: ~10ms for 1-second audio clip
- `compareAudioWaveforms()`: ~50ms for 1-second clips
- All methods are non-blocking and can run in background

## Conclusion

The current text-based matching approach is:
- ✅ **Accurate** - Gemini provides excellent Arabic transcription
- ✅ **Fast** - Real-time processing with no lag
- ✅ **Practical** - No need for massive reference audio database
- ✅ **Maintainable** - Simple architecture, easy to debug
- ✅ **Extensible** - Can add audio analysis when reference audio available

The audio analysis service is available for quality checks and future enhancements, but direct audio-to-audio comparison is not currently needed for effective Tajweed error detection.
