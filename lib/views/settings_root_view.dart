import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_manager/view_models/settings_preferences_view_model.dart';
// import 'package:url_manager/view_models/ai_settings_view_model.dart';
// import 'package:url_manager/views/ai_settings_view.dart';
// import 'package:url_manager/views/status_overview_view.dart';
// ↑ AI関連の画面は最初のリリースで提供しないため、依存関係をコメントアウトしておく。

/// 設定画面のルートビュー。概要カードでAI設定とストレージ状況を可視化する。
class SettingsRootView extends ConsumerWidget {
  const SettingsRootView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ThemeやTextScalerを取得してDynamic Typeに対応。
    final theme = Theme.of(context);
    final textScaler = MediaQuery.textScalerOf(context);

    // Providerから個人設定を取得。
    final settingsPreferences =
        ref.watch(settingsPreferencesProvider); // 個人設定の現在値を取得。

    // 保存完了を利用者に通知するスナックバー表示用のヘルパー。
    void showSavedSnackBar(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

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
          // 設定項目のカード群。AI要約を含まない運用に合わせ、ストレージ中心の情報に絞る。
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // const Divider(height: 1),
                // ListTile(
                //   leading: const Icon(Icons.auto_awesome),
                //   title: Text(
                //     'AIサマリー設定',
                //     textScaler: textScaler,
                //     style: theme.textTheme.titleMedium,
                //   ),
                //   subtitle: Text(
                //     'モデル・エンドポイント・生成粒度を調整',
                //     textScaler: textScaler,
                //     style: theme.textTheme.bodySmall,
                //   ),
                //   trailing: const Icon(Icons.chevron_right),
                //   onTap: () {
                //     Navigator.of(context).push(
                //       MaterialPageRoute(
                //         builder: (_) => const AiSettingsView(),
                //       ),
                //     );
                //   },
                // ),
                // const Divider(height: 1),
                // SwitchListTile.adaptive(
                //   value: settingsPreferences.wifiOnlySummaries,
                //   onChanged: (value) async {
                //     await ref
                //         .read(settingsPreferencesProvider.notifier)
                //         .updateWifiOnlySummaries(value);
                //     if (!context.mounted) {
                //       return;
                //     }
                //     showSavedSnackBar('通信設定を保存しました');
                //   },
                //   title: Text(
                //     'Wi-Fi時のみ要約リクエスト',
                //     textScaler: textScaler,
                //     style: theme.textTheme.titleSmall,
                //   ),
                //   subtitle: Text(
                //     settingsPreferences.wifiOnlySummaries
                //         ? 'Wi-Fi接続時のみAI要約リクエストを送信します'
                //         : 'モバイルデータ通信でもAI要約リクエストを送信します',
                //     textScaler: textScaler,
                //     style: theme.textTheme.bodySmall,
                //   ),
                // ),
                // ↑ AI要約に紐づく設定項目は将来復活させる想定でコメントアウトし、UIから隠している。
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
                const Divider(height: 1),
                // 削除確認ダイアログのスキップ設定。
                SwitchListTile.adaptive(
                  value: settingsPreferences.skipDeleteConfirm,
                  onChanged: (value) async {
                    await ref
                        .read(settingsPreferencesProvider.notifier)
                        .updateSkipDeleteConfirm(value);
                    if (!context.mounted) {
                      return;
                    }
                    showSavedSnackBar('削除確認設定を保存しました');
                  },
                  title: Text(
                    '削除時に確認を表示しない',
                    textScaler: textScaler,
                    style: theme.textTheme.titleSmall,
                  ),
                  subtitle: Text(
                    settingsPreferences.skipDeleteConfirm
                        ? '確認なしで直接削除します'
                        : '削除前に確認ダイアログを表示します',
                    textScaler: textScaler,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                // 共有保存後のリダイレクト設定。
                SwitchListTile.adaptive(
                  value: settingsPreferences.shouldRedirectAfterShare,
                  onChanged: (value) async {
                    await ref
                        .read(settingsPreferencesProvider.notifier)
                        .updateRedirectAfterShare(value);
                    if (!context.mounted) {
                      return;
                    }
                    showSavedSnackBar('共有設定を保存しました');
                  },
                  title: Text(
                    '保存後にアプリを開く',
                    textScaler: textScaler,
                    style: theme.textTheme.titleSmall,
                  ),
                  subtitle: Text(
                    settingsPreferences.shouldRedirectAfterShare
                        ? '共有完了時に自動でアプリを開きます'
                        : '共有完了後も元のアプリにとどまります',
                    textScaler: textScaler,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          // バージョン情報。
          Text(
            'バージョン 1.0.0',
            textScaler: textScaler,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  // List<String> _extractMissingSettings(AiSettings settings) {
  //   final missing = <String>[];
  //   if (settings.apiKey.trim().isEmpty) {
  //     missing.add('APIキー');
  //   }
  //   if (settings.baseUrl.trim().isEmpty) {
  //     missing.add('ベースURL');
  //   }
  //   if (settings.model.trim().isEmpty) {
  //     missing.add('モデル');
  //   }
  //   if (settings.endpointPath.trim().isEmpty) {
  //     missing.add('エンドポイント');
  //   }
  //   return missing;
  // }
  // ↑ AI設定の検証ロジックも利用箇所がなくなったため一時的にコメントアウトして保管する。
}
