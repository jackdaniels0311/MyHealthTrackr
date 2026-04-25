import 'package:flutter/material.dart';
import 'package:myhealthtrackr/pages/barcode_scanner_page.dart';
import 'package:myhealthtrackr/pages/diary_page.dart';
import 'package:myhealthtrackr/pages/home_page.dart';
import 'package:myhealthtrackr/pages/meal_recommendation_setup_page.dart';
import 'package:myhealthtrackr/pages/profile_page.dart';
import 'package:myhealthtrackr/pages/saved_meal_detail_page.dart';
import 'package:myhealthtrackr/pages/saved_meal_editor_page.dart';
import 'package:myhealthtrackr/services/api_client.dart';
import 'package:myhealthtrackr/services/auth_scope.dart';
import 'package:myhealthtrackr/services/food_service.dart';
import 'package:myhealthtrackr/services/saved_meals_service.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';
import 'package:myhealthtrackr/themes/app_icons.dart';
import 'package:myhealthtrackr/themes/app_text_styles.dart';
import 'package:myhealthtrackr/widgets/app_snack.dart';
import 'package:myhealthtrackr/widgets/barcode_scanner_symbol_icon.dart';

class PlansPage extends StatefulWidget {
  const PlansPage({super.key});

  static const routeName = '/plans';

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  static const Color _panelBorder = AppColours.panelBorder;
  static const Color _mutedText = AppColours.textSubtle;

  final SavedMealsService _savedMealsService = const SavedMealsService();
  bool _hasLoadedPlans = false;
  bool _isLoading = true;
  String? _errorMessage;
  List<SavedMealData> _meals = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasLoadedPlans) return;
    _hasLoadedPlans = true;
    _loadPlans();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = 140.0 + MediaQuery.paddingOf(context).bottom;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColours.background,
        body: Stack(
          children: [
            _buildBackdropAccent(
              alignment: const Alignment(-0.85, -1.0),
              size: 210,
              colour: AppColours.primary.withValues(alpha: 0.10),
            ),
            _buildBackdropAccent(
              alignment: const Alignment(1.0, -0.4),
              size: 220,
              colour: AppColours.primary.withValues(alpha: 0.08),
            ),
            SafeArea(
              bottom: false,
              child: RefreshIndicator(
                color: AppColours.primary,
                onRefresh: _loadPlans,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(22, 18, 22, bottomPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(),
                      const SizedBox(height: 24),
                      _buildMealPlanSection(),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Saved meals',
                              style: AppTextStyles.title.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: _openCreateMeal,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColours.primary,
                              foregroundColor: AppColours.onDark,
                            ),
                            icon: const Icon(AppIcons.editOutlined, size: 18),
                            label: const Text('Create Meal'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_isLoading)
                        _buildLoadingState()
                      else if (_errorMessage != null)
                        _buildErrorState()
                      else if (_meals.isEmpty)
                        _buildEmptyState()
                      else
                        ..._buildMealCards(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(context),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plans',
                style: AppTextStyles.headline.copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Get AI meal recommendations or manage saved meals for faster diary logging.',
                style: AppTextStyles.bodyMuted.copyWith(
                  color: _mutedText,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColours.primary.withValues(alpha: 0.28),
            border: Border.all(
              color: AppColours.primary.withValues(alpha: 0.18),
            ),
          ),
          child: const Icon(
            AppIcons.calendarMonthRounded,
            color: AppColours.primary,
            size: 30,
          ),
        ),
      ],
    );
  }

  Widget _buildMealPlanSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: AppColours.secondary.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _panelBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColours.shadowSoft,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColours.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  AppIcons.queryStatsRounded,
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
                      'AI meal recommendations',
                      style: AppTextStyles.title.copyWith(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Want personalised meal recommendations based on your goals, preferences and foods you want to avoid?',
                      style: AppTextStyles.bodyMuted.copyWith(
                        color: AppColours.textMuted,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _openMealRecommendationSetup,
              style: FilledButton.styleFrom(
                backgroundColor: AppColours.primary,
                foregroundColor: AppColours.onDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(AppIcons.restaurantMenuRounded, size: 19),
              label: const Text('Get Started'),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMealCards() {
    return [
      for (var index = 0; index < _meals.length; index++) ...[
        _buildMealCard(_meals[index]),
        if (index != _meals.length - 1) const SizedBox(height: 16),
      ],
    ];
  }

  Widget _buildMealCard(SavedMealData meal) {
    return Material(
      color: AppColours.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _openMealDetails(meal),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            color: AppColours.secondary.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _panelBorder),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColours.primary.withValues(alpha: 0.18),
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
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${meal.items.length} item${meal.items.length == 1 ? '' : 's'}',
                          style: AppTextStyles.bodyMuted.copyWith(
                            color: AppColours.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    AppIcons.chevronRightRounded,
                    color: AppColours.textSubtle,
                    size: 26,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _MetricPill(
                icon: AppIcons.localFireDepartmentRounded,
                label: FoodService.formatCalories(meal.totalCalories),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetricPill(
                    icon: AppIcons.spaRounded,
                    label:
                        '${FoodService.formatMetric(meal.totalProtein)} protein',
                  ),
                  _MetricPill(
                    icon: AppIcons.grainRounded,
                    label: '${FoodService.formatMetric(meal.totalCarbs)} carbs',
                  ),
                  _MetricPill(
                    icon: AppIcons.boltRounded,
                    label: '${FoodService.formatMetric(meal.totalFat)} fat',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: AppColours.secondary.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No saved meals yet',
            style: AppTextStyles.title.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You currently do not have any meals saved. Tap the "Create" button above to start building your meal library.',
            style: AppTextStyles.bodyMuted.copyWith(
              color: AppColours.textMuted,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(color: AppColours.primary),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: AppColours.secondary.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unable to load plans',
            style: AppTextStyles.title.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _errorMessage ?? 'Something went wrong.',
            style: AppTextStyles.bodyMuted.copyWith(color: _mutedText),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loadPlans,
            style: FilledButton.styleFrom(
              backgroundColor: AppColours.primary,
              foregroundColor: AppColours.onDark,
            ),
            child: const Text('Try again'),
          ),
        ],
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

  Widget _buildBottomNav(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      child: Container(
        height: 94,
        decoration: BoxDecoration(
          color: AppColours.secondary.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _panelBorder),
          boxShadow: const [
            BoxShadow(
              color: AppColours.shadowPanel,
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavDestination(
              icon: AppIcons.homeOutlined,
              activeIcon: AppIcons.homeRounded,
              label: 'Home',
              selected: false,
              onTap: () => _openRootRoute(context, HomePage.routeName),
            ),
            _buildNavDestination(
              icon: AppIcons.menuBookOutlined,
              activeIcon: AppIcons.menuBookRounded,
              label: 'Diary',
              selected: false,
              onTap: () => _openRootRoute(context, DiaryPage.routeName),
            ),
            _buildCenterNavAction(context),
            _buildNavDestination(
              icon: AppIcons.calendarMonthOutlined,
              activeIcon: AppIcons.calendarMonthRounded,
              label: 'Plans',
              selected: true,
              onTap: () {},
            ),
            _buildNavDestination(
              icon: AppIcons.personOutlineRounded,
              activeIcon: AppIcons.personRounded,
              label: 'Profile',
              selected: false,
              onTap: () => _openRootRoute(context, ProfilePage.routeName),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterNavAction(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.pushNamed(context, BarcodeScannerPage.routeName),
      child: SizedBox(
        width: 76,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: AppColours.primary,
                boxShadow: [
                  BoxShadow(
                    color: AppColours.primary.withValues(alpha: 0.30),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const BarcodeScannerSymbolIcon(size: 30),
                  Text(
                    'Scan',
                    style: AppTextStyles.label.copyWith(
                      color: AppColours.onDark,
                      fontSize: 11,
                      height: 1,
                      fontWeight: FontWeight.w700,
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

  void _openRootRoute(BuildContext context, String routeName) {
    Navigator.of(context).pushNamedAndRemoveUntil(routeName, (route) => false);
  }

  Widget _buildNavDestination({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 64,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? activeIcon : icon,
              size: 28,
              color: selected ? AppColours.primary : _mutedText,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: selected ? AppColours.primary : _mutedText,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final meals = await AuthScope.of(context).withAuthenticatedSession((
        session,
      ) {
        return _savedMealsService.fetchMeals(session: session);
      });
      if (!mounted) return;
      setState(() {
        _meals = meals;
        _isLoading = false;
      });
    } on ApiFailure catch (error) {
      if (!mounted) return;
      if (error.statusCode == 404) {
        setState(() {
          _meals = const [];
          _errorMessage = null;
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Unable to load your saved meals right now. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _openMealRecommendationSetup() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const MealRecommendationSetupPage(),
      ),
    );
  }

  Future<void> _openCreateMeal() async {
    final createdMeal = await Navigator.of(context).push<SavedMealData>(
      MaterialPageRoute<SavedMealData>(
        builder: (_) => const SavedMealEditorPage(),
      ),
    );
    if (!mounted || createdMeal == null) return;
    await _loadPlans();
    if (!mounted) return;
    AppSnack.success(context, '${createdMeal.name} has been saved.');
  }

  Future<void> _openMealDetails(SavedMealData meal) async {
    final action = await Navigator.of(context).push<SavedMealDetailAction>(
      MaterialPageRoute<SavedMealDetailAction>(
        builder: (_) => SavedMealDetailPage(meal: meal),
      ),
    );

    if (!mounted || action == null) return;
    await _loadPlans();
    if (!mounted) return;

    final message = switch (action) {
      SavedMealDetailAction.updated => 'Meal updated.',
      SavedMealDetailAction.deleted => 'Meal deleted.',
      SavedMealDetailAction.logged => 'Meal added to your diary.',
    };
    AppSnack.success(context, message);
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
