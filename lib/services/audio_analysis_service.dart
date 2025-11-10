import 'dart:typed_data';
import 'dart:math' as math;

/// Audio analysis service for analyzing audio quality and characteristics.
/// 
/// This service provides tools to analyze recorded audio for:
/// - Volume/energy levels
/// - Frequency characteristics
/// - Pitch detection
/// - Audio quality metrics
/// 
/// Note: This service is designed for audio quality analysis, NOT for 
/// word-by-word comparison. The app uses Gemini Live API transcription
/// combined with text-based fuzzy matching for recitation verification.
/// 
/// Audio-to-audio comparison would require reference recordings of a 
/// professional reciter, which are not currently available in the app.
class AudioAnalysisService {
  /// Compare two audio buffers and return similarity score (0.0 to 1.0)
  /// Higher score means more similar audio characteristics
  static double compareAudioWaveforms(Uint8List audio1, Uint8List audio2) {
    if (audio1.isEmpty || audio2.isEmpty) return 0.0;

    // Convert PCM bytes to float samples
    final samples1 = _pcmToFloat(audio1);
    final samples2 = _pcmToFloat(audio2);

    if (samples1.isEmpty || samples2.isEmpty) return 0.0;

    // Normalize to same length
    final minLength = math.min(samples1.length, samples2.length);
    final normalized1 = samples1.sublist(0, minLength);
    final normalized2 = samples2.sublist(0, minLength);

    // Compare multiple characteristics
    final waveformSimilarity = _calculateWaveformSimilarity(normalized1, normalized2);
    final energySimilarity = _calculateEnergySimilarity(normalized1, normalized2);
    final frequencySimilarity = _calculateFrequencySimilarity(normalized1, normalized2);
    final pitchSimilarity = _calculatePitchSimilarity(normalized1, normalized2);

    // Weight the different characteristics
    final overallScore = (waveformSimilarity * 0.3 +
            energySimilarity * 0.2 +
            frequencySimilarity * 0.25 +
            pitchSimilarity * 0.25)
        .clamp(0.0, 1.0);

    return overallScore;
  }

  /// Convert PCM 16-bit audio bytes to float samples
  static List<double> _pcmToFloat(Uint8List pcmData) {
    final samples = <double>[];
    for (int i = 0; i < pcmData.length - 1; i += 2) {
      // Convert 2 bytes to 16-bit signed integer (little-endian)
      final sample = (pcmData[i] & 0xff) | ((pcmData[i + 1] & 0x7f) << 8);
      final signedSample = (pcmData[i + 1] & 0x80) == 0
          ? sample
          : sample - 65536;
      // Normalize to -1.0 to 1.0
      samples.add(signedSample / 32768.0);
    }
    return samples;
  }

  /// Calculate waveform similarity using cross-correlation
  static double _calculateWaveformSimilarity(List<double> samples1, List<double> samples2) {
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
  static double _calculateEnergySimilarity(List<double> samples1, List<double> samples2) {
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
  static double _calculateFrequencySimilarity(List<double> samples1, List<double> samples2) {
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
  static double _calculatePitchSimilarity(List<double> samples1, List<double> samples2) {
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

  /// Check if audio quality is sufficient for transcription
  /// Returns a map with quality status and recommendations
  static Map<String, dynamic> checkAudioQuality(Uint8List audioData) {
    if (audioData.isEmpty) {
      return {
        'isGood': false,
        'issues': ['No audio data'],
        'recommendations': ['Ensure microphone is working'],
      };
    }

    final samples = _pcmToFloat(audioData);
    if (samples.isEmpty) {
      return {
        'isGood': false,
        'issues': ['Could not process audio'],
        'recommendations': ['Check audio format (PCM 16-bit expected)'],
      };
    }

    final issues = <String>[];
    final recommendations = <String>[];

    // Check volume level
    final rms = _calculateMagnitude(samples);
    if (rms < 0.01) {
      issues.add('Volume too low');
      recommendations.add('Speak louder or move closer to microphone');
    } else if (rms > 0.9) {
      issues.add('Volume too high (may be clipping)');
      recommendations.add('Speak softer or move away from microphone');
    }

    // Check for silence
    final energy = _calculateEnergy(samples);
    if (energy < 0.0001) {
      issues.add('Audio appears to be silent');
      recommendations.add('Check if microphone is muted');
    }

    // Check peak amplitude for clipping
    final peak = samples.reduce((a, b) => math.max(a.abs(), b.abs()));
    if (peak > 0.95) {
      issues.add('Audio may be clipping');
      recommendations.add('Reduce input volume');
    }

    return {
      'isGood': issues.isEmpty,
      'issues': issues,
      'recommendations': recommendations,
      'metrics': {
        'rms': rms,
        'energy': energy,
        'peak': peak,
      },
    };
  }
}
