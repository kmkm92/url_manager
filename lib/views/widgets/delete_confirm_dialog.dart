import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_manager/view_models/settings_preferences_view_model.dart';

/// 削除確認をボトムシートで表示し、削除を実行するかどうかを返す。
/// 「次回以降表示しない」チェックボックスを含み、設定をSharedPreferencesに保存する。
Future<bool> showDeleteConfirmDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String title,
  String? message,
}) async {
  // 設定で確認ダイアログをスキップする場合は即座にtrueを返す。
  final skipConfirm = ref.read(settingsPreferencesProvider).skipDeleteConfirm;
  if (skipConfirm) {
    return true;
  }

  // ボトムシートを表示
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _DeleteConfirmSheet(
      title: title,
      message: message,
    ),
  );

  // ダイアログがキャンセルされた場合はfalseを返す。
  return result ?? false;
}

class _DeleteConfirmSheet extends ConsumerStatefulWidget {
  const _DeleteConfirmSheet({
    required this.title,
    this.message,
  });

  final String title;
  final String? message;

  @override
  ConsumerState<_DeleteConfirmSheet> createState() =>
      _DeleteConfirmSheetState();
}

class _DeleteConfirmSheetState extends ConsumerState<_DeleteConfirmSheet> {
  bool _doNotShowAgain = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.delete_outline,
            color: theme.colorScheme.error,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            widget.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          // 「次回以降表示しない」
          InkWell(
            onTap: () {
              setState(() {
                _doNotShowAgain = !_doNotShowAgain;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _doNotShowAgain
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: _doNotShowAgain
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '次回以降表示しない',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('キャンセル'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    if (_doNotShowAgain) {
                      await ref
                          .read(settingsPreferencesProvider.notifier)
                          .updateSkipDeleteConfirm(true);
                    }
                    if (!context.mounted) return;
                    Navigator.of(context).pop(true);
                  },
                  child: Text(
                    '削除',
                    style: TextStyle(
                      color: theme.colorScheme.onError,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
