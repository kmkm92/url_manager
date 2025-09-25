import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

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

    final lightScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1A73E8),
      brightness: Brightness.light,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1A73E8),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'URL Manager',
      debugShowCheckedModeBanner: false,
      // 明るいテーマの定義。ライトモードで利用する。
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightScheme,
        scaffoldBackgroundColor: lightScheme.surface,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: lightScheme.inverseSurface,
          contentTextStyle: TextStyle(color: lightScheme.onInverseSurface),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: lightScheme.surfaceVariant.withOpacity(0.4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: lightScheme.outlineVariant),
        ),
      ),
      // ダークテーマの定義。ユーザーが強制ダークをONにした場合に利用する。
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkScheme,
        scaffoldBackgroundColor: darkScheme.surface,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: darkScheme.inverseSurface,
          contentTextStyle: TextStyle(color: darkScheme.onInverseSurface),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkScheme.surfaceVariant.withOpacity(0.4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: darkScheme.outlineVariant),
        ),
      ),
      // ダークテーマ設定に応じてテーマモードを切り替える。
      themeMode: settings.enableDarkTheme ? ThemeMode.dark : ThemeMode.system,
      home: const UrlListView(),
    );
  }
}
