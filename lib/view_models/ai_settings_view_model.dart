import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _apiKeyPreferenceKey = 'ai_api_key';
const _baseUrlPreferenceKey = 'ai_base_url';
const _modelPreferenceKey = 'ai_model';
const _endpointPreferenceKey = 'ai_endpoint_path';

@immutable
class AiSettings {
  const AiSettings({
    this.apiKey = '',
    this.baseUrl = 'https://api.openai.com/v1',
    this.model = 'gpt-4o-mini',
    this.endpointPath = '/chat/completions',
  });

  final String apiKey;
  final String baseUrl;
  final String model;
  final String endpointPath;

  bool get isConfigured =>
      apiKey.trim().isNotEmpty && baseUrl.trim().isNotEmpty && model.trim().isNotEmpty;

  AiSettings copyWith({
    String? apiKey,
    String? baseUrl,
    String? model,
    String? endpointPath,
  }) {
    return AiSettings(
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
    final storedSettings = state.copyWith(
      apiKey: prefs.getString(_apiKeyPreferenceKey) ?? state.apiKey,
      baseUrl: prefs.getString(_baseUrlPreferenceKey) ?? state.baseUrl,
      model: prefs.getString(_modelPreferenceKey) ?? state.model,
      endpointPath:
          prefs.getString(_endpointPreferenceKey) ?? state.endpointPath,
    );
    state = storedSettings;
  }

  Future<void> updateApiKey(String apiKey) async {
    final newState = state.copyWith(apiKey: apiKey.trim());
    state = newState;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPreferenceKey, newState.apiKey);
  }

  Future<void> updateBaseUrl(String baseUrl) async {
    final sanitized = baseUrl.trim().isEmpty
        ? const AiSettings().baseUrl
        : baseUrl.trim();
    final newState = state.copyWith(baseUrl: sanitized);
    state = newState;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlPreferenceKey, newState.baseUrl);
  }

  Future<void> updateModel(String model) async {
    final sanitized = model.trim().isEmpty ? state.model : model.trim();
    final newState = state.copyWith(model: sanitized);
    state = newState;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelPreferenceKey, newState.model);
  }

  Future<void> updateEndpointPath(String endpointPath) async {
    final sanitized = endpointPath.trim().isEmpty
        ? const AiSettings().endpointPath
        : endpointPath.trim();
    final normalized = sanitized.startsWith('/') ? sanitized : '/$sanitized';
    final newState = state.copyWith(endpointPath: normalized);
    state = newState;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_endpointPreferenceKey, newState.endpointPath);
  }
}

final aiSettingsProvider =
    StateNotifierProvider<AiSettingsNotifier, AiSettings>((ref) {
  return AiSettingsNotifier();
});
