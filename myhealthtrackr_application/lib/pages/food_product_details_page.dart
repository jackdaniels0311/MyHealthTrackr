import 'package:flutter/material.dart';
import 'package:myhealthtrackr/themes/app_icons.dart';
import 'package:myhealthtrackr/services/api_client.dart';
import 'package:myhealthtrackr/services/auth_scope.dart';
import 'package:myhealthtrackr/services/food_service.dart';
import 'package:myhealthtrackr/services/meal_logging_service.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';
import 'package:myhealthtrackr/themes/app_text_styles.dart';
import 'package:myhealthtrackr/widgets/app_snack.dart';
import 'package:myhealthtrackr/widgets/nutrition_breakdown_card.dart';

class FoodProductDetailsPage extends StatefulWidget {
  const FoodProductDetailsPage({
    super.key,
    required this.product,
    this.initialMealType,
    this.logDate,
  });

  final FoodProduct product;
  final String? initialMealType;
  final DateTime? logDate;

  @override
  State<FoodProductDetailsPage> createState() => _FoodProductDetailsPageState();
}

class _FoodProductDetailsPageState extends State<FoodProductDetailsPage> {
  final MealLoggingService _mealLoggingService = const MealLoggingService();
  late final TextEditingController _servingSizeController;
  late final TextEditingController _servingQuantityController;

  late String _selectedMealType;
  bool _isSaving = false;

  FoodProduct get _product => widget.product;

  @override
  void initState() {
    super.initState();
    _servingSizeController = TextEditingController(
      text: _extractServingSizeValue(_product.servingSize),
    );
    _servingQuantityController = TextEditingController(text: '1');
    _selectedMealType = widget.initialMealType?.trim().isNotEmpty == true
        ? widget.initialMealType!.trim()
        : _defaultMealType();
  }

  @override
  void dispose() {
    _servingSizeController.dispose();
    _servingQuantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedServingNutrients = _selectedServingNutrients;
    final brand = _product.brand?.trim();

    return Scaffold(
      backgroundColor: AppColours.background,
      body: Stack(
        children: [
          _buildBackdropAccent(
            alignment: const Alignment(-0.9, -1.0),
            size: 180,
            colour: AppColours.primary.withValues(alpha: 0.10),
          ),
          _buildBackdropAccent(
            alignment: const Alignment(1.0, -0.7),
            size: 220,
            colour: AppColours.accentHydration.withValues(alpha: 0.08),
          ),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(context),
                  const SizedBox(height: 24),
                  _buildHeroCard(brand),
                  const SizedBox(height: 18),
                  _buildMeasurementsSection(),
                  const SizedBox(height: 18),
                  _buildMealSelectionSection(),
                  const SizedBox(height: 18),
                  _buildNutritionSection(
                    title: 'Nutrition For Selected Serving',
                    nutrients: selectedServingNutrients,
                  ),
                  const SizedBox(height: 18),
                  _buildNutritionSection(
                    title: 'Nutrition Per 100g/ml',
                    nutrients: ResolvedFoodNutrients(
                      calories: _product.nutrients.caloriesPer100g,
                      protein: _product.nutrients.proteinPer100g,
                      carbs: _product.nutrients.carbsPer100g,
                      fat: _product.nutrients.fatPer100g,
                      fibre: _product.nutrients.fibrePer100g,
                      sugar: _product.nutrients.sugarPer100g,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _addToMeal,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColours.primary,
                        foregroundColor: AppColours.onDark,
                        disabledBackgroundColor: AppColours.primary.withValues(
                          alpha: 0.45,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: Text(_isSaving ? 'Adding item...' : 'Add to meal'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return GestureDetector(
      onTap: _isSaving ? null : () => Navigator.of(context).pop(),
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
    );
  }

  Widget _buildHeroCard(String? brand) {
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
          Text(
            _product.name,
            style: AppTextStyles.headline.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (brand != null && brand.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              brand,
              style: AppTextStyles.bodyMuted.copyWith(
                color: AppColours.textMuted,
                fontSize: 17,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMeasurementsSection() {
    return _buildSectionCard(
      title: 'Measurements',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((_product.quantity ?? '').trim().isNotEmpty) ...[
            _buildReadOnlyDetail(
              label: 'Pack quantity',
              value: _product.quantity!.trim(),
            ),
            const SizedBox(height: 16),
          ],
          _buildFieldLabel('Serving size'),
          const SizedBox(height: 10),
          TextField(
            controller: _servingSizeController,
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
            decoration: _inputDecoration(
              hintText: 'e.g. 300',
              suffixText: 'g/ml',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          _buildFieldLabel('Serving quantity'),
          const SizedBox(height: 10),
          TextField(
            controller: _servingQuantityController,
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
            decoration: _inputDecoration(
              hintText: 'Enter quantity, e.g. 1 or 0.5',
              suffixText: null,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSelectionSection() {
    return _buildSectionCard(
      title: 'Add To Meal',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('Meal'),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _selectedMealType,
            dropdownColor: AppColours.secondary,
            iconEnabledColor: AppColours.textMuted,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: AppColours.onDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            items: MealLoggingService.mealTypes
                .map(
                  (mealType) => DropdownMenuItem<String>(
                    value: mealType,
                    child: Text(mealType),
                  ),
                )
                .toList(),
            onChanged: _isSaving
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() => _selectedMealType = value);
                  },
            decoration: _inputDecoration(
              hintText: 'Select a meal',
              suffixText: null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSection({
    required String title,
    required ResolvedFoodNutrients nutrients,
  }) {
    return _buildSectionCard(
      title: title,
      child: Column(
        children: [
          NutritionBreakdownCard(
            calories: nutrients.calories,
            protein: nutrients.protein,
            carbs: nutrients.carbs,
            fat: nutrients.fat,
          ),
          const SizedBox(height: 16),
          _buildReadOnlyDetail(
            label: 'Calories',
            value: FoodService.formatCalories(nutrients.calories),
          ),
          const SizedBox(height: 14),
          _buildReadOnlyDetail(
            label: 'Protein',
            value: FoodService.formatMetric(nutrients.protein),
          ),
          const SizedBox(height: 14),
          _buildReadOnlyDetail(
            label: 'Carbs',
            value: FoodService.formatMetric(nutrients.carbs),
          ),
          const SizedBox(height: 14),
          _buildReadOnlyDetail(
            label: 'Fat',
            value: FoodService.formatMetric(nutrients.fat),
          ),
          const SizedBox(height: 14),
          _buildReadOnlyDetail(
            label: 'Fibre',
            value: FoodService.formatMetric(nutrients.fibre),
          ),
          const SizedBox(height: 14),
          _buildReadOnlyDetail(
            label: 'Sugar',
            value: FoodService.formatMetric(nutrients.sugar),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: AppColours.secondary.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColours.panelBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColours.shadowSoft,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.title.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildReadOnlyDetail({required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: AppColours.textSubtle,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String value) {
    return Text(
      value,
      style: AppTextStyles.label.copyWith(
        color: AppColours.onDark,
        fontSize: 15,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required String? suffixText,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: AppColours.inputFill,
      hintText: hintText,
      hintStyle: const TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        color: AppColours.textFaint,
      ),
      suffixText: suffixText,
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
        borderSide: const BorderSide(color: AppColours.primary, width: 1.5),
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

  Future<void> _addToMeal() async {
    final servingQuantity = _parseServingQuantity();
    final servingSize = _servingSizeController.text.trim();

    if (servingSize.isEmpty) {
      _showMessage('Please enter a serving size before adding this item.');
      return;
    }

    if (_product.parseServingSizeGrams(servingSize) == null) {
      _showMessage('Please enter the serving size in grams, for example 30g.');
      return;
    }

    if (servingQuantity == null || servingQuantity <= 0) {
      _showMessage('Please enter a valid serving quantity greater than zero.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await AuthScope.of(context).withAuthenticatedSession((session) {
        return _mealLoggingService.addFoodToMeal(
          session: session,
          product: _product,
          mealType: _selectedMealType,
          servingSize: servingSize,
          servingQuantity: servingQuantity,
          logDate: widget.logDate,
        );
      });

      if (!mounted) return;
      Navigator.of(context).pop(_selectedMealType);
    } on ApiFailure catch (error) {
      AppSnack.error(context, error.message);
    } catch (_) {
      AppSnack.error(
        context,
        'Unable to add this item right now. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showMessage(String message) {
    AppSnack.show(context, message);
  }

  ResolvedFoodNutrients get _selectedServingNutrients {
    final servingSize = _servingSizeController.text.trim();
    final servingQuantity = _parseServingQuantity();
    if (servingSize.isEmpty) {
      return const ResolvedFoodNutrients();
    }
    if (servingQuantity == null || servingQuantity <= 0) {
      return const ResolvedFoodNutrients();
    }

    return _product.resolveNutrientsForServingSize(
      servingSize,
      servingQuantity,
    );
  }

  double? _parseServingQuantity() {
    final trimmed = _servingQuantityController.text.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  String _extractServingSizeValue(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return '';

    final match = RegExp(r'(\d+(?:[.,]\d+)?)').firstMatch(text);
    if (match == null) return '';

    return match.group(1)!.replaceAll(',', '.');
  }

  String _defaultMealType() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Breakfast';
    if (hour < 15) return 'Lunch';
    if (hour < 22) return 'Dinner';
    return 'Snacks';
  }
}
