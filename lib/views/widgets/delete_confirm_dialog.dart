import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_manager/view_models/settings_preferences_view_model.dart';

/// 削除確認ダイアログを表示し、削除を実行するかどうかを返す。
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

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => _DeleteConfirmDialog(
      title: title,
      message: message,
    ),
  );

  // ダイアログがキャンセルされた場合はfalseを返す。
  if (result == null) {
    return false;
  }

  return result;
}

class _DeleteConfirmDialog extends ConsumerStatefulWidget {
  const _DeleteConfirmDialog({
    required this.title,
    this.message,
  });

  final String title;
  final String? message;

  @override
  ConsumerState<_DeleteConfirmDialog> createState() =>
      _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends ConsumerState<_DeleteConfirmDialog> {
  bool _doNotShowAgain = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      icon: Icon(
        Icons.delete_outline,
        color: theme.colorScheme.error,
        size: 32,
      ),
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.message != null) ...[
            Text(
              widget.message!,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
          ],
          // 「次回以降表示しない」チェックボックス
          CheckboxListTile(
            value: _doNotShowAgain,
            onChanged: (value) {
              setState(() {
                _doNotShowAgain = value ?? false;
              });
            },
            title: Text(
              '次回以降表示しない',
              style: theme.textTheme.bodyMedium,
            ),
            contentPadding: EdgeInsets.zero,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text('キャンセル'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
          ),
          onPressed: () async {
            // 「次回以降表示しない」がチェックされている場合、設定を保存。
            if (_doNotShowAgain) {
              await ref
                  .read(settingsPreferencesProvider.notifier)
                  .updateSkipDeleteConfirm(true);
            }
            if (!context.mounted) return;
            Navigator.of(context).pop(true);
          },
          child: const Text('削除'),
        ),
      ],
    );
  }
}
