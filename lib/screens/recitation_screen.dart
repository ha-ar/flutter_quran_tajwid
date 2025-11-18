import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/highlighted_word.dart';
import '../providers/app_state.dart';
import '../services/audio_recording_service.dart';
import '../services/feedback_speech_service.dart';
import '../services/gemini_live_service.dart';
import '../services/quran_json_service.dart';
import '../utils/arabic_utils.dart';

class RecitationScreen extends ConsumerStatefulWidget {
  const RecitationScreen({super.key});

  @override
  ConsumerState<RecitationScreen> createState() => _RecitationScreenState();
}

class _RecitationScreenState extends ConsumerState<RecitationScreen> {
  static const int _surahNumber = 1;
  static const Duration _matchThrottle =
      Duration(milliseconds: 500); // Increased from 100ms
  static const int _segmentDurationMs =
      500; // Reduced from 2000ms for faster processing

  late final AudioRecordingService _audioRecordingService;
  final FeedbackSpeechService _feedbackSpeechService = FeedbackSpeechService();
  GeminiLiveService? _geminiService;
  StreamSubscription<GeminiTranscriptionMessage>? _transcriptionSubscription;
  StreamSubscription<String>? _geminiErrorSubscription;

  bool _isLoadingSurah = true;
  // Audio matching temporarily disabled; retained for future reactivation.
  // bool _isMatchingAudio = false;
  // DateTime _lastMatchAttempt = DateTime.fromMillisecondsSinceEpoch(0);
  int? _activeVerse;
  int _nextVerseToDetect = 1;
  int _maxVerseNumber = 7;
  bool _verseDetectionEnabled =
      true; // Controls sequential verse inference enablement
  // bool _awaitingTranscription = false; // Reserved for streaming state tracking.

  void _provideAudibleFeedback(WordStatus status) {
    switch (status) {
      case WordStatus.recitedCorrect:
        _feedbackSpeechService.speakStatus('correct');
        break;
      case WordStatus.recitedNearMiss:
        _feedbackSpeechService.speakStatus('near');
        break;
      case WordStatus.recitedTajweedError:
        _feedbackSpeechService.speakStatus('error');
        break;
      case WordStatus.unrecited:
        // Skip live unrecited feedback to prevent noise.
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _audioRecordingService = AudioRecordingService();
    _feedbackSpeechService.init();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _audioRecordingService.initialize();
    await _loadSurah();
  }

  Future<void> _loadSurah() async {
    final quranService = ref.read(quranJsonServiceProvider);
    final surah = quranService.getSurah(_surahNumber);
    final surahName = surah?.surahName ?? 'Al-Fatiha';
    final words = quranService.getSurahWords(_surahNumber);

    if (words.isNotEmpty) {
      var maxVerse = 0;
      for (final word in words) {
        if (word.verseNumber > maxVerse) {
          maxVerse = word.verseNumber;
        }
      }
      _maxVerseNumber = maxVerse;
    } else {
      _maxVerseNumber = 7;
    }

    _nextVerseToDetect = 1;
    _verseDetectionEnabled = true;
    _activeVerse = null;

    final highlighted = <HighlightedWord>[];
    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      final isMarker = _isVerseMarkerWord(word);
      highlighted.add(
        HighlightedWord(
          text: word.text,
          simpleText: word.simpleText,
          status: WordStatus.unrecited,
          tajweedError: null,
          verseNumber: word.verseNumber,
          wordIndex: i,
          isVerseMarker: isMarker,
        ),
      );
    }

    ref.read(highlightedWordsProvider.notifier).state = highlighted;
    ref.read(currentSurahNumberProvider.notifier).state = _surahNumber;
    ref.read(currentSurahNameProvider.notifier).state = surahName;
    ref.read(statusMessageProvider.notifier).state =
        'Ready to recite Surah Al-Fatiha';

    if (mounted) {
      setState(() {
        _isLoadingSurah = false;
      });
    }
  }

  bool _isVerseMarkerWord(QuranWord word) {
    final clean = word.simpleText.trim();
    final display = word.text.trim();

    if (clean.isEmpty && display.isEmpty) {
      return true;
    }

    if (RegExp(r'^[\d٠-٩]+$').hasMatch(clean)) {
      return true;
    }

    if (RegExp(r'^[۟۞۝۩﴾﴿\s]+$').hasMatch(display)) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final highlightedWords = ref.watch(highlightedWordsProvider);
    final statusMessage = ref.watch(statusMessageProvider);
    final isReciting = ref.watch(isRecitingProvider);
    final surahName = ref.watch(currentSurahNameProvider);

    if (_isLoadingSurah) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final verseGroups = _groupWordsByVerse(highlightedWords);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recitation Test'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                surahName.isEmpty ? 'Surah Al-Fatiha' : surahName,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              _buildStatusBanner(statusMessage),
              const SizedBox(height: 16),
              Expanded(
                child: verseGroups.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        children: verseGroups.entries
                            .map(
                              (entry) => _buildVerseTile(
                                entry.key,
                                entry.value,
                              ),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: 16),
              _buildControls(isReciting),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF38BDF8)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'ArabicUI',
          fontSize: 14,
          color: Color(0xFF0369A1),
        ),
        textDirection: TextDirection.ltr,
      ),
    );
  }

  Widget _buildControls(bool isReciting) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed:
                isReciting ? () => _stopRecitation() : () => _startRecitation(),
            icon: Icon(isReciting ? Icons.stop : Icons.play_arrow),
            label: Text(isReciting ? 'Stop Recitation' : 'Start Recitation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isReciting
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _resetAll,
            icon: const Icon(Icons.refresh),
            label: const Text('Reset'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF111827),
              side: const BorderSide(color: Color(0xFF6B7280)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Map<int, List<HighlightedWord>> _groupWordsByVerse(
    List<HighlightedWord> words,
  ) {
    final grouped = <int, List<HighlightedWord>>{};
    for (final word in words) {
      if (word.isVerseMarker) {
        continue;
      }
      grouped.putIfAbsent(word.verseNumber, () => []).add(word);
    }

    final sortedKeys = grouped.keys.toList()..sort();
    final sortedMap = <int, List<HighlightedWord>>{};
    for (final key in sortedKeys) {
      sortedMap[key] = grouped[key]!;
    }
    return sortedMap;
  }

  Widget _buildVerseTile(int verseNumber, List<HighlightedWord> words) {
    final isActive = _activeVerse == verseNumber;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? const Color(0xFF0284C7) : const Color(0xFFE5E7EB),
          width: isActive ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVerseNumberChip(verseNumber, isActive),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.start,
                children: words.map(_buildWordChip).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerseNumberChip(int verseNumber, bool isActive) {
    final color = isActive ? const Color(0xFF0284C7) : const Color(0xFF0F172A);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? const Color(0xFFE0F2FE) : const Color(0xFFF3F4F6),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        verseNumber.toString(),
        style: TextStyle(
          fontFamily: 'ArabicUI',
          fontWeight: FontWeight.bold,
          color: color,
          fontSize: 16,
        ),
        textDirection: TextDirection.rtl,
      ),
    );
  }

  Widget _buildWordChip(HighlightedWord word) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;

    switch (word.status) {
      case WordStatus.recitedCorrect:
        backgroundColor = const Color(0xFFD1F4E8);
        borderColor = const Color(0xFF10B981);
        textColor = const Color(0xFF047857);
        break;
      case WordStatus.recitedNearMiss:
        backgroundColor = const Color(0xFFFFF7D6); // soft yellow background
        borderColor = const Color(0xFFF59E0B); // amber border
        textColor = const Color(0xFF92400E); // dark amber text
        break;
      case WordStatus.recitedTajweedError:
        backgroundColor = const Color(0xFFFEE2E2);
        borderColor = const Color(0xFFDC2626);
        textColor = const Color(0xFF991B1B);
        break;
      case WordStatus.unrecited:
        // Restore neutral grey for not-yet-recited words
        backgroundColor = const Color(0xFFF3F4F6);
        borderColor = const Color(0xFFE5E7EB);
        textColor = const Color(0xFF1F2937);
        break;
    }

    final wordContainer = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Text(
        word.text,
        style: TextStyle(
          fontFamily: 'Quranic',
          fontSize: 18,
          color: textColor,
        ),
        textDirection: TextDirection.rtl,
      ),
    );

    // Add tooltip for words with tajweed errors or near-miss suggestions
    if ((word.status == WordStatus.recitedTajweedError ||
            word.status == WordStatus.recitedNearMiss) &&
        word.tajweedError != null &&
        word.tajweedError!.isNotEmpty) {
      // Wrap with InkWell to allow tap + long press + hover (desktop/web) interactions
      return InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          // Show a snack bar fallback if Tooltip doesn't appear (e.g., some platforms)
          final ctx = context;
          ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(
                word.tajweedError!,
                style: const TextStyle(fontFamily: 'ArabicUI'),
              ),
              backgroundColor: word.status == WordStatus.recitedNearMiss
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF991B1B),
              duration: const Duration(seconds: 3),
            ),
          );
          // Play audio feedback only when user requests info
          if (word.status == WordStatus.recitedNearMiss) {
            _feedbackSpeechService.speakStatus('near');
          } else if (word.status == WordStatus.recitedTajweedError) {
            _feedbackSpeechService.speakStatus('error');
          }
        },
        child: Tooltip(
          message: word.status == WordStatus.recitedNearMiss
              ? 'Near miss: ${word.tajweedError!}'
              : 'Tajweed error: ${word.tajweedError!}',
          triggerMode: TooltipTriggerMode.tap, // Ensures simple tap works
          showDuration: const Duration(seconds: 4),
          waitDuration: const Duration(milliseconds: 150),
          textStyle: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontFamily: 'ArabicUI',
          ),
          decoration: BoxDecoration(
            color: word.status == WordStatus.recitedNearMiss
                ? const Color(0xFFF59E0B)
                : const Color(0xFF991B1B),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          preferBelow: false,
          verticalOffset: 12,
          child: wordContainer,
        ),
      );
    }

    return wordContainer;
  }

  Future<void> _startRecitation() async {
    if (_audioRecordingService.isRecording) {
      return;
    }

    final connected = await _ensureGeminiConnected();
    if (!connected) {
      return;
    }

    final audioMatching = ref.read(audioMatchingServiceProvider);
    audioMatching.clearBuffer();
    audioMatching.resetMatchTracking();

    _activeVerse = null;
    _nextVerseToDetect = 1;
    _verseDetectionEnabled = true;

    ref.read(isRecitingProvider.notifier).state = true;
    ref.read(statusMessageProvider.notifier).state = 'Listening...';

    await _audioRecordingService.startRecording(
      onAudioData: _handleAudioChunk,
      onError: (error) {
        ref.read(statusMessageProvider.notifier).state = error;
        ref.read(isRecitingProvider.notifier).state = false;
      },
    );
  }

  Future<bool> _ensureGeminiConnected() async {
    final service = ref.read(geminiLiveServiceProvider);
    if (service == null) {
      ref.read(statusMessageProvider.notifier).state =
          'Please configure Gemini API key.';
      return false;
    }

    _geminiService = service;

    if (_geminiService!.isConnected) {
      return true;
    }

    try {
      await _geminiService!.connect();
      _transcriptionSubscription?.cancel();
      _transcriptionSubscription =
          _geminiService!.transcriptionStream.listen(_handleTranscription);
      _geminiErrorSubscription?.cancel();
      _geminiErrorSubscription = _geminiService!.errorStream.listen((error) {
        ref.read(statusMessageProvider.notifier).state = 'Gemini: $error';
      });
      return true;
    } catch (e) {
      ref.read(statusMessageProvider.notifier).state =
          'Failed to connect to Gemini: $e';
      return false;
    }
  }

  void _handleAudioChunk(List<int> chunk) {
    // SKIP AUDIO PROCESSING FOR NOW - only send to Gemini for transcription

    final audioMatching = ref.read(audioMatchingServiceProvider);
    audioMatching.addAudioChunk(chunk);

    // Extract segment just to prevent buffer growth
    final segment = audioMatching.extractSegment(_segmentDurationMs);
    if (segment == null) {
      return; // Not enough data yet
    }

    // Process segment asynchronously
    Future(() async {
      try {
        // Send to Gemini for transcription only (skip audio matching)
        if (_geminiService?.isConnected ?? false) {
          await _sendSegmentToGemini(segment);
        }

        // SKIP AUDIO MATCHING - commented out for now
        // if (!shouldThrottleMatching && !_awaitingTranscription) {
        //   _lastMatchAttempt = now;
        //   _isMatchingAudio = true;
        //   await _matchAudioSegment(segment);
        //   _isMatchingAudio = false;
        // }
      } finally {
        // Always remove processed bytes to prevent buffer growth
        audioMatching.removeProcessedBytes(segment.length);
      }
    });
  }

  // _matchAudioSegment retained for historical context; removed to clear lint.

  Future<void> _sendSegmentToGemini(Uint8List segment) async {
    final service = _geminiService;
    if (service == null || !service.isConnected) {
      return;
    }

    await service.sendAudioChunk(segment);
  }

  void _handleTranscription(GeminiTranscriptionMessage message) {
    if (!message.isFinal) {
      return;
    }

    final text = message.text.trim();
    if (text.isEmpty) {
      return;
    }

    // SKIP AUDIO MATCHING: Always infer verse from transcription
    int? verseNumber = _inferVerseFromTranscription(text);

    if (verseNumber == null) {
      // Could not determine verse - might be starting or noise
      ref.read(statusMessageProvider.notifier).state =
          'Listening... (transcribed: $text)';
      return;
    }

    // Set active verse if detected
    if (_activeVerse != verseNumber) {
      if (mounted) {
        setState(() {
          _activeVerse = verseNumber;
        });
      }
      ref.read(statusMessageProvider.notifier).state =
          'Verse $verseNumber: detected from transcription. Processing...';
    }

    _applyTranscriptionToVerse(verseNumber, text);
  }

  int? _inferVerseFromTranscription(String transcription) {
    final tokens = transcription
        .split(RegExp(r'\s+'))
        .map(normalizeArabic)
        .where((token) => token.isNotEmpty)
        .toList();

    if (tokens.isEmpty) {
      return null;
    }

    debugPrint('Inferring verse from tokens: $tokens');

    final allWords = ref.read(highlightedWordsProvider);
    final verseCandidates = <int, int>{}; // verse number -> match count

    // Count how many tokens match words in each verse (only unrecited words)
    for (final word in allWords) {
      if (word.isVerseMarker || word.status == WordStatus.recitedCorrect) {
        continue;
      }

      final normalized = normalizeArabic(word.simpleText);
      if (normalized.isEmpty) {
        continue;
      }

      // Check for exact match OR fuzzy match (substring)
      for (final token in tokens) {
        if (token.length >= 2 && normalized.length >= 2) {
          if (token == normalized ||
              token.contains(normalized) ||
              normalized.contains(token)) {
            verseCandidates[word.verseNumber] =
                (verseCandidates[word.verseNumber] ?? 0) + 1;
            break; // Count each word once per verse
          }
        }
      }
    }

    if (verseCandidates.isEmpty) {
      debugPrint('No verse candidates found');
      return null;
    }

    debugPrint('Verse candidates: $verseCandidates');

    // Prefer the next expected verse if it has good matches
    if (verseCandidates.containsKey(_nextVerseToDetect)) {
      final expectedVerseMatches = verseCandidates[_nextVerseToDetect]!;
      // If expected verse has at least 1 match, use it
      if (expectedVerseMatches > 0) {
        debugPrint(
            'Using expected verse $_nextVerseToDetect with $expectedVerseMatches matches');
        return _nextVerseToDetect;
      }
    }

    // Otherwise, return the verse with the most matches
    var bestVerse = verseCandidates.keys.first;
    var bestCount = verseCandidates[bestVerse]!;

    for (final entry in verseCandidates.entries) {
      if (entry.value > bestCount) {
        bestVerse = entry.key;
        bestCount = entry.value;
      }
    }

    debugPrint('Best verse: $bestVerse with $bestCount matches');
    return bestVerse;
  }

  void _applyTranscriptionToVerse(int verseNumber, String transcription) {
    final tokens = transcription
        .split(RegExp(r'\s+'))
        .map(normalizeArabic)
        .where((token) => token.isNotEmpty)
        .toList();

    if (tokens.isEmpty) {
      return;
    }

    final allWords = List<HighlightedWord>.from(
      ref.read(highlightedWordsProvider),
    );
    final verseIndices = <int>[];

    for (var i = 0; i < allWords.length; i++) {
      final word = allWords[i];
      if (word.verseNumber == verseNumber && !word.isVerseMarker) {
        verseIndices.add(i);
      }
    }

    if (verseIndices.isEmpty) {
      return;
    }

    final tokenCounts = <String, int>{};
    for (final token in tokens) {
      tokenCounts[token] = (tokenCounts[token] ?? 0) + 1;
    }

    debugPrint('Transcription tokens: $tokens');
    debugPrint('Processing ${verseIndices.length} words in verse $verseNumber');

    // More lenient matching - check for exact match OR substring match
    for (final index in verseIndices) {
      final expected = normalizeArabic(allWords[index].simpleText);
      if (expected.isEmpty) {
        continue;
      }

      if (allWords[index].status == WordStatus.recitedCorrect) {
        continue;
      }

      // Try exact match first
      final available = tokenCounts[expected] ?? 0;
      if (available > 0) {
        // Word found in transcription - mark as correct
        tokenCounts[expected] = available - 1;
        allWords[index] = allWords[index].copyWith(
          status: WordStatus.recitedCorrect,
          tajweedError: null,
        );
        debugPrint(
            '✓ Exact match: "${allWords[index].text}" (normalized: "$expected")');
        // Removed automatic audio for correct words (too chatty)
        continue;
      }

      // STRICTER FUZZY MATCHING: Three tiers (correct / near-miss / error)
      bool foundFuzzy = false;
      for (final token in tokens.toList()) {
        if (expected.length >= 2 && token.length >= 2) {
          final similarity = arabicSimilarity(expected, token);
          if (similarity >= kMinRecitationSimilarity) {
            // Accept as correct only if similarity passes threshold
            final tokenIdx = tokens.indexOf(token);
            if (tokenIdx >= 0) tokens.removeAt(tokenIdx);
            allWords[index] = allWords[index].copyWith(
              status: WordStatus.recitedCorrect,
              tajweedError: null,
            );
            debugPrint(
                '✓ Fuzzy match (accepted, sim=${similarity.toStringAsFixed(2)}): "${allWords[index].text}" ≈ "$token"');
            // Removed automatic audio for correct fuzzy matches
            foundFuzzy = true;
            break;
          } else if (similarity >= 0.60) {
            // Near miss: show yellow and allow improvement (not counted as error in verse completion)
            final tokenIdx = tokens.indexOf(token);
            if (tokenIdx >= 0) tokens.removeAt(tokenIdx);
            allWords[index] = allWords[index].copyWith(
              status: WordStatus.recitedNearMiss,
              tajweedError:
                  'Approximate pronunciation (similarity ${similarity.toStringAsFixed(2)}) - target ≥ ${kMinRecitationSimilarity.toStringAsFixed(2)}',
            );
            debugPrint(
                '⚠ Near fuzzy (near-miss, sim=${similarity.toStringAsFixed(2)}): "${allWords[index].text}" vs "$token"');
            // Audio will play when user taps tooltip, not automatically here
            foundFuzzy = true;
            break;
          }
        }
      }

      if (!foundFuzzy) {
        debugPrint(
            '✗ Word not found: "${allWords[index].text}" (normalized: "$expected")');
      }
    }

    ref.read(highlightedWordsProvider.notifier).state = allWords;

    final hasUnrecited = verseIndices.any(
      (index) => allWords[index].status == WordStatus.unrecited,
    );
    final errorCount = verseIndices
        .where(
            (index) => allWords[index].status == WordStatus.recitedTajweedError)
        .length;

    var message = hasUnrecited
        ? 'Verse $verseNumber: waiting for remaining words'
        : errorCount > 0
            ? 'Verse $verseNumber: $errorCount words not recognized'
            : 'Verse $verseNumber: completed successfully';

    if (!hasUnrecited) {
      // Verse complete - now mark any remaining unrecited words as errors
      for (final index in verseIndices) {
        if (allWords[index].status == WordStatus.unrecited) {
          allWords[index] = allWords[index].copyWith(
            status: WordStatus.recitedTajweedError,
            tajweedError: 'Word not recognized in transcription',
          );
        }
      }
      ref.read(highlightedWordsProvider.notifier).state = allWords;

      // Recalculate error count after marking missed words
      final finalErrorCount = verseIndices
          .where((index) =>
              allWords[index].status == WordStatus.recitedTajweedError)
          .length;

      // Move to next verse
      _activeVerse = null;

      if (verseNumber < _maxVerseNumber) {
        _nextVerseToDetect = verseNumber + 1; // Always go to next verse
        _verseDetectionEnabled = true;
        message = finalErrorCount > 0
            ? 'Verse $verseNumber: $finalErrorCount words not recognized - ready for verse $_nextVerseToDetect'
            : 'Verse $verseNumber: completed successfully - ready for verse $_nextVerseToDetect';
        debugPrint('✓ Verse $verseNumber complete. Next: $_nextVerseToDetect');
      } else {
        _verseDetectionEnabled = false;
        _nextVerseToDetect = _maxVerseNumber;
        message = finalErrorCount > 0
            ? 'Surah completed with errors in $finalErrorCount words'
            : 'Surah Al-Fatiha completed successfully';
        debugPrint('✓ Surah complete!');

        // Show summary report after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showSummaryReport();
          }
        });
      }
    } else {
      _verseDetectionEnabled = true;
      debugPrint(
          'Verse $verseNumber: Still has unrecited words, waiting for more transcription');
    }

    ref.read(statusMessageProvider.notifier).state = message;
  }

  void _showSummaryReport() {
    final allWords = ref.read(highlightedWordsProvider);

    // Calculate statistics
    int totalWords = 0;
    int correctWords = 0;
    int errorWords = 0;
    int unrecitedWords = 0;
    int nearMissWords = 0;
    final verseStats = <int, Map<String, dynamic>>{};
    final errorWordsList = <Map<String, String>>[];
    final nearMissWordsList = <Map<String, String>>[];

    for (final word in allWords) {
      if (word.isVerseMarker) continue;

      totalWords++;

      // Initialize verse stats
      verseStats.putIfAbsent(
          word.verseNumber,
          () => {
                'total': 0,
                'correct': 0,
                'nearMiss': 0,
                'errors': 0,
                'unrecited': 0,
              });

      verseStats[word.verseNumber]!['total'] =
          (verseStats[word.verseNumber]!['total'] as int) + 1;

      switch (word.status) {
        case WordStatus.recitedCorrect:
          correctWords++;
          verseStats[word.verseNumber]!['correct'] =
              (verseStats[word.verseNumber]!['correct'] as int) + 1;
          break;
        case WordStatus.recitedNearMiss:
          nearMissWords++;
          verseStats[word.verseNumber]!['nearMiss'] =
              (verseStats[word.verseNumber]!['nearMiss'] as int) + 1;
          nearMissWordsList.add({
            'verse': word.verseNumber.toString(),
            'word': word.text,
            'hint': word.tajweedError ?? 'تحسين مطلوب',
          });
          break;
        case WordStatus.recitedTajweedError:
          errorWords++;
          verseStats[word.verseNumber]!['errors'] =
              (verseStats[word.verseNumber]!['errors'] as int) + 1;
          errorWordsList.add({
            'verse': word.verseNumber.toString(),
            'word': word.text,
            'error': word.tajweedError ?? 'Unknown error',
          });
          break;
        case WordStatus.unrecited:
          unrecitedWords++;
          verseStats[word.verseNumber]!['unrecited'] =
              (verseStats[word.verseNumber]!['unrecited'] as int) + 1;
          break;
      }
    }

    final accuracy = totalWords > 0
        ? (correctWords / totalWords * 100).toStringAsFixed(1)
        : '0.0';

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assessment, color: Color(0xFF0284C7), size: 28),
              SizedBox(width: 8),
              Text(
                'تقرير التلاوة',
                style: TextStyle(
                  fontFamily: 'ArabicUI',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Overall Statistics
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0284C7)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'الإحصائيات العامة',
                        style: TextStyle(
                          fontFamily: 'ArabicUI',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildStatRow(
                          'إجمالي الكلمات', totalWords.toString(), Colors.blue),
                      _buildStatRow('الكلمات الصحيحة', correctWords.toString(),
                          Colors.green),
                      if (nearMissWords > 0)
                        _buildStatRow('الكلمات القريبة',
                            nearMissWords.toString(), Colors.amber),
                      _buildStatRow(
                          'الكلمات الخاطئة', errorWords.toString(), Colors.red),
                      if (unrecitedWords > 0)
                        _buildStatRow('الكلمات غير المقروءة',
                            unrecitedWords.toString(), Colors.red),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'الدقة: ',
                            style: TextStyle(
                              fontFamily: 'ArabicUI',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$accuracy%',
                            style: TextStyle(
                              fontFamily: 'ArabicUI',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: double.parse(accuracy) >= 80
                                  ? Colors.green
                                  : double.parse(accuracy) >= 60
                                      ? Colors.orange
                                      : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (nearMissWordsList.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'الكلمات القريبة من الصحيح (تحسين بسيط)',
                    style: TextStyle(
                      fontFamily: 'ArabicUI',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  ...nearMissWordsList.map((item) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7D6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF59E0B)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'آية ${item['verse']}',
                                    style: const TextStyle(
                                      fontFamily: 'ArabicUI',
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item['word']!,
                                    style: const TextStyle(
                                      fontFamily: 'Quranic',
                                      fontSize: 18,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['hint']!,
                              style: const TextStyle(
                                fontFamily: 'ArabicUI',
                                fontSize: 12,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],

                if (errorWordsList.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'الكلمات التي تحتاج إلى تحسين',
                    style: TextStyle(
                      fontFamily: 'ArabicUI',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  ...errorWordsList.map((error) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFDC2626)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDC2626),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'آية ${error['verse']}',
                                    style: const TextStyle(
                                      fontFamily: 'ArabicUI',
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    error['word']!,
                                    style: const TextStyle(
                                      fontFamily: 'Quranic',
                                      fontSize: 18,
                                      color: Color(0xFF991B1B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              error['error']!,
                              style: const TextStyle(
                                fontFamily: 'ArabicUI',
                                fontSize: 12,
                                color: Color(0xFF991B1B),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'إغلاق',
                style: TextStyle(fontFamily: 'ArabicUI', fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetAll();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'إعادة المحاولة',
                style: TextStyle(fontFamily: 'ArabicUI', fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'ArabicUI',
              fontSize: 14,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'ArabicUI',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _stopRecitation() async {
    await _audioRecordingService.stopRecording();
    _transcriptionSubscription?.cancel();
    _geminiErrorSubscription?.cancel();
    final gemini = _geminiService;
    if (gemini != null) {
      await gemini.disconnect();
    }
    ref.read(isRecitingProvider.notifier).state = false;
    ref.read(statusMessageProvider.notifier).state = 'Recitation stopped';
    // Show summary immediately with current progress
    if (mounted) {
      Future.microtask(() => _showSummaryReport());
    }
  }

  void _resetAll() {
    final reset = ref
        .read(highlightedWordsProvider)
        .map(
          (word) => word.copyWith(
            status: WordStatus.unrecited,
            tajweedError: null,
          ),
        )
        .toList();

    ref.read(highlightedWordsProvider.notifier).state = reset;
    ref.read(audioMatchingServiceProvider).clearBuffer();
    ref.read(statusMessageProvider.notifier).state =
        'Ready to recite Surah Al-Fatiha';
    _activeVerse = null;
    _nextVerseToDetect = 1;
    _verseDetectionEnabled = true;
  }

  @override
  void dispose() {
    _transcriptionSubscription?.cancel();
    _geminiErrorSubscription?.cancel();
    final gemini = _geminiService;
    if (gemini != null) {
      unawaited(gemini.disconnect());
    }
    unawaited(_audioRecordingService.dispose());
    _feedbackSpeechService.dispose();
    super.dispose();
  }
}
