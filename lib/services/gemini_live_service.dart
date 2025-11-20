import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class GeminiLiveMessage {
  final String? text;
  final String? audio;
  final String messageType;

  GeminiLiveMessage({
    this.text,
    this.audio,
    required this.messageType,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': messageType,
      'text': text,
      'audio': audio,
    };
  }
}

class GeminiTranscriptionMessage {
  final String text;
  final bool isFinal;

  GeminiTranscriptionMessage({
    required this.text,
    required this.isFinal,
  });

  factory GeminiTranscriptionMessage.fromJson(Map<String, dynamic> json) {
    // Handle inputTranscription format
    if (json.containsKey('inputTranscription') &&
        json['inputTranscription'] is Map) {
      final transcriptionData =
          json['inputTranscription'] as Map<String, dynamic>;
      final text = transcriptionData['text'] as String? ?? '';
      final isFinal = transcriptionData['isFinal'] as bool? ?? false;
      return GeminiTranscriptionMessage(
        text: text.trim(),
        isFinal: isFinal,
      );
    }

    // Handle modelTurn responses format
    if (json.containsKey('modelTurn') && json['modelTurn'] is Map) {
      final modelTurn = json['modelTurn'] as Map<String, dynamic>;
      if (modelTurn.containsKey('parts') && modelTurn['parts'] is List) {
        final parts = modelTurn['parts'] as List;
        for (var part in parts) {
          if (part is Map && part.containsKey('text')) {
            final text = part['text'] as String? ?? '';
            return GeminiTranscriptionMessage(
              text: text.trim(),
              isFinal: true,
            );
          }
        }
      }
    }

    // Fallback for unexpected structure
    return GeminiTranscriptionMessage(text: '', isFinal: false);
  }
}

class GeminiLiveService {
  final String apiKey;
  final String model = 'gemini-2.0-flash-live-001';

  WebSocketChannel? _channel;
  final StreamController<GeminiTranscriptionMessage> _transcriptionController =
      StreamController<GeminiTranscriptionMessage>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  bool _isConnected = false;

  Stream<GeminiTranscriptionMessage> get transcriptionStream =>
      _transcriptionController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  GeminiLiveService({required this.apiKey});

  /// Connect to Gemini Live API
  Future<void> connect() async {
    if (_isConnected) {
      debugPrint('[GeminiLiveService] Already connected.');
      return;
    }

    try {
      debugPrint('[GeminiLiveService] Connecting...');
      // Updated WebSocket URL for Gemini multimodal live API to v1beta
      final wsUrl =
          'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key=$apiKey';

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _isConnected = true;
      _connectionController.add(true);
      debugPrint(
          '[GeminiLiveService] WebSocket channel created. Sending setup message...');

      // Send initial setup message
      await _sendSetupMessage();

      // Listen for incoming messages
      _channel!.stream.listen(
        (message) {
          // No need to print raw message here, _handleMessage will do it.
          _handleMessage(message);
        },
        onError: (error) {
          debugPrint('[GeminiLiveService] WebSocket error: $error');
          _handleDisconnect();
          _errorController.add('WebSocket error: $error');
        },
        onDone: () {
          debugPrint('[GeminiLiveService] WebSocket connection closed.');
          _handleDisconnect();
        },
      );
    } catch (e) {
      debugPrint('[GeminiLiveService] Connection failed: $e');
      _handleDisconnect();
      _errorController.add('Connection failed: $e');
    }
  }

  void _handleDisconnect() {
    if (_isConnected) {
      _isConnected = false;
      _connectionController.add(false);
      _errorController.add('Connection failed: Disconnected ');
    }
  }

  /// Send setup/configuration message to Gemini
  Future<void> _sendSetupMessage() async {
    if (_channel == null) return;
    try {
      final setupMessage = {
        'setup': {
          'model': 'models/$model',
          'generationConfig': {
            'responseModalities': ['TEXT'],
          },
          'systemInstruction': {
            'parts': [
              {
                'text':
                    'You are a Quran recitation assistant. Transcribe the Arabic audio accurately. Only output the transcribed Arabic text, no other language can be used.',
              }
            ]
          }
        }
      };

      final encodedMessage = jsonEncode(setupMessage);
      debugPrint('[GeminiLiveService] Sending setup: $encodedMessage');
      _channel!.sink.add(encodedMessage);
    } catch (e) {
      debugPrint('[GeminiLiveService] Setup message failed: $e');
      _errorController.add('Setup message failed: $e');
    }
  }

  /// Send audio chunk to Gemini
  Future<void> sendAudioChunk(Uint8List audioData) async {
    if (!_isConnected || _channel == null) {
      const errorMessage = 'Not connected to Gemini. Cannot send audio.';
      debugPrint('[GeminiLiveService] $errorMessage');
      // Do not add to error controller to avoid spamming the UI
      return;
    }

    try {
      // Encode audio data to base64
      final base64Audio = base64Encode(audioData);

      final audioMessage = {
        'realtimeInput': {
          'mediaChunks': [
            {'data': base64Audio, 'mimeType': 'audio/pcm;rate=16000'}
          ]
        }
      };

      _channel!.sink.add(jsonEncode(audioMessage));
    } catch (e) {
      final errorMessage = 'Failed to send audio: $e';
      debugPrint('[GeminiLiveService] $errorMessage');
      _errorController.add(errorMessage);
    }
  }

  /// Handle incoming messages from Gemini
  void _handleMessage(dynamic message) {
    try {
      String messageString;
      if (message is List<int>) {
        // Decode the message if it's a byte array
        messageString = utf8.decode(message);
      } else if (message is String) {
        messageString = message;
      } else {
        debugPrint(
            '[GeminiLiveService] Received unexpected message type: ${message.runtimeType}');
        return;
      }

      debugPrint('[GeminiLiveService] Raw message received: $messageString');
      final decoded = jsonDecode(messageString) as Map<String, dynamic>;

      // Check for server content with transcription or text response
      if (decoded.containsKey('serverContent')) {
        final serverContent = decoded['serverContent'] as Map<String, dynamic>;
        final transcription =
            GeminiTranscriptionMessage.fromJson(serverContent);

        if (transcription.text.isNotEmpty && transcription.isFinal) {
          debugPrint(
              '[GeminiLiveService] Parsed Text: "${transcription.text}", IsFinal: ${transcription.isFinal}');
          _transcriptionController.add(transcription);
        } else {
          debugPrint(
              '[GeminiLiveService] Parsed an empty transcription message.');
        }
      }

      // Handle errors
      if (decoded.containsKey('error')) {
        final errorObj = decoded['error'];
        final error = (errorObj is Map && errorObj['message'] != null)
            ? errorObj['message'].toString()
            : 'Unknown error';
        debugPrint('[GeminiLiveService] Gemini error: $error');
        _errorController.add('Gemini error: $error');
      }
    } catch (e) {
      final errorMessage = 'Message parsing error: $e';
      debugPrint('[GeminiLiveService] $errorMessage');
      _errorController.add(errorMessage);
    }
  }

  /// Disconnect from Gemini
  Future<void> disconnect() async {
    try {
      debugPrint('[GeminiLiveService] Disconnecting...');
      await _channel?.sink.close();
      _handleDisconnect();
      debugPrint('[GeminiLiveService] Disconnected.');
    } catch (e) {
      final errorMessage = 'Disconnect failed: $e';
      debugPrint('[GeminiLiveService] $errorMessage');
      _errorController.add(errorMessage);
    }
  }

  /// Check if connected
  bool get isConnected => _isConnected;

  /// Dispose resources
  void dispose() {
    disconnect();
    _transcriptionController.close();
    _errorController.close();
    _connectionController.close();
  }
}
