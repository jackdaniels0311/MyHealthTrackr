import 'package:flutter/material.dart';
import 'package:myhealthtrackr/pages/saved_meal_item_editor_page.dart';
import 'package:myhealthtrackr/services/api_client.dart';
import 'package:myhealthtrackr/services/auth_scope.dart';
import 'package:myhealthtrackr/services/food_service.dart';
import 'package:myhealthtrackr/services/meal_logging_service.dart';
import 'package:myhealthtrackr/services/saved_meals_service.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';
import 'package:myhealthtrackr/themes/app_icons.dart';
import 'package:myhealthtrackr/themes/app_text_styles.dart';
import 'package:myhealthtrackr/widgets/app_snack.dart';
import 'package:myhealthtrackr/widgets/nutrition_breakdown_card.dart';

class LogSavedMealPage extends StatefulWidget {
  const LogSavedMealPage({
    super.key,
    required this.meal,
    this.initialMealType,
    this.initialLogDate,
  });

  final SavedMealData meal;
  final String? initialMealType;
  final DateTime? initialLogDate;

  @override
  State<LogSavedMealPage> createState() => _LogSavedMealPageState();
}

class _LogSavedMealPageState extends State<LogSavedMealPage> {
  final SavedMealsService _savedMealsService = const SavedMealsService();
  late List<SavedMealItemData> _items;
  late String _selectedMealType;
  late DateTime _selectedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _items = List<SavedMealItemData>.from(widget.meal.items);
    _selectedMealType =
        widget.initialMealType != null &&
            MealLoggingService.calorieMealTypes.contains(widget.initialMealType)
        ? widget.initialMealType!
        : MealLoggingService.calorieMealTypes.first;
    final baseDate = widget.initialLogDate ?? DateTime.now();
    _selectedDate = DateTime(baseDate.year, baseDate.month, baseDate.day);
  }

  @override
  Widget build(BuildContext context) {
    final totals = _MealLogTotals.fromItems(_items);

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
                  _buildLoggingOptionsCard(),
                  const SizedBox(height: 18),
                  _buildNutritionSummary(totals),
                  const SizedBox(height: 18),
                  _buildItemsSection(),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _logMeal,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColours.primary,
                        foregroundColor: AppColours.onDark,
                        disabledBackgroundColor: AppColours.primary.withValues(
                          alpha: 0.45,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: Text(
                        _isSaving ? 'Logging meal...' : 'Log to diary',
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
          onTap: _isSaving ? null : () => Navigator.of(context).pop(false),
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
                'Log meal',
                style: AppTextStyles.title.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Review this meal before copying it into your diary.',
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
            widget.meal.name,
            style: AppTextStyles.headline.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Diary edits here affect this entry only and do not change the saved meal.',
            style: AppTextStyles.bodyMuted.copyWith(
              color: AppColours.textMuted,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggingOptionsCard() {
    return _buildSectionCard(
      title: 'Diary Options',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('Diary meal'),
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
            items: MealLoggingService.calorieMealTypes
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

  Widget _buildNutritionSummary(_MealLogTotals totals) {
    return _buildSectionCard(
      title: 'Meal Overview',
      child: Column(
        children: [
          NutritionBreakdownCard(
            calories: totals.calories,
            protein: totals.protein,
            carbs: totals.carbs,
            fat: totals.fat,
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'Calories',
            FoodService.formatCalories(totals.calories),
          ),
          const SizedBox(height: 14),
          _buildSummaryRow('Protein', FoodService.formatMetric(totals.protein)),
          const SizedBox(height: 14),
          _buildSummaryRow('Carbs', FoodService.formatMetric(totals.carbs)),
          const SizedBox(height: 14),
          _buildSummaryRow('Fat', FoodService.formatMetric(totals.fat)),
          const SizedBox(height: 14),
          _buildSummaryRow('Fibre', FoodService.formatMetric(totals.fibre)),
          const SizedBox(height: 14),
          _buildSummaryRow('Sugar', FoodService.formatMetric(totals.sugar)),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    return _buildSectionCard(
      title: 'Items For This Diary Entry',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You can edit serving sizes or remove items here. Adding new items is not enabled in this flow yet.',
            style: AppTextStyles.bodyMuted.copyWith(
              color: AppColours.textMuted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          if (_items.isEmpty)
            Text(
              'At least one item is required to log this meal.',
              style: AppTextStyles.bodyMuted.copyWith(
                color: AppColours.textMuted,
                fontSize: 15,
              ),
            )
          else ...[
            for (var index = 0; index < _items.length; index++) ...[
              _buildItemRow(_items[index], index),
              if (index != _items.length - 1) const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildItemRow(SavedMealItemData item, int index) {
    final servingSize = item.servingSize;
    final quantity = item.quantity;
    final quantityLabel = quantity == null
        ? '--'
        : quantity == quantity.roundToDouble()
        ? quantity.toStringAsFixed(0)
        : quantity.toStringAsFixed(1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColours.background.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                FoodService.formatCalories(item.calories),
                style: AppTextStyles.label.copyWith(
                  color: AppColours.onDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            servingSize == null || servingSize <= 0
                ? 'Quantity: $quantityLabel'
                : 'Serving: ${servingSize}g/ml x $quantityLabel',
            style: AppTextStyles.bodyMuted.copyWith(
              color: AppColours.textMuted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Spacer(),
              TextButton.icon(
                onPressed: _isSaving ? null : () => _editItem(index),
                icon: const Icon(AppIcons.editOutlined, size: 18),
                label: const Text('Edit'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _isSaving ? null : () => _removeItem(index),
                style: TextButton.styleFrom(foregroundColor: AppColours.danger),
                icon: const Icon(AppIcons.closeRounded, size: 18),
                label: const Text('Remove'),
              ),
            ],
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

  Widget _buildFieldLabel(String value) {
    return Text(
      value,
      style: AppTextStyles.label.copyWith(
        color: AppColours.onDark,
        fontSize: 15,
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
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
        Text(
          value,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
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

  Future<void> _editItem(int index) async {
    final updated = await Navigator.of(context).push<SavedMealItemData>(
      MaterialPageRoute<SavedMealItemData>(
        builder: (_) => SavedMealItemEditorPage.editItem(
          initialItem: _items[index],
          actionLabel: 'Update entry',
          helperText:
              'Adjust this item for the diary entry you are about to log.',
        ),
      ),
    );
    if (!mounted || updated == null) return;
    setState(() {
      final nextItems = List<SavedMealItemData>.from(_items);
      nextItems[index] = updated;
      _items = nextItems;
    });
  }

  void _removeItem(int index) {
    setState(() {
      final nextItems = List<SavedMealItemData>.from(_items)..removeAt(index);
      _items = nextItems;
    });
  }

  Future<void> _logMeal() async {
    if (_items.isEmpty) {
      _showMessage('Please keep at least one item before logging this meal.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await AuthScope.of(context).withAuthenticatedSession((session) {
        return _savedMealsService.logMealToDiary(
          session: session,
          savedMealId: widget.meal.id,
          mealType: _selectedMealType,
          logDate: _selectedDate,
          items: _items,
        );
      });

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiFailure catch (error) {
      AppSnack.error(context, error.message);
    } catch (_) {
      AppSnack.error(
        context,
        'Unable to log this meal right now. Please try again.',
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
}

class _MealLogTotals {
  const _MealLogTotals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fibre,
    required this.sugar,
  });

  factory _MealLogTotals.fromItems(List<SavedMealItemData> items) {
    return _MealLogTotals(
      calories: items.fold(0, (sum, item) => sum + (item.calories ?? 0)),
      protein: items.fold(0, (sum, item) => sum + (item.protein ?? 0)),
      carbs: items.fold(0, (sum, item) => sum + (item.carbs ?? 0)),
      fat: items.fold(0, (sum, item) => sum + (item.fat ?? 0)),
      fibre: items.fold(0, (sum, item) => sum + (item.fibre ?? 0)),
      sugar: items.fold(0, (sum, item) => sum + (item.sugar ?? 0)),
    );
  }

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fibre;
  final double sugar;
}
