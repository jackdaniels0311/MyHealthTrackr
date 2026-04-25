import 'package:flutter/material.dart';
import 'package:myhealthtrackr/pages/start_page.dart';
import 'package:myhealthtrackr/services/api_client.dart';
import 'package:myhealthtrackr/services/auth_scope.dart';
import 'package:myhealthtrackr/services/auth_service.dart';
import 'package:myhealthtrackr/services/food_service.dart';
import 'package:myhealthtrackr/services/goal_service.dart';
import 'package:myhealthtrackr/services/meal_plan_service.dart';
import 'package:myhealthtrackr/services/profile_service.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';
import 'package:myhealthtrackr/themes/app_icons.dart';
import 'package:myhealthtrackr/themes/app_text_styles.dart';
import 'package:myhealthtrackr/widgets/app_snack.dart';

class MealRecommendationSetupPage extends StatefulWidget {
  const MealRecommendationSetupPage({super.key});

  static const routeName = '/meal-recommendations/setup';

  @override
  State<MealRecommendationSetupPage> createState() =>
      _MealRecommendationSetupPageState();
}

class _MealRecommendationSetupPageState
    extends State<MealRecommendationSetupPage> {
  static const List<_SetupStep> _steps = <_SetupStep>[
    _SetupStep(
      title: 'Confirm your profile',
      subtitle: 'Review the goal and food restrictions used for this plan.',
    ),
    _SetupStep(
      title: 'Choose a plan style',
      subtitle: 'Select the diet approach and meals you want recommended.',
    ),
    _SetupStep(
      title: 'Refine the target',
      subtitle: 'Tell the assistant what matters most for this plan.',
    ),
    _SetupStep(
      title: 'Cuisine preferences',
      subtitle: 'Add cuisines you enjoy and ones you would rather avoid.',
    ),
  ];

  static const List<String> _dietPlanTypes = <String>[
    'Balanced',
    'High protein',
    'Low carb',
    'Mediterranean',
    'Plant focused',
    'Budget friendly',
    'Quick meals',
  ];

  static const List<String> _mealTypeOptions = <String>[
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
  ];

  static const List<String> _dietTargets = <String>[
    'Hit my calorie target',
    'Increase protein',
    'Keep meals filling',
    'Keep meals simple',
    'Reduce sugar',
    'Support training',
  ];

  final ProfileService _profileService = const ProfileService();
  final GoalService _goalService = const GoalService();
  final MealPlanService _mealPlanService = const MealPlanService();

  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _dietaryPreferencesController =
      TextEditingController();
  final TextEditingController _dislikedFoodsController =
      TextEditingController();
  final TextEditingController _likedCuisinesController =
      TextEditingController();
  final TextEditingController _dislikedCuisinesController =
      TextEditingController();

  int _currentStep = 0;
  bool _hasLoaded = false;
  bool _isLoading = true;
  bool _isGenerating = false;
  String? _loadError;
  String? _selectedGoalType;
  String? _selectedDietPlanType = _dietPlanTypes.first;
  String? _selectedDietTarget = _dietTargets.first;
  final Set<String> _selectedMealTypes = {'Breakfast', 'Lunch', 'Dinner'};
  MealPlanData? _mealPlan;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasLoaded) return;
    _hasLoaded = true;
    _loadDefaults();
  }

  @override
  void dispose() {
    _allergiesController.dispose();
    _dietaryPreferencesController.dispose();
    _dislikedFoodsController.dispose();
    _likedCuisinesController.dispose();
    _dislikedCuisinesController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaults() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    final authController = AuthScope.of(context);

    try {
      final results = await authController.withAuthenticatedSession((
        session,
      ) async {
        final profile = await _profileService.fetchProfile(session: session);
        final goal = await _goalService.fetchCurrentGoal(session: session);
        return (profile: profile, goal: goal);
      });

      if (!mounted) return;
      setState(() {
        _selectedGoalType = results.goal?.goalType;
        _allergiesController.text = results.profile.allergies ?? '';
        _dietaryPreferencesController.text =
            results.profile.dietaryPreferences ?? '';
        _isLoading = false;
      });
    } on AuthFailure catch (error) {
      await _handleUnauthorizedSession(message: error.message);
    } on ApiFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.message;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Unable to open meal recommendations: $error';
        _isLoading = false;
      });
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

  void _goBack() {
    if (_isGenerating) return;
    if (_mealPlan != null) {
      setState(() => _mealPlan = null);
      return;
    }
    if (_currentStep == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() => _currentStep -= 1);
  }

  Future<void> _goNext() async {
    if (_isGenerating) return;

    final validation = _validateStep(_currentStep);
    if (validation != null) {
      AppSnack.warning(context, validation);
      return;
    }

    if (_currentStep == _steps.length - 1) {
      await _generatePlan();
      return;
    }

    setState(() => _currentStep += 1);
  }

  String? _validateStep(int stepIndex) {
    switch (stepIndex) {
      case 0:
        if (_selectedGoalType == null) {
          return 'Please choose the goal to plan around.';
        }
        if (_allergiesController.text.trim().isEmpty) {
          return 'Please confirm allergies or enter None.';
        }
        return null;
      case 1:
        if (_selectedDietPlanType == null) {
          return 'Please choose a diet plan type.';
        }
        if (_selectedMealTypes.isEmpty) {
          return 'Please select at least one meal type.';
        }
        return null;
      case 2:
        return _selectedDietTarget == null
            ? 'Please choose your main diet target.'
            : null;
      default:
        return null;
    }
  }

  Future<void> _generatePlan() async {
    setState(() {
      _isGenerating = true;
      _mealPlan = null;
    });

    final preferences = MealPlanPreferences(
      goalType: _selectedGoalType,
      allergies: _allergiesController.text,
      dietaryPreferences: _dietaryPreferencesController.text,
      dietPlanType: _selectedDietPlanType,
      mealTypes: _selectedMealTypes.toList(growable: false),
      dietTarget: _selectedDietTarget,
      dislikedFoods: _dislikedFoodsController.text,
      likedCuisines: _likedCuisinesController.text,
      dislikedCuisines: _dislikedCuisinesController.text,
    );

    try {
      final plan = await AuthScope.of(context).withAuthenticatedSession(
        (session) => _mealPlanService.generatePlan(
          session: session,
          preferences: preferences,
        ),
      );
      if (!mounted) return;
      setState(() {
        _mealPlan = plan;
        _isGenerating = false;
      });
    } on AuthFailure catch (error) {
      await _handleUnauthorizedSession(message: error.message);
    } on ApiFailure catch (error) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      AppSnack.error(context, error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      AppSnack.error(
        context,
        'Unable to generate your meal recommendations right now.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColours.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColours.primary),
      );
    }

    if (_loadError != null) {
      return _buildLoadError();
    }

    if (_mealPlan != null) {
      return _buildResultBody(_mealPlan!);
    }

    final step = _steps[_currentStep];
    final canAdvance = !_isGenerating && _validateStep(_currentStep) == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meal recommendations',
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
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: _buildStepCard(step),
          ),
        ),
        const SizedBox(height: 20),
        _buildActionRow(canAdvance: canAdvance),
      ],
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColours.secondary.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColours.primary.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              AppIcons.cloudOffRounded,
              color: AppColours.primary,
              size: 44,
            ),
            const SizedBox(height: 18),
            Text(
              'Unable to load setup',
              style: AppTextStyles.title.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted.copyWith(
                color: AppColours.textMuted,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loadDefaults,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColours.primary,
                  foregroundColor: AppColours.onDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Try again',
                  style: AppTextStyles.button.copyWith(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(_SetupStep step) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColours.secondary.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColours.primary.withValues(alpha: 0.25)),
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
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildProfileStep();
      case 1:
        return _buildPlanStyleStep();
      case 2:
        return _buildTargetStep();
      case 3:
        return _buildCuisineStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildProfileStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdown<String>(
          label: 'Goal',
          value: _selectedGoalType,
          hintText: 'Choose goal',
          items: UserGoal.goalTypes,
          onChanged: (value) => setState(() => _selectedGoalType = value),
        ),
        const SizedBox(height: 18),
        _buildTextField(
          controller: _allergiesController,
          label: 'Allergies',
          hintText: 'None, peanuts, dairy...',
          helperText: 'These foods will be avoided in the AI prompt.',
        ),
        const SizedBox(height: 18),
        _buildTextField(
          controller: _dietaryPreferencesController,
          label: 'Dietary preferences',
          hintText: 'Vegetarian, halal, gluten-free...',
          helperText: 'Use commas for more than one preference.',
        ),
      ],
    );
  }

  Widget _buildPlanStyleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdown<String>(
          label: 'Diet plan type',
          value: _selectedDietPlanType,
          hintText: 'Choose plan type',
          items: _dietPlanTypes,
          onChanged: (value) => setState(() => _selectedDietPlanType = value),
        ),
        const SizedBox(height: 22),
        Text(
          'Meal types',
          style: AppTextStyles.label.copyWith(
            color: AppColours.onDark,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _mealTypeOptions
              .map((mealType) {
                final selected = _selectedMealTypes.contains(mealType);
                return FilterChip(
                  selected: selected,
                  label: Text(mealType),
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _selectedMealTypes.add(mealType);
                      } else {
                        _selectedMealTypes.remove(mealType);
                      }
                    });
                  },
                  backgroundColor: AppColours.inputFill,
                  selectedColor: AppColours.primary.withValues(alpha: 0.28),
                  checkmarkColor: AppColours.primary,
                  labelStyle: AppTextStyles.label.copyWith(
                    color: selected ? AppColours.onDark : AppColours.textMuted,
                  ),
                  side: BorderSide(
                    color: selected
                        ? AppColours.primary.withValues(alpha: 0.45)
                        : AppColours.transparent,
                  ),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildTargetStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdown<String>(
          label: 'Main target',
          value: _selectedDietTarget,
          hintText: 'Choose target',
          items: _dietTargets,
          onChanged: (value) => setState(() => _selectedDietTarget = value),
        ),
        const SizedBox(height: 18),
        _buildTextField(
          controller: _dislikedFoodsController,
          label: 'Foods to avoid',
          hintText: 'Mushrooms, tuna, eggs...',
          helperText: 'Add foods you dislike, separated by commas.',
          required: false,
        ),
      ],
    );
  }

  Widget _buildCuisineStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _likedCuisinesController,
          label: 'Cuisines you like',
          hintText: 'Italian, Indian, Mediterranean...',
          helperText: 'Optional, but helps shape the recommendations.',
          required: false,
        ),
        const SizedBox(height: 18),
        _buildTextField(
          controller: _dislikedCuisinesController,
          label: 'Cuisines to avoid',
          hintText: 'Thai, Mexican...',
          helperText: 'Optional cuisines the assistant should avoid.',
          required: false,
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required String hintText,
    required List<T> items,
    required ValueChanged<T?> onChanged,
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
        DropdownButtonFormField<T>(
          initialValue: value,
          dropdownColor: AppColours.secondary,
          iconEnabledColor: AppColours.textMuted,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: AppColours.onDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(item.toString()),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: _inputDecoration(hintText: hintText),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required String helperText,
    bool required = true,
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
          minLines: 1,
          maxLines: 3,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: AppColours.onDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          decoration: _inputDecoration(
            hintText: required ? hintText : '$hintText (optional)',
          ),
        ),
        const SizedBox(height: 10),
        Text(
          helperText,
          style: AppTextStyles.bodyMuted.copyWith(
            color: AppColours.textMuted,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hintText}) {
    return InputDecoration(
      filled: true,
      fillColor: AppColours.inputFill,
      hintText: hintText,
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
        borderSide: const BorderSide(color: AppColours.primary, width: 1.5),
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

  Widget _buildActionRow({required bool canAdvance}) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 56,
            child: OutlinedButton(
              onPressed: _isGenerating ? null : _goBack,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColours.onDark,
                side: BorderSide(color: AppColours.borderLight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                _currentStep == 0 ? 'Cancel' : 'Back',
                style: AppTextStyles.button.copyWith(fontSize: 16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: canAdvance ? _goNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColours.primary,
                foregroundColor: AppColours.onDark,
                disabledBackgroundColor: AppColours.primary.withValues(
                  alpha: 0.5,
                ),
                disabledForegroundColor: AppColours.textHigh,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColours.onDark,
                      ),
                    )
                  : Text(
                      _currentStep == _steps.length - 1 ? 'Generate' : 'Next',
                      style: AppTextStyles.button.copyWith(fontSize: 16),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultBody(MealPlanData plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your recommendations',
          style: AppTextStyles.headline.copyWith(
            fontSize: 34,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Review the AI-generated meal plan and ingredient quantities.',
          style: AppTextStyles.bodyMuted.copyWith(
            color: AppColours.textMuted,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 22),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(plan),
                const SizedBox(height: 14),
                for (final meal in plan.meals) ...[
                  _buildMealCard(meal),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: _goBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColours.onDark,
                    side: BorderSide(color: AppColours.borderLight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Edit setup',
                    style: AppTextStyles.button.copyWith(fontSize: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isGenerating ? null : _generatePlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColours.primary,
                    foregroundColor: AppColours.onDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Regenerate',
                    style: AppTextStyles.button.copyWith(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(MealPlanData plan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColours.secondary.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColours.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.summary,
            style: AppTextStyles.bodyMuted.copyWith(
              color: AppColours.textMuted,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricPill(
                icon: AppIcons.localFireDepartmentRounded,
                label:
                    '${FoodService.formatCalories(plan.totals.calories)} / ${FoodService.formatCalories(plan.targets.calories)}',
              ),
              _MetricPill(
                icon: AppIcons.spaRounded,
                label:
                    '${FoodService.formatMetric(plan.totals.protein)} protein',
              ),
              _MetricPill(
                icon: AppIcons.grainRounded,
                label: '${FoodService.formatMetric(plan.totals.carbs)} carbs',
              ),
              _MetricPill(
                icon: AppIcons.boltRounded,
                label: '${FoodService.formatMetric(plan.totals.fat)} fat',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            plan.estimateNotice,
            style: AppTextStyles.bodyMuted.copyWith(
              color: AppColours.textSubtle,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(MealPlanMealData meal) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColours.secondary.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColours.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            meal.mealType,
            style: AppTextStyles.label.copyWith(
              color: AppColours.primary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            meal.name,
            style: AppTextStyles.title.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricPill(
                icon: AppIcons.localFireDepartmentRounded,
                label: FoodService.formatCalories(meal.calories),
              ),
              _MetricPill(
                icon: AppIcons.spaRounded,
                label: '${FoodService.formatMetric(meal.protein)} protein',
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final ingredient in meal.ingredients)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    AppIcons.checkRounded,
                    color: AppColours.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${ingredient.name}: ${ingredient.displayQuantity}',
                      style: AppTextStyles.bodyMuted.copyWith(
                        color: AppColours.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (meal.matchReason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              meal.matchReason,
              style: AppTextStyles.bodyMuted.copyWith(
                color: AppColours.textSubtle,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColours.background.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColours.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              fontSize: 13,
              color: AppColours.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupStep {
  const _SetupStep({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}
