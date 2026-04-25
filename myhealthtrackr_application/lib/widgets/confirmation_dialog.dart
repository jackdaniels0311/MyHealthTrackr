import 'package:flutter/material.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';
import 'package:myhealthtrackr/themes/app_text_styles.dart';

Future<bool> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  bool isDestructive = false,
  bool emphasizeCancelAction = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final confirmTextButton = TextButton(
        onPressed: () => Navigator.of(dialogContext).pop(true),
        style: TextButton.styleFrom(
          foregroundColor: isDestructive
              ? AppColours.danger
              : AppColours.textMuted,
        ),
        child: Text(confirmLabel),
      );
      final confirmFilledButton = FilledButton(
        onPressed: () => Navigator.of(dialogContext).pop(true),
        style: FilledButton.styleFrom(
          backgroundColor: isDestructive
              ? AppColours.danger
              : AppColours.primary,
          foregroundColor: AppColours.onDark,
        ),
        child: Text(confirmLabel),
      );
      final cancelTextButton = TextButton(
        onPressed: () => Navigator.of(dialogContext).pop(false),
        child: Text(cancelLabel),
      );
      final cancelFilledButton = FilledButton(
        onPressed: () => Navigator.of(dialogContext).pop(false),
        style: FilledButton.styleFrom(
          backgroundColor: AppColours.primary,
          foregroundColor: AppColours.onDark,
        ),
        child: Text(cancelLabel),
      );

      return AlertDialog(
        backgroundColor: AppColours.secondary,
        title: Text(
          title,
          style: AppTextStyles.title.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          message,
          style: AppTextStyles.bodyMuted.copyWith(color: AppColours.textMuted),
        ),
        actions: [
          if (emphasizeCancelAction) ...[
            confirmTextButton,
            cancelFilledButton,
          ] else ...[
            cancelTextButton,
            confirmFilledButton,
          ],
        ],
      );
    },
  );

  return confirmed ?? false;
}
