import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_manager/view_models/ai_settings_view_model.dart';
import 'package:url_manager/view_models/storage_info_view_model.dart';

/// ステータス概要の詳細情報を一覧表示する画面。
class StatusOverviewView extends ConsumerWidget {
  const StatusOverviewView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dynamic Typeに追従するためTextScalerを取得する。
    final textScaler = MediaQuery.textScalerOf(context);
    final theme = Theme.of(context);

    // ProviderからAI設定とストレージ情報を取得する。
    final aiSettings = ref.watch(aiSettingsProvider);
    final storageInfo = ref.watch(storageInfoProvider);

    final missingSettings = _extractMissingSettings(aiSettings);
    const totalSettingKeys = 4;
    final settingsCompletion =
        1 - (missingSettings.length / totalSettingKeys);
    final normalizedSettingsCompletion =
        settingsCompletion.clamp(0.0, 1.0).toDouble();
    final lastSyncedAt = storageInfo.lastSyncedAt;
    final formattedSync = lastSyncedAt == null
        ? '未同期'
        : DateFormat.yMMMd('ja').add_Hm().format(lastSyncedAt.toLocal());

    return Scaffold(
      appBar: AppBar(
        // 画面タイトル。戻る操作を提供するAppBar。
        title: Text(
          'ステータス概要',
          textScaler: textScaler,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AI設定状況の説明テキスト。
                  Text(
                    aiSettings.isConfigured
                        ? 'AI設定は正常に構成されています。'
                        : 'AI設定が未完了です。',
                    textScaler: textScaler,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  // 不足している設定項目の詳細リスト。
                  if (missingSettings.isNotEmpty)
                    Text(
                      '未完了の項目: ${missingSettings.join(' / ')}',
                      textScaler: textScaler,
                      style: theme.textTheme.bodySmall,
                    ),
                  if (missingSettings.isEmpty)
                    Text(
                      '全ての必須項目が入力済みです。',
                      textScaler: textScaler,
                      style: theme.textTheme.bodySmall,
                    ),
                  const SizedBox(height: 16),
                  // 設定項目の進捗バー。
                  Text(
                    '設定完了率',
                    textScaler: textScaler,
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: normalizedSettingsCompletion,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '約${(normalizedSettingsCompletion * 100).toStringAsFixed(0)}%が完了しています。',
                    textScaler: textScaler,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  // ストレージ状況の見出し。
                  Text(
                    'ストレージ使用状況',
                    textScaler: textScaler,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  // 保存済みURL件数と最終同期日時。
                  Text(
                    '保存済みURL: ${storageInfo.usedEntries}/${storageInfo.capacityEntries}件',
                    textScaler: textScaler,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '最終同期: $formattedSync',
                    textScaler: textScaler,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  // 使用率の進捗バー。
                  Text(
                    'ストレージ使用率',
                    textScaler: textScaler,
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: storageInfo.usageRatio,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '約${(storageInfo.usageRatio * 100).clamp(0, 100).toStringAsFixed(0)}%を使用中です。',
                    textScaler: textScaler,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// AI設定の未完了項目を抽出するヘルパー。
  List<String> _extractMissingSettings(AiSettings settings) {
    final missing = <String>[];
    if (settings.apiKey.trim().isEmpty) {
      missing.add('APIキー');
    }
    if (settings.baseUrl.trim().isEmpty) {
      missing.add('ベースURL');
    }
    if (settings.model.trim().isEmpty) {
      missing.add('モデル');
    }
    if (settings.endpointPath.trim().isEmpty) {
      missing.add('エンドポイント');
    }
    return missing;
  }
}
