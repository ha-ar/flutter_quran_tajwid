import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import '../models/highlighted_word.dart';
import '../models/recitation_summary.dart';
import '../providers/app_state.dart';
import '../services/quran_json_service.dart';
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
          padding: const EdgeInsets.all(16.0),
          child: surahNumber == 0
              ? _buildSurahSelector()
              : (recitationSummary != null
                  ? _buildSummaryView(recitationSummary)
                  : _buildRecitationView(context, surahName, highlightedWords, isReciting, statusMessage, audioLevel)),
        ),
      ),
    );
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
                  'لم يتم العثور على سور. حاول إعادة التحميل.',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'ArabicUI',
                    color: Color(0xFF374151),
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(surahNamesProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة تحميل'),
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
                const SizedBox(height: 30),
                Container(
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
                        final surah = quranService.getSurah(surahNumber);
                        if (surah != null) {
                          // Get all words from surah (including verse markers for display)
                          final words = quranService.getSurahWords(surahNumber);

                          // Create highlighted words from QuranWord objects
                          // Use text for display and simpleText for comparison
                          // Verse markers will display but won't interfere with matching
                          final highlighted = words
                              .map((word) => HighlightedWord(
                                    text: word.text,
                                    simpleText: word.simpleText,
                                    status: WordStatus.unrecited,
                                  ))
                              .toList();

                          // Store surah info
                          ref.read(currentSurahNumberProvider.notifier).state =
                              surahNumber;
                          ref.read(currentSurahNameProvider.notifier).state =
                              surah.surahName;

                          ref.read(highlightedWordsProvider.notifier).state =
                              highlighted;

                          ref.read(statusMessageProvider.notifier).state =
                              'جاهز للبدء';
                        }
                      }
                    },
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
