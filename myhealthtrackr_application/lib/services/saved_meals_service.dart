import 'package:myhealthtrackr/config/app_config.dart';
import 'package:myhealthtrackr/services/api_client.dart';
import 'package:myhealthtrackr/services/auth_service.dart';
import 'package:myhealthtrackr/services/food_service.dart';

class SavedMealsService {
  const SavedMealsService({ApiClient? apiClient})
    : _apiClient = apiClient ?? const ApiClient();

  final ApiClient _apiClient;

  Future<List<SavedMealData>> fetchMeals({required AuthSession session}) async {
    final userId = await _fetchCurrentUserId(session: session);
    final mealsJson = await _apiClient.getJsonList(
      AppConfig.userSavedMealsUri(userId),
      session: session,
    );
    return mealsJson.map(SavedMealData.fromApi).toList(growable: false);
  }

  Future<SavedMealData> createMeal({
    required AuthSession session,
    required String name,
    required List<SavedMealItemData> items,
  }) async {
    final userId = await _fetchCurrentUserId(session: session);
    final response = await _apiClient.postJson(
      AppConfig.userSavedMealsUri(userId),
      session: session,
      body: {
        'name': name.trim(),
        'items': items
            .map((item) => item.toApiPayload())
            .toList(growable: false),
      },
    );
    if (response == null) {
      throw const ApiFailure(
        'The server returned an empty saved meal response.',
      );
    }
    return SavedMealData.fromApi(response);
  }

  Future<SavedMealData> updateMeal({
    required AuthSession session,
    required int savedMealId,
    required String name,
    required List<SavedMealItemData> items,
  }) async {
    final userId = await _fetchCurrentUserId(session: session);
    final response = await _apiClient.putJson(
      AppConfig.userSavedMealUri(userId, savedMealId),
      session: session,
      body: {
        'name': name.trim(),
        'items': items
            .map((item) => item.toApiPayload())
            .toList(growable: false),
      },
    );
    if (response == null) {
      throw const ApiFailure(
        'The server returned an empty saved meal response.',
      );
    }
    return SavedMealData.fromApi(response);
  }

  Future<void> deleteMeal({
    required AuthSession session,
    required int savedMealId,
  }) async {
    final userId = await _fetchCurrentUserId(session: session);
    await _apiClient.delete(
      AppConfig.userSavedMealUri(userId, savedMealId),
      session: session,
    );
  }

  Future<void> logMealToDiary({
    required AuthSession session,
    required int savedMealId,
    required String mealType,
    required DateTime logDate,
    required List<SavedMealItemData> items,
  }) async {
    final userId = await _fetchCurrentUserId(session: session);
    final response = await _apiClient.postJson(
      AppConfig.userSavedMealLogUri(userId, savedMealId),
      session: session,
      body: {
        'meal_type': mealType.trim(),
        'log_date': logDate.toIso8601String(),
        'items': items
            .map((item) => item.toApiPayload())
            .toList(growable: false),
      },
    );
    if (response == null) {
      throw const ApiFailure(
        'The server returned an empty meal logging response.',
      );
    }
  }

  Future<int> _fetchCurrentUserId({required AuthSession session}) async {
    final userJson = await _apiClient.getJson(
      AppConfig.userMeUri(),
      session: session,
    );
    final userId = _readNullableInt(userJson?['id']);
    if (userId == null || userId <= 0) {
      throw const ApiFailure('The server returned an invalid user id.');
    }
    return userId;
  }
}

class SavedMealData {
  const SavedMealData({
    required this.id,
    required this.userId,
    required this.name,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int userId;
  final String name;
  final List<SavedMealItemData> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SavedMealData.fromApi(Map<String, dynamic> json) {
    final id = _readNullableInt(json['saved_meal_id']);
    final userId = _readNullableInt(json['user_id']);
    final name = json['name']?.toString().trim() ?? '';
    final itemsJson = json['items'];
    if (id == null || userId == null || name.isEmpty || itemsJson is! List) {
      throw const ApiFailure('The server returned an invalid saved meal.');
    }
    return SavedMealData(
      id: id,
      userId: userId,
      name: name,
      items: itemsJson
          .whereType<Map<String, dynamic>>()
          .map(SavedMealItemData.fromApi)
          .toList(growable: false),
      createdAt: _readNullableDateTime(json['created_at']),
      updatedAt: _readNullableDateTime(json['updated_at']),
    );
  }

  double get totalCalories =>
      items.fold(0, (sum, item) => sum + (item.calories ?? 0));

  double get totalProtein =>
      items.fold(0, (sum, item) => sum + (item.protein ?? 0));

  double get totalCarbs =>
      items.fold(0, (sum, item) => sum + (item.carbs ?? 0));

  double get totalFat => items.fold(0, (sum, item) => sum + (item.fat ?? 0));

  double get totalFibre =>
      items.fold(0, (sum, item) => sum + (item.fibre ?? 0));

  double get totalSugar =>
      items.fold(0, (sum, item) => sum + (item.sugar ?? 0));
}

class SavedMealItemData {
  const SavedMealItemData({
    this.id,
    required this.name,
    Object? servingSize,
    this.quantity,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.fibre,
    this.sugar,
  }) : _servingSize = servingSize;

  factory SavedMealItemData.fromApi(Map<String, dynamic> json) {
    final name = json['meal_name']?.toString().trim() ?? '';
    if (name.isEmpty) {
      throw const ApiFailure('The server returned an invalid saved meal item.');
    }
    return SavedMealItemData(
      id: _readNullableInt(json['saved_meal_item_id']),
      name: name,
      servingSize: json['serving_size'],
      quantity: _parseNullableDouble(json['quantity']),
      calories: _parseNullableDouble(json['calories']),
      protein: _parseNullableDouble(json['protein']),
      carbs: _parseNullableDouble(json['carbs']),
      fat: _parseNullableDouble(json['fat']),
      fibre: _parseNullableDouble(json['fibre']),
      sugar: _parseNullableDouble(json['sugar']),
    );
  }

  factory SavedMealItemData.fromProduct({
    required FoodProduct product,
    required String servingSize,
    required double servingQuantity,
  }) {
    final resolved = product.resolveNutrientsForServingSize(
      servingSize,
      servingQuantity,
    );
    return SavedMealItemData(
      name: product.brand?.trim().isNotEmpty == true
          ? '${product.name} (${product.brand!.trim()})'
          : product.name,
      servingSize: _parseServingSizeToInt(servingSize),
      quantity: servingQuantity,
      calories: resolved.calories,
      protein: resolved.protein,
      carbs: resolved.carbs,
      fat: resolved.fat,
      fibre: resolved.fibre,
      sugar: resolved.sugar,
    );
  }

  final int? id;
  final String name;
  final Object? _servingSize;
  final double? quantity;
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? fibre;
  final double? sugar;

  int? get servingSize => _readServingSizeValue(_servingSize);

  double? get totalGramsLogged {
    final gramsPerServing = servingSize;
    final servingQuantity = quantity;
    if (gramsPerServing == null || gramsPerServing <= 0) {
      return null;
    }
    if (servingQuantity == null || servingQuantity <= 0) {
      return null;
    }
    return gramsPerServing * servingQuantity;
  }

  ResolvedFoodNutrients get nutrientsPer100g {
    final totalGrams = totalGramsLogged;
    return ResolvedFoodNutrients(
      calories: _derivePer100g(calories, totalGrams),
      protein: _derivePer100g(protein, totalGrams),
      carbs: _derivePer100g(carbs, totalGrams),
      fat: _derivePer100g(fat, totalGrams),
      fibre: _derivePer100g(fibre, totalGrams),
      sugar: _derivePer100g(sugar, totalGrams),
    );
  }

  String get defaultServingSize {
    final value = servingSize;
    if (value == null || value <= 0) return '';
    return value.toString();
  }

  SavedMealItemData copyWith({
    int? id,
    String? name,
    Object? servingSize,
    double? quantity,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fibre,
    double? sugar,
  }) {
    return SavedMealItemData(
      id: id ?? this.id,
      name: name ?? this.name,
      servingSize: servingSize ?? _servingSize,
      quantity: quantity ?? this.quantity,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fibre: fibre ?? this.fibre,
      sugar: sugar ?? this.sugar,
    );
  }

  SavedMealItemData recalculate({
    required String servingSize,
    required double servingQuantity,
  }) {
    final grams = parseServingSizeGrams(servingSize);
    if (grams == null || grams <= 0 || servingQuantity <= 0) {
      throw const ApiFailure(
        'Please enter a valid serving size and quantity for this item.',
      );
    }

    final factor = (grams * servingQuantity) / 100;
    final per100g = nutrientsPer100g;
    return copyWith(
      servingSize: grams.round(),
      quantity: servingQuantity,
      calories: _scaleNullable(per100g.calories, factor),
      protein: _scaleNullable(per100g.protein, factor),
      carbs: _scaleNullable(per100g.carbs, factor),
      fat: _scaleNullable(per100g.fat, factor),
      fibre: _scaleNullable(per100g.fibre, factor),
      sugar: _scaleNullable(per100g.sugar, factor),
    );
  }

  Map<String, dynamic> toApiPayload() {
    return {
      'meal_name': name,
      'serving_size': servingSize,
      'quantity': quantity,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fibre': fibre,
      'sugar': sugar,
    };
  }

  static double? parseServingSizeGrams(String servingSize) {
    final normalized = servingSize.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    final gramMatch = RegExp(r'(\d+(?:\.\d+)?)\s*g\b').firstMatch(normalized);
    if (gramMatch != null) {
      return double.tryParse(gramMatch.group(1)!);
    }

    if (RegExp(r'^\d+(?:\.\d+)?$').hasMatch(normalized)) {
      return double.tryParse(normalized);
    }

    return null;
  }
}

double? _parseNullableDouble(Object? value) {
  return switch (value) {
    int number => number.toDouble(),
    double number => number,
    String number => double.tryParse(number),
    _ => null,
  };
}

int? _readNullableInt(Object? value) {
  return switch (value) {
    int number => number,
    String number => int.tryParse(number),
    _ => null,
  };
}

DateTime? _readNullableDateTime(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text);
}

double? _scaleNullable(double? value, double factor) {
  if (value == null) return null;
  return value * factor;
}

double? _derivePer100g(double? total, double? grams) {
  if (total == null || grams == null || grams <= 0) {
    return null;
  }
  return (total / grams) * 100;
}

int _parseServingSizeToInt(String servingSize) {
  final grams = SavedMealItemData.parseServingSizeGrams(servingSize);
  if (grams == null || grams <= 0) {
    throw const ApiFailure(
      'Please enter the serving size in grams, for example 30g.',
    );
  }
  return grams.round();
}

int? _readServingSizeValue(Object? value) {
  return switch (value) {
    int number => number,
    double number => number.round(),
    String text => () {
      final trimmed = text.trim();
      if (trimmed.isEmpty) return null;
      final direct = int.tryParse(trimmed);
      if (direct != null) return direct;
      final grams = SavedMealItemData.parseServingSizeGrams(trimmed);
      return grams?.round();
    }(),
    _ => null,
  };
}
