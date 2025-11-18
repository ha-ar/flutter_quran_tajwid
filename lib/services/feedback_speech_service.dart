import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';

/// Provides short audible feedback for recitation events.
/// Uses debouncing to avoid spamming TTS on rapid word matches.
class FeedbackSpeechService {
  final FlutterTts _tts = FlutterTts();
  DateTime _lastSpoken = DateTime.fromMillisecondsSinceEpoch(0);
  Duration minInterval = const Duration(milliseconds: 500);
  bool _initialized = false;
  bool enabled = true; // Allow user toggling later

  Future<void> init() async {
    if (_initialized) return;
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45); // Slow for clarity
      await _tts.setVolume(0.8);
      _initialized = true;
    } catch (e) {
      // Silently fail; app still functions without audio feedback
    }
  }

  Future<void> speakStatus(String statusKey) async {
    if (!enabled) return;
    final now = DateTime.now();
    if (now.difference(_lastSpoken) < minInterval) return; // debounce
    _lastSpoken = now;

    String phrase;
    switch (statusKey) {
      case 'correct':
        phrase = 'Correct';
        break;
      case 'near':
        phrase = 'Near';
        break;
      case 'error':
        phrase = 'Error';
        break;
      case 'missed':
        phrase = 'Unrecited';
        break;
      default:
        phrase = '';
    }
    if (phrase.isEmpty) return;
    try {
      await _tts.stop();
      await _tts.speak(phrase);
    } catch (_) {
      // Ignore TTS failures
    }
  }

  Future<void> dispose() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
