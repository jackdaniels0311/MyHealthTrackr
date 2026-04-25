import 'package:flutter/material.dart';
import 'package:myhealthtrackr/pages/food_search_page.dart';
import 'package:myhealthtrackr/pages/saved_meal_item_editor_page.dart';
import 'package:myhealthtrackr/services/api_client.dart';
import 'package:myhealthtrackr/services/auth_scope.dart';
import 'package:myhealthtrackr/services/food_service.dart';
import 'package:myhealthtrackr/services/saved_meals_service.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';
import 'package:myhealthtrackr/themes/app_icons.dart';
import 'package:myhealthtrackr/themes/app_text_styles.dart';
import 'package:myhealthtrackr/widgets/app_snack.dart';
import 'package:myhealthtrackr/widgets/confirmation_dialog.dart';
import 'package:myhealthtrackr/widgets/nutrition_breakdown_card.dart';

class SavedMealEditorPage extends StatefulWidget {
  const SavedMealEditorPage({super.key, this.existingMeal});

  final SavedMealData? existingMeal;

  @override
  State<SavedMealEditorPage> createState() => _SavedMealEditorPageState();
}

class _SavedMealEditorPageState extends State<SavedMealEditorPage> {
  final SavedMealsService _savedMealsService = const SavedMealsService();
  late final TextEditingController _nameController;
  final FocusNode _nameFocusNode = FocusNode();
  late List<SavedMealItemData> _items;
  String? _initialMealName;
  List<String>? _initialItemSignatures;
  bool _isSaving = false;

  bool get _isEditing => widget.existingMeal != null;
  String get _pageTitle => _isEditing ? 'Edit meal' : 'Create meal';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingMeal?.name ?? '',
    );
    _items = List<SavedMealItemData>.from(
      widget.existingMeal?.items ?? const [],
    );
    _captureInitialSnapshot();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _clearFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totals = _totals;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _isSaving) return;
        _handleBackNavigation();
      },
      child: Scaffold(
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
                    _buildMealNameCard(),
                    const SizedBox(height: 18),
                    _buildNutritionSummary(totals),
                    const SizedBox(height: 18),
                    _buildItemsSection(),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSaving ? null : _saveMeal,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColours.primary,
                          foregroundColor: AppColours.onDark,
                          disabledBackgroundColor: AppColours.primary
                              .withValues(alpha: 0.45),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: Text(
                          _isSaving
                              ? (_isEditing
                                    ? 'Saving changes...'
                                    : 'Creating meal...')
                              : (_isEditing ? 'Save meal' : 'Create meal'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : _handleBackNavigation,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColours.onDark,
                          side: BorderSide(
                            color: AppColours.primary.withValues(alpha: 0.55),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: _isSaving ? null : _handleBackNavigation,
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
                _pageTitle,
                style: AppTextStyles.title.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Edit, remove or add items to your meal.',
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

  Widget _buildMealNameCard() {
    return _buildSectionCard(
      title: 'Meal Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('Meal name'),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: AppColours.onDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            decoration: _inputDecoration(
              hintText: 'e.g. Chicken rice bowl',
              suffixText: null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSummary(_MealTotals totals) {
    return _buildSectionCard(
      title: 'Nutrition Summary',
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
      title: 'Items',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_items.isEmpty)
            Text(
              'Add at least one food item to save this meal.',
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
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isSaving ? null : _addItem,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColours.onDark,
                side: BorderSide(
                  color: AppColours.primary.withValues(alpha: 0.55),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(AppIcons.searchRounded, size: 20),
              label: const Text('Add food item'),
            ),
          ),
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
              FilledButton.icon(
                onPressed: _isSaving ? null : () => _editItem(index),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColours.primary,
                  foregroundColor: AppColours.onDark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(AppIcons.editOutlined, size: 18),
                label: const Text('Edit'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _isSaving ? null : () => _removeItem(index),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColours.danger,
                  side: const BorderSide(color: AppColours.danger),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
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

  _MealTotals get _totals => _MealTotals.fromItems(_items);
  String get _normalizedMealName => _nameController.text.trim();
  bool get _hasUnsavedChanges {
    _captureInitialSnapshot();
    return _normalizedMealName != _initialMealName ||
        !_listEquals(_itemSignatures(_items), _initialItemSignatures!);
  }

  Future<void> _addItem() async {
    final selection = await Navigator.of(context).push<FoodSearchSelection>(
      MaterialPageRoute<FoodSearchSelection>(
        builder: (_) => const FoodSearchPage(),
      ),
    );

    if (!mounted || selection == null) return;
    if (selection.openBarcodeScanner) {
      _showMessage('Barcode scanning is not available in meal plans yet.');
      return;
    }

    final product = selection.product;
    if (product == null) return;

    final item = await Navigator.of(context).push<SavedMealItemData>(
      MaterialPageRoute<SavedMealItemData>(
        builder: (_) => SavedMealItemEditorPage.fromProduct(product: product),
      ),
    );

    if (!mounted || item == null) return;
    setState(() => _items = [..._items, item]);
    _clearFocus();
  }

  Future<void> _editItem(int index) async {
    final updated = await Navigator.of(context).push<SavedMealItemData>(
      MaterialPageRoute<SavedMealItemData>(
        builder: (_) =>
            SavedMealItemEditorPage.editItem(initialItem: _items[index]),
      ),
    );

    if (!mounted || updated == null) return;
    setState(() {
      final nextItems = List<SavedMealItemData>.from(_items);
      nextItems[index] = updated;
      _items = nextItems;
    });
    _clearFocus();
  }

  void _removeItem(int index) {
    setState(() {
      final nextItems = List<SavedMealItemData>.from(_items)..removeAt(index);
      _items = nextItems;
    });
  }

  Future<void> _saveMeal() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Please give this meal a name before saving it.');
      return;
    }
    if (_items.isEmpty) {
      _showMessage('Please add at least one item before saving this meal.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final savedMeal = await AuthScope.of(context).withAuthenticatedSession((
        session,
      ) {
        if (_isEditing) {
          return _savedMealsService.updateMeal(
            session: session,
            savedMealId: widget.existingMeal!.id,
            name: name,
            items: _items,
          );
        }
        return _savedMealsService.createMeal(
          session: session,
          name: name,
          items: _items,
        );
      });

      if (!mounted) return;
      Navigator.of(context).pop(savedMeal);
    } on ApiFailure catch (error) {
      AppSnack.error(context, error.message);
    } catch (_) {
      AppSnack.error(
        context,
        'Unable to save this meal right now. Please try again.',
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

  void _clearFocus() {
    _nameFocusNode.unfocus();
    FocusScope.of(context).unfocus();
  }

  Future<void> _handleBackNavigation() async {
    _clearFocus();
    if (!_hasUnsavedChanges) {
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }

    final shouldLeave = await showConfirmationDialog(
      context: context,
      title: 'Unsaved changes?',
      message:
          'You have unsaved changes to this meal. Keep editing to save them, or leave and lose those changes.',
      confirmLabel: 'Leave',
      cancelLabel: 'Keep editing',
      emphasizeCancelAction: true,
      isDestructive: true,
    );

    if (!mounted || !shouldLeave) return;
    Navigator.of(context).pop();
  }

  List<String> _itemSignatures(List<SavedMealItemData> items) {
    return items.map(_itemSignature).toList(growable: false);
  }

  String _itemSignature(SavedMealItemData item) {
    return [
      item.id?.toString() ?? '',
      item.name.trim(),
      item.servingSize?.toString() ?? '',
      _numericSignature(item.quantity),
      _numericSignature(item.calories),
      _numericSignature(item.protein),
      _numericSignature(item.carbs),
      _numericSignature(item.fat),
      _numericSignature(item.fibre),
      _numericSignature(item.sugar),
    ].join('|');
  }

  String _numericSignature(double? value) {
    if (value == null) return '';
    return value.toStringAsFixed(4);
  }

  bool _listEquals(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  void _captureInitialSnapshot() {
    _initialMealName ??= _normalizedMealName;
    _initialItemSignatures ??= _itemSignatures(_items);
  }
}

class _MealTotals {
  const _MealTotals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fibre,
    required this.sugar,
  });

  factory _MealTotals.fromItems(List<SavedMealItemData> items) {
    return _MealTotals(
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
