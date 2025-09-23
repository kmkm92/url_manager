import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_manager/view_models/settings_preferences_view_model.dart';
import 'package:url_manager/views/ai_settings_view.dart';

class SettingsRootView extends ConsumerWidget {
  const SettingsRootView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // アプリ全体の操作系設定をRiverpod経由で監視し、UIのトグルと同期させる。
    final settings = ref.watch(settingsPreferencesProvider);

    // 設定が変更された際に即座にフィードバックできるようSnackBar表示用の関数を用意。
    void showPreferenceSavedMessage(String message) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(message)),
        );
    }
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
        children: [
          Text(
            '設定',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.auto_awesome),
                  title: const Text('AIサマリー設定'),
                  subtitle: const Text('モデル・エンドポイント・生成粒度を調整'),
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
                SwitchListTile.adaptive(
                  // Wi-Fi接続時のみAI要約を実行する設定。StateNotifierの値と同期。
                  value: settings.wifiOnlySummary,
                  onChanged: (_) async {
                    final enabled = await ref
                        .read(settingsPreferencesProvider.notifier)
                        .toggleWifiOnlySummary();
                    showPreferenceSavedMessage(
                      enabled
                          ? 'Wi-Fi接続時のみAI要約を実行します'
                          : 'モバイル回線でもAI要約を実行します',
                    );
                  },
                  title: const Text('Wi-Fi時のみ要約リクエスト'),
                  subtitle: Text(
                    settings.wifiOnlySummary
                        ? '通信量を抑えるためWi-Fi接続時のみAI要約を実行'
                        : 'モバイル回線でもAI要約を実行して素早く要約取得',
                  ),
                ),
                SwitchListTile.adaptive(
                  // Dynamic Type優先設定。アクセシビリティ対応のためのトグル。
                  value: settings.preferDynamicType,
                  onChanged: (_) async {
                    final enabled = await ref
                        .read(settingsPreferencesProvider.notifier)
                        .togglePreferDynamicType();
                    showPreferenceSavedMessage(
                      enabled
                          ? 'OSの文字サイズ設定に合わせて表示します'
                          : 'アプリ既定の文字サイズで表示します',
                    );
                  },
                  title: const Text('Dynamic Typeを優先'),
                  subtitle: Text(
                    settings.preferDynamicType
                        ? 'OSの文字サイズ設定に追従して可読性を確保'
                        : 'アプリ内の固定フォントサイズを使用',
                  ),
                ),
                SwitchListTile.adaptive(
                  // アプリ全体のダークテーマ有効化設定。
                  value: settings.enableDarkTheme,
                  onChanged: (_) async {
                    final enabled = await ref
                        .read(settingsPreferencesProvider.notifier)
                        .toggleDarkTheme();
                    showPreferenceSavedMessage(
                      enabled
                          ? '常にダークテーマで表示します'
                          : 'システム設定に合わせたテーマで表示します',
                    );
                  },
                  title: const Text('ダークテーマを常に使用'),
                  subtitle: Text(
                    settings.enableDarkTheme
                        ? '夜間や暗所で見やすいダークテーマを固定'
                        : 'システムテーマに追従して表示を自動調整',
                  ),
                ),
                ListTile(
                  // 起動時に開くタブを選択する設定。DropdownでRiverpod状態と同期。
                  title: const Text('起動時の表示タブ'),
                  subtitle: Text('現在: ${settings.startTab.label}'),
                  trailing: DropdownButton<StartTab>(
                    value: settings.startTab,
                    onChanged: (value) async {
                      if (value == null) {
                        return;
                      }
                      await ref
                          .read(settingsPreferencesProvider.notifier)
                          .updateStartTab(value);
                      showPreferenceSavedMessage(
                        '起動時に「${value.label}」タブを表示します',
                      );
                    },
                    items: StartTab.values
                        .map(
                          (tab) => DropdownMenuItem<StartTab>(
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
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(Icons.notifications_outlined),
                  title: Text('通知'),
                  subtitle: Text('朝のダイジェストと未読リマインダをカスタマイズ'),
                  trailing: Icon(Icons.chevron_right),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.import_export),
                  title: Text('インポート / エクスポート'),
                  subtitle: Text('BookmarksやCSVから取り込み、MD/JSONで書き出し'),
                  trailing: Icon(Icons.chevron_right),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.privacy_tip_outlined),
                  title: Text('プライバシー'),
                  subtitle: Text('ローカル保存と暗号化ポリシーを確認'),
                  trailing: Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'バージョン 1.0.0\nローカル保存専用 - App Group対応',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
