# Quick Reference Card - Text Highlighting

## Your Question & Answer (In 30 Seconds)

**Q: How are we highlighting the text? Audio maps over text?**

**A:** 
- Audio is matched to **verses** (not words)
- Waveform comparison identifies which verse you're reciting
- We look up all words from that verse
- Those words get marked as `recitedCorrect`
- UI renders them GREEN
- **The VERSE NUMBER maps audio to text**

---

## The Flow (60 Seconds)

```
Record audio → Buffer 500ms → Compare with reference verses →
Find match (e.g., Verse 5) → Look up words in Verse 5 →
Find those words in display → Mark as recitedCorrect →
Render in GREEN ✅
```

---

## Key Files & What They Do

| File | Does What |
|------|-----------|
| `recitation_screen.dart` | Coordinates: recording → matching → highlighting |
| `audio_matching_service.dart` | Compares audio against reference verses |
| `audio_analysis_service.dart` | Waveform comparison (similarity score) |
| `surah_display.dart` | Renders text with green/red/gray colors |
| `highlighted_word.dart` | Has `status` field (recitedCorrect/error/unrecited) |

---

## Code Locations (With Line Numbers)

| What | File | Lines |
|-----|------|-------|
| Audio matching starts | `recitation_screen.dart` | 376 |
| Verse matching logic | `recitation_screen.dart` | 407 |
| Word highlighting | `recitation_screen.dart` | 454 |
| Word coloring | `surah_display.dart` | 140 |
| Verse match algorithm | `audio_matching_service.dart` | 77 |

---

## Word Status → Color Mapping

```
recitedCorrect      → 🟢 #D1F4E8 (light green)
recitedTajweedError → 🔴 #FEE2E2 (light red)
unrecited           → ⚪ #F3F4F6 (light gray)
```

---

## Configuration Values

```
Sample Rate:        16000 Hz (16 kHz)
Check Interval:     500 ms
Confidence Threshold: 0.75 (75% similar)
Search Window:      ±5 verses around last match
Max Checks:         10 verses per segment
```

---

## Debug: Add These Prints

**In `_matchAudioSegment()` (line 407):**
```dart
print('Matches: ${matches.length}');
for (final m in matches) {
  print('  Verse ${m.verseNumber}: ${(m.score * 100).toStringAsFixed(1)}%');
}
```

**In `_highlightVerseWords()` (line 454):**
```dart
print('Reference words: ${verseWords.length}');
print('Words highlighted: $currentWordIndex / ${verseWords.length}');
```

**Expected output:**
```
Matches: 1
  Verse 5: 85%
Reference words: 4
Words highlighted: 4 / 4
```

---

## Common Problems & Fixes

| Problem | Likely Cause | Fix |
|---------|------------|-----|
| Always gray | No matches | Lower `minScore` (line 421) |
| Status changes, stays gray | Word mismatch | Log `simpleText` comparisons |
| Only some words green | Word count mismatch | Check verse data |
| No UI update | Provider not watched | Check `ref.watch()` on line 53 |

---

## How Word Matching Works

1. Verse 5 identified
2. Get reference words: `getSurahWords().where(verseNumber == 5)`
3. Get: ["بسم", "الله", "الرحمن", "الرحيم"]
4. Compare `simpleText` (no diacritics)
5. If match found: Update status to `recitedCorrect`
6. Update provider: Trigger UI rebuild
7. Render: Green boxes appear

---

## Provider State Update

```dart
// Before
[{text: "بسم", status: unrecited}, ...]

// After matching
[{text: "بسم", status: recitedCorrect}, ...]

// Triggers
ref.watch(highlightedWordsProvider) → rebuilds
SurahDisplay.build() → called
_buildWordWidget() → applies color
```

---

## Testing Each Stage

```
✅ Audio recording?      → Look for "Recording started" message
✅ Audio matching?       → Look for "Verse X: Y%" in logs
✅ Verse lookup?         → Look for "Reference words: N" in logs
✅ Word matching?        → Look for "Words highlighted: N / M" in logs
✅ Provider update?      → Look for state change logs
✅ UI render?            → Look for green boxes on screen
```

---

## The Complete Picture

```
┌─────────────────────────────────────────┐
│ 1. Audio Input (Microphone)             │
│    ↓                                    │
│ 2. Buffering (500ms segments)           │
│    ↓                                    │
│ 3. Waveform Comparison (Audio Service) │
│    ↓                                    │
│ 4. Verse Identification (Score > 0.75) │
│    ↓                                    │
│ 5. Word Lookup (Quran JSON Service)    │
│    ↓                                    │
│ 6. Word Matching (Compare simpleText)  │
│    ↓                                    │
│ 7. Status Update (Provider change)      │
│    ↓                                    │
│ 8. UI Rebuild (SurahDisplay)           │
│    ↓                                    │
│ 9. Color Rendering (_buildWordWidget)  │
│    ↓                                    │
│ 10. 🟢 GREEN HIGHLIGHTING 🟢            │
└─────────────────────────────────────────┘
```

---

## Data Model

```dart
HighlightedWord {
  String text;           // "بِسْمِ" (with diacritics, for display)
  String simpleText;     // "بسم" (clean, for matching)
  WordStatus status;     // recitedCorrect, recitedTajweedError, unrecited
  String? tajweedError;  // null or error message
}

// Status colors
enum WordStatus {
  unrecited,          // Gray
  recitedCorrect,     // Green ✅
  recitedTajweedError,// Red ❌
}
```

---

## Algorithm (High Level)

```
For each 500ms audio segment:
  1. For each verse in sliding window:
       - Load reference audio from assets/audio/surah_###/verse_##.pcm
       - Compare user audio with reference
       - Calculate similarity score
       - If score > 0.75: MATCH found!
  2. Get best match (highest score)
  3. Look up words for matched verse
  4. Find words in display text
  5. Mark as recitedCorrect
  6. Update provider (triggers UI)
```

---

## Asset Structure

```
assets/audio/
├── surah_001/
│   ├── verse_001.pcm
│   ├── verse_002.pcm
│   └── ...
├── surah_002/
│   └── ...
└── ...
```

Each `.pcm` file is raw 16-bit PCM audio at 16kHz mono.

---

## One-Minute Summary

> Your highlighting system identifies **which verse** the user is reciting (by comparing audio waveforms), then **highlights all words from that verse** in green. No character-level timing needed. The verse number is the link between audio and text.

---

## For Complete Details

📖 Full docs: `HIGHLIGHTING_DOCS_INDEX.md`
🔍 Debugging: `DEBUG_HIGHLIGHTING_CHECKLIST.md`
📊 Visuals: `HIGHLIGHTING_VISUAL_GUIDE.md`

---

Print this card and keep it handy! 📋
