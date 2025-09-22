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
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _domainMeta = const VerificationMeta('domain');
  @override
  late final GeneratedColumn<String> domain = GeneratedColumn<String>(
      'domain', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _isStarredMeta =
      const VerificationMeta('isStarred');
  @override
  late final GeneratedColumn<bool> isStarred = GeneratedColumn<bool>(
      'is_starred', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_starred" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
      'is_read', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_read" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isArchivedMeta =
      const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
      'is_archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _ogImageUrlMeta =
      const VerificationMeta('ogImageUrl');
  @override
  late final GeneratedColumn<String> ogImageUrl = GeneratedColumn<String>(
      'og_image_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _savedAtMeta =
      const VerificationMeta('savedAt');
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
      'saved_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        message,
        url,
        details,
        domain,
        tags,
        isStarred,
        isRead,
        isArchived,
        ogImageUrl,
        savedAt
      ];
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
    }
    if (data.containsKey('domain')) {
      context.handle(_domainMeta,
          domain.isAcceptableOrUnknown(data['domain']!, _domainMeta));
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
    }
    if (data.containsKey('is_starred')) {
      context.handle(_isStarredMeta,
          isStarred.isAcceptableOrUnknown(data['is_starred']!, _isStarredMeta));
    }
    if (data.containsKey('is_read')) {
      context.handle(_isReadMeta,
          isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta));
    }
    if (data.containsKey('is_archived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['is_archived']!, _isArchivedMeta));
    }
    if (data.containsKey('og_image_url')) {
      context.handle(
          _ogImageUrlMeta,
          ogImageUrl.isAcceptableOrUnknown(
              data['og_image_url']!, _ogImageUrlMeta));
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
      domain: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}domain'])!,
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags'])!,
      isStarred: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_starred'])!,
      isRead: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_read'])!,
      isArchived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_archived'])!,
      ogImageUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}og_image_url']),
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
  final String domain;
  final String tags;
  final bool isStarred;
  final bool isRead;
  final bool isArchived;
  final String? ogImageUrl;
  final DateTime savedAt;
  const Url(
      {this.id,
      required this.message,
      required this.url,
      required this.details,
      required this.domain,
      required this.tags,
      required this.isStarred,
      required this.isRead,
      required this.isArchived,
      this.ogImageUrl,
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
    map['domain'] = Variable<String>(domain);
    map['tags'] = Variable<String>(tags);
    map['is_starred'] = Variable<bool>(isStarred);
    map['is_read'] = Variable<bool>(isRead);
    map['is_archived'] = Variable<bool>(isArchived);
    if (!nullToAbsent || ogImageUrl != null) {
      map['og_image_url'] = Variable<String>(ogImageUrl);
    }
    map['saved_at'] = Variable<DateTime>(savedAt);
    return map;
  }

  UrlsCompanion toCompanion(bool nullToAbsent) {
    return UrlsCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      message: Value(message),
      url: Value(url),
      details: Value(details),
      domain: Value(domain),
      tags: Value(tags),
      isStarred: Value(isStarred),
      isRead: Value(isRead),
      isArchived: Value(isArchived),
      ogImageUrl: ogImageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(ogImageUrl),
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
      domain: serializer.fromJson<String>(json['domain']),
      tags: serializer.fromJson<String>(json['tags']),
      isStarred: serializer.fromJson<bool>(json['isStarred']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      ogImageUrl: serializer.fromJson<String?>(json['ogImageUrl']),
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
      'domain': serializer.toJson<String>(domain),
      'tags': serializer.toJson<String>(tags),
      'isStarred': serializer.toJson<bool>(isStarred),
      'isRead': serializer.toJson<bool>(isRead),
      'isArchived': serializer.toJson<bool>(isArchived),
      'ogImageUrl': serializer.toJson<String?>(ogImageUrl),
      'savedAt': serializer.toJson<DateTime>(savedAt),
    };
  }

  Url copyWith(
          {Value<int?> id = const Value.absent(),
          String? message,
          String? url,
          String? details,
          String? domain,
          String? tags,
          bool? isStarred,
          bool? isRead,
          bool? isArchived,
          Value<String?> ogImageUrl = const Value.absent(),
          DateTime? savedAt}) =>
      Url(
        id: id.present ? id.value : this.id,
        message: message ?? this.message,
        url: url ?? this.url,
        details: details ?? this.details,
        domain: domain ?? this.domain,
        tags: tags ?? this.tags,
        isStarred: isStarred ?? this.isStarred,
        isRead: isRead ?? this.isRead,
        isArchived: isArchived ?? this.isArchived,
        ogImageUrl: ogImageUrl.present ? ogImageUrl.value : this.ogImageUrl,
        savedAt: savedAt ?? this.savedAt,
      );
  Url copyWithCompanion(UrlsCompanion data) {
    return Url(
      id: data.id.present ? data.id.value : this.id,
      message: data.message.present ? data.message.value : this.message,
      url: data.url.present ? data.url.value : this.url,
      details: data.details.present ? data.details.value : this.details,
      domain: data.domain.present ? data.domain.value : this.domain,
      tags: data.tags.present ? data.tags.value : this.tags,
      isStarred: data.isStarred.present ? data.isStarred.value : this.isStarred,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
      ogImageUrl:
          data.ogImageUrl.present ? data.ogImageUrl.value : this.ogImageUrl,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Url(')
          ..write('id: $id, ')
          ..write('message: $message, ')
          ..write('url: $url, ')
          ..write('details: $details, ')
          ..write('domain: $domain, ')
          ..write('tags: $tags, ')
          ..write('isStarred: $isStarred, ')
          ..write('isRead: $isRead, ')
          ..write('isArchived: $isArchived, ')
          ..write('ogImageUrl: $ogImageUrl, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, message, url, details, domain, tags,
      isStarred, isRead, isArchived, ogImageUrl, savedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Url &&
          other.id == this.id &&
          other.message == this.message &&
          other.url == this.url &&
          other.details == this.details &&
          other.domain == this.domain &&
          other.tags == this.tags &&
          other.isStarred == this.isStarred &&
          other.isRead == this.isRead &&
          other.isArchived == this.isArchived &&
          other.ogImageUrl == this.ogImageUrl &&
          other.savedAt == this.savedAt);
}

class UrlsCompanion extends UpdateCompanion<Url> {
  final Value<int?> id;
  final Value<String> message;
  final Value<String> url;
  final Value<String> details;
  final Value<String> domain;
  final Value<String> tags;
  final Value<bool> isStarred;
  final Value<bool> isRead;
  final Value<bool> isArchived;
  final Value<String?> ogImageUrl;
  final Value<DateTime> savedAt;
  const UrlsCompanion({
    this.id = const Value.absent(),
    this.message = const Value.absent(),
    this.url = const Value.absent(),
    this.details = const Value.absent(),
    this.domain = const Value.absent(),
    this.tags = const Value.absent(),
    this.isStarred = const Value.absent(),
    this.isRead = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.ogImageUrl = const Value.absent(),
    this.savedAt = const Value.absent(),
  });
  UrlsCompanion.insert({
    this.id = const Value.absent(),
    required String message,
    required String url,
    this.details = const Value.absent(),
    this.domain = const Value.absent(),
    this.tags = const Value.absent(),
    this.isStarred = const Value.absent(),
    this.isRead = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.ogImageUrl = const Value.absent(),
    required DateTime savedAt,
  })  : message = Value(message),
        url = Value(url),
        savedAt = Value(savedAt);
  static Insertable<Url> custom({
    Expression<int>? id,
    Expression<String>? message,
    Expression<String>? url,
    Expression<String>? details,
    Expression<String>? domain,
    Expression<String>? tags,
    Expression<bool>? isStarred,
    Expression<bool>? isRead,
    Expression<bool>? isArchived,
    Expression<String>? ogImageUrl,
    Expression<DateTime>? savedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (message != null) 'message': message,
      if (url != null) 'url': url,
      if (details != null) 'details': details,
      if (domain != null) 'domain': domain,
      if (tags != null) 'tags': tags,
      if (isStarred != null) 'is_starred': isStarred,
      if (isRead != null) 'is_read': isRead,
      if (isArchived != null) 'is_archived': isArchived,
      if (ogImageUrl != null) 'og_image_url': ogImageUrl,
      if (savedAt != null) 'saved_at': savedAt,
    });
  }

  UrlsCompanion copyWith(
      {Value<int?>? id,
      Value<String>? message,
      Value<String>? url,
      Value<String>? details,
      Value<String>? domain,
      Value<String>? tags,
      Value<bool>? isStarred,
      Value<bool>? isRead,
      Value<bool>? isArchived,
      Value<String?>? ogImageUrl,
      Value<DateTime>? savedAt}) {
    return UrlsCompanion(
      id: id ?? this.id,
      message: message ?? this.message,
      url: url ?? this.url,
      details: details ?? this.details,
      domain: domain ?? this.domain,
      tags: tags ?? this.tags,
      isStarred: isStarred ?? this.isStarred,
      isRead: isRead ?? this.isRead,
      isArchived: isArchived ?? this.isArchived,
      ogImageUrl: ogImageUrl ?? this.ogImageUrl,
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
    if (domain.present) {
      map['domain'] = Variable<String>(domain.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (isStarred.present) {
      map['is_starred'] = Variable<bool>(isStarred.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (ogImageUrl.present) {
      map['og_image_url'] = Variable<String>(ogImageUrl.value);
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
          ..write('domain: $domain, ')
          ..write('tags: $tags, ')
          ..write('isStarred: $isStarred, ')
          ..write('isRead: $isRead, ')
          ..write('isArchived: $isArchived, ')
          ..write('ogImageUrl: $ogImageUrl, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UrlsTable urls = $UrlsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [urls];
}

typedef $$UrlsTableCreateCompanionBuilder = UrlsCompanion Function({
  Value<int?> id,
  required String message,
  required String url,
  Value<String> details,
  Value<String> domain,
  Value<String> tags,
  Value<bool> isStarred,
  Value<bool> isRead,
  Value<bool> isArchived,
  Value<String?> ogImageUrl,
  required DateTime savedAt,
});
typedef $$UrlsTableUpdateCompanionBuilder = UrlsCompanion Function({
  Value<int?> id,
  Value<String> message,
  Value<String> url,
  Value<String> details,
  Value<String> domain,
  Value<String> tags,
  Value<bool> isStarred,
  Value<bool> isRead,
  Value<bool> isArchived,
  Value<String?> ogImageUrl,
  Value<DateTime> savedAt,
});

class $$UrlsTableFilterComposer extends Composer<_$AppDatabase, $UrlsTable> {
  $$UrlsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get message => $composableBuilder(
      column: $table.message, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get details => $composableBuilder(
      column: $table.details, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get domain => $composableBuilder(
      column: $table.domain, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isStarred => $composableBuilder(
      column: $table.isStarred, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isRead => $composableBuilder(
      column: $table.isRead, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ogImageUrl => $composableBuilder(
      column: $table.ogImageUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get savedAt => $composableBuilder(
      column: $table.savedAt, builder: (column) => ColumnFilters(column));
}

class $$UrlsTableOrderingComposer extends Composer<_$AppDatabase, $UrlsTable> {
  $$UrlsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get message => $composableBuilder(
      column: $table.message, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get details => $composableBuilder(
      column: $table.details, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get domain => $composableBuilder(
      column: $table.domain, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isStarred => $composableBuilder(
      column: $table.isStarred, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isRead => $composableBuilder(
      column: $table.isRead, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ogImageUrl => $composableBuilder(
      column: $table.ogImageUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get savedAt => $composableBuilder(
      column: $table.savedAt, builder: (column) => ColumnOrderings(column));
}

class $$UrlsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UrlsTable> {
  $$UrlsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get details =>
      $composableBuilder(column: $table.details, builder: (column) => column);

  GeneratedColumn<String> get domain =>
      $composableBuilder(column: $table.domain, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<bool> get isStarred =>
      $composableBuilder(column: $table.isStarred, builder: (column) => column);

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => column);

  GeneratedColumn<String> get ogImageUrl => $composableBuilder(
      column: $table.ogImageUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);
}

class $$UrlsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UrlsTable,
    Url,
    $$UrlsTableFilterComposer,
    $$UrlsTableOrderingComposer,
    $$UrlsTableAnnotationComposer,
    $$UrlsTableCreateCompanionBuilder,
    $$UrlsTableUpdateCompanionBuilder,
    (Url, BaseReferences<_$AppDatabase, $UrlsTable, Url>),
    Url,
    PrefetchHooks Function()> {
  $$UrlsTableTableManager(_$AppDatabase db, $UrlsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UrlsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UrlsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UrlsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int?> id = const Value.absent(),
            Value<String> message = const Value.absent(),
            Value<String> url = const Value.absent(),
            Value<String> details = const Value.absent(),
            Value<String> domain = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<bool> isStarred = const Value.absent(),
            Value<bool> isRead = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<String?> ogImageUrl = const Value.absent(),
            Value<DateTime> savedAt = const Value.absent(),
          }) =>
              UrlsCompanion(
            id: id,
            message: message,
            url: url,
            details: details,
            domain: domain,
            tags: tags,
            isStarred: isStarred,
            isRead: isRead,
            isArchived: isArchived,
            ogImageUrl: ogImageUrl,
            savedAt: savedAt,
          ),
          createCompanionCallback: ({
            Value<int?> id = const Value.absent(),
            required String message,
            required String url,
            Value<String> details = const Value.absent(),
            Value<String> domain = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<bool> isStarred = const Value.absent(),
            Value<bool> isRead = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<String?> ogImageUrl = const Value.absent(),
            required DateTime savedAt,
          }) =>
              UrlsCompanion.insert(
            id: id,
            message: message,
            url: url,
            details: details,
            domain: domain,
            tags: tags,
            isStarred: isStarred,
            isRead: isRead,
            isArchived: isArchived,
            ogImageUrl: ogImageUrl,
            savedAt: savedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UrlsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UrlsTable,
    Url,
    $$UrlsTableFilterComposer,
    $$UrlsTableOrderingComposer,
    $$UrlsTableAnnotationComposer,
    $$UrlsTableCreateCompanionBuilder,
    $$UrlsTableUpdateCompanionBuilder,
    (Url, BaseReferences<_$AppDatabase, $UrlsTable, Url>),
    Url,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UrlsTableTableManager get urls => $$UrlsTableTableManager(_db, _db.urls);
}
