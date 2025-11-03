import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:flutter/foundation.dart';

class AudioRecordingService {
  late final AudioRecorder _recorder;
  Stream<Uint8List>? _recordStream;
  bool _isRecording = false;

  Future<void> initialize() async {
    _recorder = AudioRecorder();

    // Check permissions
    if (await _recorder.hasPermission()) {
      debugPrint('Microphone permission granted');
    }
  }

  Future<void> startRecording({
    required void Function(List<int>) onAudioData,
    required void Function(String) onError,
  }) async {
    try {
      if (_isRecording) {
        onError('Already recording');
        return;
      }

      // Check if permission is granted
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        onError('Microphone permission not granted');
        return;
      }

      // Start recording with raw PCM audio
      _recordStream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 128000,
        ),
      );

      _isRecording = true;

      // Listen to audio stream
      _recordStream?.listen(
        (chunk) {
          onAudioData(chunk);
        },
        onError: (error) {
          onError('Recording error: $error');
          _isRecording = false;
        },
        onDone: () {
          _isRecording = false;
        },
      );

    } catch (e) {
      onError('Failed to start recording: $e');
      _isRecording = false;
    }
  }

  Future<void> stopRecording() async {
    try {
      if (_isRecording) {
        await _recorder.stop();
        _isRecording = false;
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }
  bool get isRecording => _isRecording;

  Future<void> dispose() async {
    await stopRecording();
    await _recorder.dispose();
  }
}
