import 'package:flutter/foundation.dart';

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

  /// Add audio chunk to buffer
  void addAudioChunk(List<int> chunk) {
    _audioBuffer.addAll(chunk);

    // Rolling buffer: if we exceed max size, drop oldest data to keep newest
    if (_audioBuffer.length > maxBufferSize) {
      final excess = _audioBuffer.length - maxBufferSize;
      _audioBuffer.removeRange(0, excess);
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

  /// Calculate audio duration in milliseconds
  static int calculateDurationMs(Uint8List audio) {
    return (audio.length ~/ bytesPerSample * 1000) ~/ sampleRate;
  }

  /// Process audio for matching (now purely buffer management as audio files are removed)
  void processAudio() {
    debugPrint('Processing audio buffer: ${_audioBuffer.length} bytes');
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
}
