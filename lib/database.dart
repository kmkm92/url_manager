import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:url_manager/models/url_model.dart';
import 'dart:io';

part 'database.g.dart'; // Driftによる自動生成ファイル

@DriftDatabase(tables: [Urls])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 3; // スキーマのバージョン

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(urls, urls.domain);
            await m.addColumn(urls, urls.tags);
            await m.addColumn(urls, urls.isStarred);
            await m.addColumn(urls, urls.isRead);
            await m.addColumn(urls, urls.isArchived);
            await m.addColumn(urls, urls.ogImageUrl);
          }
          // v3: ファビコンURLカラムを追加
          if (from < 3) {
            await m.addColumn(urls, urls.faviconUrl);
          }
        },
      );

  // 取得（最新順にソート）
  Future<List<Url>> getAllUrls() =>
      (select(urls)..orderBy([(t) => OrderingTerm.desc(t.savedAt)])).get();
  // 挿入
  Future<int> insertUrl(Url url) => into(urls).insert(url);
  // 更新
  Future<void> updateUrl(Url url) => update(urls).replace(url);
  // 削除
  Future<void> deleteUrl(Url url) => delete(urls).delete(url);
}

// データベース接続を開くための関数
final provideDatabase = FutureProvider<AppDatabase>((ref) async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File(p.join(dbFolder.path, 'db.sqlite'));
  return AppDatabase(NativeDatabase(file));
});
