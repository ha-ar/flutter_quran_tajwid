import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'audio_analysis_service.dart';
import 'audio_reference_service.dart';

/// Service for buffering and segmenting user's recorded audio
/// and matching it against reference audio files
class AudioMatchingService {
  // Buffer to accumulate audio chunks
  final List<int> _audioBuffer = [];

  // Maximum buffer size to prevent infinite growth (5 seconds of audio)
  static const int maxBufferSize = 160000; // 160kB = ~5 seconds at 16kHz 16-bit

  // Configuration for audio processing
  static const int sampleRate = 16000; // 16 kHz
  static const int bytesPerSample = 2; // 16-bit PCM
  static const int samplesPerSecond = sampleRate;
  static const int bytesPerSecond = sampleRate * bytesPerSample;

  // Track last match for sliding window
  int _lastMatchedVerse = 0;
  DateTime _lastMatchTime = DateTime.now();

  /// Add audio chunk to buffer
  void addAudioChunk(List<int> chunk) {
    _audioBuffer.addAll(chunk);

    // Prevent infinite buffer growth by removing old data if buffer gets too large
    if (_audioBuffer.length > maxBufferSize) {
      final excessBytes = _audioBuffer.length - maxBufferSize;
      _audioBuffer.removeRange(0, excessBytes);
    }

    debugPrint('Audio buffer size: ${_audioBuffer.length} bytes');
  }

  /// Get current buffer as Uint8List
  Uint8List getBuffer() {
    return Uint8List.fromList(_audioBuffer);
  }

  /// Extract audio segment of specified duration from buffer start
  /// Duration in milliseconds
  Uint8List? extractSegment(int durationMs) {
    final bytesNeeded = (sampleRate * durationMs ~/ 1000) * bytesPerSample;

    if (_audioBuffer.length < bytesNeeded) {
      return null; // Not enough audio data yet
    }

    final segment = _audioBuffer.sublist(0, bytesNeeded);
    return Uint8List.fromList(segment);
  }

  /// Remove the first N bytes from buffer (after processing)
  void removeProcessedBytes(int count) {
    if (count >= _audioBuffer.length) {
      _audioBuffer.clear();
    } else {
      _audioBuffer.removeRange(0, count);
    }
    debugPrint(
        'Removed $count bytes, buffer now: ${_audioBuffer.length} bytes');
  }

  /// Clear buffer
  void clearBuffer() {
    _audioBuffer.clear();
  }

  /// Reset match tracking (call when switching surahs or restarting)
  void resetMatchTracking() {
    _lastMatchedVerse = 0;
    _lastMatchTime = DateTime.now();
  }

  /// Check if enough time has passed since last match (throttling)
  bool shouldMatch({int minIntervalMs = 200}) {
    final elapsed = DateTime.now().difference(_lastMatchTime).inMilliseconds;
    return elapsed >= minIntervalMs;
  }

  /// Calculate audio duration in milliseconds
  static int calculateDurationMs(Uint8List audio) {
    return (audio.length ~/ bytesPerSample * 1000) ~/ sampleRate;
  }

  /// Try to match audio segment with reference verses using a sliding window around last match
  /// Returns list of matching verses with scores, sorted by score (highest first)
  Future<List<({int verseNumber, double score})>> matchWithVerses(
    Uint8List userAudio,
    int surahNumber, {
    double minScore = 0.3, // Optimized for speed
    int maxMatches = 1,
    int maxVerseToCheck = 1, // Only check one verse by default
    int windowRadius = 0, // No window by default for speed
  }) async {
    final matches = <({int verseNumber, double score})>[];
    final durationMs = calculateDurationMs(userAudio);

    debugPrint('Matching ${durationMs}ms of audio against surah $surahNumber');

    // Use sliding window: if we had a recent match, search around it; otherwise start from verse 1
    int startVerse = 1;
    int endVerse = maxVerseToCheck;

    if (_lastMatchedVerse > 0) {
      // Slide window around last matched verse
      startVerse = (_lastMatchedVerse - windowRadius).clamp(1, 286);
      endVerse = (_lastMatchedVerse + windowRadius).clamp(1, 286);
    }

    for (int verse = startVerse; verse <= endVerse; verse++) {
      final refAudio = await AudioReferenceService.loadReferenceAudio(
        surahNumber,
        verse,
      );

      if (refAudio == null) continue;

      // Compare with full reference only (skip expensive offset loop for speed)
      final score = AudioAnalysisService.compareAudioWaveformsFast(
        userAudio,
        refAudio,
      );

      if (score >= minScore) {
        matches.add((verseNumber: verse, score: score));
      }
    }

    // Sort by score (highest first)
    matches.sort((a, b) => b.score.compareTo(a.score));

    // Update last match info and remember for next sliding window
    if (matches.isNotEmpty) {
      _lastMatchedVerse = matches.first.verseNumber;
      _lastMatchTime = DateTime.now();
    }

    // Return top matches
    return matches.take(maxMatches).toList();
  }

  /// Match audio with word-level reference
  Future<List<({String wordKey, double score})>> matchWithWords(
    Uint8List userAudio, {
    double minScore = 0.6,
    int maxMatches = 10,
  }) async {
    final matches = <({String wordKey, double score})>[];

    // This would require having reference audio for each word
    // For now, this is a placeholder for future expansion
    debugPrint('Word-level matching not yet implemented');

    return matches;
  }

  /// Get detailed matching report
  Future<String> getMatchingReport(
    Uint8List userAudio,
    int surahNumber,
  ) async {
    final matches = await matchWithVerses(userAudio, surahNumber);
    final durationMs = calculateDurationMs(userAudio);

    final report = StringBuffer();
    report.writeln('Audio Matching Report');
    report.writeln('====================');
    report.writeln('Duration: ${durationMs}ms');
    report.writeln('Surah: $surahNumber');
    report.writeln('Matches found: ${matches.length}');
    report.writeln('-----------------------------------------');

    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      final percentage = (match.score * 100).toStringAsFixed(1);
      report
          .writeln('${i + 1}. Verse ${match.verseNumber}: $percentage% match');
    }

    return report.toString();
  }
}
