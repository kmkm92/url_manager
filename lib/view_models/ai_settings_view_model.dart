import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _apiKeyPreferenceKey = 'ai_api_key';
const _baseUrlPreferenceKey = 'ai_base_url';
const _modelPreferenceKey = 'ai_model';
const _endpointPreferenceKey = 'ai_endpoint_path';
const _providerPreferenceKey = 'ai_provider';

const _openAiDefaultBaseUrl = 'https://api.openai.com/v1';
const _openAiDefaultModel = 'gpt-4o-mini';
const _openAiDefaultEndpoint = '/chat/completions';

const _geminiDefaultBaseUrl = 'https://generativelanguage.googleapis.com';
const _geminiDefaultModel = 'gemini-1.5-flash';
const _geminiDefaultEndpoint =
    '/v1beta/models/gemini-1.5-flash:generateContent';

enum AiProvider { openAi, gemini }

String _defaultBaseUrlFor(AiProvider provider) {
  switch (provider) {
    case AiProvider.openAi:
      return _openAiDefaultBaseUrl;
    case AiProvider.gemini:
      return _geminiDefaultBaseUrl;
  }
}

String _defaultModelFor(AiProvider provider) {
  switch (provider) {
    case AiProvider.openAi:
      return _openAiDefaultModel;
    case AiProvider.gemini:
      return _geminiDefaultModel;
  }
}

String _defaultEndpointFor(AiProvider provider) {
  switch (provider) {
    case AiProvider.openAi:
      return _openAiDefaultEndpoint;
    case AiProvider.gemini:
      return _geminiDefaultEndpoint;
  }
}

@immutable
class AiSettings {
  const AiSettings({
    this.provider = AiProvider.openAi,
    this.apiKey = '',
    this.baseUrl = _openAiDefaultBaseUrl,
    this.model = _openAiDefaultModel,
    this.endpointPath = _openAiDefaultEndpoint,
  });

  final AiProvider provider;
  final String apiKey;
  final String baseUrl;
  final String model;
  final String endpointPath;

  bool get isConfigured =>
      apiKey.trim().isNotEmpty &&
      baseUrl.trim().isNotEmpty &&
      model.trim().isNotEmpty &&
      endpointPath.trim().isNotEmpty;

  AiSettings copyWith({
    AiProvider? provider,
    String? apiKey,
    String? baseUrl,
    String? model,
    String? endpointPath,
  }) {
    return AiSettings(
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      endpointPath: endpointPath ?? this.endpointPath,
    );
  }
}

class AiSettingsNotifier extends StateNotifier<AiSettings> {
  AiSettingsNotifier() : super(const AiSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final providerString = prefs.getString(_providerPreferenceKey);
    final provider = _parseProvider(providerString) ?? state.provider;
    final storedSettings = state.copyWith(
      provider: provider,
      apiKey: prefs.getString(_apiKeyPreferenceKey) ?? state.apiKey,
      baseUrl: prefs.getString(_baseUrlPreferenceKey) ??
          _defaultBaseUrlFor(provider),
      model: prefs.getString(_modelPreferenceKey) ??
          _defaultModelFor(provider),
      endpointPath: prefs.getString(_endpointPreferenceKey) ??
          _defaultEndpointFor(provider),
    );
    state = storedSettings;
  }

  Future<void> updateProvider(AiProvider provider) async {
    final newState = state.copyWith(
      provider: provider,
      baseUrl: _defaultBaseUrlFor(provider),
      model: _defaultModelFor(provider),
      endpointPath: _defaultEndpointFor(provider),
    );
    state = newState;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_providerPreferenceKey, provider.name);
    await prefs.setString(_baseUrlPreferenceKey, newState.baseUrl);
    await prefs.setString(_modelPreferenceKey, newState.model);
    await prefs.setString(_endpointPreferenceKey, newState.endpointPath);
  }

  Future<void> updateApiKey(String apiKey) async {
    final newState = state.copyWith(apiKey: apiKey.trim());
    state = newState;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPreferenceKey, newState.apiKey);
  }

  Future<void> updateBaseUrl(String baseUrl) async {
    final sanitized = baseUrl.trim().isEmpty
        ? _defaultBaseUrlFor(state.provider)
        : baseUrl.trim();
    final newState = state.copyWith(baseUrl: sanitized);
    state = newState;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlPreferenceKey, newState.baseUrl);
  }

  Future<void> updateModel(String model) async {
    final sanitized =
        model.trim().isEmpty ? _defaultModelFor(state.provider) : model.trim();
    final newState = state.copyWith(model: sanitized);
    state = newState;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelPreferenceKey, newState.model);
  }

  Future<void> updateEndpointPath(String endpointPath) async {
    final sanitized = endpointPath.trim().isEmpty
        ? _defaultEndpointFor(state.provider)
        : endpointPath.trim();
    final normalized = sanitized.startsWith('/') ? sanitized : '/$sanitized';
    final newState = state.copyWith(endpointPath: normalized);
    state = newState;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_endpointPreferenceKey, newState.endpointPath);
  }
}

AiProvider? _parseProvider(String? providerString) {
  if (providerString == null || providerString.isEmpty) {
    return null;
  }
  return AiProvider.values.firstWhere(
    (provider) => provider.name == providerString,
    orElse: () => AiProvider.openAi,
  );
}

final aiSettingsProvider =
    StateNotifierProvider<AiSettingsNotifier, AiSettings>((ref) {
  return AiSettingsNotifier();
});
