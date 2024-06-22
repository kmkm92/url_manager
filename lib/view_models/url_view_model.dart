import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_manager/database.dart';

final urlListProvider =
    StateNotifierProvider<UrlListNotifier, List<Url>>((ref) {
  return UrlListNotifier(ref);
});

class UrlListNotifier extends StateNotifier<List<Url>> {
  final Ref _ref;
  StreamSubscription? _intentSub;
  final List<SharedMediaFile> _sharedFiles = [];

  UrlListNotifier(this._ref) : super([]) {
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
        (List<SharedMediaFile> value) {
      _sharedFiles.clear();
      _sharedFiles.addAll(value);
      if (_sharedFiles.isNotEmpty) {
        addUrlFromShare(_sharedFiles.first.message!, _sharedFiles.first.path);
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
        addUrlFromShare(_sharedFiles.first.message!, _sharedFiles.first.path);
      }
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

    final insertId = await db.insertUrl(url);

    await loadUrls();
  }

  Future<void> addUrlFromShare(String message, String url) async {
    final newUrl = Url(
      message: message,
      url: url,
      details: '',
      savedAt: DateTime.now(),
    );
    await addUrl(newUrl);

    await loadUrls();
    // await sortUrl();
  }

  Future<void> opemUrl(BuildContext context, stringUrl) async {
    final url = Uri.parse(stringUrl);
    final _canLaunch = await canLaunchUrl(url);

    if (!_canLaunch) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('urlが開けません'),
        ),
      );
    }
    launchUrl(url);
    await loadUrls();
  }

// 論理削除
  Future<void> deleteUrl(Url url) async {
    final db = await _ref.read(provideDatabase.future);
    final deleteId = await db.deleteUrl(url);

    await loadUrls();
  }

  Future<void> addOrUpdateUrl(Url url) async {
    final db = await _ref.read(provideDatabase.future);
    if (url.id == null) {
      // 新しいタスクを追加
      final insertId = await db.insertUrl(url);
    } else {
      // 既存のタスクを更新
      await db.updateUrl(url);
    }
    // loadUrls();
    await loadUrls();
  }
}
