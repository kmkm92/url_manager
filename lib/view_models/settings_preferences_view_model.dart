import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// SharedPreferencesのキーは用途ごとにコメントで管理し、見通しを良くする。
const _wifiOnlyKey = 'settings_wifi_only_summaries'; // Wi-Fi接続時のみAI要約を送信する設定の保存キー。
const _dynamicTypeKey = 'settings_prefer_dynamic_type'; // Dynamic Type優先設定の保存キー。
const _darkThemeKey = 'settings_enable_dark_theme'; // ダークテーマ利用設定の保存キー。
const _startupTabKey = 'settings_startup_tab'; // アプリ起動時に表示するタブを保持する保存キー。

/// アプリの起動時タブを列挙で管理し、保存・復元を簡単にする。
enum StartupTab {
  home, // URL一覧のホームタブ。
  history, // 履歴タブ。
  settings, // 設定タブ。
}

extension StartupTabLabel on StartupTab {
  /// UIの表示名をまとめて管理する。
  String get label {
    switch (this) {
      case StartupTab.home:
        return 'ホーム';
      case StartupTab.history:
        return '履歴';
      case StartupTab.settings:
        return '設定';
    }
  }
}

@immutable
class SettingsPreferencesState {
  const SettingsPreferencesState({
    this.wifiOnlySummaries = false,
    this.preferDynamicType = true,
    this.enableDarkTheme = false,
    this.startupTab = StartupTab.home,
  });

  final bool wifiOnlySummaries; // モバイルデータを抑えるため、Wi-Fi時のみ要約を投げるかどうか。
  final bool preferDynamicType; // OSの文字サイズ指定を優先させるかどうか。
  final bool enableDarkTheme; // 常にダークテーマを使うかどうか。
  final StartupTab startupTab; // アプリ起動時に開くタブ。

  SettingsPreferencesState copyWith({
    bool? wifiOnlySummaries,
    bool? preferDynamicType,
    bool? enableDarkTheme,
    StartupTab? startupTab,
  }) {
    return SettingsPreferencesState(
      wifiOnlySummaries: wifiOnlySummaries ?? this.wifiOnlySummaries,
      preferDynamicType: preferDynamicType ?? this.preferDynamicType,
      enableDarkTheme: enableDarkTheme ?? this.enableDarkTheme,
      startupTab: startupTab ?? this.startupTab,
    );
  }
}

/// 設定の永続化と状態管理を担うStateNotifier。
class SettingsPreferencesNotifier
    extends StateNotifier<SettingsPreferencesState> {
  SettingsPreferencesNotifier() : super(const SettingsPreferencesState()) {
    _loadPreferences();
  }

  SharedPreferences? _cachedPrefs; // 何度も取得しないようキャッシュ。

  Future<SharedPreferences> get _prefs async {
    return _cachedPrefs ??= await SharedPreferences.getInstance();
  }

  /// 保存済みの値をSharedPreferencesから復元し、Stateに反映する。
  Future<void> _loadPreferences() async {
    final prefs = await _prefs;
    final startupName = prefs.getString(_startupTabKey);
    final parsedStartupTab = StartupTab.values.firstWhere(
      (tab) => tab.name == startupName,
      orElse: () => state.startupTab,
    );
    state = state.copyWith(
      wifiOnlySummaries: prefs.getBool(_wifiOnlyKey) ?? state.wifiOnlySummaries,
      preferDynamicType:
          prefs.getBool(_dynamicTypeKey) ?? state.preferDynamicType,
      enableDarkTheme: prefs.getBool(_darkThemeKey) ?? state.enableDarkTheme,
      startupTab: parsedStartupTab,
    );
  }

  /// Wi-Fi制限設定を更新し永続化する。
  Future<void> updateWifiOnlySummaries(bool enabled) async {
    state = state.copyWith(wifiOnlySummaries: enabled);
    final prefs = await _prefs;
    await prefs.setBool(_wifiOnlyKey, enabled);
  }

  /// Dynamic Type優先設定を更新し永続化する。
  Future<void> updatePreferDynamicType(bool enabled) async {
    state = state.copyWith(preferDynamicType: enabled);
    final prefs = await _prefs;
    await prefs.setBool(_dynamicTypeKey, enabled);
  }

  /// ダークテーマ利用設定を更新し永続化する。
  Future<void> updateEnableDarkTheme(bool enabled) async {
    state = state.copyWith(enableDarkTheme: enabled);
    final prefs = await _prefs;
    await prefs.setBool(_darkThemeKey, enabled);
  }

  /// 起動時に開くタブを更新し永続化する。
  Future<void> updateStartupTab(StartupTab tab) async {
    state = state.copyWith(startupTab: tab);
    final prefs = await _prefs;
    await prefs.setString(_startupTabKey, tab.name);
  }
}

/// 設定プリファレンスをWidgetツリーへ提供するためのProvider。
final settingsPreferencesProvider = StateNotifierProvider<
    SettingsPreferencesNotifier, SettingsPreferencesState>((ref) {
  return SettingsPreferencesNotifier();
});
