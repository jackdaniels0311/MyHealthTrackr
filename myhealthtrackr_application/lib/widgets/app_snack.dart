import 'package:flutter/material.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';
import 'package:myhealthtrackr/themes/app_text_styles.dart';
import 'package:snackify/enums/snack_enums.dart';
import 'package:snackify/initializers.dart';
import 'package:snackify/overlay_entry.dart';

enum AppSnackType { success, error, warning, info }

final class AppSnack {
  const AppSnack._();

  static const double _bottomNavigationClearance = 112;

  static OverlayEntry? _activeEntry;
  static AnimationController? _activeAnimationController;

  static void show(
    BuildContext context,
    String message, {
    AppSnackType? type,
    String? title,
  }) {
    final resolvedType = type ?? _inferType(message);
    final accent = _accentFor(resolvedType);
    final overlayState = Overlay.of(context);
    final animationController = createAnimationController(
      overlayState,
      const Duration(milliseconds: 260),
    );

    _dismissActiveSnack();

    late final OverlayEntry snackEntry;
    snackEntry = buildOverlayEntry(
      context: context,
      title: Text(title ?? _titleFor(resolvedType), style: _titleStyle),
      subtitle: Text(message, style: _messageStyle),
      snackType: _snackifyTypeFor(resolvedType),
      backgroundColor: AppColours.inputFill,
      iconColor: accent,
      icon: _iconFor(resolvedType),
      speakOnShow: false,
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      borderRadius: BorderRadius.circular(18),
      offset: const Offset(4, _bottomNavigationClearance),
      animationController: animationController,
      backgroundGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColours.inputFill,
          AppColours.inputFill,
          accent.withValues(alpha: 0.28),
        ],
        stops: const [0, 0.68, 1],
      ),
      snackShadow: [
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
      position: SnackPosition.bottom,
      actionWidget: IconButton(
        onPressed: _dismissActiveSnack,
        icon: const Icon(Icons.close_rounded, color: AppColours.textMuted),
      ),
      onClose: _dismissActiveSnack,
      onDismissed: (_) => _disposeActiveSnack(),
    );

    _activeEntry = snackEntry;
    _activeAnimationController = animationController;
    overlayState.insert(snackEntry);
    animationController.forward();

    Future<void>.delayed(const Duration(seconds: 3), () {
      if (_activeEntry == snackEntry) {
        _dismissActiveSnack();
      }
    });
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

  static SnackType _snackifyTypeFor(AppSnackType type) {
    return switch (type) {
      AppSnackType.success => SnackType.success,
      AppSnackType.error => SnackType.error,
      AppSnackType.warning => SnackType.warning,
      AppSnackType.info => SnackType.info,
    };
  }

  static void _dismissActiveSnack() {
    final entry = _activeEntry;
    final animationController = _activeAnimationController;
    if (entry == null || animationController == null) {
      return;
    }

    _activeEntry = null;
    _activeAnimationController = null;

    animationController.reverse().then((_) {
      entry.remove();
      animationController.dispose();
    });
  }

  static void _disposeActiveSnack() {
    _activeEntry?.remove();
    _activeAnimationController?.dispose();
    _activeEntry = null;
    _activeAnimationController = null;
  }
}
