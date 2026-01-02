// URL保存フォーム画面を描画し、入力内容の保存を担うウィジェット。

import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_manager/database.dart';
import 'package:url_manager/models/tag_utils.dart';
import 'package:url_manager/view_models/url_view_model.dart';

class AddUrlFormView extends ConsumerStatefulWidget {
  final Url? url;

  AddUrlFormView({this.url});

  @override
  _AddUrlFormViewState createState() => _AddUrlFormViewState();
}

class _AddUrlFormViewState extends ConsumerState<AddUrlFormView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  final _noteController = TextEditingController();
  final _tagsController = TextEditingController();
  bool _isStarred = false;
  bool _isRead = false;
  bool _isArchived = false;

  @override
  void initState() {
    super.initState();
    if (widget.url != null) {
      _titleController.text = widget.url!.message;
      _urlController.text = widget.url!.url;
      _noteController.text = widget.url!.details;
      _tagsController.text = widget.url!.tags;
      _isStarred = widget.url!.isStarred;
      _isRead = widget.url!.isRead;
      _isArchived = widget.url!.isArchived;
    }
    _urlController.addListener(_updateUrlFieldHeight);
  }

  @override
  void dispose() {
    _urlController.removeListener(_updateUrlFieldHeight);
    _titleController.dispose();
    _urlController.dispose();
    _noteController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _updateUrlFieldHeight() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // 画面描画時に利用するテーマ色情報をまとめて取得しておく。

    // URLリストの監視を行い、既存タグ候補を抽出する
    final urls = ref.watch(urlListProvider);
    final existingTags = SplayTreeSet<String>.from(
      urls.expand((url) => parseTags(url.tags)),
    );
    final currentTags = parseTags(_tagsController.text);

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surface,
        elevation: 0,
        title: const Text('URLを保存'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _addOrUpdateUrl,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            // シートの背景色もテーマカラーから取得し、ダークテーマでも違和感が出ないようにする。
            color: colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          // ラベル色や枠線色をテーマに追従させ、ライト/ダーク双方で読みやすくする。
                          floatingLabelStyle:
                              TextStyle(color: colorScheme.onSurface),
                          labelText: 'タイトル',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.outline),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: colorScheme.primary, width: 2),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                        ),
                        validator: (value) {
                          if (value != null && value.length >= 100) {
                            return '最大文字数は100文字です。';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _urlController,
                        minLines: 1,
                        maxLines: null,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.url],
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          floatingLabelStyle:
                              TextStyle(color: colorScheme.onSurface),
                          labelText: 'URL',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.outline),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: colorScheme.primary, width: 2),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'URLを入力してください。';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _noteController,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'メモ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.outline),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: colorScheme.primary, width: 2),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _tagsController,
                        decoration: InputDecoration(
                          labelText: 'タグ（カンマ区切り）',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.outline),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: colorScheme.primary, width: 2),
                          ),
                          helperText: '例: Flutter, Drift, 要約',
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      if (existingTags.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        // 既存タグから選択できるチップ一覧を表示
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: existingTags
                              .map(
                                (tag) => ChoiceChip(
                                  label: Text(tag),
                                  selected: currentTags.contains(tag),
                                  onSelected: (_) => _toggleTag(tag),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 16),
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
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                        child: Text(widget.url == null ? '追加' : '更新'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addOrUpdateUrl() async {
    // フォーム入力を検証し、状態に応じてURLを新規保存または更新する。
    if (!(_formKey.currentState?.validate() ?? false)) return;

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

  // チップタップ時にタグ入力欄のテキストを整形しながら更新する
  void _toggleTag(String tag) {
    final normalizedTag = tag.trim();
    final tags = LinkedHashSet<String>.from(parseTags(_tagsController.text));

    if (tags.contains(normalizedTag)) {
      tags.remove(normalizedTag);
    } else {
      tags.add(normalizedTag);
    }

    setState(() {
      final updated = tags.join(', ');
      _tagsController
        ..text = updated
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: updated.length),
        );
    });
  }
}
