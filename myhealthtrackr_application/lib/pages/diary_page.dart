import 'package:flutter/material.dart';
import 'package:myhealthtrackr/themes/app_icons.dart';
import 'package:myhealthtrackr/pages/barcode_scanner_page.dart';
import 'package:myhealthtrackr/pages/edit_meal_item_page.dart';
import 'package:myhealthtrackr/pages/food_search_page.dart';
import 'package:myhealthtrackr/pages/home_page.dart';
import 'package:myhealthtrackr/pages/plans_page.dart';
import 'package:myhealthtrackr/pages/profile_page.dart';
import 'package:myhealthtrackr/services/api_client.dart';
import 'package:myhealthtrackr/services/auth_scope.dart';
import 'package:myhealthtrackr/services/meal_logging_service.dart';
import 'package:myhealthtrackr/services/auth_service.dart';
import 'package:myhealthtrackr/services/nutrition_targets_service.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';
import 'package:myhealthtrackr/themes/app_text_styles.dart';
import 'package:myhealthtrackr/themes/meal_visuals.dart';
import 'package:myhealthtrackr/widgets/app_snack.dart';
import 'package:myhealthtrackr/widgets/barcode_scanner_symbol_icon.dart';
import 'package:myhealthtrackr/widgets/calorie_breakdown_card.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});

  static const routeName = '/diary';

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  static const Color _panelBorder = AppColours.panelBorder;
  static const Color _mutedText = AppColours.textSubtle;
  static const double _quickAddWaterMl = 500;

  final MealLoggingService _mealLoggingService = const MealLoggingService();
  final NutritionTargetsService _nutritionTargetsService =
      const NutritionTargetsService();
  final ScrollController _scrollController = ScrollController();
  final Set<String> _expandedMealGroupIds = <String>{};

  DateTime _selectedDate = DateTime.now();
  DiaryDayData? _dayData;
  NutritionTargets? _nutritionTargets;
  bool _hasLoadedDiary = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasLoadedDiary) return;
    _hasLoadedDiary = true;
    _loadDiary();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = 140.0 + MediaQuery.paddingOf(context).bottom;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColours.background,
        body: Container(
          color: AppColours.background,
          child: Stack(
            children: [
              _buildBackdropAccent(
                alignment: const Alignment(-0.9, -1.05),
                size: 180,
                colour: AppColours.primary.withValues(alpha: 0.10),
              ),
              _buildBackdropAccent(
                alignment: const Alignment(1.0, -0.7),
                size: 210,
                colour: AppColours.primary.withValues(alpha: 0.07),
              ),
              SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(22, 18, 22, bottomPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(context),
                      const SizedBox(height: 24),
                      _buildDateSelector(),
                      const SizedBox(height: 28),
                      _buildSummaryCard(),
                      const SizedBox(height: 22),
                      Text(
                        'Meals',
                        style: AppTextStyles.title.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isLoading)
                        _buildLoadingState()
                      else if (_errorMessage != null)
                        _buildErrorState()
                      else
                        ..._buildMealSections(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNav(context),
      ),
    );
  }

  Future<void> _loadDiary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final snapshot = await AuthScope.of(context).withAuthenticatedSession((
        session,
      ) async {
        final diaryFuture = _mealLoggingService.fetchDiaryDay(
          session: session,
          date: _selectedDate,
        );
        final targetsFuture = _fetchNutritionTargetsOrNull(session: session);

        final diary = await diaryFuture;
        final nutritionTargets = await targetsFuture;

        return _DiarySnapshot(diary: diary, nutritionTargets: nutritionTargets);
      });

      if (!mounted) return;
      setState(() {
        _dayData = snapshot.diary;
        _nutritionTargets = snapshot.nutritionTargets;
        _isLoading = false;
      });
    } on ApiFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Unable to load the diary for this date right now. Please try again.';
        _isLoading = false;
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Diary',
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
                    _fullDateLabel(
                      DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day,
                      ),
                    ),
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
            AppIcons.menuBookRounded,
            color: AppColours.primary,
            size: 30,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final dayData = _dayData ?? DiaryDayData.empty(_selectedDate);
    final calorieGoal = _nutritionTargets?.recommendedCaloriesKcal;
    final double? remainingCalories = calorieGoal == null
        ? null
        : (calorieGoal - dayData.totalCalories).clamp(0.0, double.infinity);
    final sectionsByMeal = {
      for (final section in dayData.sections) section.mealType: section,
    };
    final mealSegments = MealLoggingService.calorieMealTypes
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

    return CalorieBreakdownCard(
      title: _buildCalorieBreakdownTitle(),
      caloriesConsumed: dayData.totalCalories,
      calorieGoal: calorieGoal,
      segments: mealSegments,
      stats: [
        CalorieBreakdownStat(
          label: 'Meals logged',
          value: '${dayData.mealsLogged} / ${mealSegments.length}',
        ),
        CalorieBreakdownStat(
          label: 'Items logged',
          value: '${dayData.totalItems}',
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

  Widget _buildDateSelector() {
    final weekStart = _startOfWeek(_selectedDate);
    final weekDates = List<DateTime>.generate(
      7,
      (index) =>
          DateTime(weekStart.year, weekStart.month, weekStart.day + index),
      growable: false,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColours.secondary.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildDateButton(
                icon: AppIcons.chevronLeftRounded,
                onTap: () => _changeWeekBy(-1),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _formatWeekRangeLabel(weekDates.first, weekDates.last),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.title.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatSelectedDateLabel(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMuted.copyWith(
                        color: _mutedText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildDateButton(
                icon: AppIcons.chevronRightRounded,
                onTap: () => _changeWeekBy(1),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              for (var index = 0; index < weekDates.length; index++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index == weekDates.length - 1 ? 0 : 8,
                    ),
                    child: _buildWeekDayTile(weekDates[index]),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDayTile(DateTime date) {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final isSelected = _isSameCalendarDay(normalizedDate, _selectedDate);
    final isToday = _isSameCalendarDay(normalizedDate, normalizedToday);

    final backgroundColor = isSelected
        ? AppColours.primary
        : isToday
        ? AppColours.primary.withValues(alpha: 0.14)
        : AppColours.background.withValues(alpha: 0.45);
    final textColor = isSelected ? AppColours.onDark : AppColours.onDark;

    return GestureDetector(
      onTap: () => _selectDate(date),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected || isToday
                ? AppColours.primary
                : AppColours.dividerLightMuted,
          ),
        ),
        child: Column(
          children: [
            Text(
              _shortWeekdayLabel(date),
              style: AppTextStyles.label.copyWith(
                color: isSelected
                    ? AppColours.onDark.withValues(alpha: 0.78)
                    : _mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${date.day}',
              style: AppTextStyles.title.copyWith(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColours.background.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: onTap == null ? AppColours.textSubtle : AppColours.onDark,
        ),
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
            'Unable to load diary',
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
            onPressed: _loadDiary,
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

  List<Widget> _buildMealSections(BuildContext context) {
    final sections =
        _dayData?.sections ?? DiaryDayData.empty(_selectedDate).sections;
    return [
      for (final section in sections) ...[
        _buildMealCard(context, section),
        const SizedBox(height: 16),
      ],
    ];
  }

  Widget _buildMealCard(BuildContext context, DiaryMealSection section) {
    final meta = MealVisuals.forType(section.mealType);
    final isWaterSection = section.mealType == MealLoggingService.waterMealType;
    final displayEntries = _buildMealDisplayEntries(section);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: meta.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(meta.icon, color: meta.accent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.mealType,
                      style: AppTextStyles.title.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      section.loggedSummary,
                      style: AppTextStyles.bodyMuted.copyWith(
                        color: _mutedText,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColours.background.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${section.items.length} item${section.items.length == 1 ? '' : 's'}',
                  style: AppTextStyles.label.copyWith(
                    color: _mutedText,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (section.items.isEmpty) ...[
            Text(
              isWaterSection
                  ? 'No water logged for this date yet.'
                  : 'Nothing logged for ${section.mealType.toLowerCase()} on this date yet.',
              style: AppTextStyles.bodyMuted.copyWith(
                color: _mutedText,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            for (final (index, entry) in displayEntries.indexed) ...[
              _buildMealDisplayEntry(entry),
              if (index != displayEntries.length - 1)
                const SizedBox(height: 10),
            ],
            const SizedBox(height: 16),
          ],
          Text(
            isWaterSection
                ? 'Log water intake'
                : 'Add ${section.mealType} item',
            style: AppTextStyles.label.copyWith(
              color: _mutedText,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (isWaterSection)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: OutlinedButton(
                      onPressed: () =>
                          _addWaterEntry(amountMl: _quickAddWaterMl),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColours.onDark,
                        side: BorderSide(
                          color: meta.accent.withValues(alpha: 0.55),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        'Add 500ml',
                        style: AppTextStyles.button.copyWith(fontSize: 15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _promptCustomWaterEntry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: meta.accent,
                        foregroundColor: AppColours.onDark,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        'Custom Amount',
                        style: AppTextStyles.button.copyWith(fontSize: 15),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: () => _openSearchForMeal(section.mealType),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColours.onDark,
                        side: BorderSide(
                          color: meta.accent.withValues(alpha: 0.55),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: const Icon(AppIcons.searchRounded, size: 20),
                      label: Text(
                        'Search',
                        style: AppTextStyles.button.copyWith(fontSize: 15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () => _openScannerForMeal(section.mealType),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: meta.accent,
                        foregroundColor: AppColours.onDark,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: const BarcodeScannerSymbolIcon(size: 20),
                      label: Text(
                        'Scan',
                        style: AppTextStyles.button.copyWith(fontSize: 15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  List<_DiaryMealDisplayEntry> _buildMealDisplayEntries(
    DiaryMealSection section,
  ) {
    final entries = <_DiaryMealDisplayEntry>[];
    final groupedItems = <String, List<DiaryMealItem>>{};

    for (final item in section.items) {
      final mealGroupId = item.mealGroupId;
      if (!item.isGroupedSavedMealItem || mealGroupId == null) {
        entries.add(_DiaryMealDisplayEntry.single(item));
        continue;
      }

      final existingGroup = groupedItems[mealGroupId];
      if (existingGroup == null) {
        final items = <DiaryMealItem>[item];
        groupedItems[mealGroupId] = items;
        entries.add(
          _DiaryMealDisplayEntry.group(
            _DiaryMealGroup(
              groupId: mealGroupId,
              groupName: item.mealGroupName!,
              items: items,
            ),
          ),
        );
        continue;
      }

      existingGroup.add(item);
    }

    return entries;
  }

  Widget _buildMealDisplayEntry(_DiaryMealDisplayEntry entry) {
    final item = entry.item;
    if (item != null) {
      return _buildMealItemRow(item);
    }

    final group = entry.group;
    if (group != null) {
      return _buildSavedMealGroupRow(group);
    }

    return const SizedBox.shrink();
  }

  Widget _buildMealItemRow(DiaryMealItem item) {
    final calories = item.calories;
    final caloriesLabel = calories == null
        ? '-- kcal'
        : calories == calories.roundToDouble()
        ? '${calories.toStringAsFixed(0)} kcal'
        : '${calories.toStringAsFixed(1)} kcal';
    final servingSize = item.servingSize;
    final servingSizeLabel = servingSize == null || servingSize <= 0
        ? null
        : '${servingSize}g';
    final quantity = item.quantity;
    final quantityLabel = quantity == null
        ? null
        : quantity == quantity.roundToDouble()
        ? quantity.toStringAsFixed(0)
        : quantity.toStringAsFixed(1);
    final amountLabel = item.waterAmountLabel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                caloriesLabel,
                textAlign: TextAlign.right,
                style: AppTextStyles.label.copyWith(
                  color: AppColours.onDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (amountLabel != null)
                Text(
                  'Amount: $amountLabel',
                  style: AppTextStyles.bodyMuted.copyWith(
                    color: _mutedText,
                    fontSize: 14,
                  ),
                ),
              if (amountLabel == null &&
                  servingSizeLabel != null &&
                  servingSizeLabel.isNotEmpty)
                Text(
                  'Serving size: $servingSizeLabel',
                  style: AppTextStyles.bodyMuted.copyWith(
                    color: _mutedText,
                    fontSize: 14,
                  ),
                ),
              if (amountLabel == null && quantityLabel != null)
                Text(
                  'Quantity: $quantityLabel',
                  style: AppTextStyles.bodyMuted.copyWith(
                    color: _mutedText,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Spacer(),
              TextButton.icon(
                onPressed: () => _openEditMealItem(item),
                style: TextButton.styleFrom(
                  foregroundColor: AppColours.primary,
                  backgroundColor: AppColours.primary.withValues(alpha: 0.10),
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavedMealGroupRow(_DiaryMealGroup group) {
    final isExpanded = _expandedMealGroupIds.contains(group.groupId);
    final calories = group.totalCalories;
    final caloriesLabel = calories == calories.roundToDouble()
        ? '${calories.toStringAsFixed(0)} kcal'
        : '${calories.toStringAsFixed(1)} kcal';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColours.background.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedMealGroupIds.remove(group.groupId);
                } else {
                  _expandedMealGroupIds.add(group.groupId);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColours.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      AppIcons.restaurantMenuRounded,
                      color: AppColours.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      group.groupName,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        caloriesLabel,
                        textAlign: TextAlign.right,
                        style: AppTextStyles.label.copyWith(
                          color: AppColours.onDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded
                            ? AppIcons.expandLessRounded
                            : AppIcons.expandMoreRounded,
                        color: _mutedText,
                        size: 22,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColours.dividerLightMuted.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 12),
                  for (final (index, item) in group.items.indexed) ...[
                    _buildMealItemRow(item),
                    if (index != group.items.length - 1)
                      const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ],
        ],
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
              selected: true,
              onTap: () {},
            ),
            _buildCenterNavAction(context),
            _buildNavDestination(
              icon: AppIcons.calendarMonthOutlined,
              activeIcon: AppIcons.calendarMonthRounded,
              label: 'Plans',
              selected: false,
              onTap: () => _openRootRoute(context, PlansPage.routeName),
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
      onTap: () => _openScannerForMeal(null),
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

  Future<void> _openScannerForMeal(String? mealType) async {
    final selectedMealType = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (context) => BarcodeScannerPage(
          initialMealType: mealType,
          logDate: _selectedDate,
        ),
      ),
    );

    if (!mounted) return;
    if (selectedMealType != null && selectedMealType.trim().isNotEmpty) {
      AppSnack.success(context, 'Item added to $selectedMealType.');
    }
    await _loadDiary();
  }

  Future<void> _openSearchForMeal(String mealType) async {
    final navigator = Navigator.of(context);
    final selection = await navigator.push<FoodSearchSelection>(
      MaterialPageRoute<FoodSearchSelection>(
        builder: (context) => FoodSearchPage(
          initialMealType: mealType,
          showSavedMealsTab: true,
          openProductDetailsOnSelect: true,
          openSavedMealLogOnSelect: true,
          logDate: _selectedDate,
        ),
      ),
    );

    if (!mounted) return;

    if (selection?.openBarcodeScanner == true) {
      await _openScannerForMeal(mealType);
      return;
    }

    final loggedMealType = selection?.loggedMealType;
    if (loggedMealType != null && loggedMealType.trim().isNotEmpty) {
      AppSnack.success(context, 'Item added to $loggedMealType.');
      await _loadDiary();
      return;
    }
  }

  Future<void> _addWaterEntry({required double amountMl}) async {
    final previousOffset = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;

    try {
      await AuthScope.of(context).withAuthenticatedSession((session) {
        return _mealLoggingService.addWaterEntry(
          session: session,
          amountMl: amountMl,
          logDate: _selectedDate,
        );
      });

      if (!mounted) return;
      final label = amountMl == amountMl.roundToDouble()
          ? amountMl.toStringAsFixed(0)
          : amountMl.toStringAsFixed(1);
      AppSnack.success(context, 'Logged $label ml of water.');
      await _loadDiary();
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        final targetOffset = previousOffset.clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );
        _scrollController.jumpTo(targetOffset.toDouble());
      });
    } on ApiFailure catch (error) {
      if (!mounted) return;
      AppSnack.error(context, error.message);
    } catch (_) {
      if (!mounted) return;
      AppSnack.error(
        context,
        'Unable to log water right now. Please try again.',
      );
    }
  }

  Future<void> _promptCustomWaterEntry() async {
    var draftValue = '500';
    final amountMl = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColours.secondary,
          title: Text(
            'Log Water',
            style: AppTextStyles.title.copyWith(
              color: AppColours.onDark,
              fontSize: 22,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: draftValue,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (value) => draftValue = value,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: AppColours.onDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText: 'Millilitres',
                  labelStyle: AppTextStyles.bodyMuted.copyWith(
                    color: _mutedText,
                  ),
                  hintText: 'Enter amount, e.g. 250 or 500',
                  hintStyle: AppTextStyles.bodyMuted.copyWith(
                    color: _mutedText,
                  ),
                  suffixText: 'ml',
                  suffixStyle: AppTextStyles.body.copyWith(
                    color: AppColours.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                  filled: true,
                  fillColor: AppColours.background.withValues(alpha: 0.65),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColours.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColours.primary),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: AppTextStyles.button.copyWith(
                  color: AppColours.textMuted,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final value = double.tryParse(draftValue.trim());
                if (value == null || value <= 0) return;
                Navigator.of(dialogContext).pop(value);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColours.primary,
                foregroundColor: AppColours.onDark,
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (amountMl == null) return;
    await _addWaterEntry(amountMl: amountMl);
  }

  Future<void> _openEditMealItem(DiaryMealItem item) async {
    final result = await Navigator.of(context).push<EditMealItemResult>(
      MaterialPageRoute<EditMealItemResult>(
        builder: (context) =>
            EditMealItemPage(item: item, logDate: _selectedDate),
      ),
    );

    if (result == null || !mounted) return;
    await _loadDiary();
    if (!mounted) return;

    switch (result) {
      case EditMealItemResult.updated:
        AppSnack.success(context, 'Item updated.');
      case EditMealItemResult.deleted:
        AppSnack.success(context, 'Item removed from diary.');
    }
  }

  Future<void> _changeWeekBy(int weeks) async {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day + (weeks * 7),
      );
    });
    await _loadDiary();
  }

  Future<void> _selectDate(DateTime date) async {
    if (_isSameCalendarDay(date, _selectedDate)) return;

    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);
    });
    await _loadDiary();
  }

  String _buildCalorieBreakdownTitle() {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedSelected = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    if (_isSameCalendarDay(normalizedSelected, normalizedToday)) {
      return "Today's calorie breakdown";
    }

    return "${_weekdayLabel(normalizedSelected)} ${_ordinalDay(normalizedSelected.day)}'s calorie breakdown";
  }

  String _formatSelectedDateLabel() {
    final selected = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final yesterday = normalizedToday.subtract(const Duration(days: 1));

    if (_isSameCalendarDay(selected, normalizedToday)) {
      return 'Today';
    }
    if (_isSameCalendarDay(selected, yesterday)) {
      return 'Yesterday';
    }

    return _fullDateLabel(selected);
  }

  String _formatWeekRangeLabel(DateTime start, DateTime end) {
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

    if (start.year == end.year && start.month == end.month) {
      return '${months[start.month - 1]} ${start.day}-${end.day}';
    }

    if (start.year == end.year) {
      return '${months[start.month - 1]} ${start.day} - ${months[end.month - 1]} ${end.day}';
    }

    return '${months[start.month - 1]} ${start.day}, ${start.year} - ${months[end.month - 1]} ${end.day}, ${end.year}';
  }

  String _shortWeekdayLabel(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1];
  }

  DateTime _startOfWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  String _fullDateLabel(DateTime date) {
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

    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    return '$weekday, $month ${date.day}';
  }

  String _weekdayLabel(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[date.weekday - 1];
  }

  String _ordinalDay(int day) {
    final remainderHundred = day % 100;
    if (remainderHundred >= 11 && remainderHundred <= 13) {
      return '${day}th';
    }

    return switch (day % 10) {
      1 => '${day}st',
      2 => '${day}nd',
      3 => '${day}rd',
      _ => '${day}th',
    };
  }

  bool _isSameCalendarDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  static String _formatMetric(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }
}

class _DiarySnapshot {
  const _DiarySnapshot({required this.diary, required this.nutritionTargets});

  final DiaryDayData diary;
  final NutritionTargets? nutritionTargets;
}

class _DiaryMealDisplayEntry {
  const _DiaryMealDisplayEntry.single(this.item) : group = null;
  const _DiaryMealDisplayEntry.group(this.group) : item = null;

  final DiaryMealItem? item;
  final _DiaryMealGroup? group;
}

class _DiaryMealGroup {
  const _DiaryMealGroup({
    required this.groupId,
    required this.groupName,
    required this.items,
  });

  final String groupId;
  final String groupName;
  final List<DiaryMealItem> items;

  double get totalCalories =>
      items.fold<double>(0, (sum, item) => sum + (item.calories ?? 0));
}
