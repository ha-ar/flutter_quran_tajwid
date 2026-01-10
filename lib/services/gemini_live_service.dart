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
    // Handle input_transcription format (official snake_case)
    if (json.containsKey('input_transcription') &&
        json['input_transcription'] is Map) {
      final transcriptionData =
          json['input_transcription'] as Map<String, dynamic>;
      final text = transcriptionData['text'] as String? ?? '';
      final isFinal = transcriptionData['is_final'] as bool? ?? false;
      return GeminiTranscriptionMessage(
        text: text.trim(),
        isFinal: isFinal,
      );
    }

    // Handle inputTranscription format (legacy/camelCase fallback)
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

    // Handle model_turn responses format (official snake_case)
    if (json.containsKey('model_turn') && json['model_turn'] is Map) {
      final modelTurn = json['model_turn'] as Map<String, dynamic>;
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

    // Handle modelTurn responses format (legacy/camelCase fallback)
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

  /// Gemini model identifier. Defaults to a recent
  /// Gemini Flash live model but can be overridden via
  /// configuration (for example from an admin panel).
  final String model;

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

  GeminiLiveService({
    required this.apiKey,
    String? model,
  }) : model = model ?? 'gemini-2.0-flash-exp';

  /// Connect to Gemini Live API. Returns true if connection was successfully initiated.
  Future<bool> connect() async {
    _isManuallyDisconnecting = false;

    if (_isConnected) {
      debugPrint('[GeminiLiveService] Already connected.');
      return true;
    }

    try {
      debugPrint('[GeminiLiveService] Connecting to v1beta...');
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
          debugPrint(
              '[GeminiLiveService] ⬇️ Received message: ${message.toString().substring(0, message.toString().length > 200 ? 200 : message.toString().length)}...');
          _handleMessage(message);
        },
        onError: (error, stackTrace) {
          debugPrint('[GeminiLiveService] ❌ WebSocket error: $error');
          debugPrint('[GeminiLiveService] Stack trace: $stackTrace');
          _handleDisconnect();
          _errorController.add('WebSocket error: $error');
        },
        onDone: () {
          debugPrint(
              '[GeminiLiveService] 🔌 WebSocket connection closed (onDone called)');
          _handleDisconnect();
        },
        cancelOnError: false,
      );
      return true;
    } catch (e) {
      debugPrint('[GeminiLiveService] Connection failed: $e');
      _handleDisconnect();
      _errorController.add('Connection failed: $e');
      return false;
    }
  }

  void _handleDisconnect() {
    if (_isConnected) {
      _isConnected = false;
      _connectionController.add(false);
      debugPrint('[GeminiLiveService] Disconnected.');

      // Attempt to reconnect if checks pass
      _attemptReconnect();
    }
  }

  void _attemptReconnect() {
    if (_isManuallyDisconnecting) {
      debugPrint('[GeminiLiveService] Manual disconnect, not reconnecting.');
      return;
    }

    // Only reconnect if we weren't manually disconnected (channel check usually sufficient)
    // and if we have an API key.
    // For now, simple backoff or immediate retry.
    debugPrint('[GeminiLiveService] 🔄 Attempting auto-reconnect...');

    Future.delayed(const Duration(milliseconds: 500), () {
      connect().then((success) {
        if (success) {
          debugPrint('[GeminiLiveService] ✅ Reconnected successfully.');
        } else {
          debugPrint('[GeminiLiveService] ❌ Reconnect failed.');
        }
      });
    });
  }

  /// Send setup/configuration message to Gemini
  Future<void> _sendSetupMessage() async {
    if (_channel == null) return;
    try {
      final setupMessage = {
        'setup': {
          'model': 'models/$model',
          'generation_config': {
            'response_modalities': ['TEXT'],
          },
          'system_instruction': {
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
        'realtime_input': {
          'media_chunks': [
            {'data': base64Audio, 'mime_type': 'audio/pcm;rate=16000'}
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
      // Check for serverContent with transcription or text response (handle both snake_case and camelCase)
      final serverContent =
          decoded['server_content'] ?? decoded['serverContent'];
      if (serverContent != null && serverContent is Map<String, dynamic>) {
        final transcription =
            GeminiTranscriptionMessage.fromJson(serverContent);

        if (transcription.text.isNotEmpty) {
          debugPrint(
              '[GeminiLiveService] Parsed Text: "${transcription.text}", IsFinal: ${transcription.isFinal}');
          _transcriptionController.add(transcription);
        } else {
          // It's normal to receive empty messages (e.g. turnComplete), just ignore them
        }
      }

      // Handle errors
      final errorObj = decoded['error'];
      if (errorObj != null) {
        String error;
        if (errorObj is Map) {
          error = errorObj['message']?.toString() ?? 'Unknown error';
          final code = errorObj['code'];
          final status = errorObj['status'];
          debugPrint('[GeminiLiveService] ❌ Gemini error details:');
          debugPrint('  - Message: $error');
          debugPrint('  - Code: $code');
          debugPrint('  - Status: $status');
          debugPrint('  - Full error object: $errorObj');
        } else {
          error = 'Unknown error: $errorObj';
        }
        _errorController.add('Gemini error: $error');
      }
    } catch (e, stackTrace) {
      final errorMessage = 'Message parsing error: $e';
      debugPrint('[GeminiLiveService] $errorMessage');
      debugPrint('[GeminiLiveService] Stack trace: $stackTrace');
      _errorController.add(errorMessage);
    }
  }

  bool _isManuallyDisconnecting = false;

  /// Disconnect from Gemini
  Future<void> disconnect() async {
    try {
      _isManuallyDisconnecting = true;
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
