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

    final metrics = _buildMetrics(urls);
    final grouped = groupBy<Url, DateTime>(
      urls,
      (url) => DateTime(url.savedAt.year, url.savedAt.month, url.savedAt.day),
    )..removeWhere((_, entries) => entries.isEmpty);

    final entries = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return SafeArea(
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 120),
        itemCount: entries.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _MetricsSection(metrics: metrics);
          }
          final entry = entries[index - 1];
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

class _MetricsSection extends StatelessWidget {
  const _MetricsSection({required this.metrics});

  final List<_Metric> metrics;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: SizedBox(
        height: 156,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return _MetricCard(metric: metric);
          },
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemCount: metrics.length,
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: metric.backgroundColor ??
            theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (metric.backgroundColor ??
                  theme.colorScheme.primary.withOpacity(0.08))
              .withOpacity(0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor:
                    metric.accentColor ?? theme.colorScheme.primary,
                child: Icon(
                  metric.icon,
                  size: 18,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  metric.trendLabel,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              metric.value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            metric.title,
            style: theme.textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _Metric {
  const _Metric({
    required this.title,
    required this.value,
    required this.icon,
    this.trendLabel = '',
    this.backgroundColor,
    this.accentColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final String trendLabel;
  final Color? backgroundColor;
  final Color? accentColor;
}

List<_Metric> _buildMetrics(List<Url> urls) {
  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final savedThisWeek =
      urls.where((url) => url.savedAt.isAfter(startOfWeek)).length;
  final unreadCount =
      urls.where((url) => !url.isRead && !url.isArchived).length;
  final groupedByUrl = groupBy(urls, (Url url) => url.url);
  final duplicateCount =
      groupedByUrl.values.where((group) => group.length > 1).length;

  return [
    _Metric(
      title: '今週の保存',
      value: '$savedThisWeek 件',
      icon: Icons.trending_up,
      trendLabel: savedThisWeek >= 5 ? 'ペース良好' : '習慣化を継続',
    ),
    _Metric(
      title: '未読のアイテム',
      value: '$unreadCount 件',
      icon: Icons.markunread_outlined,
      trendLabel: unreadCount == 0 ? 'すべて消化済み' : '優先度順に整理',
      backgroundColor: Colors.lightBlue.withOpacity(0.15),
      accentColor: Colors.lightBlue,
    ),
    _Metric(
      title: '重複候補',
      value: '$duplicateCount 件',
      icon: Icons.link_off_outlined,
      trendLabel: duplicateCount == 0 ? 'クリーン' : 'マージを検討',
      backgroundColor: Colors.teal.withOpacity(0.12),
      accentColor: Colors.teal,
    ),
  ];
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
