import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// SharedPreferences に保存するキー定義。用途をコメントで明示して管理する。
const _wifiOnlySummaryKey = 'settings_wifi_only_summary'; // AI要約をWi-Fi接続時のみに制限するかどうか。
const _preferDynamicTypeKey = 'settings_prefer_dynamic_type'; // OSのDynamic Type設定に追従するかどうか。
const _darkThemeKey = 'settings_enable_dark_theme'; // アプリ全体でダークテーマを有効化するかどうか。
const _startTabKey = 'settings_start_tab'; // アプリ起動時に最初に表示するタブの識別子。

/// アプリ全体の表示や操作に関する永続設定をまとめたステート。
@immutable
class SettingsPreferencesState {
  const SettingsPreferencesState({
    this.wifiOnlySummary = false,
    this.preferDynamicType = true,
    this.enableDarkTheme = false,
    this.startTab = StartTab.inbox,
  });

  /// AI要約をWi-Fi接続時に限定するためのフラグ。
  final bool wifiOnlySummary;

  /// OSのDynamic Type（文字サイズ）設定を優先するかどうかのフラグ。
  final bool preferDynamicType;

  /// true の場合は常にダークテーマを使用し、false の場合はシステム設定に従うフラグ。
  final bool enableDarkTheme;

  /// アプリを起動した際に最初に開くタブを示す設定値。
  final StartTab startTab;

  SettingsPreferencesState copyWith({
    bool? wifiOnlySummary,
    bool? preferDynamicType,
    bool? enableDarkTheme,
    StartTab? startTab,
  }) {
    return SettingsPreferencesState(
      wifiOnlySummary: wifiOnlySummary ?? this.wifiOnlySummary,
      preferDynamicType: preferDynamicType ?? this.preferDynamicType,
      enableDarkTheme: enableDarkTheme ?? this.enableDarkTheme,
      startTab: startTab ?? this.startTab,
    );
  }
}

/// 起動時に表示するタブを表現する列挙型。ユーザーが頻繁に利用する画面を選択できるようにする。
enum StartTab {
  inbox, // 受信/最新タブ。
  favorites, // お気に入りタブ。
  tags, // タグ別一覧タブ。
}

/// UIで表示名を扱いやすくするための拡張。列挙値ごとにラベルを返す。
extension StartTabLabel on StartTab {
  String get label {
    switch (this) {
      case StartTab.inbox:
        return '最新フィード';
      case StartTab.favorites:
        return 'お気に入り';
      case StartTab.tags:
        return 'タグ';
    }
  }
}

/// SharedPreferences と連携しながら [SettingsPreferencesState] を管理する StateNotifier。
class SettingsPreferencesNotifier
    extends StateNotifier<SettingsPreferencesState> {
  SettingsPreferencesNotifier() : super(const SettingsPreferencesState()) {
    _loadPreferences();
  }

  /// 保存済みの設定を非同期に読み出し、StateNotifier に反映する。
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final storedStartTab = _parseStartTab(prefs.getString(_startTabKey));
    state = state.copyWith(
      wifiOnlySummary: prefs.getBool(_wifiOnlySummaryKey) ?? state.wifiOnlySummary,
      preferDynamicType:
          prefs.getBool(_preferDynamicTypeKey) ?? state.preferDynamicType,
      enableDarkTheme: prefs.getBool(_darkThemeKey) ?? state.enableDarkTheme,
      startTab: storedStartTab ?? state.startTab,
    );
  }

  /// Wi-Fi制限設定をトグルし、新しい状態を返す。
  Future<bool> toggleWifiOnlySummary() async {
    final newValue = !state.wifiOnlySummary;
    state = state.copyWith(wifiOnlySummary: newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wifiOnlySummaryKey, newValue);
    return newValue;
  }

  /// Dynamic Type優先設定をトグルし、新しい状態を返す。
  Future<bool> togglePreferDynamicType() async {
    final newValue = !state.preferDynamicType;
    state = state.copyWith(preferDynamicType: newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_preferDynamicTypeKey, newValue);
    return newValue;
  }

  /// ダークテーマ設定をトグルし、新しい状態を返す。
  Future<bool> toggleDarkTheme() async {
    final newValue = !state.enableDarkTheme;
    state = state.copyWith(enableDarkTheme: newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkThemeKey, newValue);
    return newValue;
  }

  /// 起動時に表示するタブを更新し、永続化する。
  Future<void> updateStartTab(StartTab tab) async {
    state = state.copyWith(startTab: tab);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_startTabKey, tab.name);
  }

  StartTab? _parseStartTab(String? raw) {
    if (raw == null) {
      return null;
    }
    return StartTab.values.firstWhere(
      (tab) => tab.name == raw,
      orElse: () => StartTab.inbox,
    );
  }
}

/// 設定カードから利用する StateNotifierProvider。UI が状態を監視できるよう公開する。
final settingsPreferencesProvider =
    StateNotifierProvider<SettingsPreferencesNotifier, SettingsPreferencesState>(
  (ref) => SettingsPreferencesNotifier(),
);
