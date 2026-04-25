import 'package:myhealthtrackr/config/app_config.dart';
import 'package:myhealthtrackr/services/api_client.dart';
import 'package:myhealthtrackr/services/auth_service.dart';

class MealPlanService {
  const MealPlanService({ApiClient? apiClient})
    : _apiClient = apiClient ?? const ApiClient();

  final ApiClient _apiClient;

  Future<MealPlanData> generatePlan({
    required AuthSession session,
    MealPlanPreferences preferences = const MealPlanPreferences(),
  }) async {
    final userId = _requireUserId(session);

    final response = await _apiClient.postJson(
      AppConfig.userMealPlanGenerateUri(userId),
      session: session,
      body: preferences.toApiPayload(),
      timeout: const Duration(seconds: 60),
    );
    if (response == null) {
      throw const ApiFailure(
        'The server returned an empty meal plan response.',
      );
    }
    return MealPlanData.fromApi(response);
  }

  Future<MealPlanSavedPreferences> fetchPreferences({
    required AuthSession session,
  }) async {
    final userId = _requireUserId(session);
    final response = await _apiClient.getJson(
      AppConfig.userMealPlanPreferencesUri(userId),
      session: session,
    );
    if (response == null) {
      return const MealPlanSavedPreferences(hasSavedPreferences: false);
    }
    return MealPlanSavedPreferences.fromApi(response);
  }

  Future<MealPlanSavedPreferences> savePreferences({
    required AuthSession session,
    required MealPlanPreferences preferences,
  }) async {
    final userId = _requireUserId(session);
    final response = await _apiClient.putJson(
      AppConfig.userMealPlanPreferencesUri(userId),
      session: session,
      body: preferences.toApiPayload(),
    );
    if (response == null) {
      throw const ApiFailure(
        'The server returned an empty meal recommendation preference response.',
      );
    }
    return MealPlanSavedPreferences.fromApi(response);
  }

  int _requireUserId(AuthSession session) {
    final userId = session.userId;
    if (userId == null || userId <= 0) {
      throw const ApiFailure(
        'The current session does not contain a valid user id.',
      );
    }
    return userId;
  }
}

class MealPlanPreferences {
  const MealPlanPreferences({
    this.goalType,
    this.allergies,
    this.dietaryPreferences,
    this.dietPlanType,
    this.mealTypes = const <String>[],
    this.dietTarget,
    this.dietTargets = const <String>[],
    this.dislikedFoods,
    this.likedCuisines,
    this.dislikedCuisines,
  });

  final String? goalType;
  final String? allergies;
  final String? dietaryPreferences;
  final String? dietPlanType;
  final List<String> mealTypes;
  final String? dietTarget;
  final List<String> dietTargets;
  final String? dislikedFoods;
  final String? likedCuisines;
  final String? dislikedCuisines;

  Map<String, dynamic> toApiPayload() {
    return <String, dynamic>{
      if (_cleanText(goalType) != null) 'goal_type': _cleanText(goalType),
      if (_cleanText(allergies) != null) 'allergies': _cleanText(allergies),
      if (_cleanText(dietaryPreferences) != null)
        'dietary_preferences': _cleanText(dietaryPreferences),
      if (_cleanText(dietPlanType) != null)
        'diet_plan_type': _cleanText(dietPlanType),
      'meal_types': mealTypes
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
      if (_cleanText(dietTarget) != null) 'diet_target': _cleanText(dietTarget),
      'diet_targets': dietTargets
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
      if (_cleanText(dislikedFoods) != null)
        'disliked_foods': _cleanText(dislikedFoods),
      if (_cleanText(likedCuisines) != null)
        'liked_cuisines': _cleanText(likedCuisines),
      if (_cleanText(dislikedCuisines) != null)
        'disliked_cuisines': _cleanText(dislikedCuisines),
    };
  }

  static String? _cleanText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}

class MealPlanData {
  const MealPlanData({
    required this.generatedAt,
    required this.goalType,
    required this.dietaryPreferences,
    required this.allergies,
    required this.targets,
    required this.summary,
    required this.estimateNotice,
    required this.mealGroups,
  });

  final DateTime? generatedAt;
  final String goalType;
  final String? dietaryPreferences;
  final String? allergies;
  final MealPlanTargets targets;
  final String summary;
  final String estimateNotice;
  final List<MealPlanMealGroupData> mealGroups;

  factory MealPlanData.fromApi(Map<String, dynamic> json) {
    final mealGroups = _readMealGroups(json);
    if (mealGroups.isEmpty) {
      throw const ApiFailure(
        'The server returned invalid meal recommendations.',
      );
    }

    return MealPlanData(
      generatedAt: _readNullableDateTime(json['generated_at']),
      goalType: json['goal_type']?.toString() ?? '',
      dietaryPreferences: _nullIfBlank(json['dietary_preferences']?.toString()),
      allergies: _nullIfBlank(json['allergies']?.toString()),
      targets: MealPlanTargets.fromApi(_readMap(json['targets'])),
      summary: json['summary']?.toString().trim() ?? '',
      estimateNotice: json['estimate_notice']?.toString().trim() ?? '',
      mealGroups: mealGroups,
    );
  }
}

class MealPlanSavedPreferences extends MealPlanPreferences {
  const MealPlanSavedPreferences({
    required this.hasSavedPreferences,
    super.goalType,
    super.allergies,
    super.dietaryPreferences,
    super.dietPlanType,
    super.mealTypes,
    super.dietTarget,
    super.dietTargets,
    super.dislikedFoods,
    super.likedCuisines,
    super.dislikedCuisines,
  });

  final bool hasSavedPreferences;

  factory MealPlanSavedPreferences.fromApi(Map<String, dynamic> json) {
    return MealPlanSavedPreferences(
      hasSavedPreferences: json['has_saved_preferences'] == true,
      goalType: _trimOrNull(json['goal_type']?.toString()),
      allergies: _trimOrNull(json['allergies']?.toString()),
      dietaryPreferences: _trimOrNull(json['dietary_preferences']?.toString()),
      dietPlanType: _trimOrNull(json['diet_plan_type']?.toString()),
      mealTypes: _readStringList(json['meal_types']),
      dietTarget: _trimOrNull(json['diet_target']?.toString()),
      dietTargets: _readStringList(json['diet_targets']),
      dislikedFoods: _trimOrNull(json['disliked_foods']?.toString()),
      likedCuisines: _trimOrNull(json['liked_cuisines']?.toString()),
      dislikedCuisines: _trimOrNull(json['disliked_cuisines']?.toString()),
    );
  }
}

List<MealPlanMealGroupData> _readMealGroups(Map<String, dynamic> json) {
  final mealGroupsJson = json['meal_groups'];
  if (mealGroupsJson is List) {
    return mealGroupsJson
        .whereType<Map<String, dynamic>>()
        .map(MealPlanMealGroupData.fromApi)
        .where((group) => group.options.isNotEmpty)
        .toList(growable: false);
  }

  final legacyMealsJson = json['meals'];
  if (legacyMealsJson is! List) {
    return const <MealPlanMealGroupData>[];
  }

  final groupedMeals = <String, List<MealPlanMealData>>{};
  for (final mealJson in legacyMealsJson.whereType<Map<String, dynamic>>()) {
    final meal = MealPlanMealData.fromApi(mealJson);
    final mealType = meal.mealType.trim().isEmpty
        ? 'Recommendations'
        : meal.mealType;
    groupedMeals.putIfAbsent(mealType, () => <MealPlanMealData>[]).add(meal);
  }

  return groupedMeals.entries
      .map(
        (entry) =>
            MealPlanMealGroupData(mealType: entry.key, options: entry.value),
      )
      .toList(growable: false);
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

class MealPlanMealGroupData {
  const MealPlanMealGroupData({required this.mealType, required this.options});

  final String mealType;
  final List<MealPlanMealData> options;

  factory MealPlanMealGroupData.fromApi(Map<String, dynamic> json) {
    final optionsJson = json['options'];
    if (optionsJson is! List) {
      throw const ApiFailure(
        'The server returned an invalid meal recommendation group.',
      );
    }

    return MealPlanMealGroupData(
      mealType: json['meal_type']?.toString().trim() ?? '',
      options: optionsJson
          .whereType<Map<String, dynamic>>()
          .map(MealPlanMealData.fromApi)
          .toList(growable: false),
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

List<String> _readStringList(Object? value) {
  if (value is! List) return const <String>[];
  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

String? _nullIfBlank(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  if (trimmed.isEmpty || trimmed.toLowerCase() == 'none') return null;
  return trimmed;
}

String? _trimOrNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
