enum LlmProvider {
  gemini,
  // Future providers (openai, etc.) can be added here.
}

/// Configuration for the LLM used by the recitation workflow.
///
/// This is designed so that it can be populated from an
/// admin/config API at runtime, while still having a
/// sensible Gemini default when no remote config exists.
class LlmConfig {
  final LlmProvider provider;

  /// Model identifier as expected by the underlying API.
  /// For Gemini this is typically something like
  /// `gemini-2.0-flash-live-001`.
  final String model;

  /// API key or token for the provider.
  final String? apiKey;

  const LlmConfig({
    required this.provider,
    required this.model,
    this.apiKey,
  });

  /// Default Gemini configuration used when there is no
  /// admin-provided config yet. The API key is injected
  /// by the caller (e.g. from environment variables).
  factory LlmConfig.geminiDefault({String? apiKey}) {
    return LlmConfig(
      provider: LlmProvider.gemini,
      model: defaultGeminiModel,
      apiKey: apiKey,
    );
  }

  static const String defaultGeminiModel = 'gemini-2.0-flash-exp';

  LlmConfig copyWith({
    LlmProvider? provider,
    String? model,
    String? apiKey,
  }) {
    return LlmConfig(
      provider: provider ?? this.provider,
      model: model ?? this.model,
      apiKey: apiKey ?? this.apiKey,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider.name,
      'model': model,
      'apiKey': apiKey,
    };
  }

  factory LlmConfig.fromJson(Map<String, dynamic> json) {
    final providerName = json['provider'] as String? ?? 'gemini';
    final provider = LlmProvider.values.firstWhere(
      (p) => p.name == providerName,
      orElse: () => LlmProvider.gemini,
    );

    return LlmConfig(
      provider: provider,
      model: json['model'] as String? ?? defaultGeminiModel,
      apiKey: json['apiKey'] as String?,
    );
  }
}
