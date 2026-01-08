// URL一覧画面で使用するフィルター関連のProvider群。
// ステータスフィルター、タグフィルター、タグ順序、検索クエリを管理する。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 検索クエリのProvider
final searchQueryProvider = StateProvider<String>((ref) => '');

// フィルター状態永続化用のキー
const _statusFilterKey = 'filter_status_filters';
const _tagFilterKey = 'filter_tag_filter';
const _tagOrderKey = 'filter_tag_order';

/// ステータスフィルターの種類
enum StatusFilter { unread, starred, archived }

/// ステータスフィルターのラベルとアイコンを提供する拡張
extension StatusFilterExtension on StatusFilter {
  String get label {
    switch (this) {
      case StatusFilter.unread:
        return '未読';
      case StatusFilter.starred:
        return 'スター';
      case StatusFilter.archived:
        return 'アーカイブ';
    }
  }

  IconData get icon {
    switch (this) {
      case StatusFilter.unread:
        return Icons.markunread_outlined;
      case StatusFilter.starred:
        return Icons.star_outline;
      case StatusFilter.archived:
        return Icons.archive_outlined;
    }
  }
}

/// ステータスフィルターを永続化するNotifier
class StatusFilterNotifier extends StateNotifier<Set<StatusFilter>> {
  StatusFilterNotifier() : super(<StatusFilter>{}) {
    _loadFromPrefs();
  }

  SharedPreferences? _prefs;

  /// SharedPreferencesから保存済みフィルターを復元
  Future<void> _loadFromPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    final savedList = _prefs?.getStringList(_statusFilterKey);
    if (savedList != null && savedList.isNotEmpty) {
      // 保存された値をenum値に変換し、存在しない値はスキップ
      final validFilters = <StatusFilter>{};
      for (final name in savedList) {
        try {
          final filter = StatusFilter.values.firstWhere((f) => f.name == name);
          validFilters.add(filter);
        } catch (_) {
          // 存在しないenum値は無視（将来のバージョンで削除された可能性）
        }
      }
      state = validFilters;
    }
  }

  /// フィルターを更新し永続化
  Future<void> update(Set<StatusFilter> newFilters) async {
    state = newFilters;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setStringList(
      _statusFilterKey,
      newFilters.map((f) => f.name).toList(),
    );
  }
}

/// タグフィルターを永続化するNotifier
class TagFilterNotifier extends StateNotifier<String?> {
  TagFilterNotifier() : super(null) {
    _loadFromPrefs();
  }

  SharedPreferences? _prefs;

  /// SharedPreferencesから保存済みタグフィルターを復元
  Future<void> _loadFromPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    final savedTag = _prefs?.getString(_tagFilterKey);
    if (savedTag != null && savedTag.isNotEmpty) {
      state = savedTag;
    }
  }

  /// タグフィルターを更新し永続化
  Future<void> update(String? newTag) async {
    state = newTag;
    _prefs ??= await SharedPreferences.getInstance();
    if (newTag == null || newTag.isEmpty) {
      await _prefs?.remove(_tagFilterKey);
    } else {
      await _prefs?.setString(_tagFilterKey, newTag);
    }
  }
}

/// タグの並び順を永続化するNotifier
class TagOrderNotifier extends StateNotifier<List<String>> {
  TagOrderNotifier() : super([]) {
    _loadFromPrefs();
  }

  SharedPreferences? _prefs;

  /// SharedPreferencesから保存済みの順序を復元
  Future<void> _loadFromPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    final savedList = _prefs?.getStringList(_tagOrderKey);
    if (savedList != null) {
      state = savedList;
    }
  }

  /// タグリストを取得（保存された順序を反映）
  List<String> getOrderedTags(List<String> availableTags) {
    final orderedTags = <String>[];
    // 保存された順序のタグを先に追加
    for (final tag in state) {
      if (availableTags.contains(tag)) {
        orderedTags.add(tag);
      }
    }
    // 新しいタグを後ろに追加
    for (final tag in availableTags) {
      if (!orderedTags.contains(tag)) {
        orderedTags.add(tag);
      }
    }
    return orderedTags;
  }

  /// 順序を更新し永続化
  Future<void> updateOrder(List<String> newOrder) async {
    state = newOrder;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setStringList(_tagOrderKey, newOrder);
  }

  /// タグの順序を入れ替え
  Future<void> reorder(
      int oldIndex, int newIndex, List<String> currentTags) async {
    final newList = List<String>.from(currentTags);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = newList.removeAt(oldIndex);
    newList.insert(newIndex, item);
    await updateOrder(newList);
  }
}

// Provider定義
final statusFilterProvider =
    StateNotifierProvider<StatusFilterNotifier, Set<StatusFilter>>(
  (ref) => StatusFilterNotifier(),
);

final tagFilterProvider = StateNotifierProvider<TagFilterNotifier, String?>(
  (ref) => TagFilterNotifier(),
);

final tagOrderProvider = StateNotifierProvider<TagOrderNotifier, List<String>>(
  (ref) => TagOrderNotifier(),
);
