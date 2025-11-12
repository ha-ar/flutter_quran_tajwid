# Quick Debugging Checklist

Use this checklist to find where highlighting is breaking.

## 🔴 Highlighting Not Working at All?

### ✅ Step 1: Check Audio Recording
```
Does recording start when you tap the button?
└─ Look for: "🔴 Recording started" message
   
If NOT:
  → Check AudioRecordingService initialization
  → Check microphone permissions
  → Check audio_service package
```

### ✅ Step 2: Check Audio Matching Attempt
Add this log to `recitation_screen.dart` line 407:

```dart
Future<void> _matchAudioSegment(Uint8List segment, int surahNumber) async {
  print('🔍 ATTEMPT MATCH: segment=${segment.length} bytes, surah=$surahNumber');
  final audioMatching = ref.read(audioMatchingServiceProvider);
  if (!audioMatching.shouldMatch(minIntervalMs: 300)) {
    print('  ⏳ Throttled (too soon)');
    return;
  }
  
  final matches = await audioMatching.matchWithVerses(
    segment,
    surahNumber,
    minScore: 0.75,
    maxMatches: 2,
    maxVerseToCheck: 10,
    windowRadius: 5,
  );
  
  print('📊 MATCHES: ${matches.length} verses above 0.75');
  for (final m in matches) {
    print('   Verse ${m.verseNumber}: ${(m.score * 100).toStringAsFixed(1)}%');
  }
  // ... rest of code ...
}
```

**Expected output**: Should see "Verse X: YY%"

**If NO output**:
  - Waveform comparison might be broken
  - Check `AudioAnalysisService.compareAudioWaveforms()`
  - Score might be too low (lower threshold to test)

### ✅ Step 3: Check Verse Word Lookup
Add this log to `recitation_screen.dart` line 454:

```dart
void _highlightVerseWords(int verseNumber) {
  final highlightedWords = ref.read(highlightedWordsProvider);
  final quranService = ref.read(quranJsonServiceProvider);
  final surahNumber = ref.read(currentSurahNumberProvider);
  
  final surah = quranService.getSurah(surahNumber);
  print('🔍 HIGHLIGHTING Verse $verseNumber in Surah $surahNumber');
  
  if (surah == null) {
    print('  ❌ Surah is null!');
    return;
  }
  
  final allWords = quranService.getSurahWords(surahNumber);
  print('  ✓ Total words in surah: ${allWords.length}');
  
  final verseWords = allWords.where((w) => w.verseNumber == verseNumber).toList();
  print('  ✓ Words in verse $verseNumber: ${verseWords.length}');
  
  if (verseWords.isEmpty) {
    print('  ❌ NO WORDS FOUND for verse $verseNumber!');
    return;
  }
  
  print('  Reference words:');
  for (int i = 0; i < verseWords.length && i < 5; i++) {
    print('    ${i+1}. "${verseWords[i].simpleText}"');
  }
  // ... rest of code ...
}
```

**Expected output**: Should list 5+ words

**If "NO WORDS FOUND"**:
  - Verse data not loaded correctly
  - Check QuranJsonService
  - Verify verse numbers in JSON

### ✅ Step 4: Check Word Matching
Continue in `_highlightVerseWords()` after the print above:

```dart
  final updatedWords = List<HighlightedWord>.from(highlightedWords);
  int currentWordIndex = 0;
  int lastHighlightedIndex = -1;
  
  print('  Searching in ${updatedWords.length} highlighted words...');
  
  for (int i = 0; i < updatedWords.length && currentWordIndex < verseWords.length; i++) {
    final highlighted = updatedWords[i];
    final reference = verseWords[currentWordIndex];
    
    bool isMatch = highlighted.simpleText.isNotEmpty && 
        reference.simpleText.isNotEmpty &&
        highlighted.simpleText == reference.simpleText;
    
    if (i < 50) {  // Only print first 50 for readability
      if (isMatch) {
        print('    ✅ Position $i: "${highlighted.simpleText}" MATCHES');
      } else if (i < 10) {
        print('    ❌ Position $i: "${highlighted.simpleText}" vs "${reference.simpleText}"');
      }
    }
    
    if (isMatch) {
      updatedWords[i] = updatedWords[i].copyWith(
        status: WordStatus.recitedCorrect,
        tajweedError: null,
      );
      lastHighlightedIndex = i;
      currentWordIndex++;
    }
  }
  
  print('  ✅ RESULT: $currentWordIndex words matched and highlighted');
  
  if (lastHighlightedIndex >= 0) {
    ref.read(highlightedWordsProvider.notifier).state = updatedWords;
    ref.read(nextWordIndexProvider.notifier).state = lastHighlightedIndex + 1;
  }
}
```

**Expected output**: Should show matching words and "X words matched"

**If "0 words matched"**:
  - Check if simpleText values match
  - Look at the ❌ lines to see the mismatch
  - Might need to normalize text (remove extra characters)

### ✅ Step 5: Verify Provider Update
After fixing above, check if UI rebuilds:

```dart
// Add this to watch the provider
ref.watch(highlightedWordsProvider).length;  // Trigger rebuild
```

**If UI still doesn't show green**:
  - Check `SurahDisplay` widget receives updated list
  - Check `_buildWordWidget()` applies correct colors

---

## 🎯 Most Common Issues & Fixes

### Issue: "Matches always 0"
**Cause**: Audio waveform comparison too strict
**Fix**: Lower `minScore` threshold in `_matchAudioSegment()`:
```dart
final matches = await audioMatching.matchWithVerses(
  segment,
  surahNumber,
  minScore: 0.5,  // ← Lower from 0.75 to 0.5
  maxMatches: 2,
  maxVerseToCheck: 10,
  windowRadius: 5,
);
```

### Issue: "Matches found but highlighting doesn't work"
**Cause**: Word matching fails
**Fix**: Check `simpleText` generation:
```dart
// Print what we have vs what we expect
print('Memory word: "${updatedWords[i].text}" → simple="${updatedWords[i].simpleText}"');
print('Reference:   "${verseWords[j].text}" → simple="${verseWords[j].simpleText}"');
```

### Issue: "All matches at score 0.0 or 1.0"
**Cause**: Comparison function might be broken
**Fix**: Check `AudioAnalysisService.compareAudioWaveforms()` is normalizing correctly

### Issue: "Words matched but still gray"
**Cause**: UI not watching provider or wrong status enum
**Fix**: Check:
```dart
// In surah_display.dart line 140
switch (word.status) {
  case WordStatus.recitedCorrect:  // ← Make sure this case exists
    backgroundColor = const Color(0xFFD1F4E8);
    // ...
}
```

---

## 📋 Copy-Paste Debug Version

Add these debug prints to `recitation_screen.dart` for full debugging:

**File: `lib/screens/recitation_screen.dart`**

**Replace `_matchAudioSegment()` method (line 407):**

```dart
Future<void> _matchAudioSegment(Uint8List segment, int surahNumber) async {
  final audioMatching = ref.read(audioMatchingServiceProvider);
  
  if (!audioMatching.shouldMatch(minIntervalMs: 300)) {
    return;
  }
  
  try {
    print('\n🔍 AUDIO MATCHING DEBUG');
    print('Segment: ${segment.length} bytes');
    print('Surah: $surahNumber');
    
    final matches = await audioMatching.matchWithVerses(
      segment,
      surahNumber,
      minScore: 0.75,
      maxMatches: 2,
      maxVerseToCheck: 10,
      windowRadius: 5,
    );
    
    print('Matches found: ${matches.length}');
    if (matches.isNotEmpty) {
      for (final m in matches) {
        print('  Verse ${m.verseNumber}: ${(m.score * 100).toStringAsFixed(1)}%');
      }
    }
    
    if (matches.isNotEmpty) {
      final bestMatch = matches.first;
      print('✅ Best match: Verse ${bestMatch.verseNumber}');
      
      ref.read(statusMessageProvider.notifier).state =
          'الآية ${bestMatch.verseNumber}: ${(bestMatch.score * 100).toStringAsFixed(0)}%';
      
      _highlightVerseWords(bestMatch.verseNumber);
    } else {
      print('❌ No matches above 0.75');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
```

**Replace `_highlightVerseWords()` method (line 454):**

```dart
void _highlightVerseWords(int verseNumber) {
  final highlightedWords = ref.read(highlightedWordsProvider);
  final quranService = ref.read(quranJsonServiceProvider);
  final surahNumber = ref.read(currentSurahNumberProvider);
  
  print('\n📝 HIGHLIGHTING DEBUG');
  print('Verse: $verseNumber in Surah: $surahNumber');
  
  final surah = quranService.getSurah(surahNumber);
  if (surah == null) {
    print('❌ Surah null!');
    return;
  }
  
  final allWords = quranService.getSurahWords(surahNumber);
  print('Total words: ${allWords.length}');
  
  final verseWords = allWords.where((w) => w.verseNumber == verseNumber).toList();
  print('Verse ${verseNumber} words: ${verseWords.length}');
  
  if (verseWords.isEmpty) {
    print('❌ NO WORDS!');
    return;
  }
  
  print('Reference verse words:');
  for (int i = 0; i < verseWords.length; i++) {
    print('  $i: "${verseWords[i].simpleText}"');
  }
  
  final updatedWords = List<HighlightedWord>.from(highlightedWords);
  int currentWordIndex = 0;
  int lastHighlightedIndex = -1;
  int matchCount = 0;
  
  for (int i = 0; i < updatedWords.length && currentWordIndex < verseWords.length; i++) {
    if (updatedWords[i].simpleText.isNotEmpty && 
        verseWords[currentWordIndex].simpleText.isNotEmpty &&
        updatedWords[i].simpleText == verseWords[currentWordIndex].simpleText) {
      
      updatedWords[i] = updatedWords[i].copyWith(
        status: WordStatus.recitedCorrect,
        tajweedError: null,
      );
      lastHighlightedIndex = i;
      currentWordIndex++;
      matchCount++;
      print('✅ Match $matchCount at index $i: "${updatedWords[i].simpleText}"');
    }
  }
  
  print('Total matched: $matchCount / ${verseWords.length}');
  
  if (lastHighlightedIndex >= 0) {
    ref.read(highlightedWordsProvider.notifier).state = updatedWords;
    ref.read(nextWordIndexProvider.notifier).state = lastHighlightedIndex + 1;
    print('✅ Provider updated');
  } else {
    print('⚠️  NO WORDS HIGHLIGHTED');
  }
}
```

Now run the app and check the logs in your IDE!

---

## 🚀 Quick Test

1. **Open your Flutter IDE console**
2. **Select a Surah**
3. **Tap Record**
4. **Recite a few words**
5. **Stop and watch console output**

You should see:
```
🔍 AUDIO MATCHING DEBUG
Segment: 16000 bytes
Surah: 1
Matches found: 1
  Verse 1: 85%
✅ Best match: Verse 1

📝 HIGHLIGHTING DEBUG
Verse: 1 in Surah: 1
Total words: 8234
Verse 1 words: 4
Reference verse words:
  0: "بسم"
  1: "الله"
  2: "الرحمن"
  3: "الرحيم"
✅ Match 1 at index 0: "بسم"
✅ Match 2 at index 1: "الله"
✅ Match 3 at index 2: "الرحمن"
✅ Match 4 at index 3: "الرحيم"
Total matched: 4 / 4
✅ Provider updated
```

If you don't see this, use the step-by-step debugging above! 🎯
