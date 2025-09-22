import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_manager/view_models/ai_settings_view_model.dart';

@immutable
class SummaryRequest {
  const SummaryRequest({
    required this.url,
    required this.title,
  });

  final String url;
  final String title;

  @override
  int get hashCode => Object.hash(url, title);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is SummaryRequest && other.url == url && other.title == title;
  }
}

class SummaryGenerationException implements Exception {
  SummaryGenerationException(this.message);
  final String message;

  @override
  String toString() => 'SummaryGenerationException: $message';
}

Uri _buildEndpointUri(String baseUrl, String endpointPath) {
  final trimmedBase = baseUrl.trim().endsWith('/')
      ? baseUrl.trim().substring(0, baseUrl.trim().length - 1)
      : baseUrl.trim();
  final sanitizedPath = endpointPath.trim().startsWith('/')
      ? endpointPath.trim().substring(1)
      : endpointPath.trim();
  return Uri.parse('$trimmedBase/$sanitizedPath');
}

Future<String> _requestSummary(
  AiSettings settings,
  SummaryRequest request,
) async {
  switch (settings.provider) {
    case AiProvider.openAi:
      return _requestOpenAiSummary(settings, request);
    case AiProvider.gemini:
      return _requestGeminiSummary(settings, request);
  }
}

Future<String> _requestOpenAiSummary(
  AiSettings settings,
  SummaryRequest request,
) async {
  final endpoint = _buildEndpointUri(settings.baseUrl, settings.endpointPath);

  final payload = <String, dynamic>{
    'model': settings.model,
    'messages': [
      {
        'role': 'system',
        'content':
            'You are an assistant that creates concise markdown summaries in Japanese.',
      },
      {
        'role': 'user',
        'content':
            '次のURLの内容を短く要約してください。要約はMarkdown形式で出力し、重要なポイントを箇条書きで示してください。URL: ${request.url}\n\n参考情報: ${request.title}',
      },
    ],
    'temperature': 0.3,
  };

  http.Response response;
  try {
    response = await http
        .post(
          endpoint,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${settings.apiKey}',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 60));
  } on TimeoutException {
    throw SummaryGenerationException('リクエストがタイムアウトしました。通信環境を確認してください。');
  } catch (error) {
    throw SummaryGenerationException('要約リクエストの送信に失敗しました: $error');
  }

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw SummaryGenerationException(
        '要約の取得に失敗しました (status: ${response.statusCode}). ${response.body}');
  }

  try {
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = decoded['choices'];
    if (choices is List && choices.isNotEmpty) {
      final firstChoice = choices.first;
      if (firstChoice is Map<String, dynamic>) {
        final message = firstChoice['message'];
        if (message is Map<String, dynamic>) {
          final content = message['content'];
          if (content is String && content.trim().isNotEmpty) {
            return content.trim();
          }
        }
        final text = firstChoice['text'];
        if (text is String && text.trim().isNotEmpty) {
          return text.trim();
        }
      }
    }
  } catch (error) {
    throw SummaryGenerationException('レスポンスの解析に失敗しました: $error');
  }

  throw SummaryGenerationException('要約結果が取得できませんでした。');
}

Future<String> _requestGeminiSummary(
  AiSettings settings,
  SummaryRequest request,
) async {
  final endpoint = _buildEndpointUri(settings.baseUrl, settings.endpointPath);
  final queryParameters = {
    ...endpoint.queryParameters,
    'key': settings.apiKey,
  };
  final uri = endpoint.replace(queryParameters: queryParameters);

  final payload = <String, dynamic>{
    'systemInstruction': {
      'role': 'system',
      'parts': [
        {
          'text':
              'You are an assistant that creates concise markdown summaries in Japanese.',
        },
      ],
    },
    'contents': [
      {
        'role': 'user',
        'parts': [
          {
            'text':
                '次のURLの内容を短く要約してください。要約はMarkdown形式で出力し、重要なポイントを箇条書きで示してください。URL: ${request.url}\n\n参考情報: ${request.title}',
          },
        ],
      },
    ],
    'generationConfig': {
      'temperature': 0.3,
      'candidateCount': 1,
    },
  };

  http.Response response;
  try {
    response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 60));
  } on TimeoutException {
    throw SummaryGenerationException('リクエストがタイムアウトしました。通信環境を確認してください。');
  } catch (error) {
    throw SummaryGenerationException('要約リクエストの送信に失敗しました: $error');
  }

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw SummaryGenerationException(
        '要約の取得に失敗しました (status: ${response.statusCode}). ${response.body}');
  }

  try {
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = decoded['candidates'];
    if (candidates is List && candidates.isNotEmpty) {
      final firstCandidate = candidates.first;
      if (firstCandidate is Map<String, dynamic>) {
        final content = firstCandidate['content'];
        if (content is Map<String, dynamic>) {
          final parts = content['parts'];
          if (parts is List) {
            for (final part in parts) {
              if (part is Map<String, dynamic>) {
                final text = part['text'];
                if (text is String && text.trim().isNotEmpty) {
                  return text.trim();
                }
              }
            }
          }
        }
      }
    }
  } catch (error) {
    throw SummaryGenerationException('レスポンスの解析に失敗しました: $error');
  }

  throw SummaryGenerationException('要約結果が取得できませんでした。');
}

const _summaryCacheStorageKey = 'url_summary_cache_entries';

class SummaryCacheNotifier
    extends StateNotifier<Map<SummaryRequest, AsyncValue<String>>> {
  SummaryCacheNotifier(this._ref) : super(const {}) {
    _restoreCache();
  }

  final Ref _ref;

  Future<void> _restoreCache() async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = prefs.getString(_summaryCacheStorageKey);
    if (serialized == null || serialized.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(serialized);
      if (decoded is! List) {
        return;
      }

      final restoredEntries = <SummaryRequest, AsyncValue<String>>{};
      for (final entry in decoded) {
        if (entry is! Map<String, dynamic>) {
          continue;
        }
        final url = entry['url'];
        final title = entry['title'];
        final summary = entry['summary'];
        if (url is String &&
            url.isNotEmpty &&
            title is String &&
            title.isNotEmpty &&
            summary is String &&
            summary.isNotEmpty) {
          restoredEntries[SummaryRequest(url: url, title: title)] =
              AsyncValue<String>.data(summary);
        }
      }

      if (restoredEntries.isNotEmpty) {
        state = {
          ...state,
          ...restoredEntries,
        };
      }
    } catch (_) {
      // Ignore any cache restoration failures and continue with an empty cache.
    }
  }

  Future<void> _persistCurrentSummaries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entries = state.entries
          .where((entry) => entry.value is AsyncData<String>)
          .map((entry) {
        final summaryValue = (entry.value as AsyncData<String>).value;
        return <String, dynamic>{
          'url': entry.key.url,
          'title': entry.key.title,
          'summary': summaryValue,
        };
      }).toList(growable: false);

      await prefs.setString(_summaryCacheStorageKey, jsonEncode(entries));
    } catch (_) {
      // Ignore persistence errors; the in-memory cache will still be available.
    }
  }

  Future<void> loadSummary(
    SummaryRequest request, {
    bool forceRefresh = false,
  }) async {
    final existing = state[request];
    if (!forceRefresh && existing is AsyncData<String>) {
      return;
    }

    final previousData = existing;

    state = {
      ...state,
      request: const AsyncValue<String>.loading(),
    };

    try {
      final settings = _ref.read(aiSettingsProvider);
      if (!settings.isConfigured) {
        throw SummaryGenerationException(
            'AIの設定が完了していません。設定画面からAPIキー、ベースURL、エンドポイント、モデルを入力してください。');
      }

      final summary = await _requestSummary(settings, request);
      state = {
        ...state,
        request: AsyncValue<String>.data(summary),
      };
      await _persistCurrentSummaries();
    } catch (error, stackTrace) {
      if (previousData is AsyncData<String>) {
        state = {
          ...state,
          request: previousData,
        };
        return;
      }
      state = {
        ...state,
        request: AsyncValue<String>.error(error, stackTrace),
      };
    }
  }
}

final summaryCacheProvider = StateNotifierProvider<SummaryCacheNotifier,
    Map<SummaryRequest, AsyncValue<String>>>((ref) {
  return SummaryCacheNotifier(ref);
});
