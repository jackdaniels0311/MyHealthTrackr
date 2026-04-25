import 'package:myhealthtrackr/config/app_config.dart';
import 'package:myhealthtrackr/services/api_client.dart';
import 'package:myhealthtrackr/services/auth_service.dart';

class FoodProductNutrients {
  const FoodProductNutrients({
    this.caloriesPer100g,
    this.proteinPer100g,
    this.carbsPer100g,
    this.fatPer100g,
    this.fibrePer100g,
    this.sugarPer100g,
    this.caloriesPerServing,
    this.proteinPerServing,
    this.carbsPerServing,
    this.fatPerServing,
    this.fibrePerServing,
    this.sugarPerServing,
  });

  final double? caloriesPer100g;
  final double? proteinPer100g;
  final double? carbsPer100g;
  final double? fatPer100g;
  final double? fibrePer100g;
  final double? sugarPer100g;
  final double? caloriesPerServing;
  final double? proteinPerServing;
  final double? carbsPerServing;
  final double? fatPerServing;
  final double? fibrePerServing;
  final double? sugarPerServing;

  factory FoodProductNutrients.fromApi(Map<String, dynamic> json) {
    return FoodProductNutrients(
      caloriesPer100g: _readNullableDouble(json['calories_per_100g']),
      proteinPer100g: _readNullableDouble(json['protein_per_100g']),
      carbsPer100g: _readNullableDouble(json['carbs_per_100g']),
      fatPer100g: _readNullableDouble(json['fat_per_100g']),
      fibrePer100g: _readNullableDouble(json['fibre_per_100g']),
      sugarPer100g: _readNullableDouble(json['sugar_per_100g']),
      caloriesPerServing: _readNullableDouble(json['calories_per_serving']),
      proteinPerServing: _readNullableDouble(json['protein_per_serving']),
      carbsPerServing: _readNullableDouble(json['carbs_per_serving']),
      fatPerServing: _readNullableDouble(json['fat_per_serving']),
      fibrePerServing: _readNullableDouble(json['fibre_per_serving']),
      sugarPerServing: _readNullableDouble(json['sugar_per_serving']),
    );
  }

  FoodProductNutrients scale(double factor) {
    return FoodProductNutrients(
      caloriesPer100g: _scaleNullable(caloriesPer100g, factor),
      proteinPer100g: _scaleNullable(proteinPer100g, factor),
      carbsPer100g: _scaleNullable(carbsPer100g, factor),
      fatPer100g: _scaleNullable(fatPer100g, factor),
      fibrePer100g: _scaleNullable(fibrePer100g, factor),
      sugarPer100g: _scaleNullable(sugarPer100g, factor),
      caloriesPerServing: _scaleNullable(caloriesPerServing, factor),
      proteinPerServing: _scaleNullable(proteinPerServing, factor),
      carbsPerServing: _scaleNullable(carbsPerServing, factor),
      fatPerServing: _scaleNullable(fatPerServing, factor),
      fibrePerServing: _scaleNullable(fibrePerServing, factor),
      sugarPerServing: _scaleNullable(sugarPerServing, factor),
    );
  }
}

class ResolvedFoodNutrients {
  const ResolvedFoodNutrients({
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.fibre,
    this.sugar,
  });

  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? fibre;
  final double? sugar;
}

class FoodProduct {
  const FoodProduct({
    required this.barcode,
    required this.name,
    required this.sourceId,
    required this.source,
    this.brand,
    this.quantity,
    this.servingSize,
    this.servingQuantity,
    this.servingUnit,
    this.imageUrl,
    this.timesLogged,
    this.lastLoggedAt,
    this.nutrients = const FoodProductNutrients(),
  });

  final String barcode;
  final String name;
  final String sourceId;
  final String source;
  final String? brand;
  final String? quantity;
  final String? servingSize;
  final double? servingQuantity;
  final String? servingUnit;
  final String? imageUrl;
  final int? timesLogged;
  final DateTime? lastLoggedAt;
  final FoodProductNutrients nutrients;

  factory FoodProduct.fromApi(Map<String, dynamic> json) {
    final barcode = json['barcode']?.toString().trim() ?? '';
    final name = json['name']?.toString().trim() ?? '';
    final sourceId = json['source_id']?.toString().trim() ?? '';
    final source = json['source']?.toString().trim() ?? '';

    if (barcode.isEmpty || name.isEmpty || sourceId.isEmpty || source.isEmpty) {
      throw const ApiFailure('The server returned an invalid food product.');
    }

    final nutrientsJson = json['nutrients'];
    return FoodProduct(
      barcode: barcode,
      name: name,
      sourceId: sourceId,
      source: source,
      brand: _readNullableString(json['brand']),
      quantity: _readNullableString(json['quantity']),
      servingSize: _readNullableString(json['serving_size']),
      servingQuantity: _readNullableDouble(json['serving_quantity']),
      servingUnit: _readNullableString(json['serving_unit']),
      imageUrl: _readNullableString(json['image_url']),
      timesLogged: _readNullableInt(json['times_logged']),
      lastLoggedAt: _readNullableDateTime(json['last_logged_at']),
      nutrients: nutrientsJson is Map<String, dynamic>
          ? FoodProductNutrients.fromApi(nutrientsJson)
          : const FoodProductNutrients(),
    );
  }

  bool get isQuickAdd => source == 'user_history';

  String get displayName {
    if (!isQuickAdd) return name;
    final splitName = _splitNameAndBrandFromLoggedName(name);
    return splitName.name;
  }

  String get subtitle {
    if (isQuickAdd) {
      final splitName = _splitNameAndBrandFromLoggedName(name);
      return splitName.brand ?? '';
    }
    if (brand != null && quantity != null) {
      return '$brand • $quantity';
    }
    return brand ?? quantity ?? 'Scanned from Open Food Facts';
  }

  ResolvedFoodNutrients resolveNutrientsForQuantity(double quantity) {
    final baseServingQuantity = servingQuantity;
    final hasServingNutrition =
        nutrients.caloriesPerServing != null ||
        nutrients.proteinPerServing != null ||
        nutrients.carbsPerServing != null ||
        nutrients.fatPerServing != null ||
        nutrients.fibrePerServing != null ||
        nutrients.sugarPerServing != null;

    if (hasServingNutrition &&
        baseServingQuantity != null &&
        baseServingQuantity > 0) {
      final factor = quantity / baseServingQuantity;
      return ResolvedFoodNutrients(
        calories: _scaleNullable(nutrients.caloriesPerServing, factor),
        protein: _scaleNullable(nutrients.proteinPerServing, factor),
        carbs: _scaleNullable(nutrients.carbsPerServing, factor),
        fat: _scaleNullable(nutrients.fatPerServing, factor),
        fibre: _scaleNullable(nutrients.fibrePerServing, factor),
        sugar: _scaleNullable(nutrients.sugarPerServing, factor),
      );
    }

    final factor = quantity / 100;
    return ResolvedFoodNutrients(
      calories: _scaleNullable(nutrients.caloriesPer100g, factor),
      protein: _scaleNullable(nutrients.proteinPer100g, factor),
      carbs: _scaleNullable(nutrients.carbsPer100g, factor),
      fat: _scaleNullable(nutrients.fatPer100g, factor),
      fibre: _scaleNullable(nutrients.fibrePer100g, factor),
      sugar: _scaleNullable(nutrients.sugarPer100g, factor),
    );
  }

  ResolvedFoodNutrients resolveNutrientsForServingSize(
    String servingSize,
    double servingQuantity,
  ) {
    final grams = parseServingSizeGrams(servingSize);
    if (grams != null && grams > 0) {
      final totalGrams = grams * servingQuantity;
      final factor = totalGrams / 100;
      return ResolvedFoodNutrients(
        calories: _scaleNullable(nutrients.caloriesPer100g, factor),
        protein: _scaleNullable(nutrients.proteinPer100g, factor),
        carbs: _scaleNullable(nutrients.carbsPer100g, factor),
        fat: _scaleNullable(nutrients.fatPer100g, factor),
        fibre: _scaleNullable(nutrients.fibrePer100g, factor),
        sugar: _scaleNullable(nutrients.sugarPer100g, factor),
      );
    }

    if (servingQuantity <= 0) {
      return const ResolvedFoodNutrients();
    }

    return resolveNutrientsForQuantity(servingQuantity);
  }

  double? parseServingSizeGrams(String servingSize) {
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

class FoodService {
  const FoodService({ApiClient? apiClient})
    : _apiClient = apiClient ?? const ApiClient();

  final ApiClient _apiClient;

  Future<List<FoodProduct>> searchFoods(
    String query, {
    int pageSize = 10,
    AuthSession? session,
    String? mealType,
  }) async {
    final normalizedQuery = query.trim();
    if (session == null && normalizedQuery.length < 2) {
      throw const ApiFailure(
        'Search terms must be at least 2 characters long.',
      );
    }

    final responseJson = await _apiClient.getJsonList(
      session == null
          ? AppConfig.foodSearchUri(normalizedQuery, pageSize: pageSize)
          : AppConfig.userFoodSearchUri(
              normalizedQuery,
              pageSize: pageSize,
              mealType: mealType,
            ),
      session: session,
    );

    return responseJson.map(FoodProduct.fromApi).toList(growable: false);
  }

  Future<FoodProduct> lookupFoodByBarcode(String barcode) async {
    final responseJson = await _apiClient.getJson(
      AppConfig.foodBarcodeUri(barcode),
    );

    if (responseJson == null) {
      throw const ApiFailure('The server returned an empty food response.');
    }

    return FoodProduct.fromApi(responseJson);
  }

  static String formatMetric(double? value, {String suffix = 'g'}) {
    if (value == null) return '--';
    final rounded = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return '$rounded$suffix';
  }

  static String formatCalories(double? value) {
    if (value == null) return '--';
    final rounded = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return '$rounded kcal';
  }
}

String? _readNullableString(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

double? _readNullableDouble(Object? value) {
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
    double number => number.toInt(),
    String number => int.tryParse(number),
    _ => null,
  };
}

DateTime? _readNullableDateTime(Object? value) {
  final text = _readNullableString(value);
  if (text == null) return null;
  return DateTime.tryParse(text);
}

({String name, String? brand}) _splitNameAndBrandFromLoggedName(String value) {
  final trimmed = value.trim();
  final match = RegExp(r'^(.*?)\s+\(([^()]+)\)$').firstMatch(trimmed);
  if (match == null) {
    return (name: trimmed, brand: null);
  }

  final parsedName = match.group(1)?.trim() ?? trimmed;
  final parsedBrand = match.group(2)?.trim();
  return (
    name: parsedName.isEmpty ? trimmed : parsedName,
    brand: parsedBrand == null || parsedBrand.isEmpty ? null : parsedBrand,
  );
}

double? _scaleNullable(double? value, double factor) {
  if (value == null) return null;
  return value * factor;
}
