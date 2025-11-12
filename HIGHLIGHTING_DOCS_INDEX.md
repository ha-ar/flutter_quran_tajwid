# Highlighting System - Documentation Index

## 📚 Quick Navigation

### For Quick Understanding
1. **START HERE**: `ANSWER_HIGHLIGHTING_QUESTION.md` - Direct answer to your question
2. **Visual Overview**: `HIGHLIGHTING_VISUAL_GUIDE.md` - Diagrams and flowcharts
3. **Step-by-Step**: `HIGHLIGHTING_FLOW_EXPLAINED.md` - Detailed explanation with code

### For Debugging
1. **Start Debugging**: `DEBUG_HIGHLIGHTING_CHECKLIST.md` - Copy-paste debug code
2. **Advanced Logging**: `DEBUG_HIGHLIGHTING_INTEGRATION.md` - Integration instructions
3. **Debug Service**: `lib/services/debug_highlighting_service.dart` - Reusable logging service

### For Implementation Details
1. **Architecture**: `HIGHLIGHTING_MECHANISM.md` - System architecture

---

## 🎯 Key Concepts

### The Highlighting Process (TL;DR)

```
Audio → Waveform Match → Verse Identified → Words Looked Up → Highlighted GREEN ✅
```

**No character-level matching. Just verse-level audio identification.**

### Core Files Involved

```
lib/screens/recitation_screen.dart
  ├─ _matchAudioSegment() — Controls audio matching flow
  ├─ _highlightVerseWords() — Highlights words from matched verse
  └─ onAudioData callback — Buffers incoming audio

lib/services/audio_matching_service.dart
  └─ matchWithVerses() — Matches audio to reference verses

lib/services/audio_analysis_service.dart
  └─ compareAudioWaveforms() — Waveform comparison algorithm

lib/widgets/surah_display.dart
  └─ _buildWordWidget() — Renders word with color based on status
```

---

## 🔍 Debugging Steps

### Quick Test (5 minutes)

1. Add print statements from `DEBUG_HIGHLIGHTING_CHECKLIST.md`
2. Run app and select a Surah
3. Tap Record and recite some words
4. Check console output for:
   ```
   Matches: 1
   Verse X: Y%
   Words highlighted: N / M
   ```

### Full Diagnosis (15 minutes)

Follow the checklist in `DEBUG_HIGHLIGHTING_CHECKLIST.md`:
1. ✅ Check Audio Recording
2. ✅ Check Audio Matching Attempt
3. ✅ Check Verse Word Lookup
4. ✅ Check Word Matching
5. ✅ Verify Provider Update
6. ✅ Check UI Rendering

### Common Issues & Fixes

| Issue | Likely Cause | Fix |
|-------|-------------|-----|
| Always gray, no highlighting | Audio matching returns no matches | Check `minScore` threshold (line 421 in recitation_screen.dart) |
| Status changes but words stay gray | Word matching fails | Log simpleText comparisons in `_highlightVerseWords()` |
| Only some words highlight | Word count mismatch | Check verse data is complete |
| UI doesn't update | Provider not watched | Verify `ref.watch(highlightedWordsProvider)` |

---

## 📊 Data Flow Summary

```
INPUT:  User's recorded audio (bytes)
        ↓
PROCESS: 
  1. Buffer segments (500ms chunks)
  2. Compare against reference verses
  3. Identify best verse match
  4. Look up words in matched verse
  5. Find words in display
  6. Update word status
        ↓
OUTPUT: Words highlighted in GREEN 🟢
```

---

## 🛠️ Implementation Details

### How Audio Matching Works

The `AudioMatchingService` uses:
- **Sliding window**: Only searches ±5 verses around last match (efficient)
- **Limited verse checks**: Max 10 verses per 500ms segment (performance)
- **Waveform comparison**: `AudioAnalysisService.compareAudioWaveforms()` (similarity score)
- **Confidence threshold**: Must be ≥ 0.75 (adjustable)

### How Words Are Highlighted

Once a verse is identified:
1. Extract words from reference: `quranService.getSurahWords(surahNumber).where((w) => w.verseNumber == verseNumber)`
2. Match with displayed: Compare `simpleText` (no diacritics)
3. Update status: `WordStatus.recitedCorrect`
4. Update provider: Trigger UI rebuild
5. Render: `_buildWordWidget()` applies green color

### Word Status Enum

```dart
enum WordStatus {
  unrecited,          // Gray - not yet recited
  recitedCorrect,     // Green - matched correctly
  recitedTajweedError,// Red - matched but has tajweed error
}
```

---

## 📝 Example Flow

### User Recites "Bismi-llahi r-rahmani r-rahim" (Surah 1, Verse 1)

```
Step 1: Audio recorded
Step 2: After 500ms, segment extracted from buffer
Step 3: matchWithVerses() called with 16,000-byte segment
Step 4: Compared against verses 1-10 (sliding window)
Step 5: Verse 1 returns 0.85 score → Match! ✅
Step 6: _highlightVerseWords(1) called
Step 7: Reference words fetched: ["بسم", "الله", "الرحمن", "الرحيم"]
Step 8: Words found in display at indices 0, 1, 2, 3
Step 9: All 4 words marked as recitedCorrect
Step 10: Provider updated → UI rebuilds
Step 11: Words render in GREEN 🟢🟢🟢🟢
```

---

## ✨ Key Insights

1. **Verse-Level Matching**: Audio is matched to verses, not words
2. **Simple Text Comparison**: Uses `simpleText` (no diacritics) for matching
3. **Efficient Searching**: Sliding window limits search space
4. **Provider-Driven UI**: UI updates via Riverpod state changes
5. **Reference Audio Storage**: `.pcm` files in `assets/audio/surah_###/`

---

## 🚀 To Get Started

1. **Understand the flow**: Read `ANSWER_HIGHLIGHTING_QUESTION.md` (2 min read)
2. **See the visuals**: Check `HIGHLIGHTING_VISUAL_GUIDE.md` (3 min read)
3. **Debug if needed**: Use `DEBUG_HIGHLIGHTING_CHECKLIST.md` (follow steps)
4. **Dig deeper**: Read `HIGHLIGHTING_FLOW_EXPLAINED.md` for details

---

## 📞 Support

### If highlighting isn't working:

1. **Check this first**: `DEBUG_HIGHLIGHTING_CHECKLIST.md` Step 1-3
2. **Add debug logs**: Use copy-paste code from `DEBUG_HIGHLIGHTING_CHECKLIST.md`
3. **Watch console**: Look for verse match output
4. **Check each stage**: Follow the 5-step checklist

### If you need to modify behavior:

1. **Change matching sensitivity**: `minScore` in `_matchAudioSegment()` line 421
2. **Change highlighting colors**: `surah_display.dart` line 140-160
3. **Change search window**: `windowRadius` in `_matchAudioSegment()` line 426
4. **Change check interval**: `maxVerseToCheck` in `_matchAudioSegment()` line 424

---

## 📖 Document Overview

| Document | Purpose | Read Time |
|----------|---------|-----------|
| `ANSWER_HIGHLIGHTING_QUESTION.md` | Direct answer + complete flow | 5 min |
| `HIGHLIGHTING_VISUAL_GUIDE.md` | Diagrams, constants, component interaction | 4 min |
| `HIGHLIGHTING_FLOW_EXPLAINED.md` | Detailed step-by-step with code | 8 min |
| `HIGHLIGHTING_MECHANISM.md` | Architecture overview | 5 min |
| `DEBUG_HIGHLIGHTING_CHECKLIST.md` | Copy-paste debugging code | 3-15 min |
| `DEBUG_HIGHLIGHTING_INTEGRATION.md` | Integration instructions | 2 min |

---

## 🎓 Learning Path

**Quick Learner** (10 min):
1. Read `ANSWER_HIGHLIGHTING_QUESTION.md`
2. Skim `HIGHLIGHTING_VISUAL_GUIDE.md`
3. Done! ✅

**Thorough Learner** (20 min):
1. Read `ANSWER_HIGHLIGHTING_QUESTION.md`
2. Study `HIGHLIGHTING_FLOW_EXPLAINED.md`
3. Review `HIGHLIGHTING_VISUAL_GUIDE.md`
4. Check `HIGHLIGHTING_MECHANISM.md`

**Debugger** (30 min):
1. Do thorough learner path above
2. Follow `DEBUG_HIGHLIGHTING_CHECKLIST.md`
3. Add prints and test
4. Review `DEBUG_HIGHLIGHTING_INTEGRATION.md`

---

## ✅ Checklist

Use this to track your understanding:

- [ ] I understand audio is matched to verses, not words
- [ ] I know the verse-level matching uses waveform comparison
- [ ] I understand how words are looked up from the matched verse
- [ ] I know how the UI is updated via provider changes
- [ ] I can explain the flow to someone else
- [ ] I can locate the key code sections
- [ ] I know how to add debug output
- [ ] I can identify where highlighting breaks if it's not working

---

**Last Updated**: November 11, 2025
**System**: Flutter Quran Tajweed App
**Component**: Text Highlighting & Audio Matching
