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

    // 画面サイズに応じたレスポンシブ対応
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isCompactWidth = screenWidth < 400; // 小さい画面（SE, miniなど）
    final isLargeWidth = screenWidth > 600; // 大きい画面（タブレット、横向き）
    final isCompactHeight = screenHeight < 600; // 縦に短い画面（横向き）

    // 画面サイズに応じたパディングを計算
    final horizontalPadding = isCompactWidth
        ? 8.0
        : isLargeWidth
            ? 24.0
            : 16.0;
    final verticalPadding = isCompactHeight ? 8.0 : 16.0;
    final innerPadding = isCompactWidth
        ? 8.0
        : isLargeWidth
            ? 24.0
            : 16.0;

    // フォームの最大幅（大画面での読みやすさのため）
    const maxFormWidth = 500.0;

    // 要素間のスペーシングを画面サイズに応じて調整
    final fieldSpacing = isCompactHeight ? 12.0 : 16.0;
    final chipSpacing = isCompactWidth ? 6.0 : 8.0;
    final actionButtonSpacing = isCompactHeight ? 16.0 : 24.0;

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
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            // シートの背景色もテーマカラーから取得し、ダークテーマでも違和感が出ないようにする。
            color: colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28.0),
              topRight: Radius.circular(28.0),
            ),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Form(
            key: _formKey,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxFormWidth),
                child: ListView(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(innerPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                borderSide:
                                    BorderSide(color: colorScheme.outline),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: colorScheme.primary, width: 2),
                              ),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest,
                              // 小さい画面用にコンテンツの余白を調整
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isCompactWidth ? 12 : 16,
                                vertical: isCompactHeight ? 12 : 16,
                              ),
                            ),
                            validator: (value) {
                              if (value != null && value.length >= 100) {
                                return '最大文字数は100文字です。';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: fieldSpacing),
                          TextFormField(
                            controller: _urlController,
                            minLines: 1,
                            maxLines: isCompactHeight ? 2 : null,
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
                                borderSide:
                                    BorderSide(color: colorScheme.outline),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: colorScheme.primary, width: 2),
                              ),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isCompactWidth ? 12 : 16,
                                vertical: isCompactHeight ? 12 : 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'URLを入力してください。';
                              }
                              // URL形式のバリデーション
                              final uri = Uri.tryParse(value.trim());
                              if (uri == null || !uri.hasScheme) {
                                return '有効なURL形式で入力してください。';
                              }
                              // http/httpsスキームのみ許可
                              final scheme = uri.scheme.toLowerCase();
                              if (scheme != 'http' && scheme != 'https') {
                                return 'http://またはhttps://で始まるURLを入力してください。';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: fieldSpacing),
                          TextFormField(
                            controller: _noteController,
                            minLines: 1,
                            maxLines: isCompactHeight ? 2 : 4,
                            decoration: InputDecoration(
                              labelText: 'メモ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: colorScheme.outline),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: colorScheme.primary, width: 2),
                              ),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isCompactWidth ? 12 : 16,
                                vertical: isCompactHeight ? 12 : 16,
                              ),
                            ),
                          ),
                          SizedBox(height: fieldSpacing),
                          TextFormField(
                            controller: _tagsController,
                            decoration: InputDecoration(
                              labelText: 'タグ（カンマ区切り）',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: colorScheme.outline),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: colorScheme.primary, width: 2),
                              ),
                              helperText: '例: Flutter, Drift, 要約',
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isCompactWidth ? 12 : 16,
                                vertical: isCompactHeight ? 12 : 16,
                              ),
                            ),
                          ),
                          if (existingTags.isNotEmpty) ...[
                            SizedBox(height: isCompactHeight ? 8 : 12),
                            // 既存タグから選択できるチップ一覧を表示
                            Wrap(
                              spacing: chipSpacing,
                              runSpacing: chipSpacing,
                              children: existingTags
                                  .map(
                                    (tag) => ChoiceChip(
                                      label: Text(
                                        tag,
                                        style: TextStyle(
                                          fontSize: isCompactWidth ? 12 : 14,
                                        ),
                                      ),
                                      selected: currentTags.contains(tag),
                                      onSelected: (_) => _toggleTag(tag),
                                      visualDensity: isCompactWidth
                                          ? VisualDensity.compact
                                          : VisualDensity.standard,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                          SizedBox(height: fieldSpacing),
                          Wrap(
                            spacing: isCompactWidth ? 8 : 12,
                            runSpacing: chipSpacing,
                            children: [
                              FilterChip(
                                label: Text(
                                  'スター',
                                  style: TextStyle(
                                    fontSize: isCompactWidth ? 12 : 14,
                                  ),
                                ),
                                selected: _isStarred,
                                onSelected: (value) {
                                  setState(() {
                                    _isStarred = value;
                                  });
                                },
                                visualDensity: isCompactWidth
                                    ? VisualDensity.compact
                                    : VisualDensity.standard,
                              ),
                              FilterChip(
                                label: Text(
                                  '既読',
                                  style: TextStyle(
                                    fontSize: isCompactWidth ? 12 : 14,
                                  ),
                                ),
                                selected: _isRead,
                                onSelected: (value) {
                                  setState(() {
                                    _isRead = value;
                                  });
                                },
                                visualDensity: isCompactWidth
                                    ? VisualDensity.compact
                                    : VisualDensity.standard,
                              ),
                              FilterChip(
                                label: Text(
                                  'アーカイブ',
                                  style: TextStyle(
                                    fontSize: isCompactWidth ? 12 : 14,
                                  ),
                                ),
                                selected: _isArchived,
                                onSelected: (value) {
                                  setState(() {
                                    _isArchived = value;
                                  });
                                },
                                visualDensity: isCompactWidth
                                    ? VisualDensity.compact
                                    : VisualDensity.standard,
                              ),
                            ],
                          ),
                          SizedBox(height: actionButtonSpacing),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _addOrUpdateUrl,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isCompactWidth ? 24 : 32,
                                  vertical: isCompactHeight ? 10 : 12,
                                ),
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                              ),
                              child: Text(widget.url == null ? '追加' : '更新'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
