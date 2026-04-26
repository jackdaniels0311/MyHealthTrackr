import 'package:flutter/material.dart';
import 'package:myhealthtrackr/services/api_client.dart';
import 'package:myhealthtrackr/services/auth_scope.dart';
import 'package:myhealthtrackr/services/weight_history_service.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';
import 'package:myhealthtrackr/themes/app_icons.dart';
import 'package:myhealthtrackr/themes/app_text_styles.dart';
import 'package:myhealthtrackr/widgets/app_snack.dart';
import 'package:myhealthtrackr/widgets/confirmation_dialog.dart';

enum LogWeightResult { created, updated, deleted }

class LogWeightPage extends StatefulWidget {
  const LogWeightPage({super.key, this.initialWeightKg, this.entry});

  final double? initialWeightKg;
  final WeightEntryData? entry;

  bool get isEditing => entry != null;

  @override
  State<LogWeightPage> createState() => _LogWeightPageState();
}

class _LogWeightPageState extends State<LogWeightPage> {
  final WeightHistoryService _weightHistoryService =
      const WeightHistoryService();
  late final TextEditingController _weightController;
  DateTime? _selectedRecordedDate;

  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController();
    _syncFormStateFromWidget();
  }

  @override
  void didUpdateWidget(covariant LogWeightPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry != widget.entry ||
        oldWidget.initialWeightKg != widget.initialWeightKg) {
      _syncFormStateFromWidget();
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _syncFormStateFromWidget() {
    final initialWeightKg = widget.entry?.weightKg ?? widget.initialWeightKg;
    _weightController.text = initialWeightKg == null
        ? ''
        : _formatInitialWeight(initialWeightKg);
    _selectedRecordedDate =
        widget.entry?.recordedAt.toLocal() ?? DateTime.now();
  }

  DateTime get _effectiveRecordedDate =>
      _selectedRecordedDate ??
      widget.entry?.recordedAt.toLocal() ??
      DateTime.now();

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.isEditing;
    final actionBarHeight = isEditing ? 166.0 : 94.0;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColours.background,
      body: Stack(
        children: [
          _buildBackdropAccent(
            alignment: const Alignment(-0.95, -1.0),
            size: 220,
            colour: AppColours.primary.withValues(alpha: 0.10),
          ),
          _buildBackdropAccent(
            alignment: const Alignment(1.0, -0.45),
            size: 200,
            colour: AppColours.primary.withValues(alpha: 0.08),
          ),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                22,
                18,
                22,
                actionBarHeight + bottomInset + 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  _buildIntroCard(),
                  const SizedBox(height: 18),
                  _buildWeightFormCard(),
                  const SizedBox(height: 18),
                  _buildDateFormCard(),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomActionBar(isEditing: isEditing),
          ),
        ],
      ),
    );
  }

  Widget _buildBackdropAccent({
    required Alignment alignment,
    required double size,
    required Color colour,
  }) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [colour, AppColours.transparent]),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: (_isSaving || _isDeleting)
              ? null
              : () => Navigator.of(context).pop(),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColours.secondary.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColours.borderLight),
            ),
            child: Icon(
              AppIcons.arrowBackRounded,
              color: _isSaving ? AppColours.textSubtle : AppColours.onDark,
              size: 26,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isEditing ? 'Edit weight entry' : 'Log current weight',
                style: AppTextStyles.title.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.isEditing
                    ? 'Update this recorded weight entry.'
                    : 'Add your latest weigh-in and update your current weight.',
                style: AppTextStyles.bodyMuted.copyWith(
                  color: AppColours.textSubtle,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: AppColours.secondary.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColours.panelBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColours.shadowHeavy,
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: AppColours.primary.withValues(alpha: 0.16),
                ),
                child: const Icon(
                  AppIcons.monitorWeightOutlined,
                  color: AppColours.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.isEditing
                      ? 'Update weight entry'
                      : 'Enter current weight',
                  style: AppTextStyles.headline.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.isEditing
                ? 'Save changes to updates this weight entry.'
                : 'Log current weight here, to add to your weight progress timeline.',
            style: AppTextStyles.bodyMuted.copyWith(
              color: AppColours.textMuted,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColours.secondary.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColours.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weight',
            style: AppTextStyles.title.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your latest weight in kilograms.',
            style: AppTextStyles.bodyMuted.copyWith(
              color: AppColours.textMuted,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _weightController,
            autofocus: false,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
            onEditingComplete: () => FocusScope.of(context).unfocus(),
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: AppColours.onDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColours.inputFill,
              hintText: 'Enter your weight',
              suffixText: 'kg',
              hintStyle: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: AppColours.textFaint,
              ),
              suffixStyle: AppTextStyles.body.copyWith(
                color: AppColours.textMuted,
                fontWeight: FontWeight.w700,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(
                  color: AppColours.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFormCard() {
    final selectedRecordedDate = _effectiveRecordedDate;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColours.secondary.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColours.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weight date',
            style: AppTextStyles.title.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the date this weight was recorded.',
            style: AppTextStyles.bodyMuted.copyWith(
              color: AppColours.textMuted,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 18),
          InkWell(
            onTap: (_isSaving || _isDeleting) ? null : _pickRecordedDate,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: AppColours.inputFill,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColours.borderLight.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    AppIcons.calendarMonthOutlined,
                    color: AppColours.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _formatDateLabel(selectedRecordedDate),
                      style: AppTextStyles.body.copyWith(
                        color: AppColours.onDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    AppIcons.chevronRightRounded,
                    color: AppColours.textSubtle,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar({required bool isEditing}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        22,
        16,
        22,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      color: AppColours.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (_isSaving || _isDeleting) ? null : _saveWeight,
              style: FilledButton.styleFrom(
                backgroundColor: AppColours.primary,
                foregroundColor: AppColours.onDark,
                disabledBackgroundColor: AppColours.primary.withValues(
                  alpha: 0.45,
                ),
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              child: Text(
                _isSaving
                    ? (isEditing ? 'Saving changes...' : 'Saving weight...')
                    : (isEditing ? 'Save changes' : 'Log current weight'),
              ),
            ),
          ),
          if (isEditing) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: (_isSaving || _isDeleting) ? null : _confirmDelete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColours.danger,
                  side: const BorderSide(color: AppColours.danger),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: Text(
                  _isDeleting ? 'Deleting...' : 'Delete weight entry',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _saveWeight() async {
    final parsedWeight = double.tryParse(_weightController.text.trim());
    if (parsedWeight == null || parsedWeight <= 0 || parsedWeight > 1000) {
      AppSnack.warning(context, 'Please enter a valid weight in kg.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await AuthScope.of(context).withAuthenticatedSession((session) {
        if (widget.entry != null) {
          final updatedRecordedAt = _buildUpdatedRecordedAt();
          return _weightHistoryService.updateWeightEntry(
            session: session,
            weightEntryId: widget.entry!.id,
            weightKg: parsedWeight,
            recordedAt: updatedRecordedAt,
          );
        }
        return _weightHistoryService.logCurrentWeight(
          session: session,
          weightKg: parsedWeight,
          recordedAt: _buildUpdatedRecordedAt(),
        );
      });

      if (!mounted) return;
      Navigator.of(context).pop(
        widget.entry == null
            ? LogWeightResult.created
            : LogWeightResult.updated,
      );
    } on ApiFailure catch (error) {
      if (!mounted) return;
      AppSnack.error(context, error.message);
    } catch (_) {
      if (!mounted) return;
      AppSnack.error(
        context,
        'Unable to log your weight right now. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickRecordedDate() async {
    final currentValue = _effectiveRecordedDate;
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(
        currentValue.year,
        currentValue.month,
        currentValue.day,
      ),
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColours.primary,
              surface: AppColours.secondary,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColours.secondary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate == null || !mounted) return;

    final existingLocalDate = _effectiveRecordedDate;
    setState(() {
      _selectedRecordedDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        existingLocalDate.hour,
        existingLocalDate.minute,
        existingLocalDate.second,
        existingLocalDate.millisecond,
        existingLocalDate.microsecond,
      );
    });
  }

  Future<void> _confirmDelete() async {
    final entry = widget.entry;
    if (entry == null) return;

    final shouldDelete = await showConfirmationDialog(
      context: context,
      title: 'Delete weight entry?',
      message:
          'This will remove the ${_formatDateTime(entry.recordedAt)} weight entry from your progress history.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      isDestructive: true,
    );

    if (!shouldDelete || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await AuthScope.of(context).withAuthenticatedSession((session) {
        return _weightHistoryService.deleteWeightEntry(
          session: session,
          weightEntryId: entry.id,
        );
      });

      if (!mounted) return;
      Navigator.of(context).pop(LogWeightResult.deleted);
    } on ApiFailure catch (error) {
      if (!mounted) return;
      AppSnack.error(context, error.message);
    } catch (_) {
      if (!mounted) return;
      AppSnack.error(
        context,
        'Unable to delete this weight entry right now. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  static String _formatInitialWeight(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  static String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }

  DateTime? _buildUpdatedRecordedAt() {
    final selectedRecordedDate = _effectiveRecordedDate;

    return DateTime(
      selectedRecordedDate.year,
      selectedRecordedDate.month,
      selectedRecordedDate.day,
      selectedRecordedDate.hour,
      selectedRecordedDate.minute,
      selectedRecordedDate.second,
      selectedRecordedDate.millisecond,
      selectedRecordedDate.microsecond,
    );
  }

  static String _formatDateLabel(DateTime value) {
    final local = value.toLocal();
    const months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }
}
