import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_manager/views/ai_settings_view.dart';

class SettingsRootView extends ConsumerWidget {
  const SettingsRootView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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
                  value: true,
                  onChanged: (_) {},
                  title: const Text('Wi-Fi時のみ要約リクエスト'),
                  subtitle: const Text('通信量を抑えたいときに有効化'),
                ),
                SwitchListTile.adaptive(
                  value: true,
                  onChanged: (_) {},
                  title: const Text('Dynamic Typeを優先'),
                  subtitle: const Text('OSの文字サイズ設定に追従'),
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
