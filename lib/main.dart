import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app_theme.dart';
import 'view_models/settings_preferences_view_model.dart';
import 'views/url_list_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja_JP');

  runApp(
    ProviderScope(
      child: const MyApp(),
    ),
  );
}

/// アプリ全体のテーマとルート画面を提供するウィジェット。
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 設定ViewModelからダークテーマ設定を購読し、テーマモードを即時反映させる。
    final settings = ref.watch(settingsPreferencesProvider);

    return MaterialApp(
      title: 'URL Manager',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: settings.themeMode,
      home: const UrlListView(),
    );
  }
}
