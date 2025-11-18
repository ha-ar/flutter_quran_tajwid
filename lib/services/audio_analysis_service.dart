import 'dart:typed_data';
import 'dart:math' as math;

/// Audio analysis service for comparing waveforms and detecting tajweed errors
class AudioAnalysisService {
  /// Ultra-fast comparison with aggressive downsampling (8x) for real-time matching
  static double compareAudioWaveformsUltraFast(
      Uint8List audio1, Uint8List audio2) {
    if (audio1.isEmpty || audio2.isEmpty) return 0.0;

    // Convert PCM bytes to float samples with aggressive downsampling (every 8th sample)
    final samples1 = _pcmToFloatDownsampled(audio1, 8);
    final samples2 = _pcmToFloatDownsampled(audio2, 8);

    if (samples1.isEmpty || samples2.isEmpty) return 0.0;

    // Normalize to same length (take minimum)
    final minLength = math.min(samples1.length, samples2.length);
    final normalized1 = samples1.sublist(0, minLength);
    final normalized2 = samples2.sublist(0, minLength);

    // Only use the most important similarity measure for speed
    final waveformSimilarity =
        _calculateWaveformSimilarityUltraFast(normalized1, normalized2);
    final energySimilarity =
        _calculateEnergySimilarityFast(normalized1, normalized2);

    // Simplified combination - only 2 measures for speed
    return (waveformSimilarity * 0.7 + energySimilarity * 0.3).clamp(0.0, 1.0);
  }

  /// Fast comparison for real-time processing - simplified version
  static double compareAudioWaveformsFast(Uint8List audio1, Uint8List audio2) {
    if (audio1.isEmpty || audio2.isEmpty) return 0.0;

    // Convert PCM bytes to float samples (simplified)
    final samples1 = _pcmToFloatFast(audio1);
    final samples2 = _pcmToFloatFast(audio2);

    if (samples1.isEmpty || samples2.isEmpty) return 0.0;

    // Normalize to same length (take minimum)
    final minLength = math.min(samples1.length, samples2.length);
    final normalized1 = samples1.sublist(0, minLength);
    final normalized2 = samples2.sublist(0, minLength);

    // Simple but effective similarity measures
    final waveformSimilarity =
        _calculateWaveformSimilarityFast(normalized1, normalized2);
    final energySimilarity =
        _calculateEnergySimilarity(normalized1, normalized2);
    final zcrSimilarity = _calculateZCRSimilarity(normalized1, normalized2);

    // Weighted combination - simplified weights
    return (waveformSimilarity * 0.5 +
            energySimilarity * 0.3 +
            zcrSimilarity * 0.2)
        .clamp(0.0, 1.0);
  }

  /// Convert PCM to float with aggressive downsampling for maximum speed
  static List<double> _pcmToFloatDownsampled(
      Uint8List pcmData, int downsampleFactor) {
    final samples = <double>[];
    final length = pcmData.length ~/ 2;
    for (int i = 0; i < length; i += downsampleFactor) {
      final idx = i * 2;
      if (idx + 1 >= pcmData.length) break;
      final sample = (pcmData[idx] & 0xff) | ((pcmData[idx + 1] & 0x7f) << 8);
      final signedSample =
          (pcmData[idx + 1] & 0x80) == 0 ? sample : sample - 65536;
      samples.add(signedSample / 32768.0);
    }
    return samples;
  }

  /// Ultra-fast waveform similarity with no additional downsampling
  static double _calculateWaveformSimilarityUltraFast(
      List<double> samples1, List<double> samples2) {
    if (samples1.isEmpty || samples2.isEmpty) return 0.0;

    // No additional downsampling since we already downsampled during PCM conversion
    double sumProduct = 0.0;
    double sum1Sq = 0.0;
    double sum2Sq = 0.0;

    for (int i = 0; i < samples1.length; i++) {
      final s1 = samples1[i];
      final s2 = samples2[i];
      sumProduct += s1 * s2;
      sum1Sq += s1 * s1;
      sum2Sq += s2 * s2;
    }

    if (sum1Sq == 0.0 || sum2Sq == 0.0) return 0.0;

    final correlation = sumProduct / math.sqrt(sum1Sq * sum2Sq);
    return correlation.abs().clamp(0.0, 1.0);
  }

  /// Fast energy similarity calculation
  static double _calculateEnergySimilarityFast(
      List<double> samples1, List<double> samples2) {
    double energy1 = 0.0;
    double energy2 = 0.0;

    for (int i = 0; i < samples1.length; i++) {
      energy1 += samples1[i] * samples1[i];
      energy2 += samples2[i] * samples2[i];
    }

    energy1 /= samples1.length;
    energy2 /= samples2.length;

    if (energy1 == 0.0 && energy2 == 0.0) return 1.0;
    if (energy1 == 0.0 || energy2 == 0.0) return 0.0;

    final ratio = math.min(energy1, energy2) / math.max(energy1, energy2);
    return ratio.clamp(0.0, 1.0);
  }

  /// Convert PCM 16-bit audio bytes to float samples (optimized)
  static List<double> _pcmToFloatFast(Uint8List pcmData) {
    final samples = <double>[];
    final length = pcmData.length ~/ 2; // Process in pairs
    for (int i = 0; i < length; i++) {
      final idx = i * 2;
      // Fast conversion without bounds checking
      final sample = (pcmData[idx] & 0xff) | ((pcmData[idx + 1] & 0x7f) << 8);
      final signedSample =
          (pcmData[idx + 1] & 0x80) == 0 ? sample : sample - 65536;
      samples.add(signedSample / 32768.0);
    }
    return samples;
  }

  /// Fast waveform similarity using simplified correlation
  static double _calculateWaveformSimilarityFast(
      List<double> samples1, List<double> samples2) {
    if (samples1.isEmpty || samples2.isEmpty) return 0.0;

    // Downsample for speed (take every 4th sample)
    final step = 4;
    double sumProduct = 0.0;
    double sum1Sq = 0.0;
    double sum2Sq = 0.0;

    for (int i = 0; i < samples1.length; i += step) {
      final s1 = samples1[i];
      final s2 = samples2[i];
      sumProduct += s1 * s2;
      sum1Sq += s1 * s1;
      sum2Sq += s2 * s2;
    }

    if (sum1Sq == 0.0 || sum2Sq == 0.0) return 0.0;

    final correlation = sumProduct / math.sqrt(sum1Sq * sum2Sq);
    return correlation.abs().clamp(0.0, 1.0);
  }

  /// Calculate ZCR similarity (frequency content indicator)
  static double _calculateZCRSimilarity(
      List<double> samples1, List<double> samples2) {
    final zcr1 = _calculateZeroCrossingRateFast(samples1);
    final zcr2 = _calculateZeroCrossingRateFast(samples2);

    if (zcr1 == 0.0 && zcr2 == 0.0) return 1.0;
    if (zcr1 == 0.0 || zcr2 == 0.0) return 0.0;

    final ratio = math.min(zcr1, zcr2) / math.max(zcr1, zcr2);
    return ratio.clamp(0.0, 1.0);
  }

  /// Fast zero-crossing rate calculation
  static double _calculateZeroCrossingRateFast(List<double> samples) {
    if (samples.length < 2) return 0.0;

    int zeroCrossings = 0;
    // Sample every 4th point for speed
    for (int i = 0; i < samples.length - 4; i += 4) {
      final s1 = samples[i];
      final s2 = samples[i + 4];
      if ((s1 >= 0 && s2 < 0) || (s1 < 0 && s2 >= 0)) {
        zeroCrossings++;
      }
    }

    return zeroCrossings / (samples.length / 4);
  }

  /// Convert PCM 16-bit audio bytes to float samples
  static List<double> _pcmToFloat(Uint8List pcmData) {
    final samples = <double>[];
    for (int i = 0; i < pcmData.length - 1; i += 2) {
      // Convert 2 bytes to 16-bit signed integer (little-endian)
      final sample = (pcmData[i] & 0xff) | ((pcmData[i + 1] & 0x7f) << 8);
      final signedSample =
          (pcmData[i + 1] & 0x80) == 0 ? sample : sample - 65536;
      // Normalize to -1.0 to 1.0
      samples.add(signedSample / 32768.0);
    }
    return samples;
  }

  /// Calculate waveform similarity using cross-correlation
  static double _calculateWaveformSimilarity(
      List<double> samples1, List<double> samples2) {
    if (samples1.isEmpty || samples2.isEmpty) return 0.0;

    double sumProduct = 0.0;
    for (int i = 0; i < samples1.length; i++) {
      sumProduct += samples1[i] * samples2[i];
    }

    final mag1 = _calculateMagnitude(samples1);
    final mag2 = _calculateMagnitude(samples2);

    if (mag1 == 0.0 || mag2 == 0.0) return 0.0;

    return (sumProduct / (mag1 * mag2)).clamp(-1.0, 1.0).abs();
  }

  /// Calculate magnitude (RMS) of audio samples
  static double _calculateMagnitude(List<double> samples) {
    double sum = 0.0;
    for (final sample in samples) {
      sum += sample * sample;
    }
    return math.sqrt(sum / samples.length);
  }

  /// Calculate energy similarity (loudness comparison)
  static double _calculateEnergySimilarity(
      List<double> samples1, List<double> samples2) {
    final energy1 = _calculateEnergy(samples1);
    final energy2 = _calculateEnergy(samples2);

    if (energy1 == 0.0 && energy2 == 0.0) return 1.0;
    if (energy1 == 0.0 || energy2 == 0.0) return 0.0;

    final ratio = math.min(energy1, energy2) / math.max(energy1, energy2);
    return ratio.clamp(0.0, 1.0);
  }

  /// Calculate total energy of audio samples
  static double _calculateEnergy(List<double> samples) {
    double energy = 0.0;
    for (final sample in samples) {
      energy += sample * sample;
    }
    return energy / samples.length;
  }

  /// Calculate frequency similarity using FFT-like analysis
  static double _calculateFrequencySimilarity(
      List<double> samples1, List<double> samples2) {
    // Simple frequency analysis using zero-crossing rate
    final zcr1 = _calculateZeroCrossingRate(samples1);
    final zcr2 = _calculateZeroCrossingRate(samples2);

    if (zcr1 == 0.0 && zcr2 == 0.0) return 1.0;
    if (zcr1 == 0.0 || zcr2 == 0.0) return 0.0;

    final ratio = math.min(zcr1, zcr2) / math.max(zcr1, zcr2);
    return ratio.clamp(0.0, 1.0);
  }

  /// Calculate zero-crossing rate (indicator of frequency content)
  static double _calculateZeroCrossingRate(List<double> samples) {
    if (samples.length < 2) return 0.0;

    int zeroCrossings = 0;
    for (int i = 0; i < samples.length - 1; i++) {
      if ((samples[i] >= 0 && samples[i + 1] < 0) ||
          (samples[i] < 0 && samples[i + 1] >= 0)) {
        zeroCrossings++;
      }
    }

    return zeroCrossings / (samples.length - 1);
  }

  /// Calculate pitch similarity using autocorrelation
  static double _calculatePitchSimilarity(
      List<double> samples1, List<double> samples2) {
    final pitch1 = _estimatePitch(samples1);
    final pitch2 = _estimatePitch(samples2);

    if (pitch1 == 0.0 && pitch2 == 0.0) return 1.0;
    if (pitch1 == 0.0 || pitch2 == 0.0) return 0.5;

    final ratio = math.min(pitch1, pitch2) / math.max(pitch1, pitch2);
    return ratio.clamp(0.0, 1.0);
  }

  /// Simple pitch estimation using autocorrelation
  static double _estimatePitch(List<double> samples) {
    if (samples.length < 100) return 0.0;

    // Simple autocorrelation for fundamental frequency
    double maxCorrelation = 0.0;
    int bestLag = 0;

    for (int lag = 10; lag < 200 && lag < samples.length ~/ 2; lag++) {
      double correlation = 0.0;
      for (int i = 0; i < samples.length - lag; i++) {
        correlation += samples[i] * samples[i + lag];
      }
      if (correlation > maxCorrelation) {
        maxCorrelation = correlation;
        bestLag = lag;
      }
    }

    // Convert lag to frequency (16000 Hz sample rate)
    if (bestLag == 0) return 0.0;
    return 16000.0 / bestLag;
  }

  /// Get detailed analysis report for debugging
  static Map<String, dynamic> analyzeAudio(Uint8List audioData) {
    if (audioData.isEmpty) {
      return {'error': 'Empty audio data'};
    }

    final samples = _pcmToFloat(audioData);
    if (samples.isEmpty) {
      return {'error': 'Could not convert PCM data'};
    }

    return {
      'duration_samples': samples.length,
      'duration_seconds': samples.length / 16000.0,
      'rms_energy': _calculateMagnitude(samples),
      'energy': _calculateEnergy(samples),
      'zero_crossing_rate': _calculateZeroCrossingRate(samples),
      'estimated_pitch_hz': _estimatePitch(samples),
      'peak_amplitude': samples.reduce((a, b) => math.max(a.abs(), b.abs())),
    };
  }
}
