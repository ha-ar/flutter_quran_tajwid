# Highlighting System - Visual Summary

## Quick Visual Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                     TEXT HIGHLIGHTING FLOW                       │
└──────────────────────────────────────────────────────────────────┘

                           🎤 USER SPEAKS
                                │
                                ▼
                    AudioRecordingService
                    (records 100ms chunks)
                                │
                    ┌───────────┴───────────┐
                    ▼                       ▼
            Every 500ms:              onAudioData callback
            Extract segment           (adds to buffer)
                    │
                    ▼
        ┌─────────────────────────────┐
        │ _matchAudioSegment()        │
        └──────────────┬──────────────┘
                       │
                ┌──────▼──────┐
                │   MATCHING   │
                │  ALGORITHM   │
                │ (verse-level)│
                └──────┬───────┘
                       │
          ┌────────────┼────────────┐
          │            │            │
          ▼            ▼            ▼
      Sliding      Load Ref    Waveform
      Window      Audio Files  Compare
      (±5v)       from assets
          │            │            │
          └────────────┴────────────┘
                       │
                    MATCHES?
                       │
            ┌──────────┴──────────┐
            │                     │
          YES                    NO
            │                     │
            ▼                     ▼
      BEST MATCH           Try next verse
     (Verse N)             or timeout
            │
            ▼
  ┌─────────────────────────┐
  │ _highlightVerseWords()  │
  │ (Verse N)               │
  └──────────┬──────────────┘
             │
             ▼
  ┌────────────────────────────────┐
  │ Get words for Verse N:         │
  │ quranService.getSurahWords()   │
  │ .where(verseNumber == N)       │
  └──────────┬─────────────────────┘
             │
             ▼
  ┌────────────────────────────────┐
  │ Match with displayed words:    │
  │ Compare simpleText             │
  │ Update status to               │
  │ recitedCorrect                 │
  └──────────┬─────────────────────┘
             │
             ▼
  ┌────────────────────────────────┐
  │ Update highlightedWordsProvider│
  └──────────┬─────────────────────┘
             │
             ▼
  ┌────────────────────────────────┐
  │   SurahDisplay rebuilds        │
  │   (watches provider)           │
  └──────────┬─────────────────────┘
             │
             ▼
  ┌────────────────────────────────┐
  │ _buildWordWidget()             │
  │ Checks word.status             │
  └──────────┬─────────────────────┘
             │
      ┌──────┴───────┬──────────┐
      │              │          │
   recited       tajweed    unrecited
   Correct       Error
      │              │          │
      ▼              ▼          ▼
    GREEN          RED         GRAY
   🟢🟢🟢         🔴🔴🔴      ⚪⚪⚪


╔══════════════════════════════════════════════════════════════════╗
║  THE KEY INSIGHT:                                               ║
║  No character-level timing!                                     ║
║  Just: verse match → look up verse words → color them          ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## Data Flow Through Components

```
┌────────────────┐
│ Audio Buffer   │  Contains 500ms of user's audio
│ (byte array)   │
└────────┬───────┘
         │
         ▼
┌────────────────────────────┐
│ AudioAnalysisService       │ Compares waveforms
│ compareAudioWaveforms()    │ Returns similarity score
└────────┬───────────────────┘   (0.0 = completely different)
         │                        (1.0 = identical)
         ▼
┌────────────────────────────┐
│ Matching Results           │ If score > 0.75:
│ [{verse: 5, score: 0.85}]  │   ✅ This is a match
└────────┬───────────────────┘
         │
         ▼
┌────────────────────────────┐
│ Verse 5 from:              │
│ quranService.getSurahWords │
│ Filter: verseNumber == 5   │
└────────┬───────────────────┘
         │
         ▼
┌────────────────────────────┐
│ Words List:                │
│ [{                         │
│   text: "بِسْمِ",          │
│   simpleText: "بسم",      │
│   verseNumber: 5,          │
│ }, ...]                    │
└────────┬───────────────────┘
         │
         ▼ (Find matches in highlighted words)
┌────────────────────────────┐
│ HighlightedWord Updates:   │
│ - simpleText: "بسم"        │
│ - status: recitedCorrect ✅│
└────────┬───────────────────┘
         │
         ▼ (Update provider)
┌────────────────────────────┐
│ highlightedWordsProvider   │
│ notifier.state = updatedList
└────────┬───────────────────┘
         │
         ▼ (Trigger rebuild)
┌────────────────────────────┐
│ SurahDisplay Widget        │
│ watches: highlightedWords  │
└────────┬───────────────────┘
         │
         ▼ (For each word)
┌────────────────────────────┐
│ _buildWordWidget():        │
│ if status == recitedCorrect│
│   color = GREEN (#D1F4E8)  │
└────────┬───────────────────┘
         │
         ▼
    🟢 GREEN HIGHLIGHTING 🟢
```

---

## Important Constants & Thresholds

```
┌─────────────────────────────────────────┐
│ Audio Configuration                     │
├─────────────────────────────────────────┤
│ Sample Rate:       16 kHz (16000 Hz)   │
│ Bit Depth:         16-bit (2 bytes)     │
│ Check Interval:    500 ms                │
│ Throttle Delay:    300 ms                │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Matching Thresholds                     │
├─────────────────────────────────────────┤
│ Min Score:         0.75 (75% similar)   │
│ Max Verses/Check:  10 verses             │
│ Window Radius:     ±5 verses             │
│ Max Matches:       2 verses              │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ UI Colors                               │
├─────────────────────────────────────────┤
│ Recited Correct:   🟢 #D1F4E8 (green)   │
│ Tajweed Error:     🔴 #FEE2E2 (red)     │
│ Unrecited:         ⚪ #F3F4F6 (gray)    │
│ Border Green:      #10B981               │
│ Border Red:        #DC2626               │
│ Border Gray:       #E5E7EB               │
└─────────────────────────────────────────┘
```

---

## File Interactions Diagram

```
                    ┌─────────────────────────────────┐
                    │ recitation_screen.dart          │
                    │ (Main coordinator)              │
                    │                                 │
                    │ _startRecitation()              │
                    │ _matchAudioSegment()            │
                    │ _highlightVerseWords()          │
                    │ _stopRecitation()               │
                    └──────────┬──────────────────────┘
                               │
            ┌──────────────────┼──────────────────┐
            │                  │                  │
            ▼                  ▼                  ▼
    ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
    │ AudioMatching    │  │QuranJsonService  │  │SurahDisplay      │
    │Service           │  │                  │  │Widget            │
    │                  │  │getSurah()        │  │                  │
    │matchWithVerses() │  │getSurahWords()   │  │_buildWordWidget()│
    │addAudioChunk()   │  │                  │  │_buildLine()      │
    └────────┬─────────┘  └──────────────────┘  └──────────────────┘
             │
             ▼
    ┌──────────────────┐
    │AudioAnalysis     │
    │Service           │
    │                  │
    │compareAudioWave  │
    │forms()           │
    └────────┬─────────┘
             │
             ▼
    ┌──────────────────┐
    │AudioReference    │
    │Service           │
    │                  │
    │loadReferenceAudio│
    │(from assets)     │
    └──────────────────┘

            ▲
            │
        READS FROM:
        assets/audio/
        surah_###/
        verse_##.pcm
```

---

## How Text Mapping Works

### Without Direct Timing:

```
User speaks: "Bismi-llahi r-rahmani r-rahim"
     │
     ▼ (converted to waveform)
[Audio Signal] ▁▂▃▂▁▂▃▅▃▂▁▂
     │
     ▼
Compare with reference: Verse 1 Audio
     │
     ▼
Match score: 0.85 (85% similar) ✅
     │
     ▼
"This user said Verse 1"
     │
     ▼
Look up: "What words are in Verse 1?"
Answer: "بسم", "الله", "الرحمن", "الرحيم"
     │
     ▼
Find those 4 words in the text display
     │
     ▼
Color them GREEN 🟢

═══════════════════════════════════════

Key: The VERSE NUMBER is what maps audio to text!
     Not character timing or FFT bin matching
```

---

## Provider State Changes

```
Initial State:
┌───────────────────────────────────┐
│ highlightedWordsProvider          │
│ [                                 │
│   {text: "بسم", status: unrecited}│
│   {text: "الله", status: unrecited}
│   {text: "...", status: unrecited}
│ ]                                 │
└───────────────────────────────────┘

                ↓ (After audio match)

After Match:
┌───────────────────────────────────┐
│ highlightedWordsProvider          │
│ [                                 │
│   {text: "بسم", status: recited✅ }│
│   {text: "الله", status: recited✅}
│   {text: "...", status: unrecited}
│ ]                                 │
└───────────────────────────────────┘

                ↓ (Provider notifies watchers)

UI Rebuilds:
  Watch detected change
  SurahDisplay.build() called
  _buildWordWidget() for each word
  Applies green color to recited words
  Renders on screen

Result: 🟢 "بسم الله" in GREEN 🟢
```

---

## Common Highlighting Failures

```
❌ Failure 1: "Always gray, never highlights"
   └─ Reason: matchWithVerses() returns empty
      └─ Fix: Check AudioAnalysisService scoring

❌ Failure 2: "Verse changes but words don't highlight"
   └─ Reason: verseWords lookup fails
      └─ Fix: Check getSurahWords() returns data

❌ Failure 3: "Words don't match in _highlightVerseWords()"
   └─ Reason: simpleText comparison fails
      └─ Fix: Log and compare strings byte-by-byte

❌ Failure 4: "Words highlighted but UI stays gray"
   └─ Reason: SurahDisplay not watching provider
      └─ Fix: Check ref.watch(highlightedWordsProvider)

❌ Failure 5: "Wrong words highlighted"
   └─ Reason: Verse number mismatch
      └─ Fix: Verify matchWithVerses() returns correct verse
```

---

## Testing Each Component

```
Test 1: Audio Capture ✅
  └─ Enable microphone
  └─ Start recording
  └─ Speak
  └─ Check buffer has data

Test 2: Audio Matching ✅
  └─ Check that matches > 0
  └─ Check scores > 0.75
  └─ Log verse numbers

Test 3: Verse Lookup ✅
  └─ Check getSurahWords() works
  └─ Verify verseNumber filtering
  └─ Log word count

Test 4: Word Matching ✅
  └─ Compare simpleText values
  └─ Check if any match = yes
  └─ Log matches

Test 5: Provider Update ✅
  └─ Check notifier.state = updatedList
  └─ Verify list has recitedCorrect status

Test 6: UI Rendering ✅
  └─ Check _buildWordWidget() colors
  └─ Look for green boxes on screen
```

---

## Summary

| Component | Purpose | Input | Output |
|-----------|---------|-------|--------|
| AudioRecordingService | Capture audio | Mic | Raw bytes |
| AudioMatchingService | Buffer & segment | Bytes | Segments |
| AudioAnalysisService | Compare waveforms | 2 audio arrays | Score (0-1) |
| AudioReferenceService | Load reference | Surah, verse | PCM bytes |
| RecitationScreen | Coordinate | Audio events | Highlight calls |
| QuranJsonService | Load Quran data | Surah, verse | Word list |
| SurahDisplay | Render UI | Word list | Colored text |

**The highlighting works by:**
1. Matching audio to verses (verse-level)
2. Looking up words in that verse
3. Marking those words as recited
4. UI renders them in color
