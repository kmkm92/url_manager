import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:url_launcher/url_launcher.dart';
import 'package:url_manager/database.dart';
import 'package:url_manager/models/tag_utils.dart';
import 'package:favicon/favicon.dart';
import 'package:url_manager/view_models/settings_preferences_view_model.dart';

final urlListProvider =
    StateNotifierProvider<UrlListNotifier, List<Url>>((ref) {
  return UrlListNotifier(ref);
});

/// 起動時に開くタブのインデックスを管理するProvider
/// 設定のstartupTabに基づいて初期値を設定する
final homeTabIndexProvider = StateProvider<int>((ref) {
  // 設定から起動時タブを取得（初期化時のみ読み取り）
  final settings = ref.read(settingsPreferencesProvider);
  return settings.startupTab.index;
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
    // getMediaStream(): アプリ起動中に共有を受け取るストリーム
    _intentSub = _eventChannel.receiveBroadcastStream().listen(
      (dynamic value) {
        if (value is List) {
          _sharedFiles.clear();
          for (final item in value) {
            if (item is Map) {
              _sharedFiles.add(SharedMediaFile.fromMap(item));
            }
          }
          if (_sharedFiles.isNotEmpty) {
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
        // エラーは無視して継続
      },
    );

    // getInitialMedia(): アプリ起動時の初期共有データを取得
    _getInitialMedia().then((List<SharedMediaFile> value) {
      _sharedFiles.clear();
      _sharedFiles.addAll(value);
      if (_sharedFiles.isNotEmpty) {
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
      final result =
          await _methodChannel.invokeMethod<List<dynamic>>('getInitialMedia');
      if (result == null) return [];

      return result
          .whereType<Map>()
          .map((item) => SharedMediaFile.fromMap(item))
          .toList();
    } on PlatformException {
      return [];
    }
  }

  /// 共有データをリセット（receive_sharing_intent.reset() と同等）
  Future<void> _resetSharedData() async {
    try {
      await _methodChannel.invokeMethod('reset');
    } on PlatformException {
      // リセット失敗は無視
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
    final prepared = await _decorateUrl(url);
    await db.insertUrl(prepared);
    await loadUrls();
  }

  // 共有インテント経由で受け取った情報を正規化し保存
  Future<void> addUrlFromShare({
    String? message,
    String? url,
    String? sharedText,
  }) async {
    // ホーム（ライブラリ）タブに切り替え
    _ref.read(homeTabIndexProvider.notifier).state = 0;

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
  Future<void> openUrl(BuildContext context, Url target) async {
    final uri = Uri.tryParse(target.url);
    if (uri == null) {
      return;
    }

    final canLaunch = await canLaunchUrl(uri);

    // 非同期処理後はcontext.mountedをチェックしてウィジェット破棄後のエラーを防止
    if (!context.mounted) return;

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
    final prepared = await _decorateUrl(url);
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

  // 保存前にタグやドメイン、ファビコンを整形・取得
  Future<Url> _decorateUrl(Url url) async {
    final normalizedTags = parseTags(url.tags).toSet().join(', ');
    // ファビコンがまだ取得されていない場合のみ取得
    String? faviconUrl = url.faviconUrl;
    if (faviconUrl == null || faviconUrl.isEmpty) {
      faviconUrl = await _fetchFavicon(url.url);
    }
    return url.copyWith(
      domain: _deriveDomain(url.url),
      tags: normalizedTags,
      details: url.details,
      faviconUrl: Value(faviconUrl),
    );
  }

  // URLからファビコンを取得
  Future<String?> _fetchFavicon(String url) async {
    try {
      final icon = await FaviconFinder.getBest(url);
      return icon?.url;
    } catch (_) {
      return null;
    }
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
