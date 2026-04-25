import 'package:flutter/material.dart';
import 'package:myhealthtrackr/themes/app_icons.dart';
import 'package:myhealthtrackr/pages/barcode_scanner_page.dart';
import 'package:myhealthtrackr/pages/diary_page.dart';
import 'package:myhealthtrackr/pages/log_weight_page.dart';
import 'package:myhealthtrackr/pages/plans_page.dart';
import 'package:myhealthtrackr/pages/profile_page.dart';
import 'package:myhealthtrackr/pages/start_page.dart';
import 'package:myhealthtrackr/services/api_client.dart';
import 'package:myhealthtrackr/services/auth_scope.dart';
import 'package:myhealthtrackr/services/auth_service.dart';
import 'package:myhealthtrackr/services/meal_logging_service.dart';
import 'package:myhealthtrackr/services/nutrition_targets_service.dart';
import 'package:myhealthtrackr/services/profile_service.dart';
import 'package:myhealthtrackr/services/weight_history_service.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';
import 'package:myhealthtrackr/themes/app_text_styles.dart';
import 'package:myhealthtrackr/themes/meal_visuals.dart';
import 'package:myhealthtrackr/widgets/barcode_scanner_symbol_icon.dart';
import 'package:myhealthtrackr/widgets/calorie_breakdown_card.dart';
import 'package:myhealthtrackr/widgets/app_snack.dart';
import 'package:myhealthtrackr/widgets/weight_progress_card.dart';

/// Home screen shown after successful login
class HomePage extends StatefulWidget {
  const HomePage({super.key, this.successMessage});

  static const routeName = '/home';

  final String? successMessage;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color _panelBorder = AppColours.panelBorder;
  static const Color _mutedText = AppColours.textSubtle;
  static const Color _trackColour = AppColours.surfaceTrack;
  static const Color _proteinColour = AppColours.accentProtein;
  static const Color _fatColour = AppColours.accentFat;
  static const Color _carbColour = AppColours.accentCarbs;
  static const Color _waterColour = AppColours.accentHydration;
  // static const Color _sleepColour = AppColours.accentGreen;

  final MealLoggingService _mealLoggingService = const MealLoggingService();
  final NutritionTargetsService _nutritionTargetsService =
      const NutritionTargetsService();
  final ProfileService _profileService = const ProfileService();
  final WeightHistoryService _weightHistoryService =
      const WeightHistoryService();

  int _navIndex = 0;
  bool _hasLoadedDashboard = false;
  bool _isLoadingDashboard = true;
  String? _dashboardErrorMessage;
  DiaryDayData? _todayDiary;
  NutritionTargets? _nutritionTargets;
  List<WeightEntryData> _weightEntries = const [];

  List<CalorieBreakdownSegment> get _mealBreakdownSegments {
    final diary = _todayDiary ?? DiaryDayData.empty(DateTime.now());
    final sectionsByMeal = {
      for (final section in diary.sections) section.mealType: section,
    };

    return MealLoggingService.calorieMealTypes
        .map((mealType) {
          final section =
              sectionsByMeal[mealType] ??
              DiaryMealSection(mealType: mealType, items: const []);
          return CalorieBreakdownSegment(
            label: mealType,
            calories: section.totalCalories,
            colour: MealVisuals.forType(mealType).accent,
          );
        })
        .toList(growable: false);
  }

  List<_ProgressStat> get _stats {
    final diary = _todayDiary ?? DiaryDayData.empty(DateTime.now());
    return <_ProgressStat>[
      _ProgressStat(
        label: 'Protein',
        value: diary.totalProtein,
        goal: _nutritionTargets?.recommendedProteinG,
        unit: 'g',
        icon: AppIcons.spaRounded,
        accent: _proteinColour,
      ),
      _ProgressStat(
        label: 'Fat',
        value: diary.totalFat,
        goal: _nutritionTargets?.recommendedFatG,
        unit: 'g',
        icon: AppIcons.boltRounded,
        accent: _fatColour,
      ),
      _ProgressStat(
        label: 'Carbs',
        value: diary.totalCarbs,
        goal: _nutritionTargets?.recommendedCarbsG,
        unit: 'g',
        icon: AppIcons.grainRounded,
        accent: _carbColour,
      ),
      // _ProgressStat(
      //   label: 'Sleep',
      //   value: 7.5,
      //   goal: 8,
      //   unit: 'hrs',
      //   icon: AppIcons.nightlightRound,
      //   accent: _sleepColour,
      // ),
      _ProgressStat(
        label: 'Water',
        value: diary.totalWaterMl,
        goal: _nutritionTargets?.recommendedWaterMl,
        unit: 'ml',
        icon: AppIcons.waterDropRounded,
        accent: _waterColour,
      ),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasLoadedDashboard) return;
    _hasLoadedDashboard = true;
    _showInitialSuccessMessage();
    _loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = 140.0 + MediaQuery.paddingOf(context).bottom;
    const horizontalPadding = 22.0;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColours.background,
        body: Container(
          color: AppColours.background,
          child: Stack(
            children: [
              _buildBackdropAccent(
                alignment: const Alignment(-0.8, -1.05),
                size: 180,
                colour: AppColours.primary.withValues(alpha: 0.10),
              ),
              _buildBackdropAccent(
                alignment: const Alignment(1.0, -0.75),
                size: 220,
                colour: AppColours.primary.withValues(alpha: 0.08),
              ),
              SafeArea(
                bottom: false,
                child: RefreshIndicator(
                  onRefresh: _loadDashboard,
                  color: AppColours.primary,
                  backgroundColor: AppColours.secondary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      18,
                      horizontalPadding,
                      bottomPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(),
                        const SizedBox(height: 28),
                        if (_isLoadingDashboard && _todayDiary == null)
                          _buildLoadingState()
                        else if (_dashboardErrorMessage != null &&
                            _todayDiary == null)
                          _buildErrorState()
                        else ...[
                          _buildHeroCard(),
                          const SizedBox(height: 28),
                          Text(
                            "Today's Nutrition Overview",
                            style: AppTextStyles.title.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildProgressGrid(
                            MediaQuery.sizeOf(context).width -
                                (horizontalPadding * 2),
                          ),
                          const SizedBox(height: 28),
                          WeightProgressCard(
                            entries: _weightEntries,
                            onLogCurrentWeight: _openLogWeightPage,
                            onSelectEntry: _openWeightEntryEditor,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNav(),
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

  Widget _buildTopBar() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: AppTextStyles.headline.copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    AppIcons.calendarMonthRounded,
                    size: 18,
                    color: _mutedText,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formattedToday(),
                    style: AppTextStyles.bodyMuted.copyWith(
                      color: _mutedText,
                      fontSize: 16,
                    ),
                  ),
                ],
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
            AppIcons.homeRounded,
            color: AppColours.primary,
            size: 30,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    final diary = _todayDiary ?? DiaryDayData.empty(DateTime.now());
    final mealSegments = _mealBreakdownSegments;
    final calorieGoal = _nutritionTargets?.recommendedCaloriesKcal;
    final double? remainingCalories = calorieGoal == null
        ? null
        : (calorieGoal - diary.totalCalories).clamp(0.0, double.infinity);

    return CalorieBreakdownCard(
      title: "Today's calorie breakdown",
      caloriesConsumed: diary.totalCalories,
      calorieGoal: _nutritionTargets?.recommendedCaloriesKcal,
      segments: mealSegments,
      stats: [
        CalorieBreakdownStat(
          label: 'Meals logged',
          value: '${diary.mealsLogged} / ${mealSegments.length}',
        ),
        CalorieBreakdownStat(
          label: 'Items logged',
          value: '${diary.totalItems}',
        ),
        CalorieBreakdownStat(
          label: 'Remaining',
          value: remainingCalories == null
              ? 'Set goal'
              : '${_formatMetric(remainingCalories)} kcal',
        ),
      ],
      helperText: _nutritionTargets == null
          ? 'Complete your health profile to unlock a personalised calorie target for this meal breakdown.'
          : null,
    );
  }

  Widget _buildProgressGrid(double availableWidth) {
    const crossAxisCount = 2;
    final totalSpacing = (crossAxisCount - 1) * 16;
    final cardWidth = (availableWidth - totalSpacing) / crossAxisCount;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        for (final stat in _stats)
          SizedBox(width: cardWidth, child: _buildProgressCard(stat)),
      ],
    );
  }

  Widget _buildProgressCard(_ProgressStat stat) {
    final goal = stat.goal;
    final hasGoal = goal != null && goal > 0;
    final completionRatio = hasGoal ? (stat.value / goal) : null;
    final progress = completionRatio?.clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  stat.label,
                  style: AppTextStyles.title.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: stat.accent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(stat.icon, color: AppColours.onDark, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            hasGoal
                ? '${_formatMetric(stat.value)} of ${_formatMetric(goal)} ${stat.unit}'
                : '${_formatMetric(stat.value)} ${stat.unit} logged',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMuted.copyWith(
              color: _mutedText,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              hasGoal ? '${(completionRatio! * 100).round()}%' : '--',
              style: AppTextStyles.headline.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildLinearProgress(progress: progress ?? 0, colour: stat.accent),
        ],
      ),
    );
  }

  Widget _buildLinearProgress({
    required double progress,
    required Color colour,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        minHeight: 14,
        backgroundColor: _trackColour,
        valueColor: AlwaysStoppedAnimation<Color>(colour),
      ),
    );
  }

  Widget _buildBottomNav() {
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
            Expanded(
              child: _buildNavDestination(
                icon: AppIcons.homeOutlined,
                activeIcon: AppIcons.homeRounded,
                label: 'Home',
                index: 0,
                onTap: () => setState(() => _navIndex = 0),
              ),
            ),
            Expanded(
              child: _buildNavDestination(
                icon: AppIcons.menuBookOutlined,
                activeIcon: AppIcons.menuBookRounded,
                label: 'Diary',
                index: 1,
                onTap: () => _openRootRoute(DiaryPage.routeName),
              ),
            ),
            _buildCenterNavAction(context),
            Expanded(
              child: _buildNavDestination(
                icon: AppIcons.calendarMonthOutlined,
                activeIcon: AppIcons.calendarMonthRounded,
                label: 'Plans',
                index: 3,
                onTap: () => _openRootRoute(PlansPage.routeName),
              ),
            ),
            Expanded(
              child: _buildNavDestination(
                icon: AppIcons.personOutlineRounded,
                activeIcon: AppIcons.personRounded,
                label: 'Profile',
                index: 4,
                onTap: () {
                  setState(() => _navIndex = 4);
                  _openRootRoute(ProfilePage.routeName);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterNavAction(BuildContext context) {
    final selected = _navIndex == 2;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() => _navIndex = 2);
        Navigator.pushNamed(context, BarcodeScannerPage.routeName).then((_) {
          if (!mounted) return;
          _loadDashboard();
          setState(() => _navIndex = 0);
        });
      },
      child: SizedBox(
        width: 68,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: AppColours.primary,
                boxShadow: [
                  BoxShadow(
                    color: AppColours.primary.withValues(
                      alpha: selected ? 0.42 : 0.26,
                    ),
                    blurRadius: selected ? 28 : 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const BarcodeScannerSymbolIcon(size: 28),
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

  void _openRootRoute(String routeName) {
    Navigator.of(context).pushNamedAndRemoveUntil(routeName, (route) => false);
  }

  Widget _buildNavDestination({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required VoidCallback onTap,
  }) {
    final selected = _navIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
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
            'Unable to load dashboard',
            style: AppTextStyles.title.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _dashboardErrorMessage ?? 'Something went wrong.',
            style: AppTextStyles.bodyMuted.copyWith(color: _mutedText),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loadDashboard,
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

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoadingDashboard = true;
      _dashboardErrorMessage = null;
    });

    final authController = AuthScope.of(context);

    try {
      final snapshot = await authController.withAuthenticatedSession((
        session,
      ) async {
        final diary = await _mealLoggingService.fetchDiaryDay(
          session: session,
          date: DateTime.now(),
        );
        final nutritionTargets = await _fetchNutritionTargetsOrNull(
          session: session,
        );
        final profile = await _profileService.fetchProfile(session: session);
        final fetchedWeightEntries = await _weightHistoryService
            .fetchWeightEntries(session: session);

        final weightEntries = fetchedWeightEntries.isNotEmpty
            ? fetchedWeightEntries
            : _fallbackWeightEntries(profile);

        return _DashboardSnapshot(
          diary: diary,
          nutritionTargets: nutritionTargets,
          weightEntries: weightEntries,
        );
      });

      if (!mounted) return;

      setState(() {
        _todayDiary = snapshot.diary;
        _nutritionTargets = snapshot.nutritionTargets;
        _weightEntries = snapshot.weightEntries;
        _isLoadingDashboard = false;
      });
    } on AuthFailure catch (error) {
      await _handleUnauthorizedSession(message: error.message);
    } on ApiFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _dashboardErrorMessage = error.message;
        _isLoadingDashboard = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _dashboardErrorMessage =
            'Unable to load your dashboard right now. Please try again.';
        _isLoadingDashboard = false;
      });
    }
  }

  Future<NutritionTargets?> _fetchNutritionTargetsOrNull({
    required AuthSession session,
  }) async {
    try {
      return await _nutritionTargetsService.fetchNutritionTargets(
        session: session,
      );
    } on ApiFailure catch (error) {
      if (error.statusCode == 400 || error.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  List<WeightEntryData> _fallbackWeightEntries(UserProfile profile) {
    final weightKg = profile.weightKg;
    if (weightKg == null || weightKg <= 0) {
      return const [];
    }

    return <WeightEntryData>[
      WeightEntryData(
        id: 0,
        userId: profile.userId,
        weightKg: weightKg,
        recordedAt: DateTime.now(),
      ),
    ];
  }

  Future<void> _openLogWeightPage() async {
    final initialWeightKg = _weightEntries.isNotEmpty
        ? _weightEntries.last.weightKg
        : null;
    final result = await Navigator.push<LogWeightResult>(
      context,
      MaterialPageRoute<LogWeightResult>(
        builder: (_) => LogWeightPage(initialWeightKg: initialWeightKg),
      ),
    );

    if (!mounted || result == null) return;
    await _loadDashboard();
    if (!mounted) return;
    AppSnack.success(context, _weightResultMessage(result));
  }

  Future<void> _openWeightEntryEditor(WeightEntryData entry) async {
    final result = await Navigator.push<LogWeightResult>(
      context,
      MaterialPageRoute<LogWeightResult>(
        builder: (_) => LogWeightPage(entry: entry),
      ),
    );

    if (!mounted || result == null) return;
    await _loadDashboard();
    if (!mounted) return;
    AppSnack.success(context, _weightResultMessage(result));
  }

  void _showInitialSuccessMessage() {
    final message = widget.successMessage?.trim();
    if (message == null || message.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppSnack.success(context, message);
    });
  }

  String _weightResultMessage(LogWeightResult result) {
    return switch (result) {
      LogWeightResult.created => 'Weight entry logged.',
      LogWeightResult.updated => 'Weight entry updated.',
      LogWeightResult.deleted => 'Weight entry deleted.',
    };
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

  String _formattedToday() {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final now = DateTime.now();
    final weekday = weekdays[now.weekday - 1];
    final month = months[now.month - 1];

    return '$weekday, $month ${now.day}';
  }

  static String _formatMetric(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }
}

class _ProgressStat {
  const _ProgressStat({
    required this.label,
    required this.value,
    required this.goal,
    required this.unit,
    required this.icon,
    required this.accent,
  });

  final String label;
  final double value;
  final double? goal;
  final String unit;
  final IconData icon;
  final Color accent;
}

class _DashboardSnapshot {
  const _DashboardSnapshot({
    required this.diary,
    required this.nutritionTargets,
    required this.weightEntries,
  });

  final DiaryDayData diary;
  final NutritionTargets? nutritionTargets;
  final List<WeightEntryData> weightEntries;
}
