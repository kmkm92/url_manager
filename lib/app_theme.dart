// アプリ全体のテーマ定義。
// ライトテーマとダークテーマを提供する。

import 'package:flutter/material.dart';

// プレミアムな印象を与えるディープブルー/インディゴをシードカラーに採用
const Color seedColor = Color(0xFF2962FF); // Blue Accent 700

/// ライトテーマのColorScheme
final ColorScheme lightScheme = ColorScheme.fromSeed(
  seedColor: seedColor,
  brightness: Brightness.light,
  surface: const Color(0xFFF5F7FA), // ほんのりグレーがかった白で目に優しく
);

/// ダークテーマのColorScheme
final ColorScheme darkScheme = ColorScheme.fromSeed(
  seedColor: seedColor,
  brightness: Brightness.dark,
  surface: const Color(0xFF121212), // 真っ黒ではなく、深みのあるダークグレー
  surfaceContainer: const Color(0xFF1E1E1E),
);

/// ライトテーマを構築
ThemeData buildLightTheme() {
  return ThemeData(
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    splashFactory: NoSplash.splashFactory,
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    useMaterial3: true,
    colorScheme: lightScheme,
    scaffoldBackgroundColor: lightScheme.surface,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: lightScheme.surface,
      surfaceTintColor: Colors.transparent, // スクロール時の色変化を抑制
      titleTextStyle: TextStyle(
        color: lightScheme.onSurface,
        fontSize: 24,
        fontWeight: FontWeight.w700, //太字でモダンに
        letterSpacing: -0.5,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: lightScheme.outline.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF323232),
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:
            BorderSide(color: lightScheme.outline.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
            color: lightScheme.outline.withValues(alpha: 0.1), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: lightScheme.primary, width: 2),
      ),
    ),
    chipTheme: ChipThemeData(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      side: BorderSide.none,
      backgroundColor:
          lightScheme.surfaceContainerHighest.withValues(alpha: 0.3),
    ),
  );
}

/// ダークテーマを構築
ThemeData buildDarkTheme() {
  return ThemeData(
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    splashFactory: NoSplash.splashFactory,
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: darkScheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
    ),
    useMaterial3: true,
    colorScheme: darkScheme,
    scaffoldBackgroundColor: darkScheme.surface,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: darkScheme.surface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: darkScheme.onSurface,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: darkScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFFE0E0E0),
      contentTextStyle: const TextStyle(color: Colors.black87, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: darkScheme.primary, width: 2),
      ),
    ),
    chipTheme: ChipThemeData(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      side: BorderSide.none,
      backgroundColor:
          darkScheme.surfaceContainerHighest.withValues(alpha: 0.3),
    ),
  );
}
