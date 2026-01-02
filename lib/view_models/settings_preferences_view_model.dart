import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// SharedPreferencesのキーは用途ごとにコメントで管理し、見通しを良くする。
const _wifiOnlyKey =
    'settings_wifi_only_summaries'; // Wi-Fi接続時のみAI要約を送信する設定の保存キー。
const _dynamicTypeKey =
    'settings_prefer_dynamic_type'; // Dynamic Type優先設定の保存キー。
const _darkThemeKey = 'settings_enable_dark_theme'; // ダークテーマ利用設定の保存キー。
const _startupTabKey = 'settings_startup_tab'; // アプリ起動時に表示するタブを保持する保存キー。
const _skipDeleteConfirmKey =
    'settings_skip_delete_confirm'; // 削除確認ダイアログをスキップする設定の保存キー。

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
    this.skipDeleteConfirm = false,
    this.shouldRedirectAfterShare = false,
  });

  final bool wifiOnlySummaries; // モバイルデータを抑えるため、Wi-Fi時のみ要約を投げるかどうか。
  final bool preferDynamicType; // OSの文字サイズ指定を優先させるかどうか。
  final bool enableDarkTheme; // 常にダークテーマを使うかどうか。
  final StartupTab startupTab; // アプリ起動時に開くタブ。
  final bool skipDeleteConfirm; // 削除時に確認ダイアログをスキップするかどうか。
  final bool shouldRedirectAfterShare; // 共有保存後にアプリを開くかどうか。

  SettingsPreferencesState copyWith({
    bool? wifiOnlySummaries,
    bool? preferDynamicType,
    bool? enableDarkTheme,
    StartupTab? startupTab,
    bool? skipDeleteConfirm,
    bool? shouldRedirectAfterShare,
  }) {
    return SettingsPreferencesState(
      wifiOnlySummaries: wifiOnlySummaries ?? this.wifiOnlySummaries,
      preferDynamicType: preferDynamicType ?? this.preferDynamicType,
      enableDarkTheme: enableDarkTheme ?? this.enableDarkTheme,
      startupTab: startupTab ?? this.startupTab,
      skipDeleteConfirm: skipDeleteConfirm ?? this.skipDeleteConfirm,
      shouldRedirectAfterShare:
          shouldRedirectAfterShare ?? this.shouldRedirectAfterShare,
    );
  }
}

/// 設定の永続化と状態管理を担うStateNotifier。
class SettingsPreferencesNotifier
    extends StateNotifier<SettingsPreferencesState> {
  SettingsPreferencesNotifier() : super(const SettingsPreferencesState()) {
    _loadPreferences();
  }

  // MethodChannel でネイティブ側と設定を同期
  static const _shareChannel = MethodChannel('com.MakotoKono.urlManager/share');

  SharedPreferences? _cachedPrefs; // 何度も取得しないようキャッシュ。
  static const _redirectAfterShareKey = 'settings_redirect_after_share';

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

    final redirectAfterShare = prefs.getBool(_redirectAfterShareKey) ?? false;

    // 起動時にネイティブ側の設定も同期しておく
    _syncRedirectSettingToNative(redirectAfterShare);

    state = state.copyWith(
      wifiOnlySummaries: prefs.getBool(_wifiOnlyKey) ?? state.wifiOnlySummaries,
      preferDynamicType:
          prefs.getBool(_dynamicTypeKey) ?? state.preferDynamicType,
      enableDarkTheme: prefs.getBool(_darkThemeKey) ?? state.enableDarkTheme,
      startupTab: parsedStartupTab,
      skipDeleteConfirm:
          prefs.getBool(_skipDeleteConfirmKey) ?? state.skipDeleteConfirm,
      shouldRedirectAfterShare: redirectAfterShare,
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

  /// 削除確認ダイアログのスキップ設定を更新し永続化する。
  Future<void> updateSkipDeleteConfirm(bool skip) async {
    state = state.copyWith(skipDeleteConfirm: skip);
    final prefs = await _prefs;
    await prefs.setBool(_skipDeleteConfirmKey, skip);
  }

  /// 共有保存後のリダイレクト設定を更新し永続化・ネイティブ同期する。
  Future<void> updateRedirectAfterShare(bool enabled) async {
    state = state.copyWith(shouldRedirectAfterShare: enabled);
    final prefs = await _prefs;
    await prefs.setBool(_redirectAfterShareKey, enabled);
    // ネイティブ側にも同期
    _syncRedirectSettingToNative(enabled);
  }

  /// ネイティブ側 (AppGroup) にリダイレクト設定を同期
  Future<void> _syncRedirectSettingToNative(bool enabled) async {
    try {
      await _shareChannel.invokeMethod('setRedirectAfterShare', enabled);
    } on PlatformException catch (e) {
      print('Failed to sync redirect setting: ${e.message}');
    }
  }
}

/// 設定プリファレンスをWidgetツリーへ提供するためのProvider。
final settingsPreferencesProvider = StateNotifierProvider<
    SettingsPreferencesNotifier, SettingsPreferencesState>((ref) {
  return SettingsPreferencesNotifier();
});
