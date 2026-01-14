// URL一覧画面。
// ホームタブ、履歴タブ、設定タブを含むメイン画面。

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_manager/database.dart';
import 'package:url_manager/models/tag_utils.dart';
import 'package:url_manager/view_models/filter_providers.dart';
import 'package:url_manager/view_models/url_view_model.dart';
import 'package:url_manager/views/history_view.dart';
import 'package:url_manager/views/settings_root_view.dart';
import 'package:url_manager/views/url_add_view.dart';
import 'package:url_manager/views/widgets/url_card.dart';
import 'package:url_manager/view_models/settings_preferences_view_model.dart';

/// URL一覧画面のルートウィジェット
class UrlListView extends ConsumerStatefulWidget {
  const UrlListView({super.key});

  @override
  ConsumerState<UrlListView> createState() => _UrlListViewState();
}

class _UrlListViewState extends ConsumerState<UrlListView> {
  bool _startupTabApplied = false;

  @override
  void initState() {
    super.initState();
    // 次のフレームで設定の起動時タブを適用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyStartupTabOnce();
    });
  }

  /// 設定が読み込まれた後、起動時タブを一度だけ適用する
  void _applyStartupTabOnce() {
    if (_startupTabApplied) return;

    final settings = ref.read(settingsPreferencesProvider);

    if (settings.isLoaded) {
      // 設定が既に読み込まれている場合は即座に適用
      _startupTabApplied = true;
      ref.read(homeTabIndexProvider.notifier).state = settings.startupTab.index;
    } else {
      // 設定がまだ読み込まれていない場合は、読み込み完了を待機
      // ignore: unused_local_variable - サブスクリプションはウィジェットのライフサイクルで自動管理される
      ref.listenManual(
        settingsPreferencesProvider,
        (previous, next) {
          if (!_startupTabApplied && next.isLoaded) {
            _startupTabApplied = true;
            ref.read(homeTabIndexProvider.notifier).state =
                next.startupTab.index;
          }
        },
      );
    }
  }

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
            backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.6),
            surfaceTintColor: Colors.transparent,
            indicatorColor:
                theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
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

/// ホームタブウィジェット
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
      final tags = parseTags(url.tags);
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

        // AND条件: すべてのフィルター条件を満たすURLのみ表示
        return statusFilters.every((filter) {
          switch (filter) {
            case StatusFilter.unread:
              return !url.isRead;
            case StatusFilter.starred:
              return url.isStarred;
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
        .expand((url) => parseTags(url.tags))
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    // タグフィルターが利用可能なタグリストに存在しない場合はリセット
    if (tagFilter != null &&
        tagFilter.isNotEmpty &&
        !availableTags
            .any((tag) => tag.toLowerCase() == tagFilter.toLowerCase())) {
      // 次のフレームでリセットを実行（ビルド中の状態変更を避けるため）
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(tagFilterProvider.notifier).update(null);
      });
    }

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
              child: UrlListEmptyState(
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
                    child: UrlCard(
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
            .withValues(alpha: 0.4),
      ),
      textInputAction: TextInputAction.search,
    );
  }
}

/// フィルターセクションウィジェット
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
                    .withValues(alpha: 0.3),
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
          // タグ順序を取得
          Builder(
            builder: (context) {
              // タグ順序の状態変更を監視（これによりreorder時に即座にリビルドされる）
              ref.watch(tagOrderProvider);
              // タグ順序を取得
              final orderedTags = ref
                  .read(tagOrderProvider.notifier)
                  .getOrderedTags(availableTags);

              return SizedBox(
                height: 40,
                child: Row(
                  children: [
                    // 「すべて」ボタン（固定）
                    ChoiceChip(
                      label: const Text('すべて'),
                      selected: tagFilter == null,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        color: tagFilter == null
                            ? Theme.of(context).colorScheme.onSecondaryContainer
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: tagFilter == null
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      selectedColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: tagFilter == null
                              ? Colors.transparent
                              : Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withValues(alpha: 0.3),
                        ),
                      ),
                      onSelected: (value) {
                        if (value) {
                          ref.read(tagFilterProvider.notifier).update(null);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    // その他のタグ（ドラッグ可能）
                    Expanded(
                      child: ReorderableListView.builder(
                        scrollDirection: Axis.horizontal,
                        buildDefaultDragHandles: false,
                        proxyDecorator: (child, index, animation) {
                          return Material(
                            elevation: 4,
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            child: child,
                          );
                        },
                        onReorder: (oldIndex, newIndex) {
                          ref.read(tagOrderProvider.notifier).reorder(
                                oldIndex,
                                newIndex,
                                orderedTags,
                              );
                        },
                        itemCount: orderedTags.length,
                        itemBuilder: (context, index) {
                          final tag = orderedTags[index];
                          return ReorderableDelayedDragStartListener(
                            key: ValueKey('tag_$tag'),
                            index: index,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(tag),
                                selected: tagFilter == tag,
                                showCheckmark: false,
                                labelStyle: TextStyle(
                                  color: tagFilter == tag
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onSecondaryContainer
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: tagFilter == tag
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                selectedColor: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: tagFilter == tag
                                        ? Colors.transparent
                                        : Theme.of(context)
                                            .colorScheme
                                            .outline
                                            .withValues(alpha: 0.3),
                                  ),
                                ),
                                onSelected: (value) {
                                  ref
                                      .read(tagFilterProvider.notifier)
                                      .update(value ? tag : null);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
