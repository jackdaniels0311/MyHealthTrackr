import 'package:flutter/material.dart';
import 'package:myhealthtrackr/themes/app_icons.dart';
import 'package:myhealthtrackr/pages/goals_setup_page.dart';
import 'package:myhealthtrackr/pages/start_page.dart';
import 'package:myhealthtrackr/services/auth_scope.dart';
import 'package:myhealthtrackr/services/auth_service.dart';
import 'package:myhealthtrackr/services/goal_service.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';
import 'package:myhealthtrackr/themes/app_text_styles.dart';
import 'package:myhealthtrackr/widgets/app_snack.dart';

class GoalDetailsPage extends StatefulWidget {
  const GoalDetailsPage({super.key});

  @override
  State<GoalDetailsPage> createState() => _GoalDetailsPageState();
}

class _GoalDetailsPageState extends State<GoalDetailsPage> {
  static const Color _panelBorder = AppColours.panelBorder;
  static const Color _mutedText = AppColours.textSubtle;

  final GoalService _goalService = const GoalService();

  UserGoal? _goal;
  bool _isLoading = true;
  bool _hasLoadedGoal = false;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasLoadedGoal) return;
    _hasLoadedGoal = true;
    _loadGoal();
  }

  Future<void> _loadGoal({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final authController = AuthScope.of(context);

    try {
      final goal = await authController.withAuthenticatedSession(
        (session) => _goalService.fetchCurrentGoal(session: session),
      );

      if (!mounted) return;

      setState(() {
        _goal = goal;
        _isLoading = false;
        _errorMessage = null;
      });
    } on AuthFailure catch (error) {
      await _handleUnauthorizedSession(message: error.message);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load goal: $error';
      });
    }
  }

  Future<void> _openGoalWizard({required bool isEditingGoal}) async {
    final savedGoal = await Navigator.push<UserGoal>(
      context,
      MaterialPageRoute(
        builder: (_) => GoalsSetupPage(
          existingGoal: _goal,
          isEditingGoal: isEditingGoal,
          closeOnSave: true,
        ),
      ),
    );

    if (!mounted || savedGoal == null) return;

    setState(() => _goal = savedGoal);
    AppSnack.success(
      context,
      isEditingGoal ? 'Goal updated successfully' : 'Goal created successfully',
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColours.background,
      body: Stack(
        children: [
          _buildBackdropAccent(
            alignment: const Alignment(-0.95, -1.0),
            size: 220,
            colour: AppColours.primary.withValues(alpha: 0.10),
          ),
          _buildBackdropAccent(
            alignment: const Alignment(1.0, -0.45),
            size: 200,
            colour: AppColours.primary.withValues(alpha: 0.08),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 18),
                  _buildBody(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 80),
          child: CircularProgressIndicator(color: AppColours.primary),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_goal == null) {
      return _buildEmptyState();
    }

    final goal = _goal!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          title: 'Current goal',
          subtitle: 'An overview of your active goal.',
          child: Column(
            children: [
              _DetailRow(
                label: 'Goal type',
                value: goal.goalType,
                icon: AppIcons.flagRounded,
              ),
              const SizedBox(height: 16),
              _DetailRow(
                label: 'Target weight',
                value: '${UserGoal.formatWeight(goal.goalWeightKg)} kg',
                icon: AppIcons.monitorWeightOutlined,
              ),
              const SizedBox(height: 16),
              _DetailRow(
                label: 'Weekly goal',
                value: goal.weeklyGoalLabel,
                icon: AppIcons.trendingUpRounded,
              ),
              const SizedBox(height: 16),
              _DetailRow(
                label: 'Target date',
                value: UserGoal.formatDate(goal.goalDate),
                icon: AppIcons.eventRounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _buildSection(
          title: 'Starting details',
          subtitle: 'The starting details for this goal.',
          child: Column(
            children: [
              _DetailRow(
                label: 'Starting weight',
                value: '${UserGoal.formatWeight(goal.goalStartWeightKg)} kg',
                icon: AppIcons.fitnessCenterRounded,
              ),
              const SizedBox(height: 16),
              _DetailRow(
                label: 'Goal created',
                value: goal.goalStartDate == null
                    ? 'Not set'
                    : UserGoal.formatDate(goal.goalStartDate!),
                icon: AppIcons.scheduleRounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => _openGoalWizard(isEditingGoal: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColours.primary,
              foregroundColor: AppColours.onDark,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              'Edit Goal',
              style: AppTextStyles.button.copyWith(fontSize: 17),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColours.onDark,
              side: BorderSide(color: AppColours.borderLight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              'Back',
              style: AppTextStyles.button.copyWith(fontSize: 17),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppColours.background.withValues(alpha: 0.96),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColours.secondary,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _panelBorder),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                AppIcons.arrowBackRounded,
                color: AppColours.onDark,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Goal',
                  style: AppTextStyles.headline.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'An overview of your current goal.',
                  style: AppTextStyles.bodyMuted.copyWith(
                    color: _mutedText,
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
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
            'Unable to load goal',
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
              onPressed: _loadGoal,
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
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColours.secondary.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColours.primary.withValues(alpha: 0.18),
            ),
            child: const Icon(
              AppIcons.flagOutlined,
              color: AppColours.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'No goal set yet',
            style: AppTextStyles.headline.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set your first goal to start tracking the outcome you want to work towards.',
            style: AppTextStyles.bodyMuted.copyWith(
              color: _mutedText,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => _openGoalWizard(isEditingGoal: false),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColours.primary,
                foregroundColor: AppColours.onDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                'Set Goal',
                style: AppTextStyles.button.copyWith(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColours.secondary.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.title.copyWith(
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTextStyles.bodyMuted.copyWith(
              color: _mutedText,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 18),
          child,
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
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColours.background.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColours.primary.withValues(alpha: 0.14),
            ),
            child: Icon(icon, color: AppColours.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    color: AppColours.textSubtle,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
