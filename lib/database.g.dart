// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $UrlsTable extends Urls with TableInfo<$UrlsTable, Url> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UrlsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, true,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _messageMeta =
      const VerificationMeta('message');
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
      'message', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
      'url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _detailsMeta =
      const VerificationMeta('details');
  @override
  late final GeneratedColumn<String> details = GeneratedColumn<String>(
      'details', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _savedAtMeta =
      const VerificationMeta('savedAt');
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
      'saved_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, message, url, details, savedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'urls';
  @override
  VerificationContext validateIntegrity(Insertable<Url> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('message')) {
      context.handle(_messageMeta,
          message.isAcceptableOrUnknown(data['message']!, _messageMeta));
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
          _urlMeta, url.isAcceptableOrUnknown(data['url']!, _urlMeta));
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('details')) {
      context.handle(_detailsMeta,
          details.isAcceptableOrUnknown(data['details']!, _detailsMeta));
    } else if (isInserting) {
      context.missing(_detailsMeta);
    }
    if (data.containsKey('saved_at')) {
      context.handle(_savedAtMeta,
          savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta));
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Url map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Url(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id']),
      message: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message'])!,
      url: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}url'])!,
      details: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}details'])!,
      savedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}saved_at'])!,
    );
  }

  @override
  $UrlsTable createAlias(String alias) {
    return $UrlsTable(attachedDatabase, alias);
  }
}

class Url extends DataClass implements Insertable<Url> {
  final int? id;
  final String message;
  final String url;
  final String details;
  final DateTime savedAt;
  const Url(
      {this.id,
      required this.message,
      required this.url,
      required this.details,
      required this.savedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<int>(id);
    }
    map['message'] = Variable<String>(message);
    map['url'] = Variable<String>(url);
    map['details'] = Variable<String>(details);
    map['saved_at'] = Variable<DateTime>(savedAt);
    return map;
  }

  UrlsCompanion toCompanion(bool nullToAbsent) {
    return UrlsCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      message: Value(message),
      url: Value(url),
      details: Value(details),
      savedAt: Value(savedAt),
    );
  }

  factory Url.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Url(
      id: serializer.fromJson<int?>(json['id']),
      message: serializer.fromJson<String>(json['message']),
      url: serializer.fromJson<String>(json['url']),
      details: serializer.fromJson<String>(json['details']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int?>(id),
      'message': serializer.toJson<String>(message),
      'url': serializer.toJson<String>(url),
      'details': serializer.toJson<String>(details),
      'savedAt': serializer.toJson<DateTime>(savedAt),
    };
  }

  Url copyWith(
          {Value<int?> id = const Value.absent(),
          String? message,
          String? url,
          String? details,
          DateTime? savedAt}) =>
      Url(
        id: id.present ? id.value : this.id,
        message: message ?? this.message,
        url: url ?? this.url,
        details: details ?? this.details,
        savedAt: savedAt ?? this.savedAt,
      );
  @override
  String toString() {
    return (StringBuffer('Url(')
          ..write('id: $id, ')
          ..write('message: $message, ')
          ..write('url: $url, ')
          ..write('details: $details, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, message, url, details, savedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Url &&
          other.id == this.id &&
          other.message == this.message &&
          other.url == this.url &&
          other.details == this.details &&
          other.savedAt == this.savedAt);
}

class UrlsCompanion extends UpdateCompanion<Url> {
  final Value<int?> id;
  final Value<String> message;
  final Value<String> url;
  final Value<String> details;
  final Value<DateTime> savedAt;
  const UrlsCompanion({
    this.id = const Value.absent(),
    this.message = const Value.absent(),
    this.url = const Value.absent(),
    this.details = const Value.absent(),
    this.savedAt = const Value.absent(),
  });
  UrlsCompanion.insert({
    this.id = const Value.absent(),
    required String message,
    required String url,
    required String details,
    required DateTime savedAt,
  })  : message = Value(message),
        url = Value(url),
        details = Value(details),
        savedAt = Value(savedAt);
  static Insertable<Url> custom({
    Expression<int>? id,
    Expression<String>? message,
    Expression<String>? url,
    Expression<String>? details,
    Expression<DateTime>? savedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (message != null) 'message': message,
      if (url != null) 'url': url,
      if (details != null) 'details': details,
      if (savedAt != null) 'saved_at': savedAt,
    });
  }

  UrlsCompanion copyWith(
      {Value<int?>? id,
      Value<String>? message,
      Value<String>? url,
      Value<String>? details,
      Value<DateTime>? savedAt}) {
    return UrlsCompanion(
      id: id ?? this.id,
      message: message ?? this.message,
      url: url ?? this.url,
      details: details ?? this.details,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (details.present) {
      map['details'] = Variable<String>(details.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UrlsCompanion(')
          ..write('id: $id, ')
          ..write('message: $message, ')
          ..write('url: $url, ')
          ..write('details: $details, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  _$AppDatabaseManager get managers => _$AppDatabaseManager(this);
  late final $UrlsTable urls = $UrlsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [urls];
}

typedef $$UrlsTableInsertCompanionBuilder = UrlsCompanion Function({
  Value<int?> id,
  required String message,
  required String url,
  required String details,
  required DateTime savedAt,
});
typedef $$UrlsTableUpdateCompanionBuilder = UrlsCompanion Function({
  Value<int?> id,
  Value<String> message,
  Value<String> url,
  Value<String> details,
  Value<DateTime> savedAt,
});

class $$UrlsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UrlsTable,
    Url,
    $$UrlsTableFilterComposer,
    $$UrlsTableOrderingComposer,
    $$UrlsTableProcessedTableManager,
    $$UrlsTableInsertCompanionBuilder,
    $$UrlsTableUpdateCompanionBuilder> {
  $$UrlsTableTableManager(_$AppDatabase db, $UrlsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$UrlsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$UrlsTableOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) => $$UrlsTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<int?> id = const Value.absent(),
            Value<String> message = const Value.absent(),
            Value<String> url = const Value.absent(),
            Value<String> details = const Value.absent(),
            Value<DateTime> savedAt = const Value.absent(),
          }) =>
              UrlsCompanion(
            id: id,
            message: message,
            url: url,
            details: details,
            savedAt: savedAt,
          ),
          getInsertCompanionBuilder: ({
            Value<int?> id = const Value.absent(),
            required String message,
            required String url,
            required String details,
            required DateTime savedAt,
          }) =>
              UrlsCompanion.insert(
            id: id,
            message: message,
            url: url,
            details: details,
            savedAt: savedAt,
          ),
        ));
}

class $$UrlsTableProcessedTableManager extends ProcessedTableManager<
    _$AppDatabase,
    $UrlsTable,
    Url,
    $$UrlsTableFilterComposer,
    $$UrlsTableOrderingComposer,
    $$UrlsTableProcessedTableManager,
    $$UrlsTableInsertCompanionBuilder,
    $$UrlsTableUpdateCompanionBuilder> {
  $$UrlsTableProcessedTableManager(super.$state);
}

class $$UrlsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $UrlsTable> {
  $$UrlsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get message => $state.composableBuilder(
      column: $state.table.message,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get url => $state.composableBuilder(
      column: $state.table.url,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get details => $state.composableBuilder(
      column: $state.table.details,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get savedAt => $state.composableBuilder(
      column: $state.table.savedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$UrlsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $UrlsTable> {
  $$UrlsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get message => $state.composableBuilder(
      column: $state.table.message,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get url => $state.composableBuilder(
      column: $state.table.url,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get details => $state.composableBuilder(
      column: $state.table.details,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get savedAt => $state.composableBuilder(
      column: $state.table.savedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class _$AppDatabaseManager {
  final _$AppDatabase _db;
  _$AppDatabaseManager(this._db);
  $$UrlsTableTableManager get urls => $$UrlsTableTableManager(_db, _db.urls);
}
