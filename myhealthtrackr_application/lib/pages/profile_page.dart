import 'package:flutter/material.dart';
import 'package:myhealthtrackr/themes/app_icons.dart';
import 'package:myhealthtrackr/pages/barcode_scanner_page.dart';
import 'package:myhealthtrackr/pages/diary_page.dart';
import 'package:myhealthtrackr/pages/goal_details_page.dart';
import 'package:myhealthtrackr/pages/home_page.dart';
import 'package:myhealthtrackr/pages/log_weight_page.dart';
import 'package:myhealthtrackr/pages/nutrition_goals_page.dart';
import 'package:myhealthtrackr/pages/plans_page.dart';
import 'package:myhealthtrackr/pages/profile_details_page.dart';
import 'package:myhealthtrackr/pages/start_page.dart';
import 'package:myhealthtrackr/services/api_client.dart';
import 'package:myhealthtrackr/services/auth_scope.dart';
import 'package:myhealthtrackr/services/auth_service.dart';
import 'package:myhealthtrackr/services/goal_service.dart';
import 'package:myhealthtrackr/services/nutrition_targets_service.dart';
import 'package:myhealthtrackr/services/profile_service.dart';
import 'package:myhealthtrackr/services/weight_history_service.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';
import 'package:myhealthtrackr/themes/app_text_styles.dart';
import 'package:myhealthtrackr/widgets/app_snack.dart';
import 'package:myhealthtrackr/widgets/barcode_scanner_symbol_icon.dart';
import 'package:myhealthtrackr/widgets/weight_progress_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  static const routeName = '/profile';

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color _panelBorder = AppColours.panelBorder;
  static const Color _mutedText = AppColours.textSubtle;

  final ProfileService _profileService = const ProfileService();
  final GoalService _goalService = const GoalService();
  final NutritionTargetsService _nutritionTargetsService =
      const NutritionTargetsService();
  final WeightHistoryService _weightHistoryService =
      const WeightHistoryService();

  UserProfile? _profile;
  UserGoal? _goal;
  NutritionTargets? _nutritionTargets;
  List<WeightEntryData> _weightEntries = const [];
  bool _isLoading = true;
  bool _hasLoadedProfile = false;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_hasLoadedProfile) return;
    _hasLoadedProfile = true;
    _loadProfile();
  }

  Future<void> _loadProfile({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final authController = AuthScope.of(context);

    try {
      final snapshot = await authController.withAuthenticatedSession((
        session,
      ) async {
        final profileFuture = _profileService.fetchProfile(session: session);
        final goalFuture = _goalService.fetchCurrentGoal(session: session);
        final nutritionTargetsFuture = _fetchNutritionTargetsOrNull(
          session: session,
        );
        final weightEntriesFuture = _weightHistoryService.fetchWeightEntries(
          session: session,
        );

        final profile = await profileFuture;
        final goal = await goalFuture;
        final nutritionTargets = await nutritionTargetsFuture;
        final weightEntries = await weightEntriesFuture;

        return _ProfileSnapshot(
          profile: profile,
          goal: goal,
          nutritionTargets: nutritionTargets,
          weightEntries: weightEntries,
        );
      });

      if (!mounted) return;

      setState(() {
        _profile = snapshot.profile;
        _goal = snapshot.goal;
        _nutritionTargets = snapshot.nutritionTargets;
        _weightEntries = snapshot.weightEntries;
        _isLoading = false;
        _errorMessage = null;
      });
    } on AuthFailure catch (error) {
      await _handleUnauthorizedSession(message: error.message);
    } on ApiFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load profile: $error';
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

  Future<void> _openFullProfile(UserProfile profile) async {
    final updatedProfile = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute(builder: (_) => ProfileDetailsPage(profile: profile)),
    );

    if (!mounted) return;

    if (updatedProfile != null) {
      setState(() => _profile = updatedProfile);
      return;
    }

    await _loadProfile(showLoader: false);
  }

  Future<void> _openGoalOverview() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const GoalDetailsPage()),
    );

    if (!mounted) return;
    await _loadProfile(showLoader: false);
  }

  Future<void> _openNutritionGoalsOverview() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const NutritionGoalsPage()),
    );

    if (!mounted) return;
    await _loadProfile(showLoader: false);
  }

  Future<void> _openLogWeightPage() async {
    final initialWeightKg = _weightEntries.isNotEmpty
        ? _weightEntries.last.weightKg
        : _profile?.weightKg;
    final result = await Navigator.push<LogWeightResult>(
      context,
      MaterialPageRoute<LogWeightResult>(
        builder: (_) => LogWeightPage(initialWeightKg: initialWeightKg),
      ),
    );

    if (!mounted || result == null) return;
    await _loadProfile(showLoader: false);
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
    await _loadProfile(showLoader: false);
    if (!mounted) return;
    AppSnack.success(context, _weightResultMessage(result));
  }

  String _weightResultMessage(LogWeightResult result) {
    return switch (result) {
      LogWeightResult.created => 'Weight entry logged.',
      LogWeightResult.updated => 'Weight entry updated.',
      LogWeightResult.deleted => 'Weight entry deleted.',
    };
  }

  Future<void> _logout() async {
    await AuthScope.of(context).logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      StartPage.routeName,
      (_) => false,
      arguments: const StartPageMessage('Successfully sign out'),
    );
  }

  Future<void> _handleUnauthorizedSession({
    String message = 'Your session is no longer valid. Please sign in again.',
  }) async {
    await AuthScope.of(context).logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      StartPage.routeName,
      (_) => false,
      arguments: StartPageMessage(message),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColours.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _profile == null) {
      return Scaffold(
        backgroundColor: AppColours.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: _buildErrorState(),
          ),
        ),
      );
    }

    final profile = _profile!;
    final goal = _goal;
    final nutritionTargets = _nutritionTargets;
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
                onRefresh: () => _loadProfile(showLoader: false),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(22, 18, 22, bottomPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 26),
                      _buildProfileHero(profile),
                      const SizedBox(height: 22),
                      _buildSectionTitle(
                        title: 'Overview',
                        subtitle:
                            'Your current weight, target, and daily calorie goal in one place.',
                      ),
                      const SizedBox(height: 16),
                      _buildPlanOverviewCard(
                        profile,
                        goal: goal,
                        nutritionTargets: nutritionTargets,
                      ),
                      const SizedBox(height: 22),
                      _buildSectionTitle(
                        title: 'Weight Progress',
                        subtitle:
                            'Track how your recorded weigh-ins change over time.',
                      ),
                      const SizedBox(height: 16),
                      WeightProgressCard(
                        entries: _weightEntries,
                        onLogCurrentWeight: _openLogWeightPage,
                        onSelectEntry: _openWeightEntryEditor,
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: _logout,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColours.onDark,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(AppIcons.logoutRounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Sign out',
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildErrorState() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColours.secondary.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _panelBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              AppIcons.cloudOffRounded,
              size: 42,
              color: AppColours.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load profile',
              style: AppTextStyles.title.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted.copyWith(
                color: _mutedText,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => _loadProfile(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColours.primary,
                  foregroundColor: AppColours.onDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  'Try again',
                  style: AppTextStyles.button.copyWith(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: AppTextStyles.headline.copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'View your health profile and goals.',
                style: AppTextStyles.bodyMuted.copyWith(
                  color: _mutedText,
                  fontSize: 15,
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
            color: AppColours.primary.withValues(alpha: 0.26),
            border: Border.all(
              color: AppColours.primary.withValues(alpha: 0.18),
            ),
          ),
          child: const Icon(
            AppIcons.personRounded,
            color: AppColours.primary,
            size: 28,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHero(UserProfile profile) {
    final completion = (profile.completionRatio * 100).round();
    final showCompletionWidget = !profile.isProfileComplete;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColours.secondary.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _panelBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColours.shadowStrong,
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColours.primary,
                      AppColours.primary.withValues(alpha: 0.72),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    profile.initials,
                    style: AppTextStyles.headline.copyWith(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      profile.displayName,
                      style: AppTextStyles.headline.copyWith(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.email,
                      style: AppTextStyles.bodyMuted.copyWith(
                        color: _mutedText,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showCompletionWidget) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColours.background.withValues(alpha: 0.48),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Profile completion',
                        style: AppTextStyles.label.copyWith(
                          color: _mutedText,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$completion%',
                        style: AppTextStyles.label.copyWith(
                          color: AppColours.onDark,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: profile.completionRatio.clamp(0.0, 1.0),
                      minHeight: 12,
                      backgroundColor: AppColours.surfaceTrack,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColours.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _openFullProfile(profile),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColours.primary,
                foregroundColor: AppColours.onDark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                'View full profile',
                style: AppTextStyles.button.copyWith(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.title.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppTextStyles.bodyMuted.copyWith(
            color: _mutedText,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanOverviewCard(
    UserProfile profile, {
    required UserGoal? goal,
    required NutritionTargets? nutritionTargets,
  }) {
    final currentWeight = profile.weightKg ?? goal?.goalStartWeightKg;
    final targetWeight = goal?.goalWeightKg;
    final calorieTarget = nutritionTargets?.recommendedCaloriesKcal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColours.secondary.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final spacing = availableWidth >= 420 ? 16.0 : 10.0;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _OverviewCard(
                      label: 'Current weight',
                      value: currentWeight == null
                          ? 'Not set'
                          : '${_formatNumber(currentWeight)} kg',
                      icon: AppIcons.monitorWeightOutlined,
                      accent: AppColours.accentHydration,
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: _OverviewCard(
                      label: 'Target weight',
                      value: targetWeight == null
                          ? 'Not set'
                          : '${_formatNumber(targetWeight)} kg',
                      icon: AppIcons.flagRounded,
                      accent: AppColours.accentProtein,
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: _OverviewCard(
                      label: 'Daily calories',
                      value: calorieTarget == null
                          ? 'Not set'
                          : '${calorieTarget.round()} kcal',
                      icon: AppIcons.localFireDepartmentRounded,
                      accent: AppColours.primary,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _openGoalOverview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColours.primary,
                    foregroundColor: AppColours.onDark,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    goal == null ? 'Set goal' : 'View current goal',
                    style: AppTextStyles.button.copyWith(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _openNutritionGoalsOverview,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColours.onDark,
                    side: BorderSide(color: AppColours.borderLight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    'View nutritional goals',
                    style: AppTextStyles.button.copyWith(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
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
            Expanded(
              child: _buildNavDestination(
                icon: AppIcons.homeOutlined,
                activeIcon: AppIcons.homeRounded,
                label: 'Home',
                selected: false,
                onTap: () => _openRootRoute(context, HomePage.routeName),
              ),
            ),
            Expanded(
              child: _buildNavDestination(
                icon: AppIcons.menuBookOutlined,
                activeIcon: AppIcons.menuBookRounded,
                label: 'Diary',
                selected: false,
                onTap: () => _openRootRoute(context, DiaryPage.routeName),
              ),
            ),
            _buildCenterNavAction(context),
            Expanded(
              child: _buildNavDestination(
                icon: AppIcons.calendarMonthOutlined,
                activeIcon: AppIcons.calendarMonthRounded,
                label: 'Plans',
                selected: false,
                onTap: () => _openRootRoute(context, PlansPage.routeName),
              ),
            ),
            Expanded(
              child: _buildNavDestination(
                icon: AppIcons.personOutlineRounded,
                activeIcon: AppIcons.personRounded,
                label: 'Profile',
                selected: true,
                onTap: () {},
              ),
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
                    color: AppColours.primary.withValues(alpha: 0.30),
                    blurRadius: 18,
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

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColours.secondary.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColours.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: AppColours.textSubtle,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.title.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ProfileSnapshot {
  const _ProfileSnapshot({
    required this.profile,
    required this.goal,
    required this.nutritionTargets,
    required this.weightEntries,
  });

  final UserProfile profile;
  final UserGoal? goal;
  final NutritionTargets? nutritionTargets;
  final List<WeightEntryData> weightEntries;
}
