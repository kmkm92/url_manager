import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_manager/database.dart';
import 'package:url_manager/models/tag_utils.dart';
import 'package:url_manager/view_models/url_view_model.dart';
import 'package:url_manager/views/history_view.dart';
import 'package:url_manager/views/settings_root_view.dart';
import 'package:url_manager/views/url_add_view.dart';
import 'package:url_manager/views/widgets/delete_confirm_dialog.dart';
import 'package:url_manager/views/widgets/url_detail_sheet.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

// フィルター状態永続化用のキー
const _statusFilterKey = 'filter_status_filters';
const _tagFilterKey = 'filter_tag_filter';

/// ステータスフィルターを永続化するNotifier
class StatusFilterNotifier extends StateNotifier<Set<StatusFilter>> {
  StatusFilterNotifier() : super(<StatusFilter>{}) {
    _loadFromPrefs();
  }

  SharedPreferences? _prefs;

  /// SharedPreferencesから保存済みフィルターを復元
  Future<void> _loadFromPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    final savedList = _prefs?.getStringList(_statusFilterKey);
    if (savedList != null && savedList.isNotEmpty) {
      state = savedList
          .map((name) => StatusFilter.values.firstWhere(
                (f) => f.name == name,
                orElse: () => StatusFilter.unread,
              ))
          .where((f) => StatusFilter.values.contains(f))
          .toSet();
    }
  }

  /// フィルターを更新し永続化
  Future<void> update(Set<StatusFilter> newFilters) async {
    state = newFilters;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setStringList(
      _statusFilterKey,
      newFilters.map((f) => f.name).toList(),
    );
  }
}

/// タグフィルターを永続化するNotifier
class TagFilterNotifier extends StateNotifier<String?> {
  TagFilterNotifier() : super(null) {
    _loadFromPrefs();
  }

  SharedPreferences? _prefs;

  /// SharedPreferencesから保存済みタグフィルターを復元
  Future<void> _loadFromPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    final savedTag = _prefs?.getString(_tagFilterKey);
    if (savedTag != null && savedTag.isNotEmpty) {
      state = savedTag;
    }
  }

  /// タグフィルターを更新し永続化
  Future<void> update(String? newTag) async {
    state = newTag;
    _prefs ??= await SharedPreferences.getInstance();
    if (newTag == null || newTag.isEmpty) {
      await _prefs?.remove(_tagFilterKey);
    } else {
      await _prefs?.setString(_tagFilterKey, newTag);
    }
  }
}

final statusFilterProvider =
    StateNotifierProvider<StatusFilterNotifier, Set<StatusFilter>>(
  (ref) => StatusFilterNotifier(),
);
final tagFilterProvider = StateNotifierProvider<TagFilterNotifier, String?>(
  (ref) => TagFilterNotifier(),
);

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
    // 現在のタブインデックスをProviderから監視
    final currentIndex = ref.watch(homeTabIndexProvider);

    return Scaffold(
      extendBody: true,
      backgroundColor: theme.colorScheme.surface,
      body: IndexedStack(
        index: currentIndex,
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
      floatingActionButton: currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _showAddUrlForm,
              icon: const Icon(Icons.add),
              label: const Text('保存'),
            )
          : null,
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: NavigationBar(
            height: 50,
            backgroundColor: theme.colorScheme.surface.withOpacity(0.6),
            surfaceTintColor: Colors.transparent,
            indicatorColor:
                theme.colorScheme.secondaryContainer.withOpacity(0.5),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
            selectedIndex: currentIndex,
            onDestinationSelected: (value) {
              ref.read(homeTabIndexProvider.notifier).state = value;
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'ホーム',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: '履歴',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: '設定',
              ),
            ],
          ),
        ),
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
    final tagFilter = ref.watch(tagFilterProvider);

    final filteredUrls = urls.where((url) {
      final tags = _extractTags(url.tags);
      final matchesSearch = searchQuery.isEmpty ||
          url.message.toLowerCase().contains(searchQuery.toLowerCase()) ||
          url.url.toLowerCase().contains(searchQuery.toLowerCase()) ||
          url.details.toLowerCase().contains(searchQuery.toLowerCase()) ||
          tags.any(
              (tag) => tag.toLowerCase().contains(searchQuery.toLowerCase()));

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

      final matchesTag = tagFilter == null ||
          tagFilter.isEmpty ||
          tags.any((tag) => tag.toLowerCase() == tagFilter.toLowerCase());

      return matchesSearch && matchesStatus && matchesTag;
    }).toList();

    final availableTags = urls
        .expand((url) => _extractTags(url.tags))
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          // ライブラリタイトル・検索・フィルターを統合したFloating Header
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: false,
            automaticallyImplyLeading: false,
            backgroundColor: Theme.of(context).colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            toolbarHeight: 190,
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 32, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchField(context),
                  const SizedBox(height: 12),
                  _FilterSection(
                    statusFilters: statusFilters,
                    availableTags: availableTags,
                  ),
                ],
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
                    padding:
                        EdgeInsets.only(top: index == 0 ? 0 : 0, bottom: 12),
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
            child: SizedBox(height: 120),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: '検索...',
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  _searchController.clear();
                  ref.read(searchQueryProvider.notifier).state = '';
                },
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.4),
      ),
      textInputAction: TextInputAction.search,
    );
  }
}

class _FilterSection extends ConsumerWidget {
  const _FilterSection({
    required this.statusFilters,
    required this.availableTags,
  });

  final Set<StatusFilter> statusFilters;
  final List<String> availableTags;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagFilter = ref.watch(tagFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final filter in StatusFilter.values)
              FilterChip(
                label: Text(filter.label),
                selected: statusFilters.contains(filter),
                showCheckmark: false,
                avatar: statusFilters.contains(filter)
                    ? null
                    : Icon(filter.icon,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                labelStyle: TextStyle(
                  color: statusFilters.contains(filter)
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: statusFilters.contains(filter)
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.3),
                selectedColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                side: BorderSide.none,
                onSelected: (value) {
                  final current = {...statusFilters};
                  if (value) {
                    current.add(filter);
                  } else {
                    current.remove(filter);
                  }
                  ref.read(statusFilterProvider.notifier).update(current);
                },
              ),
          ],
        ),
        if (availableTags.isNotEmpty) ...[
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('すべて'),
                  selected: tagFilter == null,
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    color: tagFilter == null
                        ? Theme.of(context).colorScheme.onSecondaryContainer
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight:
                        tagFilter == null ? FontWeight.bold : FontWeight.normal,
                  ),
                  selectedColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: tagFilter == null
                          ? Colors.transparent
                          : Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.3),
                    ),
                  ),
                  onSelected: (value) {
                    if (value) {
                      ref.read(tagFilterProvider.notifier).update(null);
                    }
                  },
                ),
                const SizedBox(width: 8),
                for (final tag in availableTags) ...[
                  ChoiceChip(
                    label: Text(tag),
                    selected: tagFilter == tag,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: tagFilter == tag
                          ? Theme.of(context).colorScheme.onSecondaryContainer
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: tagFilter == tag
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    selectedColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: tagFilter == tag
                            ? Colors.transparent
                            : Theme.of(context)
                                .colorScheme
                                .outline
                                .withOpacity(0.3),
                      ),
                    ),
                    onSelected: (value) {
                      ref
                          .read(tagFilterProvider.notifier)
                          .update(value ? tag : null);
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
          color: theme.colorScheme.tertiaryContainer,
          icon: Icons.archive_outlined,
          alignment: Alignment.centerLeft,
          label: 'アーカイブ',
        ),
        secondaryBackground: _SwipeBackground(
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
            if (!context.mounted) return false;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: const Text('URLを削除しました'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  showCloseIcon: true,
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
                        child: _Thumbnail(
                            domain: url.domain, imageUrl: url.ogImageUrl),
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
                                        _StatusBadge(
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
                                PopupMenuButton<_OverflowAction>(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(Icons.more_vert,
                                      color:
                                          theme.colorScheme.onSurfaceVariant),
                                  onSelected: (value) {
                                    _handleOverflowAction(
                                        context, ref, value, url);
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
                                    PopupMenuItem(
                                      value: _OverflowAction.toggleRead,
                                      child: ListTile(
                                        leading: Icon(
                                          url.isRead
                                              ? Icons.mark_email_read
                                              : Icons.markunread,
                                        ),
                                        title: Text(
                                            url.isRead ? '未読に戻す' : '既読にする'),
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

  void _handleOverflowAction(
    BuildContext context,
    WidgetRef ref,
    _OverflowAction action,
    Url url,
  ) {
    switch (action) {
      case _OverflowAction.openExternal:
        ref.read(urlListProvider.notifier).openUrl(context, url);
        break;
      case _OverflowAction.copyLink:
        Clipboard.setData(ClipboardData(text: url.url));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('リンクをコピーしました')),
        );
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

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.domain, required this.imageUrl});

  final String domain;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.05),
          width: 1,
        ),
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
          : Icon(
              Icons.public,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              size: 32,
            ),
    );
  }
}

enum _OverflowAction {
  openExternal,
  copyLink,

  toggleRead,
  edit,
  toggleArchive
}

List<String> _extractTags(String raw) {
  return parseTags(raw);
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
