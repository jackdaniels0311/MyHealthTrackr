import 'package:flutter/material.dart';
import 'package:myhealthtrackr/pages/saved_meal_editor_page.dart';
import 'package:myhealthtrackr/services/api_client.dart';
import 'package:myhealthtrackr/services/auth_scope.dart';
import 'package:myhealthtrackr/services/food_service.dart';
import 'package:myhealthtrackr/services/saved_meals_service.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';
import 'package:myhealthtrackr/themes/app_icons.dart';
import 'package:myhealthtrackr/themes/app_text_styles.dart';
import 'package:myhealthtrackr/widgets/app_snack.dart';
import 'package:myhealthtrackr/widgets/nutrition_breakdown_card.dart';

enum SavedMealDetailAction { updated, deleted, logged }

class SavedMealDetailPage extends StatefulWidget {
  const SavedMealDetailPage({super.key, required this.meal});

  final SavedMealData meal;

  @override
  State<SavedMealDetailPage> createState() => _SavedMealDetailPageState();
}

class _SavedMealDetailPageState extends State<SavedMealDetailPage> {
  final SavedMealsService _savedMealsService = const SavedMealsService();
  late SavedMealData _meal;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _meal = widget.meal;
  }

  @override
  Widget build(BuildContext context) {
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
                  _buildNutritionSummary(),
                  const SizedBox(height: 18),
                  _buildItemsSection(),
                  const SizedBox(height: 28),
                  _buildActions(),
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
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColours.secondary.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColours.borderLight),
            ),
            child: const Icon(
              AppIcons.arrowBackRounded,
              color: AppColours.onDark,
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
                'Meal details',
                style: AppTextStyles.title.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'View your meals nutrition.',
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
            _meal.name,
            style: AppTextStyles.headline.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_meal.items.length} item${_meal.items.length == 1 ? '' : 's'} saved',
            style: AppTextStyles.bodyMuted.copyWith(
              color: AppColours.textMuted,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSummary() {
    return _buildSectionCard(
      title: 'Nutrition Summary',
      child: Column(
        children: [
          NutritionBreakdownCard(
            calories: _meal.totalCalories,
            protein: _meal.totalProtein,
            carbs: _meal.totalCarbs,
            fat: _meal.totalFat,
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'Calories',
            FoodService.formatCalories(_meal.totalCalories),
          ),
          const SizedBox(height: 14),
          _buildSummaryRow(
            'Protein',
            FoodService.formatMetric(_meal.totalProtein),
          ),
          const SizedBox(height: 14),
          _buildSummaryRow('Carbs', FoodService.formatMetric(_meal.totalCarbs)),
          const SizedBox(height: 14),
          _buildSummaryRow('Fat', FoodService.formatMetric(_meal.totalFat)),
          const SizedBox(height: 14),
          _buildSummaryRow('Fibre', FoodService.formatMetric(_meal.totalFibre)),
          const SizedBox(height: 14),
          _buildSummaryRow('Sugar', FoodService.formatMetric(_meal.totalSugar)),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    return _buildSectionCard(
      title: 'Items',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < _meal.items.length; index++) ...[
            _buildItemRow(_meal.items[index]),
            if (index != _meal.items.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildItemRow(SavedMealItemData item) {
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
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _openEditor,
            style: FilledButton.styleFrom(
              backgroundColor: AppColours.primary,
              foregroundColor: AppColours.onDark,
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            icon: const Icon(AppIcons.editOutlined, size: 18),
            label: const Text('Edit meal'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isDeleting ? null : _confirmDelete,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColours.danger,
              side: const BorderSide(color: AppColours.danger),
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            icon: const Icon(AppIcons.closeRounded, size: 18),
            label: Text(_isDeleting ? 'Deleting...' : 'Delete meal'),
          ),
        ),
      ],
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

  Future<void> _openEditor() async {
    final updatedMeal = await Navigator.of(context).push<SavedMealData>(
      MaterialPageRoute<SavedMealData>(
        builder: (_) => SavedMealEditorPage(existingMeal: _meal),
      ),
    );
    if (!mounted || updatedMeal == null) return;
    setState(() => _meal = updatedMeal);
    Navigator.of(context).pop(SavedMealDetailAction.updated);
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColours.secondary,
          title: Text(
            'Delete meal?',
            style: AppTextStyles.title.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'This will remove ${_meal.name} from your saved meals. Existing diary entries will stay unchanged.',
            style: AppTextStyles.bodyMuted.copyWith(
              color: AppColours.textMuted,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColours.danger,
                foregroundColor: AppColours.onDark,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      await AuthScope.of(context).withAuthenticatedSession((session) {
        return _savedMealsService.deleteMeal(
          session: session,
          savedMealId: _meal.id,
        );
      });
      if (!mounted) return;
      Navigator.of(context).pop(SavedMealDetailAction.deleted);
    } on ApiFailure catch (error) {
      AppSnack.error(context, error.message);
    } catch (_) {
      AppSnack.error(
        context,
        'Unable to delete this meal right now. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }
}
