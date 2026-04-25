import 'package:myhealthtrackr/config/app_config.dart';
import 'package:myhealthtrackr/services/api_client.dart';
import 'package:myhealthtrackr/services/auth_service.dart';

class NutritionTargets {
  static const Map<String, double> _waterActivityBonusesMl = {
    'Not Active': 0,
    'Lightly Active': 250,
    'Active': 500,
    'Very Active': 750,
  };

  const NutritionTargets({
    required this.nutritionTargetId,
    required this.userId,
    required this.profileId,
    required this.goalId,
    required this.ageYears,
    required this.weightKg,
    required this.heightCm,
    required this.activityLevel,
    required this.activityMultiplier,
    required this.goalType,
    required this.weeklyGoalKg,
    required this.bmrKcal,
    required this.tdeeKcal,
    required this.calorieAdjustmentKcal,
    required this.recommendedCaloriesKcal,
    required this.recommendedProteinG,
    required this.recommendedCarbsG,
    required this.recommendedFatG,
    required this.recommendedFibreG,
    required this.recommendedSugarGMax,
    required double? recommendedWaterMl,
  }) : _recommendedWaterMl = recommendedWaterMl;

  final int nutritionTargetId;
  final int userId;
  final int profileId;
  final int? goalId;
  final int ageYears;
  final double weightKg;
  final double heightCm;
  final String activityLevel;
  final double activityMultiplier;
  final String goalType;
  final double weeklyGoalKg;
  final double bmrKcal;
  final double tdeeKcal;
  final double calorieAdjustmentKcal;
  final double recommendedCaloriesKcal;
  final double recommendedProteinG;
  final double recommendedCarbsG;
  final double recommendedFatG;
  final double recommendedFibreG;
  final double recommendedSugarGMax;
  final double? _recommendedWaterMl;

  double get recommendedWaterMl {
    final storedValue = _recommendedWaterMl;
    if (storedValue != null && storedValue > 0) {
      return storedValue;
    }

    if (weightKg <= 0) {
      return 0;
    }

    final activityBonusMl = _waterActivityBonusesMl[activityLevel] ?? 0;
    final baselineMl = weightKg * 35;
    return _roundToNearestIncrement(
      baselineMl + activityBonusMl,
      increment: 50,
    );
  }

  factory NutritionTargets.fromApi(Map<String, dynamic> json) {
    final nutritionTargetId = _readNullableInt(json['nutrition_target_id']);
    final userId = _readNullableInt(json['user_id']);
    final profileId = _readNullableInt(json['profile_id']);

    if (nutritionTargetId == null || userId == null || profileId == null) {
      throw const ApiFailure(
        'The server returned an invalid nutrition target response.',
      );
    }

    return NutritionTargets(
      nutritionTargetId: nutritionTargetId,
      userId: userId,
      profileId: profileId,
      goalId: _readNullableInt(json['goal_id']),
      ageYears: _readNullableInt(json['age_years']) ?? 0,
      weightKg: _readNullableDouble(json['weight_kg']) ?? 0,
      heightCm: _readNullableDouble(json['height_cm']) ?? 0,
      activityLevel: json['activity_level']?.toString() ?? '',
      activityMultiplier: _readNullableDouble(json['activity_multiplier']) ?? 0,
      goalType: json['goal_type']?.toString() ?? '',
      weeklyGoalKg: _readNullableDouble(json['weekly_goal_kg']) ?? 0,
      bmrKcal: _readNullableDouble(json['bmr_kcal']) ?? 0,
      tdeeKcal: _readNullableDouble(json['tdee_kcal']) ?? 0,
      calorieAdjustmentKcal:
          _readNullableDouble(json['calorie_adjustment_kcal']) ?? 0,
      recommendedCaloriesKcal:
          _readNullableDouble(json['recommended_calories_kcal']) ?? 0,
      recommendedProteinG:
          _readNullableDouble(json['recommended_protein_g']) ?? 0,
      recommendedCarbsG: _readNullableDouble(json['recommended_carbs_g']) ?? 0,
      recommendedFatG: _readNullableDouble(json['recommended_fat_g']) ?? 0,
      recommendedFibreG: _readNullableDouble(json['recommended_fibre_g']) ?? 0,
      recommendedSugarGMax:
          _readNullableDouble(json['recommended_sugar_g_max']) ?? 0,
      recommendedWaterMl:
          _readNullableDouble(json['recommended_water_ml']) ?? 0,
    );
  }

  static int? _readNullableInt(Object? value) {
    return switch (value) {
      int number => number,
      String number => int.tryParse(number),
      _ => null,
    };
  }

  static double? _readNullableDouble(Object? value) {
    return switch (value) {
      int number => number.toDouble(),
      double number => number,
      String number => double.tryParse(number),
      _ => null,
    };
  }

  static double _roundToNearestIncrement(
    double value, {
    required double increment,
  }) {
    if (increment <= 0) {
      return value;
    }

    return (value / increment).roundToDouble() * increment;
  }
}

class NutritionTargetsService {
  const NutritionTargetsService({ApiClient? apiClient})
    : _apiClient = apiClient ?? const ApiClient();

  final ApiClient _apiClient;

  Future<NutritionTargets> fetchNutritionTargets({
    required AuthSession session,
  }) async {
    final userId = session.userId;
    if (userId == null || userId <= 0) {
      throw const ApiFailure(
        'The current session does not contain a valid user id.',
      );
    }

    final responseJson = await _apiClient.getJson(
      AppConfig.userNutritionTargetsUri(userId),
      session: session,
    );

    if (responseJson == null) {
      throw const ApiFailure(
        'The server returned an empty nutrition target response.',
      );
    }

    return NutritionTargets.fromApi(responseJson);
  }
}
