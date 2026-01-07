import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:url_manager/database.dart';
import 'package:url_manager/models/tag_utils.dart';
import 'package:url_manager/view_models/url_view_model.dart';

class UrlDetailSheet extends ConsumerStatefulWidget {
  const UrlDetailSheet({
    super.key,
    required this.controller,
    required this.url,
    required this.onEdit,
  });

  final ScrollController controller;
  final Url url;
  final void Function([Url? url]) onEdit;

  @override
  ConsumerState<UrlDetailSheet> createState() => _UrlDetailSheetState();
}

class _UrlDetailSheetState extends ConsumerState<UrlDetailSheet> {
  late TextEditingController _memoController;
  late TextEditingController _tagsController;
  late bool _isStarred;
  late bool _isRead;
  late bool _isArchived;

  @override
  void initState() {
    super.initState();
    _memoController = TextEditingController(text: widget.url.details);
    _tagsController = TextEditingController(text: widget.url.tags);
    _isStarred = widget.url.isStarred;
    _isRead = widget.url.isRead;
    _isArchived = widget.url.isArchived;
  }

  @override
  void dispose() {
    _memoController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final urls = ref.watch(urlListProvider);
    final latest = urls.firstWhere(
      (item) => item.id == widget.url.id,
      orElse: () => widget.url,
    );
    final duplicates = urls
        .where((candidate) =>
            candidate.id != latest.id &&
            (candidate.url == latest.url ||
                (candidate.domain.isNotEmpty &&
                    candidate.domain == latest.domain)))
        .toList();

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          controller: widget.controller,
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (latest.ogImageUrl != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Hero(
                    tag: 'url-image-${latest.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        latest.ogImageUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox.shrink(); // エラー時は表示しない
                        },
                      ),
                    ),
                  ),
                ),
              Text(
                latest.domain.isEmpty ? '保存元不明' : latest.domain,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      latest.message.isEmpty ? latest.url : latest.message,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: '編集',
                    onPressed: () {
                      widget.onEdit(latest);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('yyyy/MM/dd HH:mm').format(latest.savedAt),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      ref
                          .read(urlListProvider.notifier)
                          .openUrl(context, latest);
                    },
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('ブラウザで開く'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: latest.url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('リンクをコピーしました')),
                      );
                    },
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('コピー'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'メモ',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _memoController,
                maxLines: 6,
                minLines: 3,
                decoration: const InputDecoration(
                  hintText: '気づきやTODOをメモ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'タグ（カンマ区切り）',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: [
                  FilterChip(
                    label: const Text('スター'),
                    selected: _isStarred,
                    onSelected: (value) {
                      setState(() {
                        _isStarred = value;
                      });
                      ref
                          .read(urlListProvider.notifier)
                          .updateMetadata(latest, isStarred: value);
                    },
                  ),
                  FilterChip(
                    label: const Text('既読'),
                    selected: _isRead,
                    onSelected: (value) {
                      setState(() {
                        _isRead = value;
                      });
                      ref
                          .read(urlListProvider.notifier)
                          .updateMetadata(latest, isRead: value);
                    },
                  ),
                  FilterChip(
                    label: const Text('アーカイブ'),
                    selected: _isArchived,
                    onSelected: (value) {
                      setState(() {
                        _isArchived = value;
                      });
                      ref
                          .read(urlListProvider.notifier)
                          .updateMetadata(latest, isArchived: value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    ref.read(urlListProvider.notifier).updateMetadata(
                          latest,
                          details: _memoController.text,
                          tags: _tagsController.text,
                        );
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('保存'),
                ),
              ),
              const SizedBox(height: 24),
              if (_tagsController.text.trim().isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final tag in parseTags(_tagsController.text))
                      Chip(
                        avatar: const Icon(Icons.tag, size: 16),
                        label: Text(tag),
                      ),
                  ],
                ),
              if (duplicates.isNotEmpty) ...[
                const SizedBox(height: 24),
                // トグル形式の重複候補セクション
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Theme(
                    // ExpansionTileのデフォルトの境界線を削除
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      childrenPadding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 8,
                      ),
                      leading: Icon(
                        Icons.content_copy_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(
                        '同一ドメイン',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${duplicates.length} 件',
                        style: theme.textTheme.bodySmall,
                      ),
                      children: duplicates
                          .map(
                            (candidate) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.link_outlined),
                              title: Text(
                                candidate.message.isEmpty
                                    ? candidate.url
                                    : candidate.message,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                DateFormat('yyyy/MM/dd HH:mm')
                                    .format(candidate.savedAt),
                              ),
                              onTap: () {
                                Navigator.of(context).pop();
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) {
                                    return DraggableScrollableSheet(
                                      expand: false,
                                      maxChildSize: 0.95,
                                      initialChildSize: 0.85,
                                      minChildSize: 0.5,
                                      builder: (context, controller) {
                                        return UrlDetailSheet(
                                          controller: controller,
                                          url: candidate,
                                          onEdit: widget.onEdit,
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
