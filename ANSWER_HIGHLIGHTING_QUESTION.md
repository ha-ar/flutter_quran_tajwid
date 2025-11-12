# Highlighting System - Complete Answer

## Your Question: "How are we highlighting the text now? As we are not doing text matching, how does the audio map over the text?"

---

## ✅ The Direct Answer

**We're NOT doing character-level text-to-audio matching.**

Instead, the system works through **verse-level identification**:

1. Your audio (500ms segments) is compared against **reference verse audio files** stored in `assets/audio/`
2. When a match is found (e.g., the audio matches verse 5), we get the verse NUMBER
3. We then look up ALL WORDS that belong to that verse from the Quran JSON data
4. We find those words in the displayed text and mark them as "recitedCorrect"
5. The UI renders them GREEN

**The mapping is through the VERSE NUMBER, not through character timing.**

---

## 🔄 Complete Flow (Step by Step)

### Step 1: Audio Capture
```
You start recording
    ↓
AudioRecordingService captures 100ms chunks
    ↓
Every ~100ms: onAudioData callback fires with chunk data
```
**Code**: `recitation_screen.dart:376`

### Step 2: Buffering & Segmentation
```
Chunk added to buffer: audioMatching.addAudioChunk(audioData)
    ↓
Buffer accumulates data
    ↓
When buffer has 500ms of audio:
  └─ Extract segment: audioMatching.extractSegment(500)
     └─ 500ms = (16000 Hz × 0.5s × 2 bytes) = 16,000 bytes
```
**Code**: `audio_matching_service.dart:33-49`

### Step 3: Verse-Level Audio Matching
```
_matchAudioSegment(segment, surahNumber) is called
    ↓
Calls: audioMatching.matchWithVerses(segment, surahNumber)
    ↓
Inside matchWithVerses():
  ├─ Sliding window: search verses around _lastMatchedVerse
  │   └─ Last match was verse 3, so search verses 1-8 (±5)
  │
  ├─ For each verse (e.g., verse 2):
  │   ├─ Load reference audio from: assets/audio/surah_001/verse_002.pcm
  │   ├─ Compare your audio with reference using: AudioAnalysisService.compareAudioWaveforms()
  │   ├─ Get similarity score: 0.0 to 1.0
  │   └─ If score ≥ 0.75: This is a MATCH! ✅
  │
  └─ Return best match: {verseNumber: 5, score: 0.85}
```
**Code**: `audio_matching_service.dart:77-140`

### Step 4: Look Up Verse Words
```
Best match found: Verse 5
    ↓
Call: quranService.getSurahWords(surahNumber)
  └─ Loads all 8,000+ words from Surah 1
    ↓
Filter by verse: .where((w) => w.verseNumber == 5)
  └─ Results: 4 words from verse 5: ["بسم", "الله", "الرحمن", "الرحيم"]
    ↓
Get these 4 words' data including:
  ├─ text: "بِسْمِ" (with diacritics, for display)
  ├─ simpleText: "بسم" (clean, for matching)
  └─ verseNumber: 5
```
**Code**: `recitation_screen.dart:454-481` in `_highlightVerseWords()`

### Step 5: Word Matching in Display
```
For each reference word from verse 5:
    ├─ Search through ALL displayed words (1000+ words in memory)
    ├─ Compare: highlightedWord.simpleText == referenceWord.simpleText
    │           ("بسم" == "بسم" ✅)
    ├─ If match found:
    │   └─ Update that word's status: WordStatus.recitedCorrect
    │
    └─ Move to next reference word

Results:
  - Word at display index 0 (بسم) → recitedCorrect ✅
  - Word at display index 1 (الله) → recitedCorrect ✅
  - Word at display index 2 (الرحمن) → recitedCorrect ✅
  - Word at display index 3 (الرحيم) → recitedCorrect ✅
```
**Code**: `recitation_screen.dart:466-478`

### Step 6: Update Provider
```
Create new list with updated words
    ↓
ref.read(highlightedWordsProvider.notifier).state = updatedWords
    ↓
All widgets watching this provider get notified
```
**Code**: `recitation_screen.dart:480`

### Step 7: UI Renders
```
SurahDisplay watches: ref.watch(highlightedWordsProvider)
    ↓
SurahDisplay.build() is called with new word list
    ↓
For each word, _buildWordWidget() is called:
  ├─ Check word.status
  ├─ If recitedCorrect:
  │   ├─ backgroundColor = #D1F4E8 (light green)
  │   ├─ textColor = #064E3B (dark green)
  │   ├─ borderColor = #10B981 (medium green)
  │
  ├─ If tajweedError:
  │   ├─ backgroundColor = #FEE2E2 (light red)
  │   └─ textColor = #7F1D1D (dark red)
  │
  └─ Else (unrecited):
      ├─ backgroundColor = #F3F4F6 (light gray)
      └─ textColor = #374151 (dark gray)
    ↓
Render with Container + Text + styling
    ↓
🟢 GREEN HIGHLIGHTING VISIBLE 🟢
```
**Code**: `surah_display.dart:140-160` in `_buildWordWidget()`

---

## 🎯 How Audio Maps to Text: The Complete Picture

```
YOUR AUDIO INPUT
       ↓
[Waveform Comparison]
   "Does this sound like Verse 1?"
   "Does this sound like Verse 2?"
   "Does this sound like Verse 3?"
       ↓
   "This matches Verse 5 at 85% confidence!" ✅
       ↓
   Extract Verse Number: 5
       ↓
[Verse 5 Lookup]
   "What words are in Verse 5 of the Quran?"
   Answer: "بسم" + "الله" + "الرحمن" + "الرحيم"
       ↓
[Word Matching]
   "Find these 4 words in the displayed text"
   Found at positions: 0, 1, 2, 3
       ↓
[Status Update]
   Mark those 4 positions as: recitedCorrect
       ↓
[UI Rendering]
   Render with GREEN color 🟢
```

**The VERSE NUMBER is what maps your audio to the text.**
Not millisecond-level timing, not character matching, just: "which verse is this audio?"

---

## 📁 File Roles

| File | What It Does |
|------|-------------|
| `recitation_screen.dart` | Controls the flow: records audio, calls matching, updates highlighting |
| `audio_matching_service.dart` | Compares user audio against reference verses, returns best verse match |
| `audio_analysis_service.dart` | Does the actual waveform comparison (calculates similarity score) |
| `audio_reference_service.dart` | Loads reference PCM audio from assets for each verse |
| `surah_display.dart` | Renders text with colors based on word status (word colors) |
| `highlighted_word.dart` | Data model for each word (has status field) |
| `quran_json_service.dart` | Loads Quran data, looks up words by verse number |

---

## ❌ What's NOT Happening

- ❌ No real-time speech recognition
- ❌ No syllable/phoneme detection
- ❌ No character-by-character timing
- ❌ No FFT bin alignment
- ❌ No Tajweed rule checking (at matching stage)

---

## ✅ What IS Happening

- ✅ Waveform shape comparison (does it SOUND similar?)
- ✅ Verse-level identification (which verse is this?)
- ✅ Word lookup (what words are in that verse?)
- ✅ Highlighting (mark those words green)
- ✅ Tajweed error detection (after highlighting, optional)

---

## 🧪 How to Verify It's Working

Add these debug prints to see each step:

**In `_matchAudioSegment()` (line 407):**
```dart
print('Segment: ${segment.length} bytes');
final matches = await audioMatching.matchWithVerses(...);
print('Matches: ${matches.length}');
for (final m in matches) {
  print('  Verse ${m.verseNumber}: ${(m.score * 100).toStringAsFixed(1)}%');
}
```

**In `_highlightVerseWords()` (line 454):**
```dart
final verseWords = allWords.where((w) => w.verseNumber == verseNumber).toList();
print('Reference words for verse $verseNumber: ${verseWords.length}');
print('Matching with ${highlightedWords.length} displayed words');
// ... after matching ...
print('Words highlighted: $matchCount / ${verseWords.length}');
```

**Expected output:**
```
Segment: 16000 bytes
Matches: 1
  Verse 5: 85%
Reference words for verse 5: 4
Matching with 8000 displayed words
Words highlighted: 4 / 4
✅ GREEN 4 WORDS VISIBLE ON SCREEN
```

---

## Summary

| Aspect | Details |
|--------|---------|
| **Audio Matching** | Waveform comparison (not speech recognition) |
| **Verse Identification** | Audio shape compared to reference verses |
| **Text Lookup** | Words retrieved from Quran JSON by verse number |
| **Text-Audio Link** | Via verse number, not timing or phonetics |
| **Highlighting** | Words marked as `recitedCorrect` status |
| **Colors** | Green for correct, red for errors, gray for unrecited |

**The beauty of this approach:** No need for perfect timing or phoneme alignment. Just "does this audio sound like verse 5?" If yes, highlight verse 5's words. Simple and effective! 🎯
