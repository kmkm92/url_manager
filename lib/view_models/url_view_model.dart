import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:url_launcher/url_launcher.dart';
import 'package:url_manager/database.dart';
import 'package:url_manager/models/tag_utils.dart';

final urlListProvider =
    StateNotifierProvider<UrlListNotifier, List<Url>>((ref) {
  return UrlListNotifier(ref);
});

/// 共有メディアファイルのデータクラス（receive_sharing_intent の SharedMediaFile と同等）
class SharedMediaFile {
  final String path;
  final String? message;
  final int type;

  SharedMediaFile({
    required this.path,
    this.message,
    required this.type,
  });

  factory SharedMediaFile.fromMap(Map<dynamic, dynamic> map) {
    return SharedMediaFile(
      path: map['path'] as String? ?? '',
      message: map['message'] as String?,
      type: map['type'] as int? ?? 0,
    );
  }
}

// URLリストの状態や共有インテントの監視を行うStateNotifier
// receive_sharing_intent と同じ挙動を再現
class UrlListNotifier extends StateNotifier<List<Url>> {
  final Ref _ref;
  StreamSubscription? _intentSub;
  final List<SharedMediaFile> _sharedFiles = [];
  Url? _recentlyDeleted;

  // MethodChannel と EventChannel（receive_sharing_intent と同じ構造）
  static const _methodChannel =
      MethodChannel('com.MakotoKono.urlManager/share');
  static const _eventChannel =
      EventChannel('com.MakotoKono.urlManager/share/stream');

  // コンストラクタで共有インテントの監視と初期データの読み込みを開始
  UrlListNotifier(this._ref) : super([]) {
    print('[UrlListNotifier] Initializing...');

    // getMediaStream(): アプリ起動中に共有を受け取るストリーム
    _intentSub = _eventChannel.receiveBroadcastStream().listen(
      (dynamic value) {
        print('[UrlListNotifier] Stream received: $value');
        if (value is List) {
          _sharedFiles.clear();
          for (final item in value) {
            print('[UrlListNotifier] Processing item: $item');
            if (item is Map) {
              _sharedFiles.add(SharedMediaFile.fromMap(item));
            }
          }
          if (_sharedFiles.isNotEmpty) {
            print(
                '[UrlListNotifier] Adding URL from stream: ${_sharedFiles.first.path}');
            addUrlFromShare(
              message: _sharedFiles.first.message,
              url: _sharedFiles.first.path,
            );
            // 処理後にリセット
            _resetSharedData();
          }
        }
      },
      onError: (err) {
        print("[UrlListNotifier] getMediaStream error: $err");
      },
    );

    // getInitialMedia(): アプリ起動時の初期共有データを取得
    _getInitialMedia().then((List<SharedMediaFile> value) {
      print('[UrlListNotifier] getInitialMedia returned ${value.length} items');
      _sharedFiles.clear();
      _sharedFiles.addAll(value);
      if (_sharedFiles.isNotEmpty) {
        print(
            '[UrlListNotifier] Adding URL from initial: ${_sharedFiles.first.path}');
        addUrlFromShare(
          message: _sharedFiles.first.message,
          url: _sharedFiles.first.path,
        );
        // 処理後にリセット
        _resetSharedData();
      }
    });

    loadUrls();
  }

  /// 初期共有データを取得（receive_sharing_intent.getInitialMedia() と同等）
  Future<List<SharedMediaFile>> _getInitialMedia() async {
    try {
      print('[UrlListNotifier] Calling getInitialMedia...');
      final result =
          await _methodChannel.invokeMethod<List<dynamic>>('getInitialMedia');
      print('[UrlListNotifier] getInitialMedia raw result: $result');
      if (result == null) return [];

      return result
          .whereType<Map>()
          .map((item) => SharedMediaFile.fromMap(item))
          .toList();
    } on PlatformException catch (e) {
      print('[UrlListNotifier] Failed to get initial media: ${e.message}');
      return [];
    }
  }

  /// 共有データをリセット（receive_sharing_intent.reset() と同等）
  Future<void> _resetSharedData() async {
    try {
      print('[UrlListNotifier] Calling reset...');
      await _methodChannel.invokeMethod('reset');
    } on PlatformException catch (e) {
      print('[UrlListNotifier] Failed to reset shared data: ${e.message}');
    }
  }

  // DBからURLリストを再取得して状態を更新
  Future<void> loadUrls() async {
    final db = await _ref.read(provideDatabase.future);
    final urls = await db.getAllUrls();
    state = urls;
  }

  // 1件のURLを永続化し、付加情報を整形した上で保存
  Future<void> addUrl(Url url) async {
    final db = await _ref.read(provideDatabase.future);
    final prepared = _decorateUrl(url);
    await db.insertUrl(prepared);
    await loadUrls();
  }

  // 共有インテント経由で受け取った情報を正規化し保存
  Future<void> addUrlFromShare({
    String? message,
    String? url,
    String? sharedText,
  }) async {
    final normalizedMessage = _normalizeSharedText(message);
    final normalizedSharedText = _normalizeSharedText(sharedText);
    final extractedUrl = _extractValidUrl(url) ??
        _extractValidUrl(normalizedMessage) ??
        _extractValidUrl(normalizedSharedText);

    if (extractedUrl == null) {
      return;
    }

    final resolvedMessage =
        normalizedMessage ?? normalizedSharedText ?? extractedUrl;

    final newUrl = Url(
      message: resolvedMessage,
      url: extractedUrl,
      details: '',
      domain: _deriveDomain(extractedUrl),
      tags: '',
      isStarred: false,
      isRead: false,
      isArchived: false,
      ogImageUrl: null,
      savedAt: DateTime.now(),
    );
    await addUrl(newUrl);
  }

  // URLを外部ブラウザで開き、既読状態の更新を行う
  Future<void> opemUrl(BuildContext context, Url target) async {
    final uri = Uri.tryParse(target.url);
    if (uri == null) {
      return;
    }

    final canLaunch = await canLaunchUrl(uri);

    if (!canLaunch) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('urlが開けません'),
        ),
      );
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (launched && !target.isRead) {
      await markAsRead(target);
    }
  }

  // 論理削除されていないURLの既読状態を更新
  Future<void> markAsRead(Url url) async {
    if (url.isRead) {
      return;
    }
    final db = await _ref.read(provideDatabase.future);
    await db.updateUrl(url.copyWith(isRead: true));
    await loadUrls();
  }

  // 論理削除（undo復元に利用）
  Future<void> deleteUrl(Url url) async {
    final db = await _ref.read(provideDatabase.future);
    _recentlyDeleted = url;
    await db.deleteUrl(url);
    await loadUrls();
  }

  // 新規作成と更新を兼ねた永続化処理
  Future<void> addOrUpdateUrl(Url url) async {
    final db = await _ref.read(provideDatabase.future);
    final prepared = _decorateUrl(url);
    if (prepared.id == null) {
      await db.insertUrl(prepared);
    } else {
      await db.updateUrl(prepared);
    }
    await loadUrls();
  }

  // お気に入りフラグのトグル
  Future<void> toggleStar(Url url) async {
    final db = await _ref.read(provideDatabase.future);
    await db.updateUrl(url.copyWith(isStarred: !url.isStarred));
    await loadUrls();
  }

  // 既読フラグのトグル
  Future<void> toggleRead(Url url) async {
    final db = await _ref.read(provideDatabase.future);
    await db.updateUrl(url.copyWith(isRead: !url.isRead));
    await loadUrls();
  }

  // アーカイブフラグのトグル
  Future<void> toggleArchive(Url url) async {
    final db = await _ref.read(provideDatabase.future);
    await db.updateUrl(url.copyWith(isArchived: !url.isArchived));
    await loadUrls();
  }

  // メタデータ（メモ・タグ等）を更新
  Future<void> updateMetadata(
    Url url, {
    String? details,
    String? tags,
    bool? isStarred,
    bool? isRead,
    bool? isArchived,
  }) async {
    final db = await _ref.read(provideDatabase.future);
    await db.updateUrl(
      url.copyWith(
        details: details ?? url.details,
        tags: tags ?? url.tags,
        isStarred: isStarred ?? url.isStarred,
        isRead: isRead ?? url.isRead,
        isArchived: isArchived ?? url.isArchived,
        domain: _deriveDomain(url.url),
      ),
    );
    await loadUrls();
  }

  // 直前に削除したURLを元に戻す
  Future<void> restoreDeleted() async {
    final toRestore = _recentlyDeleted;
    if (toRestore == null) {
      return;
    }
    _recentlyDeleted = null;
    await addOrUpdateUrl(
        toRestore.copyWith(id: const Value(null), savedAt: DateTime.now()));
  }

  @override
  void dispose() {
    _intentSub?.cancel();
    super.dispose();
  }

  // 保存前にタグやドメインを整形
  Url _decorateUrl(Url url) {
    final normalizedTags = parseTags(url.tags).toSet().join(', ');
    return url.copyWith(
      domain: _deriveDomain(url.url),
      tags: normalizedTags,
      details: url.details,
    );
  }

  // URLからドメイン部分を抽出
  String _deriveDomain(String sourceUrl) {
    try {
      final uri = Uri.parse(sourceUrl);
      return uri.host;
    } catch (_) {
      return '';
    }
  }

  // 共有テキストから不要な空白を除去
  String? _normalizeSharedText(String? text) {
    final trimmed = text?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  // メッセージ本文からURLらしき文字列を抽出
  String? _extractValidUrl(String? text) {
    final normalized = _normalizeSharedText(text);
    if (normalized == null) {
      return null;
    }

    final directMatch = _sanitizeUrl(normalized);
    if (directMatch != null) {
      return directMatch;
    }

    final match = _urlRegExp.firstMatch(normalized);
    if (match != null) {
      return _sanitizeUrl(match.group(0));
    }
    return null;
  }

  // URL文字列から不要な括弧等を取り除き、http/httpsのみ許可
  String? _sanitizeUrl(String? text) {
    if (text == null) {
      return null;
    }

    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final firstSegment = trimmed.split(RegExp('\\s+')).first;
    var cleaned = firstSegment;

    const leadingTrimChars = ['<', '(', '['];
    const trailingTrimChars = ['>', ')', ']'];

    while (cleaned.isNotEmpty && leadingTrimChars.contains(cleaned[0])) {
      cleaned = cleaned.substring(1);
    }

    while (cleaned.isNotEmpty &&
        trailingTrimChars.contains(cleaned[cleaned.length - 1])) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }

    Uri? uri = Uri.tryParse(cleaned);
    if (uri != null && uri.hasScheme) {
      final scheme = uri.scheme.toLowerCase();
      if (scheme == 'http' || scheme == 'https') {
        return uri.toString();
      }
    }

    if ((uri == null || !uri.hasScheme) && cleaned.startsWith('www.')) {
      uri = Uri.tryParse('https://$cleaned');
      if (uri != null) {
        return uri.toString();
      }
    }

    return null;
  }

  // URL検出用の正規表現（http/httpsに限定）
  static final RegExp _urlRegExp =
      RegExp('https?://[^\\s]+', caseSensitive: false);
}
