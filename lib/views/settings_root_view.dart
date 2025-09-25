import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_manager/view_models/ai_settings_view_model.dart';
import 'package:url_manager/view_models/settings_preferences_view_model.dart';
import 'package:url_manager/view_models/storage_info_view_model.dart';
import 'package:url_manager/views/ai_settings_view.dart';
import 'package:url_manager/views/status_overview_view.dart';

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
    final settingsPreferences =
        ref.watch(settingsPreferencesProvider); // 個人設定の現在値を取得。

    // 保存完了を利用者に通知するスナックバー表示用のヘルパー。
    void showSavedSnackBar(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    final missingSettings = _extractMissingSettings(aiSettings);
    final lastSyncedAt = storageInfo.lastSyncedAt;
    final formattedSync = lastSyncedAt == null
        ? '未同期'
        : DateFormat.yMMMd('ja').add_Hm().format(lastSyncedAt.toLocal());

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
        children: [
          // 設定セクションのタイトル。
          Text(
            '設定',
            textScaler: textScaler,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // 設定項目のカード群。ステータス概要も一項目として含める。
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // 設定群のトップとしてステータス概要画面への遷移を提供するタイル。
                ListTile(
                  leading: const Icon(Icons.dashboard_outlined),
                  title: Text(
                    'ステータス概要',
                    textScaler: textScaler,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  isThreeLine: true,
                  subtitle: Text(
                    aiSettings.isConfigured
                        ? 'AI設定は完了・保存URL ${storageInfo.usedEntries}件\n最終同期: $formattedSync'
                        : 'AI設定未完了（${missingSettings.join(' / ')}）\n最終同期: $formattedSync',
                    textScaler: textScaler,
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // 詳細なステータスを確認できる画面へ遷移する。
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const StatusOverviewView(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                // AI設定関連の操作項目。
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
                // Wi-Fi時のみ要約リクエスト設定。StateNotifierの値と同期させる。
                SwitchListTile.adaptive(
                  value: settingsPreferences.wifiOnlySummaries,
                  onChanged: (value) async {
                    await ref
                        .read(settingsPreferencesProvider.notifier)
                        .updateWifiOnlySummaries(value);
                    if (!context.mounted) {
                      return;
                    }
                    showSavedSnackBar('通信設定を保存しました');
                  },
                  title: Text(
                    'Wi-Fi時のみ要約リクエスト',
                    textScaler: textScaler,
                    style: theme.textTheme.titleSmall,
                  ),
                  subtitle: Text(
                    settingsPreferences.wifiOnlySummaries
                        ? 'Wi-Fi接続時のみAI要約リクエストを送信します'
                        : 'モバイルデータ通信でもAI要約リクエストを送信します',
                    textScaler: textScaler,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                // Dynamic Type優先設定。メディアクエリとの整合を保つ。
                SwitchListTile.adaptive(
                  value: settingsPreferences.preferDynamicType,
                  onChanged: (value) async {
                    await ref
                        .read(settingsPreferencesProvider.notifier)
                        .updatePreferDynamicType(value);
                    if (!context.mounted) {
                      return;
                    }
                    showSavedSnackBar('文字サイズ設定を保存しました');
                  },
                  title: Text(
                    'Dynamic Typeを優先',
                    textScaler: textScaler,
                    style: theme.textTheme.titleSmall,
                  ),
                  subtitle: Text(
                    settingsPreferences.preferDynamicType
                        ? 'OSの文字サイズ設定に追従します'
                        : 'アプリ独自のタイポグラフィを優先します',
                    textScaler: textScaler,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                // ダークテーマの強制適用設定。デザインポリシーをユーザーに委ねる。
                SwitchListTile.adaptive(
                  value: settingsPreferences.enableDarkTheme,
                  onChanged: (value) async {
                    await ref
                        .read(settingsPreferencesProvider.notifier)
                        .updateEnableDarkTheme(value);
                    if (!context.mounted) {
                      return;
                    }
                    showSavedSnackBar('テーマ設定を保存しました');
                  },
                  title: Text(
                    '常にダークテーマを使用',
                    textScaler: textScaler,
                    style: theme.textTheme.titleSmall,
                  ),
                  subtitle: Text(
                    settingsPreferences.enableDarkTheme
                        ? '常時ダークテーマで表示します'
                        : 'システムテーマに合わせて表示します',
                    textScaler: textScaler,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const Divider(height: 1),
                // 起動時に表示するタブ設定。Dropdownで即時保存する。
                ListTile(
                  leading: const Icon(Icons.tab),
                  title: Text(
                    '起動時に開くタブ',
                    textScaler: textScaler,
                    style: theme.textTheme.titleSmall,
                  ),
                  subtitle: Text(
                    '${settingsPreferences.startupTab.label}を既定で表示します',
                    textScaler: textScaler,
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: DropdownButton<StartupTab>(
                    value: settingsPreferences.startupTab,
                    onChanged: (tab) async {
                      if (tab == null) {
                        return;
                      }
                      await ref
                          .read(settingsPreferencesProvider.notifier)
                          .updateStartupTab(tab);
                      if (!context.mounted) {
                        return;
                      }
                      showSavedSnackBar('起動タブ設定を保存しました');
                    },
                    items: StartupTab.values
                        .map(
                          (tab) => DropdownMenuItem<StartupTab>(
                            value: tab,
                            child: Text(tab.label),
                          ),
                        )
                        .toList(),
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
