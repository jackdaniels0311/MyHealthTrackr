import 'package:flutter/material.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';
import 'package:myhealthtrackr/themes/app_text_styles.dart';

enum AppSnackType { success, error, warning, info }

final class AppSnack {
  const AppSnack._();

  static void show(
    BuildContext context,
    String message, {
    AppSnackType? type,
    String? title,
  }) {
    final resolvedType = type ?? _inferType(message);
    final accent = _accentFor(resolvedType);
    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          backgroundColor: AppColours.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          content: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColours.secondary,
                  AppColours.inputFill,
                  accent.withValues(alpha: 0.28),
                ],
                stops: const [0, 0.68, 1],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColours.shadowHeavy.withValues(alpha: 0.85),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: accent.withValues(alpha: 0.20),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(_iconFor(resolvedType), color: accent, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title ?? _titleFor(resolvedType),
                        style: _titleStyle,
                      ),
                      const SizedBox(height: 4),
                      Text(message, style: _messageStyle),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: messenger.hideCurrentSnackBar,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColours.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  static void success(BuildContext context, String message, {String? title}) {
    show(context, message, type: AppSnackType.success, title: title);
  }

  static void error(BuildContext context, String message, {String? title}) {
    show(context, message, type: AppSnackType.error, title: title);
  }

  static void warning(BuildContext context, String message, {String? title}) {
    show(context, message, type: AppSnackType.warning, title: title);
  }

  static const _titleStyle = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColours.onDark,
    fontSize: 15,
    fontWeight: FontWeight.w800,
    height: 1.15,
  );

  static const _messageStyle = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColours.textMuted,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  static AppSnackType _inferType(String message) {
    final normalized = message.trim().toLowerCase();
    if (normalized.contains('success') ||
        normalized.contains('saved') ||
        normalized.contains('updated') ||
        normalized.contains('created') ||
        normalized.contains('added') ||
        normalized.contains('logged')) {
      return AppSnackType.success;
    }
    if (normalized.contains('unable') ||
        normalized.contains('error') ||
        normalized.contains('failed') ||
        normalized.contains('invalid')) {
      return AppSnackType.error;
    }
    if (normalized.startsWith('please') ||
        normalized.contains('must be') ||
        normalized.contains('not available')) {
      return AppSnackType.warning;
    }
    return AppSnackType.info;
  }

  static String _titleFor(AppSnackType type) {
    return switch (type) {
      AppSnackType.success => 'Success',
      AppSnackType.error => 'Something went wrong',
      AppSnackType.warning => 'Warning',
      AppSnackType.info => 'Update',
    };
  }

  static Color _accentFor(AppSnackType type) {
    return switch (type) {
      AppSnackType.success => AppColours.success,
      AppSnackType.error => AppColours.danger,
      AppSnackType.warning => AppColours.warning,
      AppSnackType.info => AppColours.accentHydration,
    };
  }

  static IconData _iconFor(AppSnackType type) {
    return switch (type) {
      AppSnackType.success => Icons.check_circle_rounded,
      AppSnackType.error => Icons.error_rounded,
      AppSnackType.warning => Icons.warning_rounded,
      AppSnackType.info => Icons.info_rounded,
    };
  }
}
