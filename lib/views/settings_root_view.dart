import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_manager/view_models/settings_preferences_view_model.dart';

/// 設定画面のルートビュー。
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

    return SafeArea(
      bottom: false,
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
          // 設定項目のカード群。
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // ダークテーマの強制適用設定。デザインポリシーをユーザーに委ねる。
                // テーマ設定。
                ListTile(
                  leading: const Icon(Icons.brightness_6),
                  title: Text(
                    'テーマ',
                    textScaler: textScaler,
                    style: theme.textTheme.titleSmall,
                  ),
                  subtitle: Text(
                    switch (settingsPreferences.themeMode) {
                      ThemeMode.system => 'システムテーマに合わせて表示します',
                      ThemeMode.light => 'ライトモードで表示します',
                      ThemeMode.dark => 'ダークモードで表示します',
                    },
                    textScaler: textScaler,
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: DropdownButton<ThemeMode>(
                    value: settingsPreferences.themeMode,
                    onChanged: (mode) async {
                      if (mode == null) {
                        return;
                      }
                      await ref
                          .read(settingsPreferencesProvider.notifier)
                          .updateThemeMode(mode);
                    },
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('システム設定に従う'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('ライトモード'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('ダークモード'),
                      ),
                    ],
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
        ],
      ),
    );
  }
}
