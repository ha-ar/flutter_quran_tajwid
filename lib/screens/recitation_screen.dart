import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import '../models/highlighted_word.dart';
import '../models/recitation_summary.dart';
import '../providers/app_state.dart';
import '../services/quran_service.dart';
import '../services/audio_recording_service.dart';
import '../widgets/surah_display.dart';
import '../widgets/audio_visualizer.dart';
import '../widgets/recitation_summary_widget.dart';
import '../utils/arabic_utils.dart';

class RecitationScreen extends ConsumerStatefulWidget {
  const RecitationScreen({super.key});

  @override
  ConsumerState<RecitationScreen> createState() => _RecitationScreenState();
}

class _RecitationScreenState extends ConsumerState<RecitationScreen> {
  late final ScrollController _scrollController;
  late AudioRecordingService _audioRecordingService;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initializeAudioRecording();
  }

  Future<void> _initializeAudioRecording() async {
    _audioRecordingService = AudioRecordingService();
    await _audioRecordingService.initialize();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _audioRecordingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSurah = ref.watch(currentSurahProvider);
    final isReciting = ref.watch(isRecitingProvider);
    final statusMessage = ref.watch(statusMessageProvider);
    final highlightedWords = ref.watch(highlightedWordsProvider);
    final recitationSummary = ref.watch(recitationSummaryProvider);
    final audioLevel = ref.watch(audioLevelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tajweed Trainer'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: currentSurah == null
              ? _buildSurahSelector()
              : (recitationSummary != null
                  ? _buildSummaryView(recitationSummary)
                  : _buildRecitationView(context, currentSurah, highlightedWords, isReciting, statusMessage, audioLevel)),
        ),
      ),
    );
  }

  /// Build Surah selector dropdown
  Widget _buildSurahSelector() {
    final surahs = ref.watch(surahNamesProvider);

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Select a Surah',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                fontFamily: 'ArabicUI',
                color: Color(0xFF064E3B),
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<int>(
                isExpanded: true,
                hint: const Text('Select...'),
                underline: const SizedBox(),
                items: surahs
                    .map((surah) => DropdownMenuItem(
                          value: surah.number,
                          child: Text(
                            '${surah.englishName} (${surah.name})',
                            style: const TextStyle(
                              fontFamily: 'ArabicUI',
                              fontSize: 14,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ))
                    .toList(),
                onChanged: (surahNumber) {
                  if (surahNumber != null) {
                    final selectedSurah =
                        QuranService.getSurah(surahNumber);
                    if (selectedSurah != null) {
                      ref.read(currentSurahProvider.notifier).state =
                          selectedSurah;

                      // Initialize highlighted words
                      final words = splitIntoWords(selectedSurah.text);
                      final highlighted = words
                          .map((word) => HighlightedWord(
                                text: word,
                                status: WordStatus.unrecited,
                              ))
                          .toList();
                      ref.read(highlightedWordsProvider.notifier).state =
                          highlighted;

                      ref.read(statusMessageProvider.notifier).state =
                          'Start again.';
                    }
                  }
                },
              ),
            ),
          ],
        ),
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
            surahName: selectedSurah.displayName,
            highlightedWords: highlightedWords,
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
    ref.read(statusMessageProvider.notifier).state = 'Connecting...'; ;

    final geminiService = ref.read(geminiLiveServiceProvider);
    if (geminiService == null) {
      ref.read(statusMessageProvider.notifier).state ='Connection error.';
      return;
    }

    try {
      // Connect to Gemini
      await geminiService.connect();
      ref.read(statusMessageProvider.notifier).state = 'Connected..';

      // Listen to transcription stream
      geminiService.transcriptionStream.listen(
        (message) {
          // Only process finalized words (isFinal: true)
          if (message.isFinal && message.text.isNotEmpty) {
            // Split into words and add to queue only when final
            final words = message.text.split(RegExp(r'\s+'));
            for (final word in words) {
              if (word.isNotEmpty) {
                final queue = ref.read(transcribedWordsQueueProvider);
                queue.add(word);
                ref.read(transcribedWordsQueueProvider.notifier).state = List.from(queue);

                // Process queue to update highlighted words
                ref.read(processTranscriptionProvider.notifier).processQueue();
              }
            }
          }
        },
        onError: (error) {
          ref.read(statusMessageProvider.notifier).state = 'خطأ: $error';
          ref.read(isRecitingProvider.notifier).state = false;
        },
      );

      // Start audio recording
      await _audioRecordingService.startRecording(
        onAudioData: (List<int> audioData) {
          // Send audio to Gemini
          geminiService.sendAudioChunk(Uint8List.fromList(audioData));
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

  /// Stop recitation
  Future<void> _stopRecitation() async {
    ref.read(isRecitingProvider.notifier).state = false;
    ref.read(statusMessageProvider.notifier).state = 'تم إيقاف الترتيل';
    
    // Stop audio recording
    await _audioRecordingService.stopRecording();
    
    // Disconnect from Gemini
    final geminiService = ref.read(geminiLiveServiceProvider);
    if (geminiService != null) {
      await geminiService.disconnect();
    }
    
    // Calculate summary
    final highlightedWords = ref.read(highlightedWordsProvider);
    final currentSurah = ref.read(currentSurahProvider);
    
    if (currentSurah != null) {
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
        surahName: currentSurah.displayName,
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
    final currentSurah = ref.read(currentSurahProvider);
    if (currentSurah != null) {
      final words = splitIntoWords(currentSurah.text);
      final highlighted = words
          .map((word) => HighlightedWord(
                text: word,
                status: WordStatus.unrecited,
              ))
          .toList();
      
      ref.read(highlightedWordsProvider.notifier).state = highlighted;
      ref.read(nextWordIndexProvider.notifier).state = 0;
      ref.read(recitedTextProvider.notifier).state = '';
      ref.read(transcribedWordsQueueProvider.notifier).state = [];
      ref.read(isRecitingProvider.notifier).state = false;
      ref.read(statusMessageProvider.notifier).state = 'جاهز للبدء';
    }
  }

  /// Reset and go back to Surah selection
  void _resetAndSelectNewSurah() {
    ref.read(currentSurahProvider.notifier).state = null;
    ref.read(highlightedWordsProvider.notifier).state = [];
    ref.read(recitationSummaryProvider.notifier).state = null;
    ref.read(nextWordIndexProvider.notifier).state = 0;
    ref.read(recitedTextProvider.notifier).state = '';
    ref.read(transcribedWordsQueueProvider.notifier).state = [];
    ref.read(isRecitingProvider.notifier).state = false;
    ref.read(statusMessageProvider.notifier).state = 'اختر سورة للبدء';
  }
}
