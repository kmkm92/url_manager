import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_manager/database.dart';
import 'package:url_manager/view_models/url_view_model.dart';
import 'package:url_manager/views/widgets/url_detail_sheet.dart';

class HistoryView extends ConsumerWidget {
  const HistoryView({super.key, this.onEdit});

  final void Function(BuildContext context, Url url)? onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urls = ref.watch(urlListProvider);
    if (urls.isEmpty) {
      return const _HistoryEmptyState();
    }

    final grouped = groupBy<Url, DateTime>(
      urls,
      (url) => DateTime(url.savedAt.year, url.savedAt.month, url.savedAt.day),
    )..removeWhere((_, entries) => entries.isEmpty);

    final entries = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return SafeArea(
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 120),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          final formattedDate =
              DateFormat('yyyy/MM/dd (E)', 'ja_JP').format(entry.key.toLocal());
          final total = entry.value.length;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                childrenPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  formattedDate,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('$total 件'),
                children: [
                  for (final url in entry.value)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        url.isRead
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: url.isRead
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                      ),
                      title: Text(
                        url.message.isEmpty ? url.url : url.message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${url.domain.isEmpty ? '保存元不明' : url.domain} ・ ${DateFormat('HH:mm').format(url.savedAt)}',
                      ),
                      onTap: () {
                        _openDetail(context, ref, url);
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openDetail(BuildContext context, WidgetRef ref, Url url) {
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
              onEdit: ([edited]) {
                Navigator.of(context).pop();
                final target = edited ?? url;
                if (onEdit != null) {
                  onEdit!(context, target);
                }
              },
            );
          },
        );
      },
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_empty,
                size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              'まだ履歴はありません',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '共有メニューから保存するとここに表示されます。',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
