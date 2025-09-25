import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_manager/database.dart';
import 'package:url_manager/view_models/url_view_model.dart';

/// URL の新規作成・更新を行うフォーム画面。
///
/// 事前に渡された [Url] がある場合は編集モードとして利用し、
/// テキストフィールドや各種フラグの初期値へ反映する。
class AddUrlFormView extends ConsumerStatefulWidget {
  final Url? url;

  const AddUrlFormView({Key? key, this.url}) : super(key: key);

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
    // テーマのカラースキームを取得し、ライト/ダーク双方で自然に見える配色へ合わせる。
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        // 編集か新規追加かが一目で分かるタイトルを表示する。
        title: Text(widget.url == null ? 'URLを追加' : 'URLを更新'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: widget.url == null ? '保存して追加' : '保存して更新',
            onPressed: _addOrUpdateUrl,
          ),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          // フォーム外をタップしたらキーボードを閉じる。
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0),
              ),
              boxShadow: theme.brightness == Brightness.light
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, -2),
                      ),
                    ]
                  : null,
            ),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),
                // タイトル入力フィールド。
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'タイトル',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: colorScheme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // URL 入力フィールド。複数行入力にも対応する。
                TextField(
                  controller: _urlController,
                  minLines: 1,
                  maxLines: null,
                  decoration: InputDecoration(
                    labelText: 'URL',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: colorScheme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // メモ入力欄。Markdown 対応で複数行を許容する。
                TextField(
                  controller: _noteController,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'メモ (Markdown 可)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: colorScheme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // タグ入力欄。サジェスト用途のヘルパーテキストを表示する。
                TextField(
                  controller: _tagsController,
                  decoration: InputDecoration(
                    labelText: 'タグ（カンマ区切り）',
                    helperText: '例: Flutter, Drift, 要約',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: colorScheme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // URL の状態を表すフラグ群。FilterChip で ON/OFF を切り替える。
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
                // フォーム全体を保存するアクションボタン。
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addOrUpdateUrl,
                    child: Text(widget.url == null ? '追加' : '更新'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 入力値を検証し、URL の新規作成または更新を行う。
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
