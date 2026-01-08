// URLカード表示用のウィジェット群。
// URLカード、スワイプ背景、ステータスバッジ、サムネイルを含む。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_manager/database.dart';
import 'package:url_manager/models/tag_utils.dart';
import 'package:url_manager/view_models/url_view_model.dart';
import 'package:url_manager/views/widgets/delete_confirm_dialog.dart';
import 'package:url_manager/views/widgets/url_detail_sheet.dart';

/// タグ文字列をリストに変換するヘルパー
List<String> extractTags(String raw) {
  return parseTags(raw);
}

/// URLカードウィジェット
class UrlCard extends ConsumerWidget {
  const UrlCard({super.key, required this.url, required this.onEdit});

  final Url url;
  final void Function([Url? url]) onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tags = extractTags(url.tags);
    final savedAt = DateFormat('yyyy/MM/dd HH:mm').format(url.savedAt);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Dismissible(
        key: ValueKey('url-${url.id ?? url.url}'),
        background: SwipeBackground(
          color: theme.colorScheme.tertiaryContainer,
          icon: url.isArchived
              ? Icons.unarchive_outlined
              : Icons.archive_outlined,
          alignment: Alignment.centerLeft,
          label: url.isArchived ? 'アーカイブ解除' : 'アーカイブ',
        ),
        secondaryBackground: SwipeBackground(
          color: theme.colorScheme.errorContainer,
          icon: Icons.delete_outline,
          alignment: Alignment.centerRight,
          label: '削除',
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            await ref.read(urlListProvider.notifier).toggleArchive(url);
            HapticFeedback.mediumImpact();
            if (!context.mounted) return false;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(url.isArchived ? 'アーカイブを解除しました' : 'アーカイブしました'),
                duration: const Duration(seconds: 1),
              ),
            );
            return false;
          }
          if (direction == DismissDirection.endToStart) {
            final confirmed = await showDeleteConfirmDialog(
              context: context,
              ref: ref,
              title: 'このURLを削除しますか？',
              message: url.message.isEmpty ? url.url : url.message,
            );
            if (!confirmed) return false;

            await ref.read(urlListProvider.notifier).deleteUrl(url);
            HapticFeedback.heavyImpact();
            return false;
          }
          return false;
        },
        child: Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            onTap: () {
              _showDetailSheet(context, ref, url, onEdit);
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'url-image-${url.id}',
                        child: Thumbnail(
                            domain: url.domain,
                            imageUrl: url.ogImageUrl,
                            faviconUrl: url.faviconUrl),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (!url.isRead) ...[
                                        StatusBadge(
                                          label: '未読',
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(height: 6),
                                      ],
                                      Text(
                                        url.message.isEmpty
                                            ? url.url
                                            : url.message,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  style: IconButton.styleFrom(
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  icon: Icon(
                                    url.isStarred
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: url.isStarred
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () {
                                    ref
                                        .read(urlListProvider.notifier)
                                        .toggleStar(url);
                                  },
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  style: IconButton.styleFrom(
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  icon: Icon(Icons.more_horiz,
                                      color:
                                          theme.colorScheme.onSurfaceVariant),
                                  onPressed: () {
                                    _showActionSheet(context, ref, url);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              url.domain.isEmpty ? '保存元不明' : url.domain,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (url.details.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      url.details,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final tag in tags)
                          Chip(
                            avatar: const Icon(Icons.tag, size: 16),
                            label: Text(tag),
                            labelStyle: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        savedAt,
                        style: theme.textTheme.bodySmall,
                      ),
                      TextButton.icon(
                        onPressed: () {
                          ref
                              .read(urlListProvider.notifier)
                              .openUrl(context, url);
                        },
                        icon: const Icon(Icons.open_in_browser),
                        label: const Text('開く'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showActionSheet(
    BuildContext context,
    WidgetRef ref,
    Url url,
  ) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: const Text('ブラウザで開く'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(urlListProvider.notifier).openUrl(context, url);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: const Text('リンクをコピー'),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: url.url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('リンクをコピーしました')),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  url.isRead ? Icons.mark_email_read : Icons.markunread,
                ),
                title: Text(url.isRead ? '未読に戻す' : '既読にする'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(urlListProvider.notifier).toggleRead(url);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('編集'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit(url);
                },
              ),
              ListTile(
                leading: Icon(url.isArchived
                    ? Icons.unarchive_outlined
                    : Icons.archive_outlined),
                title: Text(
                  url.isArchived ? 'アーカイブ解除' : 'アーカイブ',
                ),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(urlListProvider.notifier).toggleArchive(url);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text(url.isArchived ? 'アーカイブを解除しました' : 'アーカイブしました'),
                    ),
                  );
                },
              ),
              Divider(
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ListTile(
                leading:
                    Icon(Icons.delete_outline, color: theme.colorScheme.error),
                title: Text('削除',
                    style: TextStyle(color: theme.colorScheme.error)),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmed = await showDeleteConfirmDialog(
                    context: context,
                    ref: ref,
                    title: 'このURLを削除しますか？',
                    message: url.message.isEmpty ? url.url : url.message,
                  );
                  if (confirmed) {
                    await ref.read(urlListProvider.notifier).deleteUrl(url);
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showDetailSheet(
    BuildContext context,
    WidgetRef ref,
    Url url,
    void Function([Url? url]) onEdit,
  ) {
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
              url: url,
              onEdit: onEdit,
            );
          },
        );
      },
    );
  }
}

/// スワイプ時の背景表示ウィジェット
class SwipeBackground extends StatelessWidget {
  const SwipeBackground({
    super.key,
    required this.color,
    required this.icon,
    required this.alignment,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final Alignment alignment;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.black87),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// ステータスバッジウィジェット
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// サムネイル表示ウィジェット
class Thumbnail extends StatelessWidget {
  const Thumbnail({
    super.key,
    required this.domain,
    required this.imageUrl,
    this.faviconUrl,
  });

  final String domain;
  final String? imageUrl;
  final String? faviconUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ファビコンがある場合はファビコンを表示、なければOG画像、どちらもなければアイコン
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final hasFavicon = faviconUrl != null && faviconUrl!.isNotEmpty;

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.05),
          width: 1,
        ),
        // OG画像がある場合は背景として表示
        image: hasImage
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
                onError: (_, __) {},
              )
            : null,
      ),
      alignment: Alignment.center,
      child: _buildContent(theme, hasImage, hasFavicon),
    );
  }

  Widget? _buildContent(ThemeData theme, bool hasImage, bool hasFavicon) {
    // OG画像がある場合: ファビコンを左下にオーバーレイ
    if (hasImage && hasFavicon) {
      return Align(
        alignment: Alignment.bottomLeft,
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              faviconUrl!,
              width: 18,
              height: 18,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
      );
    }

    // OG画像がなくファビコンがある場合: ファビコンを中央に大きく表示
    if (!hasImage && hasFavicon) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          faviconUrl!,
          width: 40,
          height: 40,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.public,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            size: 32,
          ),
        ),
      );
    }

    // OG画像がある場合: 何も表示しない
    if (hasImage) {
      return null;
    }

    // どちらもない場合: デフォルトアイコン
    return Icon(
      Icons.public,
      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      size: 32,
    );
  }
}

/// 空の状態表示ウィジェット
class UrlListEmptyState extends StatelessWidget {
  const UrlListEmptyState(
      {super.key, required this.hasUrls, required this.onAdd});

  final bool hasUrls;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasUrls ? Icons.filter_alt_off_outlined : Icons.inbox_outlined,
            size: 72,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            hasUrls ? '条件に合うアイテムがありません' : 'まだ保存されていません',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            hasUrls
                ? 'フィルタを変更するか新しいURLを追加してください。'
                : '共有メニューや右下の「保存」からURLを追加しましょう。',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('URLを保存'),
          ),
        ],
      ),
    );
  }
}
