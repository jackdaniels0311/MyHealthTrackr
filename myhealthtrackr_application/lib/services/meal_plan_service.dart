import 'package:myhealthtrackr/config/app_config.dart';
import 'package:myhealthtrackr/services/api_client.dart';
import 'package:myhealthtrackr/services/auth_service.dart';

class MealPlanService {
  const MealPlanService({ApiClient? apiClient})
    : _apiClient = apiClient ?? const ApiClient();

  final ApiClient _apiClient;

  Future<MealPlanData> generatePlan({required AuthSession session}) async {
    final userId = session.userId;
    if (userId == null || userId <= 0) {
      throw const ApiFailure(
        'The current session does not contain a valid user id.',
      );
    }

    final response = await _apiClient.postJson(
      AppConfig.userMealPlanGenerateUri(userId),
      session: session,
      body: const <String, dynamic>{},
      timeout: const Duration(seconds: 60),
    );
    if (response == null) {
      throw const ApiFailure('The server returned an empty meal plan response.');
    }
    return MealPlanData.fromApi(response);
  }
}

class MealPlanData {
  const MealPlanData({
    required this.generatedAt,
    required this.goalType,
    required this.dietaryPreferences,
    required this.allergies,
    required this.targets,
    required this.totals,
    required this.summary,
    required this.estimateNotice,
    required this.meals,
  });

  final DateTime? generatedAt;
  final String goalType;
  final String? dietaryPreferences;
  final String? allergies;
  final MealPlanTargets targets;
  final MealPlanTotals totals;
  final String summary;
  final String estimateNotice;
  final List<MealPlanMealData> meals;

  factory MealPlanData.fromApi(Map<String, dynamic> json) {
    final mealsJson = json['meals'];
    if (mealsJson is! List) {
      throw const ApiFailure('The server returned an invalid meal plan.');
    }

    return MealPlanData(
      generatedAt: _readNullableDateTime(json['generated_at']),
      goalType: json['goal_type']?.toString() ?? '',
      dietaryPreferences: _nullIfBlank(json['dietary_preferences']?.toString()),
      allergies: _nullIfBlank(json['allergies']?.toString()),
      targets: MealPlanTargets.fromApi(_readMap(json['targets'])),
      totals: MealPlanTotals.fromApi(_readMap(json['totals'])),
      summary: json['summary']?.toString().trim() ?? '',
      estimateNotice: json['estimate_notice']?.toString().trim() ?? '',
      meals: mealsJson
          .whereType<Map<String, dynamic>>()
          .map(MealPlanMealData.fromApi)
          .toList(growable: false),
    );
  }
}

class MealPlanTargets {
  const MealPlanTargets({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  factory MealPlanTargets.fromApi(Map<String, dynamic> json) {
    return MealPlanTargets(
      calories: _readDouble(json['calories']),
      protein: _readDouble(json['protein']),
      carbs: _readDouble(json['carbs']),
      fat: _readDouble(json['fat']),
    );
  }
}

class MealPlanTotals {
  const MealPlanTotals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fibre,
    required this.sugar,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fibre;
  final double sugar;

  factory MealPlanTotals.fromApi(Map<String, dynamic> json) {
    return MealPlanTotals(
      calories: _readDouble(json['calories']),
      protein: _readDouble(json['protein']),
      carbs: _readDouble(json['carbs']),
      fat: _readDouble(json['fat']),
      fibre: _readDouble(json['fibre']),
      sugar: _readDouble(json['sugar']),
    );
  }
}

class MealPlanMealData {
  const MealPlanMealData({
    required this.mealType,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fibre,
    required this.sugar,
    required this.ingredients,
    required this.matchReason,
  });

  final String mealType;
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fibre;
  final double sugar;
  final List<MealPlanIngredientData> ingredients;
  final String matchReason;

  factory MealPlanMealData.fromApi(Map<String, dynamic> json) {
    final ingredientsJson = json['ingredients'];
    if (ingredientsJson is! List) {
      throw const ApiFailure('The server returned an invalid meal plan meal.');
    }

    return MealPlanMealData(
      mealType: json['meal_type']?.toString().trim() ?? '',
      name: json['name']?.toString().trim() ?? '',
      calories: _readDouble(json['calories']),
      protein: _readDouble(json['protein']),
      carbs: _readDouble(json['carbs']),
      fat: _readDouble(json['fat']),
      fibre: _readDouble(json['fibre']),
      sugar: _readDouble(json['sugar']),
      ingredients: ingredientsJson
          .whereType<Map<String, dynamic>>()
          .map(MealPlanIngredientData.fromApi)
          .toList(growable: false),
      matchReason: json['match_reason']?.toString().trim() ?? '',
    );
  }
}

class MealPlanIngredientData {
  const MealPlanIngredientData({
    required this.name,
    required this.quantity,
    required this.unit,
  });

  final String name;
  final double quantity;
  final String unit;

  factory MealPlanIngredientData.fromApi(Map<String, dynamic> json) {
    return MealPlanIngredientData(
      name: json['name']?.toString().trim() ?? '',
      quantity: _readDouble(json['quantity']),
      unit: json['unit']?.toString().trim() ?? '',
    );
  }

  String get displayQuantity {
    final whole = quantity.roundToDouble();
    final formatted = (quantity - whole).abs() < 0.01
        ? whole.toInt().toString()
        : quantity.toStringAsFixed(1);
    return '$formatted $unit'.trim();
  }
}

Map<String, dynamic> _readMap(Object? value) {
  return value is Map<String, dynamic> ? value : const <String, dynamic>{};
}

double _readDouble(Object? value) {
  return switch (value) {
    int number => number.toDouble(),
    double number => number,
    String number => double.tryParse(number) ?? 0,
    _ => 0,
  };
}

DateTime? _readNullableDateTime(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

String? _nullIfBlank(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  if (trimmed.isEmpty || trimmed.toLowerCase() == 'none') return null;
  return trimmed;
}
