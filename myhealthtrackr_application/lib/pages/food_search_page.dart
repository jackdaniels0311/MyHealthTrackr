import 'package:flutter/material.dart';
import 'package:myhealthtrackr/pages/food_product_details_page.dart';
import 'package:myhealthtrackr/pages/log_saved_meal_page.dart';
import 'package:myhealthtrackr/services/saved_meals_service.dart';
import 'package:myhealthtrackr/services/api_client.dart';
import 'package:myhealthtrackr/services/auth_scope.dart';
import 'package:myhealthtrackr/services/food_service.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';
import 'package:myhealthtrackr/themes/app_icons.dart';
import 'package:myhealthtrackr/themes/app_text_styles.dart';
import 'package:myhealthtrackr/themes/meal_visuals.dart';
import 'package:myhealthtrackr/widgets/barcode_scanner_symbol_icon.dart';

class FoodSearchPage extends StatefulWidget {
  const FoodSearchPage({
    super.key,
    this.initialMealType,
    this.showSavedMealsTab = false,
    this.openProductDetailsOnSelect = false,
    this.openSavedMealLogOnSelect = false,
    this.logDate,
  });

  final String? initialMealType;
  final bool showSavedMealsTab;
  final bool openProductDetailsOnSelect;
  final bool openSavedMealLogOnSelect;
  final DateTime? logDate;

  @override
  State<FoodSearchPage> createState() => _FoodSearchPageState();
}

class FoodSearchSelection {
  const FoodSearchSelection.product(this.product)
    : savedMeal = null,
      loggedMealType = null,
      openBarcodeScanner = false;

  const FoodSearchSelection.savedMeal(this.savedMeal)
    : product = null,
      loggedMealType = null,
      openBarcodeScanner = false;

  const FoodSearchSelection.loggedMealType(this.loggedMealType)
    : product = null,
      savedMeal = null,
      openBarcodeScanner = false;

  const FoodSearchSelection.openScanner()
    : product = null,
      savedMeal = null,
      loggedMealType = null,
      openBarcodeScanner = true;

  final FoodProduct? product;
  final SavedMealData? savedMeal;
  final String? loggedMealType;
  final bool openBarcodeScanner;
}

class _FoodSearchPageState extends State<FoodSearchPage> {
  final FoodService _foodService = const FoodService();
  final SavedMealsService _savedMealsService = const SavedMealsService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<FoodProduct> _results = const <FoodProduct>[];
  List<SavedMealData> _savedMeals = const <SavedMealData>[];
  int _selectedTabIndex = 0;
  bool _hasSearched = false;
  bool _isLoadingQuickAdd = false;
  bool _isLoadingSavedMeals = false;
  bool _isSearching = false;
  String? _errorMessage;
  String? _savedMealsErrorMessage;

  MealVisual get _mealVisual {
    final mealType = widget.initialMealType?.trim();
    if (mealType == null || mealType.isEmpty) {
      return const MealVisual(
        icon: AppIcons.searchRounded,
        accent: AppColours.primary,
      );
    }
    return MealVisuals.forType(mealType);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadQuickAddItems();
      if (widget.showSavedMealsTab) {
        _loadSavedMeals();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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
          SafeArea(bottom: false, child: _buildScrollableContent(context)),
        ],
      ),
    );
  }

  Widget _buildScrollableContent(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return ListView(
      padding: EdgeInsets.fromLTRB(22, 18, 22, 22 + bottomInset),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const BouncingScrollPhysics(),
      children: [
        _buildTopBar(context),
        const SizedBox(height: 24),
        _buildSearchCard(),
        const SizedBox(height: 18),
        if (widget.showSavedMealsTab) ...[
          _buildTabBar(),
          const SizedBox(height: 18),
        ],
        ..._buildActiveSection(),
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

  Widget _buildTopBar(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
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
    );
  }

  Widget _buildSearchCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: AppColours.secondary.withValues(alpha: 0.94),
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
            'Search for your food',
            style: AppTextStyles.title.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Type a product name or brand to search.',
            style: AppTextStyles.bodyMuted.copyWith(
              color: AppColours.textMuted,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _performSearch(),
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: AppColours.onDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Search for foods, brands...',
              hintStyle: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: AppColours.textSubtle,
                fontSize: 16,
              ),
              filled: true,
              fillColor: AppColours.inputFill,
              prefixIcon: const Icon(
                AppIcons.searchRounded,
                color: AppColours.textSubtle,
              ),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchController,
                builder: (context, value, child) {
                  if (value.text.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    onPressed: _clearSearch,
                    icon: const Icon(AppIcons.closeRounded),
                    color: AppColours.onDark,
                  );
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSearching ? null : _openScanner,
              style: FilledButton.styleFrom(
                backgroundColor: AppColours.primary,
                foregroundColor: AppColours.onDark,
                disabledBackgroundColor: AppColours.primary.withValues(
                  alpha: 0.45,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const BarcodeScannerSymbolIcon(size: 20),
              label: const Text('Scan a barcode instead'),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildResultsSection() {
    if (_isSearching || (_isLoadingQuickAdd && _results.isEmpty)) {
      return const <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: CircularProgressIndicator(color: AppColours.primary),
          ),
        ),
      ];
    }

    if (_errorMessage != null) {
      return <Widget>[
        _buildInfoCard(
          title: 'Unable to search right now',
          message: _errorMessage!,
        ),
      ];
    }

    if (!_hasSearched) {
      if (_results.isNotEmpty) {
        return _buildResultCards();
      }
      return <Widget>[
        _buildInfoCard(
          title: 'Start searching',
          message:
              'Search results will appear here once you enter a product name. Regular foods will show up here automatically when available.',
        ),
      ];
    }

    if (_results.isEmpty) {
      return <Widget>[
        _buildInfoCard(
          title: 'No results found...',
          message:
              'We could not find any matches for that search right now. Try a more specific search, such as a product name or brand, or scan the barcode instead.',
        ),
      ];
    }

    return _buildResultCards();
  }

  List<Widget> _buildSavedMealsSection() {
    if (_isLoadingSavedMeals) {
      return const <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: CircularProgressIndicator(color: AppColours.primary),
          ),
        ),
      ];
    }

    if (_savedMealsErrorMessage != null) {
      return <Widget>[
        _buildInfoCard(
          title: 'Unable to load saved meals',
          message: _savedMealsErrorMessage!,
        ),
      ];
    }

    if (_savedMeals.isEmpty) {
      return <Widget>[
        _buildInfoCard(
          title: 'No saved meals yet',
          message:
              'Create meals from the Plans page and they will appear here for quick diary logging.',
        ),
      ];
    }

    return [
      for (var index = 0; index < _savedMeals.length; index++) ...[
        if (index > 0) const SizedBox(height: 14),
        _buildSavedMealCard(_savedMeals[index]),
      ],
    ];
  }

  List<Widget> _buildActiveSection() {
    if (!widget.showSavedMealsTab || _selectedTabIndex == 0) {
      return _buildResultsSection();
    }
    return _buildSavedMealsSection();
  }

  List<Widget> _buildResultCards() {
    return [
      for (var index = 0; index < _results.length; index++) ...[
        if (index > 0) const SizedBox(height: 14),
        _buildResultCard(_results[index]),
      ],
    ];
  }

  Widget _buildInfoCard({required String title, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: AppColours.secondary.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColours.panelBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.title.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTextStyles.bodyMuted.copyWith(
              color: AppColours.textMuted,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColours.secondary.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColours.panelBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              label: 'Recent items',
              index: 0,
              icon: AppIcons.menuBookRounded,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTabButton(
              label: 'Saved meals',
              index: 1,
              icon: AppIcons.restaurantMenuRounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required int index,
    required IconData icon,
  }) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColours.primary
              : AppColours.background.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColours.onDark : AppColours.textMuted,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label.copyWith(
                  color: isSelected ? AppColours.onDark : AppColours.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(FoodProduct product) {
    final mealVisual = _mealVisual;

    return Material(
      color: AppColours.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _handleProductSelection(product),
        child: Ink(
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: mealVisual.accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  mealVisual.icon,
                  color: mealVisual.accent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.displayName,
                      style: AppTextStyles.title.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (product.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        product.subtitle,
                        style: AppTextStyles.bodyMuted.copyWith(
                          color: AppColours.textMuted,
                          fontSize: 15,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _ResultPill(
                          icon: AppIcons.localFireDepartmentRounded,
                          label: _formatCaloriesPer100g(
                            product.nutrients.caloriesPer100g,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                AppIcons.chevronRightRounded,
                color: AppColours.textSubtle,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedMealCard(SavedMealData meal) {
    return Material(
      color: AppColours.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _handleSavedMealSelection(meal),
        child: Ink(
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColours.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  AppIcons.restaurantMenuRounded,
                  color: AppColours.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.name,
                      style: AppTextStyles.title.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${meal.items.length} item${meal.items.length == 1 ? '' : 's'}',
                      style: AppTextStyles.bodyMuted.copyWith(
                        color: AppColours.textMuted,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ResultPill(
                      icon: AppIcons.localFireDepartmentRounded,
                      label: FoodService.formatCalories(meal.totalCalories),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                AppIcons.chevronRightRounded,
                color: AppColours.textSubtle,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      await _loadQuickAddItems();
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _errorMessage = null;
    });

    try {
      final results = await AuthScope.of(context).withAuthenticatedSession((
        session,
      ) {
        return _foodService.searchFoods(
          query,
          session: session,
          mealType: widget.initialMealType,
        );
      });
      if (!mounted) return;
      setState(() {
        _results = results;
        _isSearching = false;
      });
    } on ApiFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _results = const <FoodProduct>[];
        _errorMessage = error.message;
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = const <FoodProduct>[];
        _errorMessage = 'Something went wrong while searching for food items.';
        _isSearching = false;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.requestFocus();
    _loadQuickAddItems();
  }

  void _openScanner() {
    Navigator.of(context).pop(const FoodSearchSelection.openScanner());
  }

  String _formatCaloriesPer100g(double? value) {
    final calories = FoodService.formatCalories(value);
    return '$calories per 100 g/ml';
  }

  Future<void> _loadQuickAddItems() async {
    setState(() {
      _hasSearched = false;
      _isLoadingQuickAdd = true;
      _isSearching = false;
      _errorMessage = null;
    });

    try {
      final results = await AuthScope.of(context).withAuthenticatedSession((
        session,
      ) {
        return _foodService.searchFoods(
          '',
          session: session,
          mealType: widget.initialMealType,
        );
      });
      if (!mounted) return;
      setState(() {
        _results = results;
        _isLoadingQuickAdd = false;
      });
    } on ApiFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _results = const <FoodProduct>[];
        _errorMessage = error.message;
        _isLoadingQuickAdd = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = const <FoodProduct>[];
        _errorMessage = 'Unable to load your quick add items right now.';
        _isLoadingQuickAdd = false;
      });
    }
  }

  Future<void> _loadSavedMeals() async {
    setState(() {
      _isLoadingSavedMeals = true;
      _savedMealsErrorMessage = null;
    });

    try {
      final meals = await AuthScope.of(context).withAuthenticatedSession((
        session,
      ) {
        return _savedMealsService.fetchMeals(session: session);
      });
      if (!mounted) return;
      setState(() {
        _savedMeals = meals;
        _isLoadingSavedMeals = false;
      });
    } on ApiFailure catch (error) {
      if (!mounted) return;
      if (error.statusCode == 404) {
        setState(() {
          _savedMeals = const <SavedMealData>[];
          _savedMealsErrorMessage = null;
          _isLoadingSavedMeals = false;
        });
        return;
      }
      setState(() {
        _savedMeals = const <SavedMealData>[];
        _savedMealsErrorMessage = error.message;
        _isLoadingSavedMeals = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _savedMeals = const <SavedMealData>[];
        _savedMealsErrorMessage =
            'Something went wrong while loading your saved meals.';
        _isLoadingSavedMeals = false;
      });
    }
  }

  Future<void> _handleProductSelection(FoodProduct product) async {
    if (!widget.openProductDetailsOnSelect) {
      Navigator.of(context).pop(FoodSearchSelection.product(product));
      return;
    }

    final selectedMealType = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (context) => FoodProductDetailsPage(
          product: product,
          initialMealType: widget.initialMealType,
          logDate: widget.logDate,
        ),
      ),
    );

    if (!mounted) return;
    if (selectedMealType == null || selectedMealType.trim().isEmpty) {
      return;
    }

    Navigator.of(
      context,
    ).pop(FoodSearchSelection.loggedMealType(selectedMealType));
  }

  Future<void> _handleSavedMealSelection(SavedMealData meal) async {
    if (!widget.openSavedMealLogOnSelect) {
      Navigator.of(context).pop(FoodSearchSelection.savedMeal(meal));
      return;
    }

    final logged = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => LogSavedMealPage(
          meal: meal,
          initialMealType: widget.initialMealType,
          initialLogDate: widget.logDate,
        ),
      ),
    );

    if (!mounted || logged != true) {
      return;
    }

    final selectedMealType = widget.initialMealType?.trim();
    if (selectedMealType == null || selectedMealType.isEmpty) {
      return;
    }

    Navigator.of(
      context,
    ).pop(FoodSearchSelection.loggedMealType(selectedMealType));
  }
}

class _ResultPill extends StatelessWidget {
  const _ResultPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColours.background.withValues(alpha: 0.45),
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
              color: AppColours.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
