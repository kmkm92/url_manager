import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:url_manager/database.dart';
import 'package:url_manager/models/tag_utils.dart';
import 'package:url_manager/view_models/url_view_model.dart';

// URLの追加・編集フォーム画面全体を管理するステートフルウィジェット
class AddUrlFormView extends ConsumerStatefulWidget {
  final Url? url;

  AddUrlFormView({this.url});

  @override
  _AddUrlFormViewState createState() => _AddUrlFormViewState();
}

class _AddUrlFormViewState extends ConsumerState<AddUrlFormView> {
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  final _noteController = TextEditingController();
  final _tagsController = TextEditingController();
  String? _errorMessage;
  bool _isStarred = false;
  bool _isRead = false;
  bool _isArchived = false;

  @override
  void initState() {
    super.initState();
    // 編集時には既存データを各入力欄に反映する
    if (widget.url != null) {
      _titleController.text = widget.url!.message;
      _urlController.text = widget.url!.url;
      _noteController.text = widget.url!.details;
      _tagsController.text = widget.url!.tags;
      _isStarred = widget.url!.isStarred;
      _isRead = widget.url!.isRead;
      _isArchived = widget.url!.isArchived;
    }
    // フィールドの表示更新のためにリスナーを設定
    _urlController.addListener(_updateUrlFieldHeight);
    _tagsController.addListener(_onTagsChanged);
  }

  @override
  void dispose() {
    // リスナーの解除とコントローラーの破棄でメモリリークを防ぐ
    _urlController.removeListener(_updateUrlFieldHeight);
    _tagsController.removeListener(_onTagsChanged);
    _titleController.dispose();
    _urlController.dispose();
    _noteController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  // URL入力欄の高さを動的に再描画するためのリスナー
  void _updateUrlFieldHeight() {
    setState(() {});
  }

  // タグ入力欄の変更を監視し、チップの選択状態を更新する
  void _onTagsChanged() {
    setState(() {});
  }

  // URLリストから既存タグを抽出し、重複排除したソート済み集合にして返す
  SplayTreeSet<String> _collectExistingTags(Iterable<Url> urls) {
    final sortedTags = SplayTreeSet<String>();
    for (final url in urls) {
      sortedTags.addAll(parseTags(url.tags));
    }
    return sortedTags;
  }

  // 現在入力済みのタグをセットとして取得し、ChoiceChipの状態判定に用いる
  Set<String> _currentTagSelection() {
    return parseTags(_tagsController.text).toSet();
  }

  // 既存タグ候補のチップをタップした際に、テキストフィールドのタグ文字列を更新する処理
  void _toggleTag(String tag) {
    final sortedTagSet = SplayTreeSet<String>()
      ..addAll(parseTags(_tagsController.text));

    if (sortedTagSet.contains(tag)) {
      sortedTagSet.remove(tag);
    } else {
      sortedTagSet.add(tag);
    }

    final updatedText = sortedTagSet.join(', ');
    setState(() {
      _tagsController.text = updatedText;
      _tagsController.selection = TextSelection.fromPosition(
        TextPosition(offset: _tagsController.text.length),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final urls = ref.watch(urlListProvider);
    // 既存URLのタグを収集してソート済み集合にまとめる
    final sortedExistingTags = _collectExistingTags(urls);
    // 現在入力されているタグをセット化し、ChoiceChipの選択状態に反映する
    final currentTagSet = _currentTagSelection();

    // 入力フォーム全体のレイアウトを構築する
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(30.0),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.check),
              onPressed: _addOrUpdateUrl,
            ),
          ],
        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
          ),
          child: ListView(
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        floatingLabelStyle: TextStyle(
                          color: Colors.black,
                        ),
                        labelText: 'タイトル',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _urlController,
                      minLines: 1,
                      maxLines: null,
                      decoration: InputDecoration(
                        floatingLabelStyle: TextStyle(
                          color: Colors.black,
                        ),
                        labelText: 'URL',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _noteController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'メモ (Markdown 可)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        labelText: 'タグ（カンマ区切り）',
                        border: OutlineInputBorder(),
                        helperText: '例: Flutter, Drift, 要約',
                      ),
                    ),
                    if (sortedExistingTags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        // 既存タグ候補を一覧で表示し、タップで入力欄へ反映する
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final tag in sortedExistingTags)
                              ChoiceChip(
                                label: Text(tag),
                                selected: currentTagSet.contains(tag),
                                onSelected: (_) => _toggleTag(tag),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // ステータスに紐づくフィルターチップ群
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('スター'),
                          selected: _isStarred,
                          onSelected: (value) {
                            setState(() {
                              _isStarred = value;
                            });
                          },
                        ),
                        FilterChip(
                          label: const Text('既読'),
                          selected: _isRead,
                          onSelected: (value) {
                            setState(() {
                              _isRead = value;
                            });
                          },
                        ),
                        FilterChip(
                          label: const Text('アーカイブ'),
                          selected: _isArchived,
                          onSelected: (value) {
                            setState(() {
                              _isArchived = value;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _addOrUpdateUrl,
                      child: Text(widget.url == null ? '追加' : '更新'),
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 入力された内容でURLレコードを作成・更新し、状態管理へ反映する
  Future<void> _addOrUpdateUrl() async {
    if (_urlController.text.isEmpty) {
      setState(() {
        _errorMessage = 'URLを入力してください。';
      });
      return;
    }
    if (_titleController.text.length >= 100) {
      setState(() {
        _errorMessage = '最大文字数は100文字です。';
      });
      return;
    }

    final newUrl = Url(
      id: widget.url?.id,
      message: _titleController.text,
      url: _urlController.text,
      details: _noteController.text,
      tags: _tagsController.text,
      domain: widget.url?.domain ?? '',
      isStarred: _isStarred,
      isRead: _isRead,
      isArchived: _isArchived,
      ogImageUrl: widget.url?.ogImageUrl,
      savedAt: widget.url?.savedAt ?? DateTime.now(),
    );
    ref.read(urlListProvider.notifier).addOrUpdateUrl(newUrl);
    Navigator.pop(context);
  }
}
