import 'package:flutter/material.dart';
import 'package:myhealthtrackr/themes/app_icons.dart';
import 'package:myhealthtrackr/pages/home_page.dart';
import 'package:myhealthtrackr/pages/start_page.dart';
import 'package:myhealthtrackr/services/auth_scope.dart';
import 'package:myhealthtrackr/services/auth_service.dart';
import 'package:myhealthtrackr/services/goal_service.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';
import 'package:myhealthtrackr/themes/app_text_styles.dart';
import 'package:myhealthtrackr/widgets/app_snack.dart';

class GoalsSetupPage extends StatefulWidget {
  const GoalsSetupPage({
    super.key,
    this.existingGoal,
    this.isEditingGoal = false,
    this.closeOnSave = false,
  });

  final UserGoal? existingGoal;
  final bool isEditingGoal;
  final bool closeOnSave;

  @override
  State<GoalsSetupPage> createState() => _GoalsSetupPageState();
}

class _GoalsSetupPageState extends State<GoalsSetupPage> {
  static const List<_GoalStep> _steps = <_GoalStep>[
    _GoalStep(
      title: 'Choose your goal',
      subtitle: 'Select the type of weight goal you want to work towards.',
    ),
    _GoalStep(
      title: 'Set your target weight',
      subtitle: 'Enter the weight you want to reach in kilograms.',
    ),
    _GoalStep(
      title: 'Pick your target date',
      subtitle: 'Choose when you want to achieve your goal weight.',
    ),
    _GoalStep(
      title: 'Add your starting weight',
      subtitle: 'Record the weight you are starting from right now.',
    ),
    _GoalStep(
      title: 'Choose your weekly pace',
      subtitle:
          'Set how much weight you want to gain, lose, or maintain each week.',
    ),
  ];

  final GoalService _goalService = const GoalService();
  final TextEditingController _targetWeightController = TextEditingController();
  final TextEditingController _startingWeightController =
      TextEditingController();

  int _currentStep = 0;
  bool _isSubmitting = false;

  String? _selectedGoalType;
  DateTime? _selectedGoalDate;
  double? _selectedWeeklyGoal;

  @override
  void initState() {
    super.initState();
    _applyExistingGoal(widget.existingGoal);
  }

  @override
  void dispose() {
    _targetWeightController.dispose();
    _startingWeightController.dispose();
    super.dispose();
  }

  void _applyExistingGoal(UserGoal? goal) {
    if (goal == null) return;
    _selectedGoalType = goal.goalType;
    _selectedGoalDate = goal.goalDate;
    _selectedWeeklyGoal = goal.weeklyGoal;
    _targetWeightController.text = _formatDecimal(goal.goalWeightKg);
    _startingWeightController.text = _formatDecimal(goal.goalStartWeightKg);
  }

  void _goBack() {
    if (_currentStep == 0 || _isSubmitting) return;
    setState(() => _currentStep -= 1);
  }

  Future<void> _goNext() async {
    if (_isSubmitting) return;

    final validationMessage = _validateStep(_currentStep);
    if (validationMessage != null) {
      AppSnack.warning(context, validationMessage);
      return;
    }

    if (_currentStep == _steps.length - 1) {
      await _submitGoal();
      return;
    }

    setState(() => _currentStep += 1);
  }

  bool get _canAdvance => !_isSubmitting && _validateStep(_currentStep) == null;

  String? _validateStep(int stepIndex) {
    switch (stepIndex) {
      case 0:
        return _selectedGoalType == null
            ? 'Please choose the goal type you want to follow.'
            : null;
      case 1:
        return _validateWeightField(
          value: _targetWeightController.text,
          label: 'Target weight',
        );
      case 2:
        return _selectedGoalDate == null
            ? 'Please choose the date you want to hit your goal weight.'
            : null;
      case 3:
        return _validateWeightField(
          value: _startingWeightController.text,
          label: 'Starting weight',
        );
      case 4:
        return _selectedWeeklyGoal == null
            ? 'Please choose your weekly goal pace.'
            : null;
      default:
        return null;
    }
  }

  String? _validateWeightField({required String value, required String label}) {
    final parsed = _parseDecimal(value);
    if (parsed == null) {
      return '$label must be a valid number.';
    }
    if (parsed <= 0 || parsed > 1000) {
      return '$label must be between 0 and 1000 kg.';
    }
    return null;
  }

  Future<void> _pickGoalDate() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate:
          _selectedGoalDate ??
          DateTime(now.year, now.month, now.day).add(const Duration(days: 30)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 10, 12, 31),
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

    if (selectedDate == null) return;

    setState(() => _selectedGoalDate = selectedDate);
  }

  Future<void> _submitGoal() async {
    final targetWeight = _parseDecimal(_targetWeightController.text);
    final startingWeight = _parseDecimal(_startingWeightController.text);
    final goalType = _selectedGoalType;
    final goalDate = _selectedGoalDate;
    final weeklyGoal = _selectedWeeklyGoal;

    if (targetWeight == null ||
        startingWeight == null ||
        goalType == null ||
        goalDate == null ||
        weeklyGoal == null) {
      AppSnack.warning(context, 'Please complete each goal step first.');
      return;
    }

    setState(() => _isSubmitting = true);

    final authController = AuthScope.of(context);

    try {
      final savedGoal = await authController.withAuthenticatedSession(
        (session) => _goalService.saveGoal(
          session: session,
          goal: UserGoal(
            goalId: widget.existingGoal?.goalId,
            userId: widget.existingGoal?.userId,
            goalType: goalType,
            goalWeightKg: targetWeight,
            goalDate: goalDate,
            goalStartWeightKg: startingWeight,
            weeklyGoal: weeklyGoal,
            goalStartDate: widget.existingGoal?.goalStartDate,
          ),
        ),
      );

      if (!mounted) return;

      if (widget.closeOnSave) {
        Navigator.of(context).pop<UserGoal>(savedGoal);
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) =>
              const HomePage(successMessage: 'Goal created successfully'),
        ),
        (_) => false,
      );
    } on AuthFailure catch (error) {
      await _handleUnauthorizedSession(message: error.message);
    } catch (error) {
      if (!mounted) return;
      AppSnack.error(context, 'Unable to save goal: $error');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleUnauthorizedSession({required String message}) async {
    await AuthScope.of(context).logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      StartPage.routeName,
      (_) => false,
      arguments: StartPageMessage(message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];

    return Scaffold(
      backgroundColor: AppColours.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.fromLTRB(
            24,
            28,
            24,
            24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isEditingGoal ? 'Update goal' : 'Set goals',
                style: AppTextStyles.headline.copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Step ${_currentStep + 1} of ${_steps.length}',
                style: AppTextStyles.bodyMuted.copyWith(
                  color: AppColours.textMuted,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 18),
              _buildProgressBar(),
              const SizedBox(height: 22),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColours.secondary.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: AppColours.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: AppTextStyles.title.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step.subtitle,
                          style: AppTextStyles.bodyMuted.copyWith(
                            color: AppColours.textMuted,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _buildStepContent(),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          onPressed: _isSubmitting ? null : _goBack,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColours.onDark,
                            side: BorderSide(color: AppColours.borderLight),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            'Back',
                            style: AppTextStyles.button.copyWith(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 14),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _canAdvance ? _goNext : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColours.primary,
                          foregroundColor: AppColours.onDark,
                          disabledBackgroundColor: AppColours.primary
                              .withValues(alpha: 0.5),
                          disabledForegroundColor: AppColours.textHigh,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: AppColours.onDark,
                                ),
                              )
                            : Text(
                                _currentStep == _steps.length - 1
                                    ? (widget.isEditingGoal
                                          ? 'Update Goal'
                                          : 'Save Goal')
                                    : 'Next',
                                style: AppTextStyles.button.copyWith(
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: List<Widget>.generate(_steps.length, (index) {
        final isActive = index <= _currentStep;
        return Expanded(
          child: Container(
            height: 8,
            margin: EdgeInsets.only(right: index == _steps.length - 1 ? 0 : 8),
            decoration: BoxDecoration(
              color: isActive ? AppColours.primary : AppColours.dividerLight,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildGoalTypeStep();
      case 1:
        return _buildWeightStep(
          label: 'Target weight',
          hintText: 'Enter your target weight',
          controller: _targetWeightController,
          helperText: 'This is the weight you want to reach.',
        );
      case 2:
        return _buildGoalDateStep();
      case 3:
        return _buildWeightStep(
          label: 'Starting weight',
          hintText: 'Enter your current weight',
          controller: _startingWeightController,
          helperText: 'This is the weight you are starting from today.',
        );
      case 4:
        return _buildWeeklyGoalStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildGoalTypeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Goal type',
          style: AppTextStyles.label.copyWith(
            color: AppColours.onDark,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _selectedGoalType,
          dropdownColor: AppColours.secondary,
          iconEnabledColor: AppColours.textMuted,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: AppColours.onDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          items: UserGoal.goalTypes
              .map(
                (goalType) => DropdownMenuItem<String>(
                  value: goalType,
                  child: Text(goalType),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedGoalType = value),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColours.inputFill,
            hintText: 'Select your goal type',
            hintStyle: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: AppColours.textFaint,
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
    );
  }

  Widget _buildWeightStep({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required String helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: AppColours.onDark,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: AppColours.onDark,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColours.inputFill,
            hintText: hintText,
            hintStyle: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: AppColours.textFaint,
            ),
            suffixText: 'kg',
            suffixStyle: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
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
        const SizedBox(height: 12),
        Text(
          helperText,
          style: AppTextStyles.bodyMuted.copyWith(
            color: AppColours.textMuted,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalDateStep() {
    return GestureDetector(
      onTap: _pickGoalDate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColours.inputFill,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _selectedGoalDate == null
                ? AppColours.transparent
                : AppColours.primary.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColours.primary.withValues(alpha: 0.14),
              ),
              child: const Icon(
                AppIcons.eventRounded,
                color: AppColours.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedGoalDate == null
                        ? 'Select target date'
                        : UserGoal.formatDate(_selectedGoalDate!),
                    style: AppTextStyles.title.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to choose when you want to reach your goal.',
                    style: AppTextStyles.bodyMuted.copyWith(
                      color: AppColours.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyGoalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly goal',
          style: AppTextStyles.label.copyWith(
            color: AppColours.onDark,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<double>(
          initialValue: _selectedWeeklyGoal,
          dropdownColor: AppColours.secondary,
          iconEnabledColor: AppColours.textMuted,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: AppColours.onDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          items: UserGoal.weeklyGoalValues
              .map(
                (value) => DropdownMenuItem<double>(
                  value: value,
                  child: Text(_weeklyGoalLabel(value)),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedWeeklyGoal = value),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColours.inputFill,
            hintText: 'Select weekly goal',
            hintStyle: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: AppColours.textFaint,
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
    );
  }

  String _weeklyGoalLabel(double value) {
    if (value == 0) {
      return 'Maintain current weight';
    }

    final direction = value < 0 ? 'Lose' : 'Gain';
    return '$direction ${value.abs().toStringAsFixed(2)} kg / week';
  }

  double? _parseDecimal(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  String _formatDecimal(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }
}

class _GoalStep {
  const _GoalStep({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}
