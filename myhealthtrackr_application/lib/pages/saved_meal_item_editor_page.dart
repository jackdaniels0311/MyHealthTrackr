import 'package:flutter/material.dart';
import 'package:myhealthtrackr/services/api_client.dart';
import 'package:myhealthtrackr/services/food_service.dart';
import 'package:myhealthtrackr/services/saved_meals_service.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';
import 'package:myhealthtrackr/themes/app_icons.dart';
import 'package:myhealthtrackr/themes/app_text_styles.dart';
import 'package:myhealthtrackr/widgets/app_snack.dart';
import 'package:myhealthtrackr/widgets/nutrition_breakdown_card.dart';

class SavedMealItemEditorPage extends StatefulWidget {
  const SavedMealItemEditorPage.fromProduct({
    super.key,
    required this.product,
    this.initialItem,
    this.actionLabel = 'Add item',
    this.helperText =
        'Choose the serving size and quantity to add to this meal.',
  });

  const SavedMealItemEditorPage.editItem({
    super.key,
    required this.initialItem,
    this.product,
    this.actionLabel = 'Update item',
    this.helperText = 'Adjust the portion for this saved meal item.',
  });

  final FoodProduct? product;
  final SavedMealItemData? initialItem;
  final String actionLabel;
  final String helperText;

  @override
  State<SavedMealItemEditorPage> createState() =>
      _SavedMealItemEditorPageState();
}

class _SavedMealItemEditorPageState extends State<SavedMealItemEditorPage> {
  late final TextEditingController _servingSizeController;
  late final TextEditingController _quantityController;
  bool _isSaving = false;

  SavedMealItemData? get _initialItem => widget.initialItem;
  FoodProduct? get _product => widget.product;

  String get _displayName {
    if (_initialItem != null) return _initialItem!.name;
    return _product?.name ?? '';
  }

  String? get _subtitle {
    final brand = _product?.brand?.trim();
    if (brand != null && brand.isNotEmpty) {
      return brand;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _servingSizeController = TextEditingController(
      text:
          _initialItem?.defaultServingSize ??
          _extractServingSizeValue(_product?.servingSize),
    );
    _quantityController = TextEditingController(
      text: _formatInitialQuantity(_initialItem?.quantity),
    );
  }

  @override
  void dispose() {
    _servingSizeController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nutrients = _selectedServingNutrients;

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
                  _buildHeroCard(),
                  const SizedBox(height: 18),
                  _buildMeasurementsSection(),
                  const SizedBox(height: 18),
                  _buildNutritionSection(
                    title: 'Nutrition For Selected Serving',
                    nutrients: nutrients,
                  ),
                  const SizedBox(height: 18),
                  _buildNutritionSection(
                    title: 'Nutrition Per 100g/ml',
                    nutrients: _nutrientsPer100g,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _saveItem,
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
                            ? '${widget.actionLabel}...'
                            : widget.actionLabel,
                      ),
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

  Widget _buildHeroCard() {
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
            _displayName,
            style: AppTextStyles.headline.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (_subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              _subtitle!,
              style: AppTextStyles.bodyMuted.copyWith(
                color: AppColours.textMuted,
                fontSize: 17,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            widget.helperText,
            style: AppTextStyles.bodyMuted.copyWith(
              color: AppColours.textSubtle,
              fontSize: 15,
            ),
          ),
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
          if ((_product?.quantity ?? '').trim().isNotEmpty) ...[
            _buildReadOnlyDetail(
              label: 'Pack quantity',
              value: _product!.quantity!.trim(),
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
              hintText: 'e.g. 30',
              suffixText: 'g/ml',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          _buildFieldLabel('Serving quantity'),
          const SizedBox(height: 10),
          TextField(
            controller: _quantityController,
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
              suffixText: 'servings',
            ),
            onChanged: (_) => setState(() {}),
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

  ResolvedFoodNutrients get _nutrientsPer100g {
    if (_product != null) {
      return ResolvedFoodNutrients(
        calories: _product!.nutrients.caloriesPer100g,
        protein: _product!.nutrients.proteinPer100g,
        carbs: _product!.nutrients.carbsPer100g,
        fat: _product!.nutrients.fatPer100g,
        fibre: _product!.nutrients.fibrePer100g,
        sugar: _product!.nutrients.sugarPer100g,
      );
    }
    return _initialItem?.nutrientsPer100g ?? const ResolvedFoodNutrients();
  }

  ResolvedFoodNutrients get _selectedServingNutrients {
    final servingSize = _servingSizeController.text.trim();
    final servingQuantity = _parseServingQuantity();
    if (servingSize.isEmpty ||
        servingQuantity == null ||
        servingQuantity <= 0) {
      return const ResolvedFoodNutrients();
    }

    if (_product != null) {
      return _product!.resolveNutrientsForServingSize(
        servingSize,
        servingQuantity,
      );
    }

    if (_initialItem != null) {
      return _initialItem!
          .recalculate(
            servingSize: servingSize,
            servingQuantity: servingQuantity,
          )
          .nutrientsPer100g
          .copyWithResolved(
            servingSize: servingSize,
            servingQuantity: servingQuantity,
          );
    }

    return const ResolvedFoodNutrients();
  }

  Future<void> _saveItem() async {
    final servingSize = _servingSizeController.text.trim();
    final servingQuantity = _parseServingQuantity();

    if (servingSize.isEmpty) {
      _showMessage('Please enter a serving size before saving this item.');
      return;
    }

    if (SavedMealItemData.parseServingSizeGrams(servingSize) == null) {
      _showMessage(
        'Please enter the serving size as a number, for example 30.',
      );
      return;
    }

    if (servingQuantity == null || servingQuantity <= 0) {
      _showMessage('Please enter a valid serving quantity greater than zero.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final item = _product != null
          ? SavedMealItemData.fromProduct(
              product: _product!,
              servingSize: servingSize,
              servingQuantity: servingQuantity,
            )
          : _initialItem!.recalculate(
              servingSize: servingSize,
              servingQuantity: servingQuantity,
            );

      if (!mounted) return;
      Navigator.of(context).pop(item);
    } on ApiFailure catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Unable to prepare this item right now. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showMessage(String message) {
    AppSnack.show(context, message);
  }

  double? _parseServingQuantity() {
    final trimmed = _quantityController.text.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  String _extractServingSizeValue(String? rawValue) {
    final trimmed = rawValue?.trim() ?? '';
    if (trimmed.isEmpty) {
      return '';
    }

    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(trimmed);
    return match?.group(1) ?? trimmed;
  }

  String _formatInitialQuantity(double? value) {
    if (value == null) return '1';
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }
}

extension on ResolvedFoodNutrients {
  ResolvedFoodNutrients copyWithResolved({
    required String servingSize,
    required double servingQuantity,
  }) {
    final grams = SavedMealItemData.parseServingSizeGrams(servingSize);
    if (grams == null || grams <= 0 || servingQuantity <= 0) {
      return const ResolvedFoodNutrients();
    }

    final factor = (grams * servingQuantity) / 100;
    return ResolvedFoodNutrients(
      calories: _scale(calories, factor),
      protein: _scale(protein, factor),
      carbs: _scale(carbs, factor),
      fat: _scale(fat, factor),
      fibre: _scale(fibre, factor),
      sugar: _scale(sugar, factor),
    );
  }

  double? _scale(double? value, double factor) {
    if (value == null) return null;
    return value * factor;
  }
}
