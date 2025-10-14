import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_manager/database.dart';
import 'package:url_manager/models/tag_utils.dart';
import 'package:url_manager/view_models/url_view_model.dart';
import 'package:url_manager/views/history_view.dart';
import 'package:url_manager/views/settings_root_view.dart';
import 'package:url_manager/views/url_add_view.dart';
import 'package:url_manager/views/widgets/url_detail_sheet.dart';
// import 'package:url_manager/view_models/url_summary_view_model.dart';
// import 'package:url_manager/views/ai_settings_view.dart';
// import 'package:url_manager/views/url_summary_view.dart';
// ↑ 初期リリースではAI要約機能を搭載しないため、関連する画面とViewModelの読み込みを一時的に無効化している。

final searchQueryProvider = StateProvider<String>((ref) => '');
final statusFilterProvider =
    StateProvider<Set<StatusFilter>>((ref) => <StatusFilter>{});
final domainFilterProvider = StateProvider<String?>((ref) => null);
final tagFilterProvider = StateProvider<String?>((ref) => null);

enum StatusFilter { unread, starred, archived }

extension on StatusFilter {
  String get label {
    switch (this) {
      case StatusFilter.unread:
        return '未読';
      case StatusFilter.starred:
        return 'スター';
      case StatusFilter.archived:
        return 'アーカイブ';
    }
  }

  IconData get icon {
    switch (this) {
      case StatusFilter.unread:
        return Icons.markunread_outlined;
      case StatusFilter.starred:
        return Icons.star_outline;
      case StatusFilter.archived:
        return Icons.archive_outlined;
    }
  }
}

class UrlListView extends ConsumerStatefulWidget {
  const UrlListView({super.key});

  @override
  ConsumerState<UrlListView> createState() => _UrlListViewState();
}

class _UrlListViewState extends ConsumerState<UrlListView> {
  int _currentIndex = 0;

  void _showAddUrlForm([Url? url]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: AddUrlFormView(url: url),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeTab(
            onEdit: _showAddUrlForm,
          ),
          HistoryView(
            onEdit: (context, url) {
              _showAddUrlForm(url);
            },
          ),
          const SettingsRootView(),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _showAddUrlForm,
              icon: const Icon(Icons.add),
              label: const Text('保存'),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (value) {
          setState(() {
            _currentIndex = value;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: '履歴',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    );
  }
}

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key, required this.onEdit});

  final void Function([Url? url]) onEdit;

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(searchQueryProvider),
    );
    _searchController.addListener(() {
      ref.read(searchQueryProvider.notifier).state = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = ref.watch(urlListProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final statusFilters = ref.watch(statusFilterProvider);
    final domainFilter = ref.watch(domainFilterProvider);
    final tagFilter = ref.watch(tagFilterProvider);

    final filteredUrls = urls.where((url) {
      final tags = _extractTags(url.tags);
      final matchesSearch = searchQuery.isEmpty ||
          url.message.toLowerCase().contains(searchQuery.toLowerCase()) ||
          url.url.toLowerCase().contains(searchQuery.toLowerCase()) ||
          url.details.toLowerCase().contains(searchQuery.toLowerCase()) ||
          tags.any((tag) => tag.toLowerCase().contains(searchQuery.toLowerCase()));

      final matchesStatus = () {
        if (statusFilters.isEmpty) {
          return !url.isArchived;
        }

        if (!statusFilters.contains(StatusFilter.archived) && url.isArchived) {
          return false;
        }

        return statusFilters.any((filter) {
          switch (filter) {
            case StatusFilter.unread:
              return !url.isRead && !url.isArchived;
            case StatusFilter.starred:
              return url.isStarred && !url.isArchived;
            case StatusFilter.archived:
              return url.isArchived;
          }
        });
      }();

      final matchesDomain =
          domainFilter == null || domainFilter.isEmpty || url.domain == domainFilter;

      final matchesTag = tagFilter == null ||
          tagFilter.isEmpty ||
          tags.any((tag) => tag.toLowerCase() == tagFilter.toLowerCase());

      return matchesSearch && matchesStatus && matchesDomain && matchesTag;
    }).toList();

    final uniqueDomains = urls
        .map((url) => url.domain)
        .where((domain) => domain.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final availableTags = urls
        .expand((url) => _extractTags(url.tags))
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('ライブラリ'),
            actions: [
              // IconButton(
              //   icon: const Icon(Icons.settings_input_component_outlined),
              //   tooltip: 'AI設定',
              //   onPressed: () {
              //     Navigator.of(context).push(
              //       MaterialPageRoute(builder: (_) => const AiSettingsView()),
              //     );
              //   },
              // ),
              // ↑ 先行リリースではAI設定画面へ遷移できないようにアクション自体をコメントアウトする。
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _buildSearchField(context),
            ),
          ),
          SliverToBoxAdapter(
            child: _FilterSection(
              statusFilters: statusFilters,
              uniqueDomains: uniqueDomains,
              availableTags: availableTags,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '検索結果: ${filteredUrls.length} / ${urls.length} 件',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ),
          if (filteredUrls.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(
                hasUrls: urls.isNotEmpty,
                onAdd: () => widget.onEdit(),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final url = filteredUrls[index];
                  return Padding(
                    padding: EdgeInsets.only(top: index == 0 ? 4 : 0, bottom: 12),
                    child: _UrlCard(
                      url: url,
                      onEdit: widget.onEdit,
                    ),
                  );
                },
                childCount: filteredUrls.length,
              ),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 96),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'URL・タイトル・メモを検索',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  ref.read(searchQueryProvider.notifier).state = '';
                },
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        filled: true,
      ),
      textInputAction: TextInputAction.search,
    );
  }
}

class _FilterSection extends ConsumerWidget {
  const _FilterSection({
    required this.statusFilters,
    required this.uniqueDomains,
    required this.availableTags,
  });

  final Set<StatusFilter> statusFilters;
  final List<String> uniqueDomains;
  final List<String> availableTags;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final domainFilter = ref.watch(domainFilterProvider);
    final tagFilter = ref.watch(tagFilterProvider);
    final hasStatusFilter = statusFilters.isNotEmpty;
    final hasDomainFilter = domainFilter != null && domainFilter.isNotEmpty;
    final hasTagFilter = tagFilter != null && tagFilter.isNotEmpty;
    final hasActiveFilter =
        hasStatusFilter || hasDomainFilter || hasTagFilter;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasActiveFilter) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (hasStatusFilter)
                        for (final filter in statusFilters)
                          Chip(
                            visualDensity: VisualDensity.compact,
                            avatar: Icon(filter.icon, size: 16),
                            label: Text(filter.label),
                          ),
                      if (hasDomainFilter)
                        Chip(
                          visualDensity: VisualDensity.compact,
                          avatar: const Icon(Icons.language, size: 16),
                          label: Text('ドメイン: $domainFilter'),
                        ),
                      if (hasTagFilter)
                        Chip(
                          visualDensity: VisualDensity.compact,
                          avatar: const Icon(Icons.sell_outlined, size: 16),
                          label: Text('タグ: $tagFilter'),
                        ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(statusFilterProvider.notifier).state = {};
                    ref.read(domainFilterProvider.notifier).state = null;
                    ref.read(tagFilterProvider.notifier).state = null;
                  },
                  child: const Text('フィルタをすべて解除'),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final filter in StatusFilter.values)
                FilterChip(
                  label: Text(filter.label),
                  avatar: Icon(filter.icon, size: 18),
                  selected: statusFilters.contains(filter),
                  onSelected: (value) {
                    final current = {...statusFilters};
                    if (value) {
                      current.add(filter);
                    } else {
                      current.remove(filter);
                    }
                    ref.read(statusFilterProvider.notifier).state = current;
                  },
                ),
              if (statusFilters.isNotEmpty)
                TextButton(
                  onPressed: () {
                    ref.read(statusFilterProvider.notifier).state = {};
                  },
                  child: const Text('ステータスをクリア'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (uniqueDomains.isNotEmpty) ...[
            const Text(
              'ドメイン',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('すべて'),
                    selected: domainFilter == null,
                    onSelected: (value) {
                      if (value) {
                        ref.read(domainFilterProvider.notifier).state = null;
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  for (final domain in uniqueDomains) ...[
                    ChoiceChip(
                      label: Text(domain),
                      selected: domainFilter == domain,
                      onSelected: (value) {
                        ref.read(domainFilterProvider.notifier).state =
                            value ? domain : null;
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (availableTags.isNotEmpty) ...[
            const Text(
              'タグ',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('すべて'),
                    selected: tagFilter == null,
                    onSelected: (value) {
                      if (value) {
                        ref.read(tagFilterProvider.notifier).state = null;
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  for (final tag in availableTags) ...[
                    ChoiceChip(
                      label: Text(tag),
                      selected: tagFilter == tag,
                      onSelected: (value) {
                        ref.read(tagFilterProvider.notifier).state =
                            value ? tag : null;
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _UrlCard extends ConsumerWidget {
  const _UrlCard({required this.url, required this.onEdit});

  final Url url;
  final void Function([Url? url]) onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tags = _extractTags(url.tags);
    final savedAt = DateFormat('yyyy/MM/dd HH:mm').format(url.savedAt);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Dismissible(
        key: ValueKey('url-${url.id ?? url.url}'),
        background: _SwipeBackground(
          color: theme.colorScheme.primaryContainer,
          icon: Icons.star,
          alignment: Alignment.centerLeft,
          label: 'スター',
        ),
        secondaryBackground: _SwipeBackground(
          color: theme.colorScheme.errorContainer,
          icon: Icons.delete_outline,
          alignment: Alignment.centerRight,
          label: '削除',
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            await ref.read(urlListProvider.notifier).toggleStar(url);
            HapticFeedback.mediumImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(url.isStarred ? 'スターを解除しました' : 'スターに追加しました'),
                duration: const Duration(seconds: 1),
              ),
            );
            return false;
          }
          if (direction == DismissDirection.endToStart) {
            await ref.read(urlListProvider.notifier).deleteUrl(url);
            HapticFeedback.heavyImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('URLを削除しました'),
                action: SnackBarAction(
                  label: '元に戻す',
                  onPressed: () {
                    ref.read(urlListProvider.notifier).restoreDeleted();
                  },
                ),
              ),
            );
            return false;
          }
          return false;
        },
        child: Card(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            onTap: () {
              _showDetailSheet(context, ref, url, onEdit);
            },
            // onLongPress: () {
            //   Navigator.of(context).push(
            //     MaterialPageRoute(
            //       builder: (_) => UrlSummary(
            //         summaryRequest: SummaryRequest(
            //           url: url.url,
            //           title: url.message,
            //         ),
            //       ),
            //     ),
            //   );
            // },
            // ↑ 長押しからAI要約画面へ遷移する動線も初期バージョンでは無効化する。
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Thumbnail(domain: url.domain, imageUrl: url.ogImageUrl),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!url.isRead)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: _StatusBadge(
                                  label: '未読',
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            Text(
                              url.message.isEmpty ? url.url : url.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    url.domain.isEmpty ? '保存元不明' : url.domain,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.brightness_1, size: 6),
                                const SizedBox(width: 6),
                                Text(
                                  _relativeTime(url.savedAt),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: Icon(
                              url.isStarred ? Icons.star : Icons.star_outline,
                              color: url.isStarred
                                  ? theme.colorScheme.primary
                                  : theme.iconTheme.color,
                            ),
                            onPressed: () {
                              ref.read(urlListProvider.notifier).toggleStar(url);
                            },
                          ),
                          PopupMenuButton<_OverflowAction>(
                            onSelected: (value) {
                              _handleOverflowAction(context, ref, value, url);
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: _OverflowAction.openExternal,
                                child: ListTile(
                                  leading: Icon(Icons.open_in_new),
                                  title: Text('ブラウザで開く'),
                                ),
                              ),
                              const PopupMenuItem(
                                value: _OverflowAction.copyLink,
                                child: ListTile(
                                  leading: Icon(Icons.copy_outlined),
                                  title: Text('リンクをコピー'),
                                ),
                              ),
                              const PopupMenuItem(
                                value: _OverflowAction.share,
                                child: ListTile(
                                  leading: Icon(Icons.share_outlined),
                                  title: Text('共有'),
                                ),
                              ),
                              PopupMenuItem(
                                value: _OverflowAction.toggleRead,
                                child: ListTile(
                                  leading: Icon(
                                    url.isRead
                                        ? Icons.mark_email_read
                                        : Icons.markunread,
                                  ),
                                  title:
                                      Text(url.isRead ? '未読に戻す' : '既読にする'),
                                ),
                              ),
                              PopupMenuItem(
                                value: _OverflowAction.toggleArchive,
                                child: ListTile(
                                  leading: Icon(url.isArchived
                                      ? Icons.unarchive_outlined
                                      : Icons.archive_outlined),
                                  title: Text(
                                    url.isArchived ? 'アーカイブ解除' : 'アーカイブ',
                                  ),
                                ),
                              ),
                              const PopupMenuItem(
                                value: _OverflowAction.edit,
                                child: ListTile(
                                  leading: Icon(Icons.edit_outlined),
                                  title: Text('編集'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (url.details.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      url.details,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
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
                              .opemUrl(context, url);
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

  void _handleOverflowAction(
    BuildContext context,
    WidgetRef ref,
    _OverflowAction action,
    Url url,
  ) {
    switch (action) {
      case _OverflowAction.openExternal:
        ref.read(urlListProvider.notifier).opemUrl(context, url);
        break;
      case _OverflowAction.copyLink:
        Clipboard.setData(ClipboardData(text: url.url));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('リンクをコピーしました')),
        );
        break;
      case _OverflowAction.share:
        Share.share(url.url, subject: url.message);
        break;
      case _OverflowAction.toggleRead:
        ref.read(urlListProvider.notifier).toggleRead(url);
        break;
      case _OverflowAction.edit:
        onEdit(url);
        break;
      case _OverflowAction.toggleArchive:
        ref.read(urlListProvider.notifier).toggleArchive(url);
        break;
    }
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

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
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

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.domain, required this.imageUrl});

  final String domain;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        image: imageUrl == null
            ? null
            : DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              ),
      ),
      alignment: Alignment.center,
      child: imageUrl != null
          ? null
          : Text(
              domain.isEmpty ? 'URL' : domain.characters.take(2).join().toUpperCase(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}

enum _OverflowAction { openExternal, copyLink, share, toggleRead, edit, toggleArchive }

List<String> _extractTags(String raw) {
  return parseTags(raw);
}

String _relativeTime(DateTime savedAt) {
  final now = DateTime.now();
  final difference = now.difference(savedAt);
  if (difference.inMinutes < 1) {
    return 'たった今';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes}分前';
  } else if (difference.inHours < 24) {
    return '${difference.inHours}時間前';
  } else if (difference.inDays < 7) {
    return '${difference.inDays}日前';
  }
  return DateFormat('yyyy/MM/dd').format(savedAt);
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasUrls, required this.onAdd});

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
