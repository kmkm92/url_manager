import 'package:drift/drift.dart';

@DataClassName('Url')
class Urls extends Table {
  IntColumn get id => integer().autoIncrement().nullable()();
  TextColumn get message => text()();
  TextColumn get url => text()();
  TextColumn get details => text().withDefault(const Constant(''))();
  TextColumn get domain => text().withDefault(const Constant(''))();
  TextColumn get tags => text().withDefault(const Constant(''))();
  BoolColumn get isStarred => boolean().withDefault(const Constant(false))();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  TextColumn get ogImageUrl => text().nullable()();
  DateTimeColumn get savedAt => dateTime()();
}
