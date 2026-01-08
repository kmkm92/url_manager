import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_manager/view_models/settings_preferences_view_model.dart';

/// 設定画面のルートビュー。
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
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showThemeSelectionSheet(
                      context,
                      ref,
                      settingsPreferences.themeMode,
                    );
                  },
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
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showStartupTabSelectionSheet(
                      context,
                      ref,
                      settingsPreferences.startupTab,
                    );
                  },
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
                  value: !settingsPreferences.shouldRedirectAfterShare,
                  onChanged: (value) async {
                    await ref
                        .read(settingsPreferencesProvider.notifier)
                        .updateRedirectAfterShare(!value);
                  },
                  title: Text(
                    '保存後に元のアプリにとどまる',
                    textScaler: textScaler,
                    style: theme.textTheme.titleSmall,
                  ),
                  subtitle: Text(
                    !settingsPreferences.shouldRedirectAfterShare
                        ? '共有完了後も元のアプリにとどまります'
                        : '共有完了時に自動でアプリを開きます',
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

  void _showThemeSelectionSheet(
    BuildContext context,
    WidgetRef ref,
    ThemeMode currentMode,
  ) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Text(
                  'テーマを選択',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              _ThemeOption(
                mode: ThemeMode.system,
                label: 'システム設定に従う',
                isSelected: currentMode == ThemeMode.system,
                onSelected: (mode) {
                  ref
                      .read(settingsPreferencesProvider.notifier)
                      .updateThemeMode(mode);
                  Navigator.pop(context);
                },
              ),
              _ThemeOption(
                mode: ThemeMode.light,
                label: 'ライトモード',
                isSelected: currentMode == ThemeMode.light,
                onSelected: (mode) {
                  ref
                      .read(settingsPreferencesProvider.notifier)
                      .updateThemeMode(mode);
                  Navigator.pop(context);
                },
              ),
              _ThemeOption(
                mode: ThemeMode.dark,
                label: 'ダークモード',
                isSelected: currentMode == ThemeMode.dark,
                onSelected: (mode) {
                  ref
                      .read(settingsPreferencesProvider.notifier)
                      .updateThemeMode(mode);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showStartupTabSelectionSheet(
    BuildContext context,
    WidgetRef ref,
    StartupTab currentTab,
  ) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Text(
                  '起動時に開くタブを選択',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              for (final tab in StartupTab.values)
                _TabOption(
                  tab: tab,
                  isSelected: currentTab == tab,
                  onSelected: (t) {
                    ref
                        .read(settingsPreferencesProvider.notifier)
                        .updateStartupTab(t);
                    Navigator.pop(context);
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.mode,
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  final ThemeMode mode;
  final String label;
  final bool isSelected;
  final ValueChanged<ThemeMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: theme.colorScheme.primary)
          : null,
      onTap: () => onSelected(mode),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}

class _TabOption extends StatelessWidget {
  const _TabOption({
    required this.tab,
    required this.isSelected,
    required this.onSelected,
  });

  final StartupTab tab;
  final bool isSelected;
  final ValueChanged<StartupTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(
        tab.label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: theme.colorScheme.primary)
          : null,
      onTap: () => onSelected(tab),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}
