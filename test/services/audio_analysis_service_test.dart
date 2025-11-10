import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quran_tajwid/services/audio_analysis_service.dart';
import 'dart:typed_data';
import 'dart:math' as math;

void main() {
  group('AudioAnalysisService', () {
    // Helper to generate test audio data (PCM 16-bit)
    Uint8List generateTestAudio(int samples, {double amplitude = 0.5, double frequency = 440.0}) {
      final buffer = <int>[];
      const sampleRate = 16000;
      
      for (int i = 0; i < samples; i++) {
        // Generate sine wave
        final value = amplitude * math.sin(2 * math.pi * frequency * i / sampleRate);
        // Convert to 16-bit PCM (little-endian)
        final intValue = (value * 32767).toInt();
        buffer.add(intValue & 0xFF); // Low byte
        buffer.add((intValue >> 8) & 0xFF); // High byte
      }
      
      return Uint8List.fromList(buffer);
    }

    // Helper to generate silent audio
    Uint8List generateSilence(int samples) {
      return Uint8List(samples * 2); // All zeros
    }

    group('checkAudioQuality', () {
      test('returns error for empty audio', () {
        final result = AudioAnalysisService.checkAudioQuality(Uint8List(0));
        expect(result['isGood'], isFalse);
        expect(result['issues'], isNotEmpty);
      });

      test('detects silence', () {
        final silent = generateSilence(1600); // 0.1 seconds of silence
        final result = AudioAnalysisService.checkAudioQuality(silent);
        expect(result['isGood'], isFalse);
        expect(result['issues'], contains('Audio appears to be silent'));
      });

      test('detects low volume', () {
        final lowVolume = generateTestAudio(1600, amplitude: 0.005); // Very low amplitude
        final result = AudioAnalysisService.checkAudioQuality(lowVolume);
        expect(result['isGood'], isFalse);
        expect(result['issues'], contains('Volume too low'));
      });

      test('detects high volume/clipping', () {
        final highVolume = generateTestAudio(1600, amplitude: 0.95); // Near clipping
        final result = AudioAnalysisService.checkAudioQuality(highVolume);
        expect(result['isGood'], isFalse);
        expect(result['issues'], contains('Volume too high (may be clipping)'));
      });

      test('accepts good quality audio', () {
        final goodAudio = generateTestAudio(1600, amplitude: 0.5); // Normal amplitude
        final result = AudioAnalysisService.checkAudioQuality(goodAudio);
        expect(result['isGood'], isTrue);
        expect(result['issues'], isEmpty);
      });

      test('provides recommendations for issues', () {
        final lowVolume = generateTestAudio(1600, amplitude: 0.005);
        final result = AudioAnalysisService.checkAudioQuality(lowVolume);
        expect(result['recommendations'], isNotEmpty);
        expect(result['recommendations'].first, contains('louder'));
      });

      test('includes metrics in result', () {
        final audio = generateTestAudio(1600, amplitude: 0.5);
        final result = AudioAnalysisService.checkAudioQuality(audio);
        expect(result['metrics'], isNotNull);
        expect(result['metrics']['rms'], isNotNull);
        expect(result['metrics']['energy'], isNotNull);
        expect(result['metrics']['peak'], isNotNull);
      });
    });

    group('analyzeAudio', () {
      test('returns error for empty audio', () {
        final result = AudioAnalysisService.analyzeAudio(Uint8List(0));
        expect(result['error'], equals('Empty audio data'));
      });

      test('calculates duration correctly', () {
        final audio = generateTestAudio(16000); // 1 second at 16kHz
        final result = AudioAnalysisService.analyzeAudio(audio);
        expect(result['duration_seconds'], closeTo(1.0, 0.01));
      });

      test('calculates energy for audio', () {
        final audio = generateTestAudio(1600, amplitude: 0.5);
        final result = AudioAnalysisService.analyzeAudio(audio);
        expect(result['energy'], greaterThan(0.0));
        expect(result['rms_energy'], greaterThan(0.0));
      });

      test('detects zero energy for silence', () {
        final silent = generateSilence(1600);
        final result = AudioAnalysisService.analyzeAudio(silent);
        expect(result['energy'], equals(0.0));
        expect(result['rms_energy'], equals(0.0));
      });

      test('calculates zero crossing rate', () {
        final audio = generateTestAudio(1600, amplitude: 0.5, frequency: 440.0);
        final result = AudioAnalysisService.analyzeAudio(audio);
        expect(result['zero_crossing_rate'], greaterThan(0.0));
      });

      test('estimates pitch', () {
        // Generate 440Hz sine wave (musical note A4)
        final audio = generateTestAudio(3200, amplitude: 0.5, frequency: 440.0);
        final result = AudioAnalysisService.analyzeAudio(audio);
        
        // Pitch estimation may not be exact, but should be in reasonable range
        expect(result['estimated_pitch_hz'], greaterThan(0.0));
      });

      test('calculates peak amplitude', () {
        final audio = generateTestAudio(1600, amplitude: 0.7);
        final result = AudioAnalysisService.analyzeAudio(audio);
        expect(result['peak_amplitude'], greaterThan(0.0));
        expect(result['peak_amplitude'], lessThanOrEqualTo(1.0));
      });
    });

    group('compareAudioWaveforms', () {
      test('returns 1.0 for identical audio', () {
        final audio1 = generateTestAudio(1600, amplitude: 0.5, frequency: 440.0);
        final audio2 = Uint8List.fromList(audio1); // Copy
        
        final similarity = AudioAnalysisService.compareAudioWaveforms(audio1, audio2);
        expect(similarity, closeTo(1.0, 0.01));
      });

      test('returns 0.0 for empty audio', () {
        final audio1 = generateTestAudio(1600);
        final empty = Uint8List(0);
        
        final similarity = AudioAnalysisService.compareAudioWaveforms(audio1, empty);
        expect(similarity, equals(0.0));
      });

      test('returns lower similarity for different frequencies', () {
        final audio1 = generateTestAudio(1600, amplitude: 0.5, frequency: 440.0);
        final audio2 = generateTestAudio(1600, amplitude: 0.5, frequency: 880.0);
        
        final similarity = AudioAnalysisService.compareAudioWaveforms(audio1, audio2);
        expect(similarity, lessThan(0.5)); // Different frequencies should be less similar
      });

      test('returns high similarity for similar audio', () {
        final audio1 = generateTestAudio(1600, amplitude: 0.5, frequency: 440.0);
        final audio2 = generateTestAudio(1600, amplitude: 0.52, frequency: 440.0); // Slightly different amplitude
        
        final similarity = AudioAnalysisService.compareAudioWaveforms(audio1, audio2);
        expect(similarity, greaterThan(0.8)); // Should still be very similar
      });

      test('handles different length audio', () {
        final audio1 = generateTestAudio(1600);
        final audio2 = generateTestAudio(3200); // Twice as long
        
        final similarity = AudioAnalysisService.compareAudioWaveforms(audio1, audio2);
        expect(similarity, greaterThanOrEqualTo(0.0));
        expect(similarity, lessThanOrEqualTo(1.0));
      });

      test('returns value between 0.0 and 1.0', () {
        final audio1 = generateTestAudio(1600, amplitude: 0.3, frequency: 300.0);
        final audio2 = generateTestAudio(1600, amplitude: 0.7, frequency: 600.0);
        
        final similarity = AudioAnalysisService.compareAudioWaveforms(audio1, audio2);
        expect(similarity, greaterThanOrEqualTo(0.0));
        expect(similarity, lessThanOrEqualTo(1.0));
      });
    });

    group('Edge cases', () {
      test('handles very short audio', () {
        final shortAudio = generateTestAudio(10); // Very short
        final result = AudioAnalysisService.analyzeAudio(shortAudio);
        expect(result['duration_seconds'], greaterThan(0.0));
      });

      test('handles corrupted PCM data gracefully', () {
        final corrupted = Uint8List.fromList([0xFF, 0xFF, 0xFF]); // Odd number of bytes
        final result = AudioAnalysisService.analyzeAudio(corrupted);
        // Should not throw, should return some result
        expect(result, isNotNull);
      });
    });
  });
}
