/// URLストレージの使用状況を算出するProvider群を定義するファイル。
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_manager/database.dart';
import 'package:url_manager/view_models/url_view_model.dart';

/// UI側に渡すストレージ情報のモデル。
class StorageInfo {
  const StorageInfo({
    required this.usedEntries,
    required this.capacityEntries,
    required this.usageRatio,
    required this.lastSyncedAt,
  });

  /// 保存済みURL件数。
  final int usedEntries;

  /// 想定する最大保存件数。
  final int capacityEntries;

  /// 使用率（0.0〜1.0に正規化済み）。
  final double usageRatio;

  /// 最終同期日時（URLの保存日時の最新値）。
  final DateTime? lastSyncedAt;
}

/// ストレージ情報を算出して返すProvider。
final storageInfoProvider = Provider<StorageInfo>((ref) {
  // URL一覧を購読し件数や最新保存日時を算出。
  final List<Url> urls = ref.watch(urlListProvider);
  const capacityEntries = 1000;
  final usedEntries = urls.length;
  final rawUsageRatio = capacityEntries == 0
      ? 0.0
      : usedEntries / capacityEntries;
  final normalizedUsageRatio = rawUsageRatio.clamp(0.0, 1.0);
  final DateTime? latestSyncedAt = urls.isEmpty
      ? null
      : urls
          .map((url) => url.savedAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);

  return StorageInfo(
    usedEntries: usedEntries,
    capacityEntries: capacityEntries,
    usageRatio: normalizedUsageRatio,
    lastSyncedAt: latestSyncedAt,
  );
});
