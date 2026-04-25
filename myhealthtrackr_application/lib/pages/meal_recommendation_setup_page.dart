import 'package:flutter/material.dart';
import 'package:myhealthtrackr/pages/start_page.dart';
import 'package:myhealthtrackr/services/api_client.dart';
import 'package:myhealthtrackr/services/auth_scope.dart';
import 'package:myhealthtrackr/services/auth_service.dart';
import 'package:myhealthtrackr/services/food_service.dart';
import 'package:myhealthtrackr/services/goal_service.dart';
import 'package:myhealthtrackr/services/meal_plan_service.dart';
import 'package:myhealthtrackr/services/profile_service.dart';
import 'package:myhealthtrackr/services/saved_meals_service.dart';
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
      title: 'Goal and targets',
      subtitle: 'Choose the goal and main diet targets for this plan.',
    ),
    _SetupStep(
      title: 'Allergies',
      subtitle: 'Confirm foods the assistant must avoid.',
    ),
    _SetupStep(
      title: 'Dietary preferences',
      subtitle: 'Confirm how you prefer to eat.',
    ),
    _SetupStep(
      title: 'Foods to avoid',
      subtitle: 'Select foods you dislike or enter your own.',
    ),
    _SetupStep(
      title: 'Choose a plan style',
      subtitle: 'Select the diet approach you want the assistant to follow.',
    ),
    _SetupStep(
      title: 'Cuisine preferences',
      subtitle: 'Add cuisines you enjoy and ones you would rather avoid.',
    ),
    _SetupStep(
      title: 'Meal types',
      subtitle: 'Choose which meals you want recommended.',
    ),
  ];

  static const List<_DietPlanOption> _dietPlanTypes = <_DietPlanOption>[
    _DietPlanOption(
      name: 'Balanced',
      description:
          'A flexible mix of protein, carbs and fats for everyday eating.',
      imageUrl:
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=800&q=80',
    ),
    _DietPlanOption(
      name: 'High protein',
      description:
          'Protein-led meals to support fullness and muscle maintenance.',
      imageUrl:
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=80',
    ),
    _DietPlanOption(
      name: 'Keto',
      description: 'Very low-carb meals with higher fats and moderate protein.',
      imageUrl:
          'https://images.unsplash.com/photo-1559847844-5315695dadae?auto=format&fit=crop&w=800&q=80',
    ),
    _DietPlanOption(
      name: 'Low carb',
      description:
          'Reduced-carb meals while keeping more flexibility than keto.',
      imageUrl:
          'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=800&q=80',
    ),
    _DietPlanOption(
      name: 'Whole-foods focused',
      description: 'Simple meals built around minimally processed ingredients.',
      imageUrl:
          'https://images.unsplash.com/photo-1498837167922-ddd27525d352?auto=format&fit=crop&w=800&q=80',
    ),
    _DietPlanOption(
      name: 'Mediterranean',
      description:
          'Vegetables, grains, lean proteins and olive-oil based meals.',
      imageUrl:
          'https://images.unsplash.com/photo-1544510808-91bcbee1df55?auto=format&fit=crop&w=800&q=80',
    ),
    _DietPlanOption(
      name: 'Pescatarian',
      description: 'Vegetarian-leaning meals with fish and seafood options.',
      imageUrl:
          'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?auto=format&fit=crop&w=800&q=80',
    ),
    _DietPlanOption(
      name: 'Vegetarian',
      description:
          'Meat-free meals with dairy, eggs or plant proteins as needed.',
      imageUrl:
          'https://images.unsplash.com/photo-1529059997568-3d847b1154f0?auto=format&fit=crop&w=800&q=80',
    ),
    _DietPlanOption(
      name: 'Vegan',
      description: 'Fully plant-based meals with no animal products.',
      imageUrl:
          'https://images.unsplash.com/photo-1511690656952-34342bb7c2f2?auto=format&fit=crop&w=800&q=80',
    ),
  ];

  static const List<String> _allergyOptions = <String>[
    'None',
    'Peanuts',
    'Dairy',
    'Eggs',
    'Wheat',
    'Gluten',
    'Fish',
    'Shellfish',
  ];

  static const List<String> _dietaryPreferenceOptions = <String>[
    'None',
    'Vegetarian',
    'Vegan',
    'Pescatarian',
    'Halal',
    'Gluten-free',
    'Dairy-free',
  ];

  static const List<String> _dislikedFoodOptions = <String>[
    'Mushrooms',
    'Olives',
    'Onions',
    'Tomatoes',
    'Seafood',
    'Tuna',
    'Eggs',
    'Avocado',
    'Beans',
    'Spicy food',
  ];

  static const List<String> _mealTypeOptions = <String>[
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snacks',
  ];

  static const List<String> _dietTargets = <String>[
    'Hit my calorie target',
    'Increase protein',
    'Keep meals filling',
    'Keep meals simple',
    'Reduce sugar',
    'Support training',
  ];

  static const List<String> _cuisineOptions = <String>[
    'British',
    'Mediterranean',
    'Italian',
    'Indian',
    'Chinese',
    'Japanese',
    'Mexican',
    'Thai',
    'Middle Eastern',
    'Caribbean',
  ];

  final ProfileService _profileService = const ProfileService();
  final GoalService _goalService = const GoalService();
  final MealPlanService _mealPlanService = const MealPlanService();
  final SavedMealsService _savedMealsService = const SavedMealsService();

  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _dietaryPreferencesController =
      TextEditingController();
  final TextEditingController _dislikedFoodsController =
      TextEditingController();
  int _currentStep = 0;
  bool _hasLoaded = false;
  bool _isLoading = true;
  bool _isGenerating = false;
  String? _loadError;
  String? _selectedGoalType;
  String? _selectedDietPlanType = _dietPlanTypes.first.name;
  final Set<String> _selectedDietTargets = {_dietTargets.first};
  final Set<String> _selectedMealTypes = {'Breakfast', 'Lunch', 'Dinner'};
  final Set<String> _likedCuisines = <String>{};
  final Set<String> _dislikedCuisines = <String>{};
  final Set<String> _savedMealKeys = <String>{};
  final Set<String> _savingMealKeys = <String>{};
  MealPlanData? _mealPlan;
  bool _hasSavedMeal = false;

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
        final savedPreferences = await _mealPlanService.fetchPreferences(
          session: session,
        );
        return (
          profile: profile,
          goal: goal,
          savedPreferences: savedPreferences,
        );
      });

      if (!mounted) return;
      setState(() {
        _applyLoadedDefaults(
          profile: results.profile,
          goal: results.goal,
          savedPreferences: results.savedPreferences,
        );
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

  void _applyLoadedDefaults({
    required UserProfile profile,
    required UserGoal? goal,
    required MealPlanSavedPreferences savedPreferences,
  }) {
    if (!savedPreferences.hasSavedPreferences) {
      _selectedGoalType = goal?.goalType;
      _allergiesController.text = profile.allergies ?? '';
      _dietaryPreferencesController.text = profile.dietaryPreferences ?? '';
      return;
    }

    _selectedGoalType = savedPreferences.goalType ?? goal?.goalType;
    _allergiesController.text =
        savedPreferences.allergies ?? profile.allergies ?? '';
    _dietaryPreferencesController.text =
        savedPreferences.dietaryPreferences ?? profile.dietaryPreferences ?? '';
    _selectedDietPlanType =
        savedPreferences.dietPlanType ?? _dietPlanTypes.first.name;
    _replaceSet(
      _selectedDietTargets,
      savedPreferences.dietTargets.isEmpty
          ? <String>{_dietTargets.first}
          : savedPreferences.dietTargets,
    );
    _replaceSet(
      _selectedMealTypes,
      savedPreferences.mealTypes.isEmpty
          ? <String>{'Breakfast', 'Lunch', 'Dinner'}
          : savedPreferences.mealTypes,
    );
    _dislikedFoodsController.text = savedPreferences.dislikedFoods ?? '';
    _replaceSet(
      _likedCuisines,
      _splitPreferenceList(savedPreferences.likedCuisines),
    );
    _replaceSet(
      _dislikedCuisines,
      _splitPreferenceList(savedPreferences.dislikedCuisines),
    );
  }

  void _replaceSet(Set<String> target, Iterable<String> values) {
    target
      ..clear()
      ..addAll(
        values.map((value) => value.trim()).where((value) => value.isNotEmpty),
      );
  }

  List<String> _splitPreferenceList(String? value) {
    if (value == null || value.trim().isEmpty) return const <String>[];
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
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
      Navigator.pop(context, _hasSavedMeal);
      return;
    }
    setState(() => _currentStep -= 1);
  }

  void _returnToMealPlans() {
    Navigator.pop(context, _hasSavedMeal);
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
        if (_selectedDietTargets.isEmpty) {
          return 'Please select at least one main diet target.';
        }
        return null;
      case 1:
        if (_allergiesController.text.trim().isEmpty) {
          return 'Please confirm allergies or enter None.';
        }
        return null;
      case 2:
        if (_dietaryPreferencesController.text.trim().isEmpty) {
          return 'Please confirm dietary preferences or enter None.';
        }
        return null;
      case 3:
        return null;
      case 4:
        return _selectedDietPlanType == null
            ? 'Please choose a diet plan type.'
            : null;
      case 6:
        return _selectedMealTypes.isEmpty
            ? 'Please select at least one meal type.'
            : null;
      default:
        return null;
    }
  }

  Future<void> _generatePlan() async {
    setState(() {
      _isGenerating = true;
      _mealPlan = null;
      _savedMealKeys.clear();
      _savingMealKeys.clear();
    });

    final preferences = MealPlanPreferences(
      goalType: _selectedGoalType,
      allergies: _allergiesController.text,
      dietaryPreferences: _dietaryPreferencesController.text,
      dietPlanType: _selectedDietPlanType,
      mealTypes: _selectedMealTypes.toList(growable: false),
      dietTargets: _selectedDietTargets.toList(growable: false),
      dislikedFoods: _dislikedFoodsController.text,
      likedCuisines: _likedCuisines.join(', '),
      dislikedCuisines: _dislikedCuisines.join(', '),
    );

    try {
      final plan = await AuthScope.of(context).withAuthenticatedSession((
        session,
      ) async {
        await _mealPlanService.savePreferences(
          session: session,
          preferences: preferences,
        );
        return _mealPlanService.generatePlan(
          session: session,
          preferences: preferences,
        );
      });
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

  Future<void> _saveMealRecommendation(
    MealPlanMealData meal, {
    required String cardKey,
  }) async {
    if (_savedMealKeys.contains(cardKey) || _savingMealKeys.contains(cardKey)) {
      return;
    }

    setState(() => _savingMealKeys.add(cardKey));

    try {
      final savedMeal = await AuthScope.of(context).withAuthenticatedSession((
        session,
      ) {
        return _savedMealsService.createMeal(
          session: session,
          name: meal.name,
          items: [
            SavedMealItemData(
              name: meal.name,
              servingSize: null,
              quantity: 1,
              calories: meal.calories,
              protein: meal.protein,
              carbs: meal.carbs,
              fat: meal.fat,
              fibre: meal.fibre,
              sugar: meal.sugar,
            ),
          ],
        );
      });

      if (!mounted) return;
      setState(() {
        _savingMealKeys.remove(cardKey);
        _savedMealKeys.add(cardKey);
        _hasSavedMeal = true;
      });
      AppSnack.success(context, '${savedMeal.name} has been saved.');
    } on AuthFailure catch (error) {
      if (mounted) {
        setState(() => _savingMealKeys.remove(cardKey));
      }
      await _handleUnauthorizedSession(message: error.message);
    } on ApiFailure catch (error) {
      if (!mounted) return;
      setState(() => _savingMealKeys.remove(cardKey));
      AppSnack.error(context, error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _savingMealKeys.remove(cardKey));
      AppSnack.error(context, 'Unable to save this meal right now.');
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

    if (_isGenerating) {
      return _buildGeneratingBody();
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

  Widget _buildGeneratingBody() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColours.secondary.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColours.primary.withValues(alpha: 0.32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 54,
              height: 54,
              child: CircularProgressIndicator(
                color: AppColours.primary,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Creating your meal plan',
              textAlign: TextAlign.center,
              style: AppTextStyles.title.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'The assistant is using your goals, preferences and food choices to build personalised recommendations.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted.copyWith(
                color: AppColours.textMuted,
                fontSize: 16,
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
        return _buildGoalStep();
      case 1:
        return _buildAllergiesStep();
      case 2:
        return _buildDietaryPreferencesStep();
      case 3:
        return _buildFoodsToAvoidStep();
      case 4:
        return _buildPlanStyleStep();
      case 5:
        return _buildCuisineStep();
      case 6:
        return _buildMealTypesStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildGoalStep() {
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
        const SizedBox(height: 24),
        _buildMultiSelectChips(
          label: 'Main targets',
          options: _dietTargets,
          selectedValues: _selectedDietTargets,
        ),
      ],
    );
  }

  Widget _buildAllergiesStep() {
    return _buildSelectableTextStep(
      controller: _allergiesController,
      label: 'Allergies',
      hintText: 'Enter allergies separated by commas',
      helperText: 'Select None if you do not have any allergies.',
      quickOptions: _allergyOptions,
    );
  }

  Widget _buildDietaryPreferencesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSelectableTextStep(
          controller: _dietaryPreferencesController,
          label: 'Dietary preferences',
          hintText: 'Enter dietary preferences separated by commas',
          helperText: 'Select None if you do not have any dietary preferences.',
          quickOptions: _dietaryPreferenceOptions,
        ),
      ],
    );
  }

  Widget _buildFoodsToAvoidStep() {
    return _buildSelectableTextStep(
      controller: _dislikedFoodsController,
      label: 'Foods to avoid',
      hintText: 'Enter disliked foods separated by commas',
      helperText: 'Select quick options or add foods you do not want included.',
      quickOptions: _dislikedFoodOptions,
      required: false,
    );
  }

  Widget _buildPlanStyleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _dietPlanTypes.map(_buildDietPlanOption).toList(),
    );
  }

  Widget _buildDietPlanOption(_DietPlanOption option) {
    final selected = _selectedDietPlanType == option.name;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: AppColours.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => setState(() => _selectedDietPlanType = option.name),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColours.inputFill,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected
                    ? AppColours.primary.withValues(alpha: 0.7)
                    : AppColours.dividerLightMuted,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(21),
                  ),
                  child: Image.network(
                    option.imageUrl,
                    width: 104,
                    height: 104,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 104,
                      height: 104,
                      color: AppColours.primary.withValues(alpha: 0.16),
                      child: const Icon(
                        AppIcons.restaurantMenuRounded,
                        color: AppColours.primary,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                option.name,
                                style: AppTextStyles.title.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (selected)
                              const Icon(
                                AppIcons.checkRounded,
                                color: AppColours.primary,
                                size: 22,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          option.description,
                          style: AppTextStyles.bodyMuted.copyWith(
                            color: AppColours.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMealTypesStep() {
    return _buildMultiSelectChips(
      label: 'Meal types',
      options: _mealTypeOptions,
      selectedValues: _selectedMealTypes,
    );
  }

  Widget _buildCuisineStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mark cuisines as liked or disliked.',
          style: AppTextStyles.bodyMuted.copyWith(
            color: AppColours.textMuted,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 14),
        ..._cuisineOptions.map(_buildCuisinePreferenceRow),
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

  Widget _buildSelectableTextStep({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required String helperText,
    required List<String> quickOptions,
    bool required = true,
  }) {
    final selectedValues = _splitCommaSeparated(controller.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick options:',
          style: AppTextStyles.label.copyWith(
            color: AppColours.onDark,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: quickOptions
              .map((option) {
                final isSelected = selectedValues.contains(option);
                return FilterChip(
                  label: Text(option),
                  selected: isSelected,
                  onSelected: (_) =>
                      _toggleCommaSeparatedValue(controller, option),
                  labelStyle: AppTextStyles.body.copyWith(
                    color: AppColours.onDark,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: AppColours.inputFill,
                  selectedColor: AppColours.primary.withValues(alpha: 0.28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: isSelected
                          ? AppColours.primary
                          : AppColours.dividerLightMuted,
                    ),
                  ),
                );
              })
              .toList(growable: false),
        ),
        const SizedBox(height: 22),
        _buildTextField(
          controller: controller,
          label: label,
          hintText: hintText,
          helperText: helperText,
          required: required,
        ),
      ],
    );
  }

  Widget _buildMultiSelectChips({
    required String label,
    required List<String> options,
    required Set<String> selectedValues,
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
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options
              .map((option) {
                final selected = selectedValues.contains(option);
                return FilterChip(
                  selected: selected,
                  label: Text(option),
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        selectedValues.add(option);
                      } else {
                        selectedValues.remove(option);
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

  Widget _buildCuisinePreferenceRow(String cuisine) {
    final liked = _likedCuisines.contains(cuisine);
    final disliked = _dislikedCuisines.contains(cuisine);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: AppColours.inputFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColours.dividerLightMuted),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              cuisine,
              style: AppTextStyles.body.copyWith(
                color: AppColours.onDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _CuisineButton(
            icon: AppIcons.thumbUpRounded,
            selected: liked,
            onTap: () => _setCuisinePreference(cuisine, liked ? null : true),
          ),
          const SizedBox(width: 8),
          _CuisineButton(
            icon: AppIcons.thumbDownRounded,
            selected: disliked,
            onTap: () =>
                _setCuisinePreference(cuisine, disliked ? null : false),
          ),
        ],
      ),
    );
  }

  void _setCuisinePreference(String cuisine, bool? liked) {
    setState(() {
      _likedCuisines.remove(cuisine);
      _dislikedCuisines.remove(cuisine);
      if (liked == true) {
        _likedCuisines.add(cuisine);
      } else if (liked == false) {
        _dislikedCuisines.add(cuisine);
      }
    });
  }

  void _toggleCommaSeparatedValue(
    TextEditingController controller,
    String value,
  ) {
    final selections = _splitCommaSeparated(controller.text).toList();
    if (value == 'None') {
      if (selections.contains('None') && selections.length == 1) {
        controller.text = '';
      } else {
        controller.text = 'None';
      }
      setState(() {});
      return;
    }

    selections.remove('None');
    if (selections.contains(value)) {
      selections.remove(value);
    } else {
      selections.add(value);
    }

    controller.text = selections.join(', ');
    setState(() {});
  }

  List<String> _splitCommaSeparated(String value) {
    final entries = value
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    final uniqueEntries = <String>[];
    for (final entry in entries) {
      if (!uniqueEntries.contains(entry)) {
        uniqueEntries.add(entry);
      }
    }
    return uniqueEntries;
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
                      _currentStep == _steps.length - 1
                          ? 'Generate Meals'
                          : 'Next',
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: OutlinedButton(
                onPressed: _goBack,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  foregroundColor: AppColours.onDark,
                  side: BorderSide(color: AppColours.borderLight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Icon(AppIcons.arrowBackRounded, size: 22),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Your Recommended meals',
                style: AppTextStyles.headline.copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'View personalised meals for your selected meal types.',
          style: AppTextStyles.bodyMuted.copyWith(
            color: AppColours.textMuted,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 22),
        _buildSummaryCard(plan),
        const SizedBox(height: 14),
        Expanded(
          child: plan.mealGroups.isEmpty
              ? _buildEmptyResultsCard()
              : _buildMealGroupTabs(plan.mealGroups),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _returnToMealPlans,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColours.primary,
              foregroundColor: AppColours.onDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'Return to meal plans',
              style: AppTextStyles.button.copyWith(fontSize: 16),
            ),
          ),
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
            _refinedSummary(plan.summary),
            style: AppTextStyles.bodyMuted.copyWith(
              color: AppColours.textMuted,
              fontSize: 15,
            ),
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

  String _refinedSummary(String summary) {
    final trimmed = summary.trim();
    if (trimmed.isEmpty) {
      return 'Here are meal ideas matched to your setup.';
    }

    if (trimmed.length <= 120) {
      return trimmed;
    }

    final sentenceEnd = trimmed.indexOf(RegExp(r'[.!?]'));
    if (sentenceEnd > 35 && sentenceEnd <= 120) {
      return trimmed.substring(0, sentenceEnd + 1);
    }

    return '${trimmed.substring(0, 117).trimRight()}...';
  }

  Widget _buildEmptyResultsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColours.secondary.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColours.panelBorder),
      ),
      child: Text(
        'No meal options were returned. Try regenerating your recommendations.',
        style: AppTextStyles.bodyMuted.copyWith(
          color: AppColours.textMuted,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildMealGroupTabs(List<MealPlanMealGroupData> groups) {
    final orderedGroups = _orderedMealGroups(groups);

    return DefaultTabController(
      length: orderedGroups.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            labelColor: AppColours.onDark,
            unselectedLabelColor: AppColours.textMuted,
            indicatorColor: AppColours.primary,
            indicatorWeight: 3,
            dividerColor: AppColours.dividerLight.withValues(alpha: 0.4),
            labelStyle: AppTextStyles.label.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
            unselectedLabelStyle: AppTextStyles.label.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            tabs: [
              for (final group in orderedGroups)
                Tab(text: _mealTypeTabLabel(group.mealType)),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: TabBarView(
              children: [
                for (final group in orderedGroups)
                  _buildMealGroupTabContent(group),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<MealPlanMealGroupData> _orderedMealGroups(
    List<MealPlanMealGroupData> groups,
  ) {
    final orderedGroups = List<MealPlanMealGroupData>.of(groups);
    orderedGroups.sort((a, b) {
      final aIndex = _mealTypeSortIndex(a.mealType);
      final bIndex = _mealTypeSortIndex(b.mealType);
      if (aIndex != bIndex) return aIndex.compareTo(bIndex);
      return a.mealType.compareTo(b.mealType);
    });
    return orderedGroups;
  }

  int _mealTypeSortIndex(String mealType) {
    switch (mealType.trim().toLowerCase()) {
      case 'breakfast':
        return 0;
      case 'lunch':
        return 1;
      case 'dinner':
        return 2;
      case 'snack':
      case 'snacks':
        return 3;
      default:
        return 99;
    }
  }

  String _mealTypeTabLabel(String mealType) {
    final normalizedMealType = mealType.trim().toLowerCase();
    if (normalizedMealType == 'snack' || normalizedMealType == 'snacks') {
      return 'Snacks';
    }
    return mealType;
  }

  Widget _buildMealGroupTabContent(MealPlanMealGroupData group) {
    if (group.options.isEmpty) {
      return SingleChildScrollView(
        child: _buildEmptyMealTypeCard(group.mealType),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < group.options.length; index++) ...[
            _buildMealCard(
              group.options[index],
              groupMealType: group.mealType,
              index: index + 1,
            ),
            if (index != group.options.length - 1) const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildEmptyMealTypeCard(String mealType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColours.secondary.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColours.panelBorder),
          ),
          child: Text(
            'No $mealType options were returned. Try regenerating your recommendations.',
            style: AppTextStyles.bodyMuted.copyWith(
              color: AppColours.textMuted,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard(
    MealPlanMealData meal, {
    required String groupMealType,
    required int index,
  }) {
    final cardKey = _mealRecommendationKey(
      meal,
      groupMealType: groupMealType,
      index: index,
    );
    final isSaving = _savingMealKeys.contains(cardKey);
    final isSaved = _savedMealKeys.contains(cardKey);

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
            'Option $index',
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
              _MetricPill(
                icon: AppIcons.grainRounded,
                label: '${FoodService.formatMetric(meal.carbs)} carbs',
              ),
              _MetricPill(
                icon: AppIcons.boltRounded,
                label: '${FoodService.formatMetric(meal.fat)} fat',
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: isSaving || isSaved
                  ? null
                  : () => _saveMealRecommendation(meal, cardKey: cardKey),
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColours.onDark,
                      ),
                    )
                  : Icon(
                      isSaved
                          ? AppIcons.checkRounded
                          : AppIcons.bookmarkAddRounded,
                      size: 20,
                    ),
              label: Text(
                isSaved
                    ? 'Saved'
                    : isSaving
                    ? 'Saving'
                    : 'Save meal',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSaved
                    ? AppColours.secondary
                    : AppColours.primary,
                foregroundColor: AppColours.onDark,
                disabledBackgroundColor: isSaved
                    ? AppColours.secondary
                    : AppColours.primary.withValues(alpha: 0.55),
                disabledForegroundColor: isSaved
                    ? AppColours.textMuted
                    : AppColours.onDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: AppTextStyles.button.copyWith(fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _mealRecommendationKey(
    MealPlanMealData meal, {
    required String groupMealType,
    required int index,
  }) {
    return [
      groupMealType.trim().toLowerCase(),
      meal.mealType.trim().toLowerCase(),
      index.toString(),
      meal.name.trim().toLowerCase(),
      meal.calories.toStringAsFixed(2),
      meal.protein.toStringAsFixed(2),
      meal.carbs.toStringAsFixed(2),
      meal.fat.toStringAsFixed(2),
    ].join('|');
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

class _DietPlanOption {
  const _DietPlanOption({
    required this.name,
    required this.description,
    required this.imageUrl,
  });

  final String name;
  final String description;
  final String imageUrl;
}

class _CuisineButton extends StatelessWidget {
  const _CuisineButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(74, 38),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        foregroundColor: selected ? AppColours.onDark : AppColours.textMuted,
        backgroundColor: selected
            ? AppColours.primary.withValues(alpha: 0.24)
            : AppColours.transparent,
        side: BorderSide(
          color: selected
              ? AppColours.primary.withValues(alpha: 0.56)
              : AppColours.dividerLightMuted,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Icon(icon, size: 18),
    );
  }
}

class _SetupStep {
  const _SetupStep({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}
