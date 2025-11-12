# Text Highlighting System - Detailed Analysis

## ❓ Your Question: "How is highlighting working? Audio maps over text?"

### Simple Answer
**We're NOT doing direct text-to-audio matching.** Instead:

1. Your audio is matched against **reference audio files** (verse-level PCM files)
2. If a match is found (e.g., verse 5), we look up which **words belong to verse 5**
3. Those words get marked as `recitedCorrect` (green highlight)
4. The UI renders them green

---

## 📊 The Complete Flow

### Stage 1: Audio Capture
```
[Microphone Input]
        ↓
[AudioRecordingService]
        ↓
onAudioData callback (100ms chunks every ~100ms)
        ↓
recitation_screen.dart line 376
```

**Code location**: `recitation_screen.dart:376`
```dart
onAudioData: (List<int> audioData) {
  audioMatching.addAudioChunk(audioData);  // Add to buffer
  
  // Every 500ms, extract and try to match
  if (audioMatching.getBuffer().length >= bytesFor500ms) {
    final segment = audioMatching.extractSegment(500);
    _matchAudioSegment(segment, surahNumber);
  }
}
```

### Stage 2: Audio Matching (Verse-Level)
```
[500ms Audio Segment]
        ↓
_matchAudioSegment() line 407
        ↓
audioMatching.matchWithVerses()
        ↓
AudioMatchingService:77
        ├─ Sliding window: last_match ± 5 verses
        ├─ Limited to 10 verse checks
        └─ For each verse:
           └─ Load reference audio from assets/audio/surah_###/verse_##.pcm
                    ↓
           Waveform comparison with user audio
                    ↓
           If score > 0.75 → MATCH!
        ↓
Returns: [{verseNumber: 5, score: 0.85}, ...]
        ↓
Best match selected: Verse 5 with 85% confidence
```

**Key files involved**:
- `audio_matching_service.dart:77` - `matchWithVerses()`
- `audio_analysis_service.dart` - `compareAudioWaveforms()` (does waveform comparison)
- `audio_reference_service.dart` - Loads `.pcm` reference files

### Stage 3: Words Lookup
```
[Best Match: Verse 5]
        ↓
_highlightVerseWords(5) line 454
        ↓
quranService.getSurahWords(surahNumber)
        ↓
Filter for: verseNumber == 5
        ↓
Get list of words in verse 5:
[
  {text: "بِسْمِ", simpleText: "بسم", verseNumber: 5},
  {text: "اللَّهِ", simpleText: "الله", verseNumber: 5},
  ...
]
```

### Stage 4: Word Matching & Highlighting
```
For each word in verse 5 from reference:
  ↓
Find matching word in highlightedWordsProvider
  ├─ Compare simpleText (no diacritics)
  ├─ If match found:
  │  └─ Set status = WordStatus.recitedCorrect
  │
  └─ If no match:
     └─ Status stays WordStatus.unrecited

Update highlightedWordsProvider with new list
```

**Code**: `recitation_screen.dart:454-481`
```dart
void _highlightVerseWords(int verseNumber) {
  final highlightedWords = ref.read(highlightedWordsProvider);
  final verseWords = allWords.where((w) => w.verseNumber == verseNumber).toList();
  
  final updatedWords = List<HighlightedWord>.from(highlightedWords);
  
  for (int i = 0; i < updatedWords.length; i++) {
    if (updatedWords[i].simpleText == referenceWord.simpleText) {
      updatedWords[i] = updatedWords[i].copyWith(
        status: WordStatus.recitedCorrect,  // ← This marks it for highlighting!
      );
    }
  }
  
  ref.read(highlightedWordsProvider.notifier).state = updatedWords;
}
```

### Stage 5: UI Rendering
```
SurahDisplay watches highlightedWordsProvider
        ↓
For each word:
  ├─ status = recitedCorrect  → Green (#D1F4E8)
  ├─ status = tajweedError    → Red (#FEE2E2)
  └─ status = unrecited       → Gray (#F3F4F6)
        ↓
_buildWordWidget() colors and renders
        ↓
[Highlighted Green Words] 🟢
```

**Code**: `surah_display.dart:140-160`
```dart
switch (word.status) {
  case WordStatus.recitedCorrect:
    backgroundColor = const Color(0xFFD1F4E8);  // Green
    textColor = const Color(0xFF064E3B);
    borderColor = const Color(0xFF10B981);
    break;
  // ...
}
```

---

## 🔗 How Audio "Maps" to Text

The mapping happens through **verse numbers**:

```
User's 500ms audio
    ↓
[Waveform Comparison]
    ↓
"This sounds like Verse 5" (85% match)
    ↓
Look up: "What words are in Verse 5?"
    ↓
quranService.getSurahWords(surahNumber)
    .where((w) => w.verseNumber == 5)
    ↓
Get 10-15 words from verse 5
    ↓
Find those words in the displayed text
    ↓
Mark them as recitedCorrect (green)
```

**The "mapping" is through the `verseNumber` field**, not through character-by-character timing.

---

## ⚠️ Why Highlighting Might NOT Be Working

### Problem 1: Audio Matching Returns No Results
- **Symptom**: Status says "جاهز للبدء" (ready), never changes
- **Cause**: `AudioAnalysisService.compareAudioWaveforms()` returns scores < 0.75
- **Test**: Add logging to `_matchAudioSegment()` to see if matches > 0

```dart
final matches = await audioMatching.matchWithVerses(...);
print('🔍 Matches found: ${matches.length}');
for (final m in matches) {
  print('  Verse ${m.verseNumber}: ${(m.score * 100).toStringAsFixed(1)}%');
}
```

### Problem 2: Verse Words Mismatch
- **Symptom**: Status changes to verse number, but no green highlighting
- **Cause**: Word count/text mismatch between reference and display
- **Test**: Log in `_highlightVerseWords()`:

```dart
print('Reference has ${verseWords.length} words');
print('Highlighted has ${highlightedWords.length} total words');
for (final w in verseWords) {
  print('  Need: "${w.simpleText}"');
}
```

### Problem 3: simpleText Mismatch
- **Symptom**: Reference and display words don't match
- **Cause**: 
  - Diacritics not removed correctly
  - Different character encoding
  - Verse marker characters included
- **Test**: Print side-by-side:

```dart
print('Memory[i]: "${updatedWords[i].simpleText}" (${updatedWords[i].simpleText.runes.toList()})');
print('Reference: "${verseWords[j].simpleText}" (${verseWords[j].simpleText.runes.toList()})');
```

### Problem 4: Provider Not Updating UI
- **Symptom**: Log shows highlighting update, but UI doesn't change
- **Cause**: Widget not watching `highlightedWordsProvider`
- **Check**: `recitation_screen.dart:53`

```dart
final highlightedWords = ref.watch(highlightedWordsProvider);  // ✅ Correct
```

---

## 🧪 How to Debug

### Add Comprehensive Logging

**File**: `recitation_screen.dart`

**In `_matchAudioSegment()`** (line 407):
```dart
final matches = await audioMatching.matchWithVerses(...);
print('═══ AUDIO MATCHING ═══');
print('Segment: ${segment.length} bytes, ${durationMs}ms');
print('Matches: ${matches.length}');
for (final m in matches) {
  print('  ✓ Verse ${m.verseNumber}: ${(m.score * 100).toStringAsFixed(1)}%');
}
```

**In `_highlightVerseWords()`** (line 454):
```dart
print('═══ HIGHLIGHT VERSE $verseNumber ═══');
print('Reference words: ${verseWords.length}');
verseWords.forEach((w) => print('  "${w.simpleText}"'));
print('Highlighted words: ${highlightedWords.length} total');
// ... matching code ...
print('Result: $currentWordIndex words matched');
```

### Check Each Stage

1. **Does audio match?**
   - Look for "✓ Verse X" in logs

2. **Are verse words loaded?**
   - Check "Reference words" count

3. **Do words match?**
   - Compare simpleText outputs

4. **Does provider update?**
   - Check "Result: X words matched"

5. **Does UI rebuild?**
   - Look for green boxes on screen

---

## 📁 File Map

| File | Purpose | Key Methods |
|------|---------|-------------|
| `audio_matching_service.dart` | Match audio to verses | `matchWithVerses()` |
| `audio_analysis_service.dart` | Waveform comparison | `compareAudioWaveforms()` |
| `audio_reference_service.dart` | Load reference PCM | `loadReferenceAudio()` |
| `recitation_screen.dart` | Main screen logic | `_matchAudioSegment()`, `_highlightVerseWords()` |
| `surah_display.dart` | Render with colors | `_buildWordWidget()` |
| `highlighted_word.dart` | Word model | `WordStatus` enum |

---

## 🎯 Summary

**Your highlighting works like this:**

```
🎤 Record audio
    ↓
📊 Match against reference verses (0.75+ confidence)
    ↓
✅ Found match: "Verse 5"
    ↓
📖 Look up words in Verse 5
    ↓
🔍 Find those words in current text
    ↓
🟢 Color them green
    ↓
✨ User sees green highlighting
```

**No direct text-to-speech matching happens.** It's all verse-level audio matching.
