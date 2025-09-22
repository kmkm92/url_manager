import 'package:drift/drift.dart' hide JsonKey;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'url_model.freezed.dart';

@DataClassName('Url')
class Urls extends Table {
  IntColumn get id => integer().autoIncrement().nullable()();
  TextColumn get message => text()();
  TextColumn get url => text()();
  TextColumn get details => text()();
  DateTimeColumn get savedAt => dateTime()();
}

@freezed
abstract class UrlItem with _$UrlItem {
  const factory UrlItem({
    required int? id,
    required String message,
    required String url,
    required String details,
    required DateTime savedAt,
  }) = _UrlItem;

  factory UrlItem.fromRow(Map<String, dynamic> row) {
    return UrlItem(
      id: row['id'] as int,
      message: row['message'] as String,
      url: row['url'] as String,
      details: row['details'] as String,
      savedAt: DateTime.parse(row['savedAt'] as String),
    );
  }
}
