import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

// アプリ起動時に読み込む永続設定を利用してテーマを切り替えるためにViewModelを参照する。
import 'view_models/settings_preferences_view_model.dart';
import 'views/url_list_view.dart';

// アプリケーションエントリーポイント。初期化処理を行ってからRiverpodのProviderScopeでラップする。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja_JP');

  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Riverpodで管理している表示設定を監視し、ダークテーマ切り替えに反映する。
    final settings = ref.watch(settingsPreferencesProvider);

    // 既存のライトテーマ。Seed ColorからColorSchemeを構築してマテリアル3に適用。
    final lightScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1A73E8),
      brightness: Brightness.light,
    );

    // ダークテーマ用のColorScheme。UI全体のコントラストを確保する。
    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0B57D0),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'URL Manager',
      debugShowCheckedModeBanner: false,
      // SharedPreferencesに保存された設定値からダークテーマを強制するか判定する。
      themeMode: settings.enableDarkTheme ? ThemeMode.dark : ThemeMode.system,
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
      home: const UrlListView(),
    );
  }
}
