import 'package:flutter/material.dart';
import 'package:myhealthtrackr/themes/app_icons.dart';
import 'package:myhealthtrackr/pages/start_page.dart';
import 'package:myhealthtrackr/services/api_client.dart';
import 'package:myhealthtrackr/services/auth_scope.dart';
import 'package:myhealthtrackr/services/auth_service.dart';
import 'package:myhealthtrackr/services/nutrition_targets_service.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';
import 'package:myhealthtrackr/themes/app_text_styles.dart';

class NutritionGoalsPage extends StatefulWidget {
  const NutritionGoalsPage({super.key});

  @override
  State<NutritionGoalsPage> createState() => _NutritionGoalsPageState();
}

class _NutritionGoalsPageState extends State<NutritionGoalsPage> {
  static const Color _panelBorder = AppColours.panelBorder;
  static const Color _mutedText = AppColours.textSubtle;

  final NutritionTargetsService _nutritionTargetsService =
      const NutritionTargetsService();

  NutritionTargets? _nutritionTargets;
  bool _isLoading = true;
  bool _hasLoadedTargets = false;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasLoadedTargets) return;
    _hasLoadedTargets = true;
    _loadNutritionGoals();
  }

  Future<void> _loadNutritionGoals({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final authController = AuthScope.of(context);

    try {
      final nutritionTargets = await authController.withAuthenticatedSession(
        (session) => _fetchNutritionTargetsOrNull(session: session),
      );

      if (!mounted) return;

      setState(() {
        _nutritionTargets = nutritionTargets;
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
        _errorMessage = 'Unable to load nutrition goals: $error';
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

    if (_nutritionTargets == null) {
      return _buildEmptyState();
    }

    final nutritionTargets = _nutritionTargets!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNutritionHero(nutritionTargets),
        const SizedBox(height: 22),
        _buildSection(
          title: 'Daily targets',
          subtitle:
              'Your current recommended daily calorie, macro, and hydration goals.',
          child: Column(
            children: [
              _DetailRow(
                label: 'Calories',
                value:
                    '${_formatNumber(nutritionTargets.recommendedCaloriesKcal)} kcal',
                icon: AppIcons.localFireDepartmentRounded,
              ),
              const SizedBox(height: 16),
              _DetailRow(
                label: 'Protein',
                value:
                    '${_formatNumber(nutritionTargets.recommendedProteinG)} g',
                icon: AppIcons.fitnessCenterRounded,
              ),
              const SizedBox(height: 16),
              _DetailRow(
                label: 'Carbs',
                value: '${_formatNumber(nutritionTargets.recommendedCarbsG)} g',
                icon: AppIcons.grainRounded,
              ),
              const SizedBox(height: 16),
              _DetailRow(
                label: 'Fat',
                value: '${_formatNumber(nutritionTargets.recommendedFatG)} g',
                icon: AppIcons.opacityRounded,
              ),
              const SizedBox(height: 16),
              _DetailRow(
                label: 'Fibre',
                value: '${_formatNumber(nutritionTargets.recommendedFibreG)} g',
                icon: AppIcons.ecoRounded,
              ),
              const SizedBox(height: 16),
              _DetailRow(
                label: 'Sugar max',
                value:
                    '${_formatNumber(nutritionTargets.recommendedSugarGMax)} g',
                icon: AppIcons.icecreamOutlined,
              ),
              const SizedBox(height: 16),
              _DetailRow(
                label: 'Water',
                value:
                    '${_formatNumber(nutritionTargets.recommendedWaterMl)} ml',
                icon: AppIcons.waterDropRounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _buildSection(
          title: 'Profile and goal inputs',
          subtitle:
              'The user profile and goal values used to calculate these nutrition goals.',
          child: Column(
            children: [
              _DetailRow(
                label: 'Goal type',
                value: nutritionTargets.goalType,
                icon: AppIcons.flagRounded,
              ),
              const SizedBox(height: 16),
              _DetailRow(
                label: 'Weekly goal',
                value:
                    '${_formatNumber(nutritionTargets.weeklyGoalKg)} kg / week',
                icon: AppIcons.trendingUpRounded,
              ),
              const SizedBox(height: 16),
              _DetailRow(
                label: 'Age used',
                value: '${nutritionTargets.ageYears} years',
                icon: AppIcons.cakeOutlined,
              ),
              const SizedBox(height: 16),
              _DetailRow(
                label: 'Weight used',
                value: '${_formatNumber(nutritionTargets.weightKg)} kg',
                icon: AppIcons.monitorWeightOutlined,
              ),
              const SizedBox(height: 16),
              _DetailRow(
                label: 'Height used',
                value: '${_formatNumber(nutritionTargets.heightCm)} cm',
                icon: AppIcons.heightRounded,
              ),
              const SizedBox(height: 16),
              _DetailRow(
                label: 'Activity level',
                value: nutritionTargets.activityLevel,
                icon: AppIcons.directionsRunRounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
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
                  'Nutritional Goals',
                  style: AppTextStyles.headline.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'An overview of your nutritional goals.',
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
            'Unable to load nutrition goals',
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
              onPressed: _loadNutritionGoals,
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
              AppIcons.queryStatsRounded,
              color: AppColours.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'No nutrition goals available yet',
            style: AppTextStyles.headline.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete the user health profile and goal so personalised nutrition goals can be generated and shown here.',
            style: AppTextStyles.bodyMuted.copyWith(
              color: _mutedText,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionHero(NutritionTargets nutritionTargets) {
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColours.background.withValues(alpha: 0.46),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              nutritionTargets.goalType,
              style: AppTextStyles.label.copyWith(
                color: _mutedText,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${_formatNumber(nutritionTargets.recommendedCaloriesKcal)} kcal per day',
            style: AppTextStyles.headline.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Protein ${_formatNumber(nutritionTargets.recommendedProteinG)} g, carbs ${_formatNumber(nutritionTargets.recommendedCarbsG)} g, fat ${_formatNumber(nutritionTargets.recommendedFatG)} g.',
            style: AppTextStyles.bodyMuted.copyWith(
              color: _mutedText,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hydration target ${_formatNumber(nutritionTargets.recommendedWaterMl)} ml per day.',
            style: AppTextStyles.bodyMuted.copyWith(
              color: _mutedText,
              fontSize: 15,
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

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
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
        crossAxisAlignment: CrossAxisAlignment.center,
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
