import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_manager/database.dart';
import 'package:url_manager/models/tag_utils.dart';

final urlListProvider =
    StateNotifierProvider<UrlListNotifier, List<Url>>((ref) {
  return UrlListNotifier(ref);
});

class UrlListNotifier extends StateNotifier<List<Url>> {
  final Ref _ref;
  StreamSubscription? _intentSub;
  StreamSubscription<String?>? _textIntentSub;
  final List<SharedMediaFile> _sharedFiles = [];
  Url? _recentlyDeleted;

  UrlListNotifier(this._ref) : super([]) {
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
        (List<SharedMediaFile> value) {
      _sharedFiles.clear();
      _sharedFiles.addAll(value);
      if (_sharedFiles.isNotEmpty) {
        addUrlFromShare(
          message: _sharedFiles.first.message,
          url: _sharedFiles.first.path,
        );
      }
    }, onError: (err) {
      print("getMediaStream error: $err");
    });

    ReceiveSharingIntent.instance
        .getInitialMedia()
        .then((List<SharedMediaFile> value) {
      _sharedFiles.clear();
      _sharedFiles.addAll(value);
      if (_sharedFiles.isNotEmpty) {
        addUrlFromShare(
          message: _sharedFiles.first.message,
          url: _sharedFiles.first.path,
        );
      }
    });

    _textIntentSub =
        ReceiveSharingIntent.instance.getTextStream().listen((String value) {
      addUrlFromShare(sharedText: value);
    }, onError: (err) {
      print("getTextStream error: $err");
    });

    ReceiveSharingIntent.instance.getInitialText().then((String? value) {
      if (value == null || value.isEmpty) {
        return;
      }
      addUrlFromShare(sharedText: value);
    });

    loadUrls();
  }

  Future<void> loadUrls() async {
    final db = await _ref.read(provideDatabase.future);
    final urls = await db.getAllUrls();
    state = urls;
  }

  Future<void> addUrl(Url url) async {
    final db = await _ref.read(provideDatabase.future);
    final prepared = _decorateUrl(url);
    await db.insertUrl(prepared);
    await loadUrls();
  }

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

    await loadUrls();
    // await sortUrl();
  }

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

  Future<void> markAsRead(Url url) async {
    if (url.isRead) {
      return;
    }
    final db = await _ref.read(provideDatabase.future);
    await db.updateUrl(url.copyWith(isRead: true));
    await loadUrls();
  }

// 論理削除
  Future<void> deleteUrl(Url url) async {
    final db = await _ref.read(provideDatabase.future);
    _recentlyDeleted = url;
    await db.deleteUrl(url);
    await loadUrls();
  }

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

  Future<void> toggleStar(Url url) async {
    final db = await _ref.read(provideDatabase.future);
    await db.updateUrl(url.copyWith(isStarred: !url.isStarred));
    await loadUrls();
  }

  Future<void> toggleRead(Url url) async {
    final db = await _ref.read(provideDatabase.future);
    await db.updateUrl(url.copyWith(isRead: !url.isRead));
    await loadUrls();
  }

  Future<void> toggleArchive(Url url) async {
    final db = await _ref.read(provideDatabase.future);
    await db.updateUrl(url.copyWith(isArchived: !url.isArchived));
    await loadUrls();
  }

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
    _textIntentSub?.cancel();
    super.dispose();
  }

  Url _decorateUrl(Url url) {
    final normalizedTags = parseTags(url.tags).toSet().join(', ');
    return url.copyWith(
      domain: _deriveDomain(url.url),
      tags: normalizedTags,
      details: url.details,
    );
  }

  String _deriveDomain(String sourceUrl) {
    try {
      final uri = Uri.parse(sourceUrl);
      return uri.host;
    } catch (_) {
      return '';
    }
  }

  String? _normalizeSharedText(String? text) {
    final trimmed = text?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

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

    while (cleaned.isNotEmpty &&
        leadingTrimChars.contains(cleaned[0])) {
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

  static final RegExp _urlRegExp =
      RegExp('https?://[^\\s]+', caseSensitive: false);
}
