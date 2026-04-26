import 'package:flutter/material.dart';
import 'package:myhealthtrackr/themes/app_icons.dart';
import 'package:myhealthtrackr/services/api_client.dart';
import 'package:myhealthtrackr/services/auth_scope.dart';
import 'package:myhealthtrackr/services/food_service.dart';
import 'package:myhealthtrackr/services/meal_logging_service.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';
import 'package:myhealthtrackr/themes/app_text_styles.dart';
import 'package:myhealthtrackr/widgets/app_snack.dart';

enum EditMealItemResult { updated, deleted }

class EditMealItemPage extends StatefulWidget {
  const EditMealItemPage({
    super.key,
    required this.item,
    required this.logDate,
  });

  final DiaryMealItem item;
  final DateTime logDate;

  @override
  State<EditMealItemPage> createState() => _EditMealItemPageState();
}

class _EditMealItemPageState extends State<EditMealItemPage> {
  final MealLoggingService _mealLoggingService = const MealLoggingService();
  late final TextEditingController _servingSizeController;
  late final TextEditingController _servingQuantityController;

  late String _selectedMealType;
  bool _isSaving = false;
  bool _isDeleting = false;

  DiaryMealItem get _item => widget.item;
  bool get _isBusy => _isSaving || _isDeleting;

  @override
  void initState() {
    super.initState();
    _servingSizeController = TextEditingController(
      text: _formatInitialServingSize(_item.servingSize),
    );
    _servingQuantityController = TextEditingController(
      text: _formatInitialQuantity(_item.quantity),
    );
    _selectedMealType = MealLoggingService.mealTypes.contains(_item.mealType)
        ? _item.mealType
        : MealLoggingService.mealTypes.first;
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
    final currentQuantity = _formatCurrentQuantityLabel(_item.quantity);

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
                  _buildHeroCard(currentQuantity),
                  const SizedBox(height: 18),
                  _buildMeasurementsSection(),
                  const SizedBox(height: 18),
                  _buildMealSelectionSection(),
                  const SizedBox(height: 18),
                  _buildNutritionSection(
                    title: 'Nutrition Per 100g',
                    nutrients: _item.nutrientsPer100g,
                  ),
                  const SizedBox(height: 18),
                  _buildNutritionSection(
                    title: 'Nutrition For Selected Serving',
                    nutrients: selectedServingNutrients,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isBusy ? null : _updateMealItem,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColours.primary,
                        foregroundColor: AppColours.onDark,
                        disabledBackgroundColor: AppColours.primary.withValues(
                          alpha: 0.45,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: Text(
                        _isSaving ? 'Updating item...' : 'Update item',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isBusy ? null : _deleteMealItem,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColours.danger,
                        side: const BorderSide(color: AppColours.danger),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: Text(
                        _isDeleting ? 'Deleting item...' : 'Delete item',
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
    return Row(
      children: [
        GestureDetector(
          onTap: _isBusy ? null : () => Navigator.of(context).pop(),
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
              color: _isBusy ? AppColours.textSubtle : AppColours.onDark,
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
                'Edit meal item',
                style: AppTextStyles.title.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Update the serving, meal, or remove this item.',
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

  Widget _buildHeroCard(String? currentQuantity) {
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
            _item.name,
            style: AppTextStyles.headline.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Currently logged in ${_item.mealType}',
            style: AppTextStyles.bodyMuted.copyWith(
              color: AppColours.textMuted,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetaPill(
                icon: AppIcons.localFireDepartmentRounded,
                label: FoodService.formatCalories(_item.calories),
              ),
              if (currentQuantity != null)
                _MetaPill(icon: AppIcons.scaleRounded, label: currentQuantity),
            ],
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
              hintText: 'Enter the quantity to log',
              suffixText: 'servings',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSelectionSection() {
    final selectedMealType =
        MealLoggingService.mealTypes.contains(_selectedMealType)
        ? _selectedMealType
        : MealLoggingService.mealTypes.first;

    return _buildSectionCard(
      title: 'Move To Meal',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('Meal'),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: selectedMealType,
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
            onChanged: _isBusy
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

  Future<void> _updateMealItem() async {
    final servingQuantity = _parseServingQuantity();
    final servingSize = _servingSizeController.text.trim();

    if (servingSize.isEmpty) {
      _showMessage('Please enter a serving size before saving this item.');
      return;
    }

    if (DiaryMealItem.parseServingSizeGrams(servingSize) == null) {
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
      await AuthScope.of(context).withAuthenticatedSession((session) {
        return _mealLoggingService.updateMealItem(
          session: session,
          item: _item,
          mealType: _selectedMealType,
          servingSize: servingSize,
          servingQuantity: servingQuantity,
          logDate: widget.logDate,
        );
      });

      if (!mounted) return;
      Navigator.of(context).pop(EditMealItemResult.updated);
    } on ApiFailure catch (error) {
      AppSnack.error(context, error.message);
    } catch (_) {
      AppSnack.error(
        context,
        'Unable to update this item right now. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteMealItem() async {
    setState(() => _isDeleting = true);

    try {
      await AuthScope.of(context).withAuthenticatedSession((session) {
        return _mealLoggingService.deleteMealItem(
          session: session,
          mealItemId: _item.id,
        );
      });

      if (!mounted) return;
      Navigator.of(context).pop(EditMealItemResult.deleted);
    } on ApiFailure catch (error) {
      AppSnack.error(context, error.message);
    } catch (_) {
      AppSnack.error(
        context,
        'Unable to delete this item right now. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
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

    return _item.resolveNutrientsForServingSize(servingSize, servingQuantity);
  }

  double? _parseServingQuantity() {
    final trimmed = _servingQuantityController.text.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  String? _formatCurrentQuantityLabel(double? value) {
    if (value == null) return null;
    final formatted = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return '$formatted serving${value == 1 ? '' : 's'} logged';
  }

  String _formatInitialQuantity(double? value) {
    if (value == null) return '1';
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  String _formatInitialServingSize(int? value) {
    if (value == null || value <= 0) return '';
    return value.toString();
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColours.background.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColours.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
