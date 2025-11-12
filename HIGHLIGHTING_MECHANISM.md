# Text Highlighting Mechanism - Current Flow

## Overview
The highlighting system works through **verse-level audio matching** rather than character/word matching. Audio is matched to verses, and then all words in that verse are highlighted.

## Current Flow (No Direct Text Matching)

```
┌─────────────────────────────────────────────────────────────────┐
│  1. USER SPEAKS (Audio Input)                                   │
│     → Captured by AudioRecordingService                          │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│  2. AUDIO BUFFERING & SEGMENTATION                              │
│     → onAudioData callback in recitation_screen.dart (line 376) │
│     → Chunks added to AudioMatchingService buffer               │
│     → Every 500ms of audio extracted as segment                 │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│  3. VERSE-LEVEL AUDIO MATCHING                                  │
│     → _matchAudioSegment() calls audioMatching.matchWithVerses()│
│     → Matches 500ms audio against reference verses using:       │
│       • Sliding window (±5 verses around last match)            │
│       • Limited verse checks (max 10 verses per call)           │
│       • Waveform comparison (AudioAnalysisService)              │
│       • High confidence threshold (minScore: 0.75)              │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│  4. BEST VERSE DETERMINED                                       │
│     → Returns top match: (verseNumber, score)                   │
│     → Best match passed to _highlightVerseWords()               │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│  5. WORDS IN VERSE HIGHLIGHTED                                  │
│     → _highlightVerseWords() (line 454):                        │
│       • Gets all words from matched verse using                 │
│         quranService.getSurahWords()                            │
│       • Matches simpleText (no diacritics) from:                │
│         - highlightedWordsProvider (all words in memory)        │
│         - Words from reference for current verse                │
│       • Updates matching words' status to:                      │
│         WordStatus.recitedCorrect                               │
│       • Updates provider with new highlighted words list        │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│  6. UI RENDERING                                                │
│     → SurahDisplay widget watches highlightedWordsProvider      │
│     → For each word in recitedCorrect status:                   │
│       • Green background: #D1F4E8                               │
│       • Green border: #10B981                                   │
│       • Dark green text: #064E3B                                │
│     → All other words show gray (unrecited)                     │
└─────────────────────────────────────────────────────────────────┘
```

## Key Files & Their Roles

### 1. `lib/screens/recitation_screen.dart`
- **Lines 376-396**: Audio recording callback
  - Adds chunks to buffer
  - Every 500ms extracts and matches segment
- **Lines 407-440**: `_matchAudioSegment()`
  - Calls `audioMatching.matchWithVerses()`
  - Gets best verse match
  - Calls `_highlightVerseWords()`
- **Lines 454-481**: `_highlightVerseWords()`
  - Finds all words in matched verse
  - Matches simpleText and updates status
  - Updates `highlightedWordsProvider`

### 2. `lib/services/audio_matching_service.dart`
- **Lines 77-140**: `matchWithVerses()`
  - Uses sliding window around `_lastMatchedVerse`
  - Limited to 10 verse checks per call
  - Compares user audio with reference using `AudioAnalysisService.compareAudioWaveforms()`
  - Returns top 2 matches sorted by score

### 3. `lib/widgets/surah_display.dart`
- **Lines 140-160**: `_buildWordWidget()`
  - Checks word.status
  - Applies color based on status:
    - `recitedCorrect` → Green
    - `recitedTajweedError` → Red
    - `unrecited` → Gray

### 4. `lib/models/highlighted_word.dart`
- **Fields**:
  - `text`: Full display text (with diacritics)
  - `simpleText`: Clean text (no diacritics) for comparison
  - `status`: WordStatus enum
  - `tajweedError`: Optional tajweed error message

## Why Highlighting Might Not Work

### ❌ Issue 1: No Audio Matching
- If audio waveform comparison isn't working, no verses match
- `matchWithVerses()` returns empty list
- `_highlightVerseWords()` never called

**Solution**: Check `AudioAnalysisService.compareAudioWaveforms()` - is it comparing correctly?

### ❌ Issue 2: Word Matching Within Verse
- Even if verse matches, words might not highlight
- The simpleText comparison might fail if:
  - `updatedWords[i].simpleText` is empty or malformed
  - `verseWords[currentWordIndex].simpleText` doesn't match
  - Word count mismatch (fewer words in memory than in reference)

**Debug**: Add console logs to `_highlightVerseWords()` to see:
```dart
print('Verse $verseNumber: ${verseWords.length} words from reference');
print('Highlighted words available: ${updatedWords.length} total');
for (var w in verseWords) {
  print('  Word: ${w.simpleText}');
}
```

### ❌ Issue 3: Provider Not Updating UI
- Provider state updated but UI not rebuilding
- Check: Is `SurahDisplay` watching `highlightedWordsProvider`?

**Current code** (line 53):
```dart
final highlightedWords = ref.watch(highlightedWordsProvider);
```
✅ This should work

### ❌ Issue 4: Wrong Verse Number
- Matching algorithm returns wrong verseNumber
- Highlighted words from different verse
- Then word matching fails because simpleText doesn't match

## Testing Checklist

1. **Enable debug prints** in `_matchAudioSegment()` and `_highlightVerseWords()`
2. **Check AudioAnalysisService**: Are scores returning > 0.75?
3. **Verify verse data**: Call `quranService.getSurah()` and `quranService.getSurahWords()`
4. **Test word matching**: Compare simpleText values manually
5. **Monitor provider updates**: Log state changes to `highlightedWordsProvider`

## Next Steps to Fix

1. Add comprehensive logging to understand where the flow breaks
2. Test audio waveform comparison in isolation
3. Verify verse data is correctly loaded
4. Check word simpleText generation
5. Confirm provider updates trigger UI rebuilds
