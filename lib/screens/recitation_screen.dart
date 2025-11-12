import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import '../models/highlighted_word.dart';
import '../models/recitation_summary.dart';
import '../providers/app_state.dart';
import '../services/audio_recording_service.dart';
import '../widgets/surah_display.dart';
import '../widgets/audio_visualizer.dart';
import '../widgets/recitation_summary_widget.dart';

class RecitationScreen extends ConsumerStatefulWidget {
  const RecitationScreen({super.key});

  @override
  ConsumerState<RecitationScreen> createState() => _RecitationScreenState();
}

class _RecitationScreenState extends ConsumerState<RecitationScreen> {
  late final ScrollController _scrollController;
  late AudioRecordingService _audioRecordingService;
  // visible words for lazy rendering
  List<HighlightedWord> _visibleWords = [];
  final int _initialVisibleWords = 120; // approx 15 lines worth of words

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _initializeAudioRecording();
  }

  Future<void> _initializeAudioRecording() async {
    _audioRecordingService = AudioRecordingService();
    await _audioRecordingService.initialize();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _audioRecordingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surahNumber = ref.watch(currentSurahNumberProvider);
    final surahName = ref.watch(currentSurahNameProvider);
    final isReciting = ref.watch(isRecitingProvider);
    final statusMessage = ref.watch(statusMessageProvider);
    final highlightedWords = ref.watch(highlightedWordsProvider);
    final recitationSummary = ref.watch(recitationSummaryProvider);
    final audioLevel = ref.watch(audioLevelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('معلم التجويد'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: surahNumber == 0
              ? _buildSurahSelector()
              : (recitationSummary != null
                  ? _buildSummaryView(recitationSummary)
                  : _buildRecitationView(context, surahName, highlightedWords, isReciting, statusMessage, audioLevel)),
        ),
      ),
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    // If user scrolls within 200 pixels of bottom, load more
    if (max - current < 200) {
      _loadMoreVisibleWords();
    }
  }

  void _loadMoreVisibleWords() {
    final highlightedWords = ref.read(highlightedWordsProvider);
    if (highlightedWords.isEmpty) return;
    final currentLen = _visibleWords.isEmpty ? 0 : _visibleWords.length;
    final nextLen = (currentLen == 0) ? _initialVisibleWords : (currentLen + 80);
    if (currentLen >= highlightedWords.length) return; // already full
    final to = nextLen.clamp(0, highlightedWords.length);
    setState(() {
      _visibleWords = highlightedWords.sublist(0, to);
    });
  }

  /// Build highlighted words for the entire surah in small async chunks to avoid blocking UI thread
  void _buildHighlightedWordsInChunks(List<dynamic> words) async {
    // words are QuranWord objects; we already set the initial chunk
    final total = words.length;
    const batch = 200; // process 200 words per iteration
    final current = ref.read(highlightedWordsProvider).length;

    var accumulated = List<HighlightedWord>.from(ref.read(highlightedWordsProvider));

    for (var i = current; i < total; i += batch) {
      final to = (i + batch).clamp(0, total);
      final chunk = words.getRange(i, to).map((word) => HighlightedWord(
            text: word.text,
            simpleText: word.simpleText,
            status: WordStatus.unrecited,
          ));
      accumulated.addAll(chunk);

      // Update provider and visible slice in small async steps
      ref.read(highlightedWordsProvider.notifier).state = List<HighlightedWord>.from(accumulated);
      setState(() {
        _visibleWords = accumulated.sublist(0, accumulated.length < _initialVisibleWords ? accumulated.length : accumulated.length);
      });

      // Yield to event loop to keep UI responsive
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  /// Build Surah selector dropdown
  Widget _buildSurahSelector() {
    final surahsAsync = ref.watch(surahNamesProvider);

    return surahsAsync.when(
      data: (surahs) {
        print('Dropdown received ${surahs.length} surahs');
        if (surahs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Select Surah',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'ArabicUI',
                    color: Color(0xFF374151),
                  ),
                  // textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(surahNamesProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Select'),
                ),
              ],
            ),
          );
        }

        return Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'اختر السورة',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'ArabicUI',
                    color: Color(0xFF064E3B),
                  ),
                ),
                const SizedBox(height: 70), // increase top spacing by 40px to avoid action bar overlap
                Padding(
                  padding: const EdgeInsets.only(top: 40.0, left: 16, right: 16), // extra top padding for dropdown menu
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<int>(
                      isExpanded: true,
                    hint: const Text('اختر السورة...'),
                    underline: const SizedBox(),
                    items: surahs
                        .map((surah) => DropdownMenuItem(
                              value: surah['number'] as int,
                              child: Text(
                                '${surah['name']} - Page ${surah['pageNumber']}',
                                style: const TextStyle(
                                  fontFamily: 'ArabicUI',
                                  fontSize: 14,
                                ),
                                  textDirection: TextDirection.rtl,
                                ),
                              ))
                          .toList(),
                      onChanged: (surahNumber) async {
                        if (surahNumber != null) {
                        final quranService = ref.read(quranJsonServiceProvider);
                        final audioMatching = ref.read(audioMatchingServiceProvider);
                        final surah = quranService.getSurah(surahNumber);
                        if (surah != null) {
                                    // Reset match tracking when surah changes
                                    audioMatching.resetMatchTracking();
                                    
                                    // Get all words from surah (including verse markers for display)
                                    final words = quranService.getSurahWords(surahNumber);

                                    // Store surah info immediately so UI can update
                                    ref.read(currentSurahNumberProvider.notifier).state = surahNumber;
                                    ref.read(currentSurahNameProvider.notifier).state = surah.surahName;

                                    // Immediately set a small chunk synchronously to avoid blocking UI
                                    final initialChunk = words.take(_initialVisibleWords).map((word) => HighlightedWord(
                                          text: word.text,
                                          simpleText: word.simpleText,
                                          status: WordStatus.unrecited,
                                        )).toList();

                                    // Set provider briefly to initial chunk and visible words
                                    ref.read(highlightedWordsProvider.notifier).state = List<HighlightedWord>.from(initialChunk);
                                    setState(() {
                                      _visibleWords = List<HighlightedWord>.from(initialChunk);
                                    });

                                    // Build remaining highlighted words in small async chunks to avoid freezing UI
                                    _buildHighlightedWordsInChunks(words);

                                    ref.read(statusMessageProvider.notifier).state = 'جاهز للبدء';
                        }
                      }
                    },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('خطأ في تحميل السور: $error'),
      ),
    );
  }

  /// Build recitation view with Surah display and controls
  Widget _buildRecitationView(
    BuildContext context,
    selectedSurah,
    List<HighlightedWord> highlightedWords,
    bool isReciting,
    String statusMessage,
    double audioLevel,
  ) {
    return Column(
      children: [
        // Status message
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            border: Border.all(color: const Color(0xFF0284C7)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            statusMessage,
            style: const TextStyle(
              color: Color(0xFF0284C7),
              fontFamily: 'ArabicUI',
              fontSize: 12,
            ),
            textDirection: TextDirection.rtl,
          ),
        ),
        const SizedBox(height: 16),
        
        // Audio visualizer
        if (isReciting)
          AudioVisualizer(level: audioLevel)
        else
          const SizedBox(height: 40),
        
        const SizedBox(height: 16),
        
        // Surah display with scrolling
        Expanded(
          child: SurahDisplay(
            surahName: selectedSurah as String,
            highlightedWords: highlightedWords,
            scrollController: _scrollController,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Control buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: isReciting ? () async => await _stopRecitation() : () async => await _startRecitation(),
              icon: Icon(isReciting ? Icons.stop : Icons.mic),
              label: Text(
                isReciting ? 'End Session' : 'Start Recitation',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isReciting ? const Color(0xFFDC2626) : const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _resetRecitation(),
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Reset',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B7280),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build summary view showing results
  Widget _buildSummaryView(recitationSummary) {
    return Column(
      children: [
        Expanded(
          child: RecitationSummaryWidget(summary: recitationSummary),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () => _resetAndSelectNewSurah(),
              icon: const Icon(Icons.home),
              label: const Text(
                'Select Another Surah',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF064E3B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Start recitation
  Future<void> _startRecitation() async {
    ref.read(isRecitingProvider.notifier).state = true;
    ref.read(statusMessageProvider.notifier).state = 'جاري تسجيل الترتيل...';

    try {
      // Get audio matching service
      final audioMatching = ref.read(audioMatchingServiceProvider);
      final surahNumber = ref.read(currentSurahNumberProvider);
      
      audioMatching.clearBuffer(); // Clear buffer at start
      
      // Start audio recording and feed directly to audio matching
      await _audioRecordingService.startRecording(
        onAudioData: (List<int> audioData) {
          // Add audio chunk to matching buffer
          audioMatching.addAudioChunk(audioData);
          
          // Try to extract and match every 500ms of audio
          final bytesFor500ms = (16000 * 0.5 * 2).toInt(); // 16kHz * 0.5s * 2 bytes
          
          if (audioMatching.getBuffer().length >= bytesFor500ms) {
            final segment = audioMatching.extractSegment(500); // 500ms segment
            
            if (segment != null) {
              // Match against reference verses
              _matchAudioSegment(segment, surahNumber);
              
              // Remove processed bytes from buffer (move to next segment)
              audioMatching.removeProcessedBytes((segment.length * 0.8).toInt());
            }
          }
        },
        onError: (String error) {
          ref.read(statusMessageProvider.notifier).state = 'خطأ في التسجيل: $error';
          ref.read(isRecitingProvider.notifier).state = false;
        },
      );
    } catch (e) {
      ref.read(statusMessageProvider.notifier).state = 'خطأ: $e';
      ref.read(isRecitingProvider.notifier).state = false;
    }
  }

  /// Match audio segment against reference verses
  Future<void> _matchAudioSegment(Uint8List segment, int surahNumber) async {
    final audioMatching = ref.read(audioMatchingServiceProvider);
    
    // Throttle: skip if we matched too recently (avoid excessive heavy work)
    if (!audioMatching.shouldMatch(minIntervalMs: 300)) {
      return;
    }
    
    try {
      print('\n🎤 ═══ AUDIO MATCHING START ═══');
      print('Segment size: ${segment.length} bytes');
      print('Surah: $surahNumber');
      
      // Match with reference verses using sliding window + limited verse checks
      final matches = await audioMatching.matchWithVerses(
        segment,
        surahNumber,
        minScore: 0.75, // High confidence threshold
        maxMatches: 2,
        maxVerseToCheck: 10, // reduced from 15; sliding window focuses the search
        windowRadius: 5, // search ±5 verses around last match
      );
      
      print('Matches found: ${matches.length}');
      for (final m in matches) {
        print('  Verse ${m.verseNumber}: ${(m.score * 100).toStringAsFixed(1)}%');
      }
      
      if (matches.isNotEmpty) {
        final bestMatch = matches.first;
        
        // Debug logging
        print('✅ Best Match - Verse ${bestMatch.verseNumber}: ${(bestMatch.score * 100).toStringAsFixed(1)}%');
        
        // Update status
        ref.read(statusMessageProvider.notifier).state =
            'الآية ${bestMatch.verseNumber}: ${(bestMatch.score * 100).toStringAsFixed(0)}%';
        
        print('Calling _highlightVerseWords(${bestMatch.verseNumber})...');
        
        // Highlight the word at this verse
        _highlightVerseWords(bestMatch.verseNumber);
      } else {
        print('❌ No matches found above threshold');
      }
      
      print('═══ AUDIO MATCHING END ═══\n');
    } catch (e) {
      print('❌ Audio matching error: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  /// Highlight all words in a specific verse
  void _highlightVerseWords(int verseNumber) {
    print('\n🔍 ═══ HIGHLIGHTING DEBUG START ═══');
    print('Target Verse: $verseNumber');
    
    final highlightedWords = ref.read(highlightedWordsProvider);
    final quranService = ref.read(quranJsonServiceProvider);
    final surahNumber = ref.read(currentSurahNumberProvider);
    
    print('Current Surah: $surahNumber');
    print('Total highlighted words in memory: ${highlightedWords.length}');
    
    // Get all words from the verse
    final surah = quranService.getSurah(surahNumber);
    if (surah == null) {
      print('❌ ERROR: Surah $surahNumber not found!');
      return;
    }
    
    final allWords = quranService.getSurahWords(surahNumber);
    print('Total words in surah: ${allWords.length}');
    
    final verseWords = allWords.where((w) => w.verseNumber == verseNumber).toList();
    print('Words in verse $verseNumber: ${verseWords.length}');
    
    if (verseWords.isEmpty) {
      print('❌ ERROR: No words found for verse $verseNumber!');
      return;
    }
    
    print('\n📖 Reference verse words:');
    for (int i = 0; i < verseWords.length; i++) {
      print('  [$i] text="${verseWords[i].text}" simple="${verseWords[i].simpleText}"');
    }
    
    // Build updated words list with all verse words highlighted at once
    final updatedWords = List<HighlightedWord>.from(highlightedWords);
    int currentWordIndex = 0;
    int lastHighlightedIndex = -1;
    int matchCount = 0;
    
    print('\n🔍 Starting word matching...');
    print('Searching through ${updatedWords.length} words in memory');
    
    for (int i = 0; i < updatedWords.length && currentWordIndex < verseWords.length; i++) {
      final memoryWord = updatedWords[i];
      final refWord = verseWords[currentWordIndex];
      
      // Compare simple text (without diacritics/markers)
      bool isMatch = memoryWord.simpleText.isNotEmpty && 
          refWord.simpleText.isNotEmpty &&
          memoryWord.simpleText == refWord.simpleText;
      
      // Debug first 10 comparisons or all matches
      if (i < 10 || isMatch) {
        if (isMatch) {
          print('  ✅ MATCH at index $i: "${memoryWord.simpleText}" == "${refWord.simpleText}"');
        } else {
          print('  ❌ NO MATCH at index $i: "${memoryWord.simpleText}" vs "${refWord.simpleText}"');
        }
      }
      
      if (isMatch) {
        // Mark this word as recited correctly
        updatedWords[i] = updatedWords[i].copyWith(
          status: WordStatus.recitedCorrect,
          tajweedError: null,
        );
        lastHighlightedIndex = i;
        currentWordIndex++;
        matchCount++;
      }
    }
    
    print('\n📊 Matching Results:');
    print('  Words matched: $matchCount / ${verseWords.length}');
    print('  Last highlighted index: $lastHighlightedIndex');
    
    // Update provider once with all changes
    if (lastHighlightedIndex >= 0) {
      print('✅ Updating highlightedWordsProvider with $matchCount new highlights');
      ref.read(highlightedWordsProvider.notifier).state = updatedWords;
      ref.read(nextWordIndexProvider.notifier).state = lastHighlightedIndex + 1;
      
      // Verify update
      final updatedState = ref.read(highlightedWordsProvider);
      final greenCount = updatedState.where((w) => w.status == WordStatus.recitedCorrect).length;
      print('✅ Provider updated! Total green words now: $greenCount');
    } else {
      print('⚠️  WARNING: No words were highlighted! lastHighlightedIndex = $lastHighlightedIndex');
    }
    
    print('═══ HIGHLIGHTING DEBUG END ═══\n');
  }

  /// Stop recitation
  Future<void> _stopRecitation() async {
    ref.read(isRecitingProvider.notifier).state = false;
    ref.read(statusMessageProvider.notifier).state = 'تم إيقاف الترتيل';
    
    // Stop audio recording
    await _audioRecordingService.stopRecording();
    
    // Clear audio buffer and reset match tracking
    final audioMatching = ref.read(audioMatchingServiceProvider);
    audioMatching.clearBuffer();
    audioMatching.resetMatchTracking();
    
    // Calculate summary
    final highlightedWords = ref.read(highlightedWordsProvider);
    final surahName = ref.read(currentSurahNameProvider);
    
    if (surahName.isNotEmpty) {
      final correctCount = highlightedWords
          .where((w) => w.status == WordStatus.recitedCorrect)
          .length;
      final errorCount = highlightedWords
          .where((w) => w.status == WordStatus.recitedTajweedError)
          .length;
      
      final tajweedErrors = highlightedWords
          .where((w) => w.tajweedError != null)
          .map((w) => TajweedError(word: w.text, error: w.tajweedError!))
          .toList();
      
      final summary = RecitationSummary(
        surahName: surahName,
        totalWords: highlightedWords.length,
        correctWords: correctCount,
        errorWords: errorCount,
        tajweedErrors: tajweedErrors,
      );
      
      ref.read(recitationSummaryProvider.notifier).state = summary;
    }
  }

  /// Reset recitation
  void _resetRecitation() {
    final highlightedWords = ref.read(highlightedWordsProvider);
    // Reset all highlighted words to unrecited
    final reset = highlightedWords
        .map((word) => word.copyWith(status: WordStatus.unrecited))
        .toList();
    ref.read(highlightedWordsProvider.notifier).state = reset;
    ref.read(nextWordIndexProvider.notifier).state = 0;
    ref.read(recitedTextProvider.notifier).state = '';
    ref.read(transcribedWordsQueueProvider.notifier).state = [];
    ref.read(isRecitingProvider.notifier).state = false;
    ref.read(statusMessageProvider.notifier).state = 'جاهز للبدء';
  }

  /// Reset and go back to Surah selection
  void _resetAndSelectNewSurah() {
    ref.read(currentSurahNumberProvider.notifier).state = 0;
    ref.read(currentSurahNameProvider.notifier).state = '';
    ref.read(highlightedWordsProvider.notifier).state = [];
    ref.read(recitationSummaryProvider.notifier).state = null;
    ref.read(nextWordIndexProvider.notifier).state = 0;
    ref.read(recitedTextProvider.notifier).state = '';
    ref.read(transcribedWordsQueueProvider.notifier).state = [];
    ref.read(isRecitingProvider.notifier).state = false;
    ref.read(statusMessageProvider.notifier).state = 'اختر سورة للبدء';
  }
}
