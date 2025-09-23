import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_manager/view_models/ai_settings_view_model.dart';
import 'package:url_manager/view_models/storage_info_view_model.dart';
import 'package:url_manager/views/ai_settings_view.dart';

/// 設定画面のルートビュー。概要カードでAI設定とストレージ状況を可視化する。
class SettingsRootView extends ConsumerWidget {
  const SettingsRootView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ThemeやTextScalerを取得してDynamic Typeに対応。
    final theme = Theme.of(context);
    final textScaler = MediaQuery.textScalerOf(context);

    // Providerから設定状況とストレージ情報を取得。
    final aiSettings = ref.watch(aiSettingsProvider);
    final storageInfo = ref.watch(storageInfoProvider);

    final missingSettings = _extractMissingSettings(aiSettings);
    final settingsCompletion =
        1 - (missingSettings.length / _totalSettingKeys);
    final normalizedSettingsCompletion =
        settingsCompletion.clamp(0.0, 1.0).toDouble();
    final lastSyncedAt = storageInfo.lastSyncedAt;
    final formattedSync = lastSyncedAt == null
        ? '未同期'
        : DateFormat.yMMMd('ja').add_Hm().format(lastSyncedAt.toLocal());

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
        children: [
          // ステータス概要を表示するカード。
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // カードタイトル。
                  Text(
                    'ステータス概要',
                    textScaler: textScaler,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // AI設定状況の説明テキスト。
                  Text(
                    aiSettings.isConfigured
                        ? 'AI設定は正常に構成されています。'
                        : 'AI設定が未完了です: ${missingSettings.join(' / ')}',
                    textScaler: textScaler,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  // 保存済みURL件数の表示。
                  Text(
                    '保存済みURL: ${storageInfo.usedEntries}件',
                    textScaler: textScaler,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  // 最終同期日時の表示。
                  Text(
                    '最終同期: $formattedSync',
                    textScaler: textScaler,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  // 不足している設定項目の進捗バー。
                  Text(
                    '不足している設定項目',
                    textScaler: textScaler,
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: normalizedSettingsCompletion,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    missingSettings.isEmpty
                        ? 'すべての必須項目が入力済みです。'
                        : '${missingSettings.length}項目が未設定です。',
                    textScaler: textScaler,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  // ストレージ使用率の進捗バー。
                  Text(
                    'ストレージ使用率',
                    textScaler: textScaler,
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: storageInfo.usageRatio,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '約${(storageInfo.usageRatio * 100).clamp(0, 100).toStringAsFixed(0)}%（${storageInfo.usedEntries}/${storageInfo.capacityEntries}件）',
                    textScaler: textScaler,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // 設定セクションのタイトル。
          Text(
            '設定',
            textScaler: textScaler,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // AI設定関連の操作カード。
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // AIサマリー設定画面へのナビゲーション。
                ListTile(
                  leading: const Icon(Icons.auto_awesome),
                  title: Text(
                    'AIサマリー設定',
                    textScaler: textScaler,
                    style: theme.textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'モデル・エンドポイント・生成粒度を調整',
                    textScaler: textScaler,
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AiSettingsView(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                // Wi-Fi時のみ要約リクエスト設定。
                SwitchListTile.adaptive(
                  value: true,
                  onChanged: (_) {},
                  title: Text(
                    'Wi-Fi時のみ要約リクエスト',
                    textScaler: textScaler,
                    style: theme.textTheme.titleSmall,
                  ),
                  subtitle: Text(
                    '通信量を抑えたいときに有効化',
                    textScaler: textScaler,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                // Dynamic Type優先設定。
                SwitchListTile.adaptive(
                  value: true,
                  onChanged: (_) {},
                  title: Text(
                    'Dynamic Typeを優先',
                    textScaler: textScaler,
                    style: theme.textTheme.titleSmall,
                  ),
                  subtitle: Text(
                    'OSの文字サイズ設定に追従',
                    textScaler: textScaler,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // その他設定項目のカード。
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // 通知設定への誘導。
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: Text(
                    '通知',
                    textScaler: textScaler,
                    style: theme.textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    '朝のダイジェストと未読リマインダをカスタマイズ',
                    textScaler: textScaler,
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
                const Divider(height: 1),
                // インポート/エクスポート設定への誘導。
                ListTile(
                  leading: const Icon(Icons.import_export),
                  title: Text(
                    'インポート / エクスポート',
                    textScaler: textScaler,
                    style: theme.textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'BookmarksやCSVから取り込み、MD/JSONで書き出し',
                    textScaler: textScaler,
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
                const Divider(height: 1),
                // プライバシー設定への誘導。
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(
                    'プライバシー',
                    textScaler: textScaler,
                    style: theme.textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'ローカル保存と暗号化ポリシーを確認',
                    textScaler: textScaler,
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // バージョン情報。
          Text(
            'バージョン 1.0.0\nローカル保存専用 - App Group対応',
            textScaler: textScaler,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  static const int _totalSettingKeys = 4;

  /// AI設定の未入力項目を抽出するヘルパー。
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
