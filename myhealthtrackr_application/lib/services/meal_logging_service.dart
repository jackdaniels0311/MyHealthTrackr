import 'package:myhealthtrackr/config/app_config.dart';
import 'package:myhealthtrackr/services/api_client.dart';
import 'package:myhealthtrackr/services/auth_service.dart';
import 'package:myhealthtrackr/services/food_service.dart';

class MealLoggingService {
  const MealLoggingService({ApiClient? apiClient})
    : _apiClient = apiClient ?? const ApiClient();

  static const String waterMealType = 'Water';
  static const int waterCupMl = 250;

  static const List<String> mealTypes = <String>[
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snacks',
    waterMealType,
  ];

  static List<String> get calorieMealTypes => mealTypes
      .where((mealType) => mealType != waterMealType)
      .toList(growable: false);

  final ApiClient _apiClient;

  static String normalizeMealTypeOrThrow(String mealType) {
    final normalizedMealType = mealType.trim();
    if (!mealTypes.contains(normalizedMealType)) {
      throw const ApiFailure(
        'Please choose a valid meal before saving this item.',
      );
    }
    return normalizedMealType;
  }

  Future<void> addFoodToMeal({
    required AuthSession session,
    required FoodProduct product,
    required String mealType,
    required String servingSize,
    required double servingQuantity,
    DateTime? logDate,
  }) async {
    final normalizedMealType = normalizeMealTypeOrThrow(mealType);

    final userId = await _fetchCurrentUserId(session: session);
    // The selected diary date controls which FoodLog bucket owns the meal.
    // That is what lets the app support logging against previous days.
    final targetDate = logDate ?? DateTime.now();
    final foodLogId = await _ensureFoodLogForDate(
      session: session,
      userId: userId,
      date: targetDate,
    );
    final mealLogId = await _ensureMealLog(
      session: session,
      userId: userId,
      foodLogId: foodLogId,
      mealType: normalizedMealType,
      mealLoggedAt: targetDate,
    );

    final nutrients = product.resolveNutrientsForServingSize(
      servingSize,
      servingQuantity,
    );
    final servingSizeValue = _parseServingSizeToInt(servingSize);

    final response = await _apiClient.postJson(
      AppConfig.userMealItemsUri(userId),
      session: session,
      body: {
        'meal_log_id': mealLogId,
        'meal_name': product.brand?.trim().isNotEmpty == true
            ? '${product.name} (${product.brand!.trim()})'
            : product.name,
        'serving_size': servingSizeValue,
        'quantity': servingQuantity,
        'calories': nutrients.calories,
        'protein': nutrients.protein,
        'carbs': nutrients.carbs,
        'fat': nutrients.fat,
        'fibre': nutrients.fibre,
        'sugar': nutrients.sugar,
        'meal_logged_at': targetDate.toIso8601String(),
      },
    );

    if (response == null) {
      throw const ApiFailure(
        'The server returned an empty meal item response.',
      );
    }
  }

  Future<void> updateMealItem({
    required AuthSession session,
    required DiaryMealItem item,
    required String mealType,
    required String servingSize,
    required double servingQuantity,
    DateTime? logDate,
  }) async {
    final normalizedMealType = normalizeMealTypeOrThrow(mealType);
    final userId = await _fetchCurrentUserId(session: session);
    final targetDate = logDate ?? item.loggedAt ?? DateTime.now();
    final foodLogId = await _ensureFoodLogForDate(
      session: session,
      userId: userId,
      date: targetDate,
    );
    final mealLogId = await _ensureMealLog(
      session: session,
      userId: userId,
      foodLogId: foodLogId,
      mealType: normalizedMealType,
      mealLoggedAt: targetDate,
    );

    final nutrients = item.resolveNutrientsForServingSize(
      servingSize,
      servingQuantity,
    );
    final servingSizeValue = _parseServingSizeToInt(servingSize);

    final response = await _apiClient.putJson(
      AppConfig.userMealItemUri(userId, item.id),
      session: session,
      body: {
        'meal_log_id': mealLogId,
        'meal_name': item.name,
        'serving_size': servingSizeValue,
        'quantity': servingQuantity,
        'calories': nutrients.calories,
        'protein': nutrients.protein,
        'carbs': nutrients.carbs,
        'fat': nutrients.fat,
        'fibre': nutrients.fibre,
        'sugar': nutrients.sugar,
        'meal_logged_at': targetDate.toIso8601String(),
      },
    );

    if (response == null) {
      throw const ApiFailure(
        'The server returned an empty meal item response.',
      );
    }
  }

  Future<void> addWaterEntry({
    required AuthSession session,
    required double amountMl,
    DateTime? logDate,
  }) async {
    if (amountMl <= 0) {
      throw const ApiFailure('Please enter a water amount greater than zero.');
    }

    final userId = await _fetchCurrentUserId(session: session);
    final targetDate = logDate ?? DateTime.now();
    final foodLogId = await _ensureFoodLogForDate(
      session: session,
      userId: userId,
      date: targetDate,
    );
    final mealLogId = await _ensureMealLog(
      session: session,
      userId: userId,
      foodLogId: foodLogId,
      mealType: waterMealType,
      mealLoggedAt: targetDate,
    );

    final existingItems = await _apiClient.getJsonList(
      AppConfig.userMealItemsUri(userId, mealLogId: mealLogId),
      session: session,
    );

    final waterItems = existingItems
        .where((item) {
          final name = item['meal_name']?.toString().trim().toLowerCase();
          return name == null || name.isEmpty || name == 'water';
        })
        .toList(growable: false);

    final existingTotalMl = waterItems.fold<double>(
      0,
      (sum, item) => sum + _readWaterAmountMl(item),
    );
    final totalMl = (existingTotalMl + amountMl).round();

    Map<String, dynamic>? response;
    if (waterItems.isNotEmpty) {
      final primaryItemId = _readNullableInt(waterItems.first['meal_item_id']);
      if (primaryItemId == null) {
        throw const ApiFailure('The server returned an invalid water entry.');
      }

      response = await _apiClient.putJson(
        AppConfig.userMealItemUri(userId, primaryItemId),
        session: session,
        body: {
          'meal_log_id': mealLogId,
          'meal_name': 'Water',
          'serving_size': totalMl,
          'quantity': 1,
          'calories': 0,
          'protein': 0,
          'carbs': 0,
          'fat': 0,
          'fibre': 0,
          'sugar': 0,
          'meal_logged_at': targetDate.toIso8601String(),
        },
      );

      for (final duplicate in waterItems.skip(1)) {
        final duplicateId = _readNullableInt(duplicate['meal_item_id']);
        if (duplicateId == null) continue;
        await _apiClient.delete(
          AppConfig.userMealItemUri(userId, duplicateId),
          session: session,
        );
      }
    } else {
      response = await _apiClient.postJson(
        AppConfig.userMealItemsUri(userId),
        session: session,
        body: {
          'meal_log_id': mealLogId,
          'meal_name': 'Water',
          'serving_size': totalMl,
          'quantity': 1,
          'calories': 0,
          'protein': 0,
          'carbs': 0,
          'fat': 0,
          'fibre': 0,
          'sugar': 0,
          'meal_logged_at': targetDate.toIso8601String(),
        },
      );
    }

    if (response == null) {
      throw const ApiFailure(
        'The server returned an empty water entry response.',
      );
    }
  }

  Future<void> deleteMealItem({
    required AuthSession session,
    required int mealItemId,
  }) async {
    final userId = await _fetchCurrentUserId(session: session);
    await _apiClient.delete(
      AppConfig.userMealItemUri(userId, mealItemId),
      session: session,
    );
  }

  Future<DiaryDayData> fetchDiaryDay({
    required AuthSession session,
    required DateTime date,
  }) async {
    final userId = await _fetchCurrentUserId(session: session);
    final logs = await _apiClient.getJsonList(
      AppConfig.userFoodLogsUri(userId, logDay: _formatLogDay(date)),
      session: session,
    );

    int? foodLogId;
    for (final log in logs) {
      final parsed = _parseDateTime(log['log_date']);
      final id = _readNullableInt(log['food_log_id']);
      if (parsed == null || id == null) continue;

      if (_isSameCalendarDay(parsed.toLocal(), date)) {
        foodLogId = id;
        break;
      }
    }

    if (foodLogId == null) {
      return DiaryDayData.empty(date);
    }

    final mealLogs = await _apiClient.getJsonList(
      AppConfig.userMealLogsUri(userId, foodLogId: foodLogId),
      session: session,
    );

    final sections = <String, DiaryMealSection>{
      for (final mealType in mealTypes)
        mealType: DiaryMealSection(mealType: mealType, items: const []),
    };

    for (final mealLog in mealLogs) {
      final mealLogId = _readNullableInt(mealLog['meal_log_id']);
      final mealType = _normalizeMealType(mealLog['meal_type']?.toString());
      if (mealLogId == null || mealType == null) continue;

      final itemsJson = await _apiClient.getJsonList(
        AppConfig.userMealItemsUri(userId, mealLogId: mealLogId),
        session: session,
      );

      final items =
          itemsJson
              .map(
                (itemJson) => DiaryMealItem.fromApi(
                  itemJson,
                  mealLogId: mealLogId,
                  mealType: mealType,
                ),
              )
              .toList()
            ..sort((left, right) => _compareMealItems(left, right));

      sections[mealType] = DiaryMealSection(mealType: mealType, items: items);
    }

    return DiaryDayData(
      date: date,
      sections: mealTypes
          .map((mealType) => sections[mealType]!)
          .toList(growable: false),
    );
  }

  Future<int> _ensureFoodLogForDate({
    required AuthSession session,
    required int userId,
    required DateTime date,
  }) async {
    final createdLog = await _apiClient.postJson(
      AppConfig.userFoodLogsUri(userId),
      session: session,
      body: {'log_date': date.toIso8601String()},
    );

    final createdId = _readNullableInt(createdLog?['food_log_id']);
    if (createdId == null) {
      throw const ApiFailure(
        'Unable to create a food log for the selected date.',
      );
    }

    return createdId;
  }

  Future<int> _ensureMealLog({
    required AuthSession session,
    required int userId,
    required int foodLogId,
    required String mealType,
    required DateTime mealLoggedAt,
  }) async {
    // Meal logs live under a FoodLog, so the FoodLog date is the canonical
    // diary day. meal_logged_at is currently stored as the selected diary date
    // as well, but it is not what the diary uses for day grouping.
    final logs = await _apiClient.getJsonList(
      AppConfig.userMealLogsUri(userId, foodLogId: foodLogId),
      session: session,
    );

    for (final log in logs) {
      final existingType = log['meal_type']?.toString().trim().toLowerCase();
      final mealLogId = _readNullableInt(log['meal_log_id']);
      if (mealLogId == null) continue;

      if (existingType == mealType.toLowerCase()) {
        return mealLogId;
      }
    }

    final createdMealLog = await _apiClient.postJson(
      AppConfig.userMealLogsUri(userId),
      session: session,
      body: {
        'food_log_id': foodLogId,
        'meal_type': mealType,
        'meal_logged_at': mealLoggedAt.toIso8601String(),
      },
    );

    final createdId = _readNullableInt(createdMealLog?['meal_log_id']);
    if (createdId == null) {
      throw const ApiFailure('Unable to create the selected meal log.');
    }

    return createdId;
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

  static DateTime? _parseDateTime(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  static int? _readNullableInt(Object? value) {
    return switch (value) {
      int number => number,
      String number => int.tryParse(number),
      _ => null,
    };
  }

  static bool _isSameCalendarDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  static String _formatLogDay(DateTime value) {
    final local = value.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String? _normalizeMealType(String? rawValue) {
    if (rawValue == null) return null;
    final normalized = rawValue.trim().toLowerCase();
    for (final mealType in mealTypes) {
      if (mealType.toLowerCase() == normalized) {
        return mealType;
      }
    }
    return null;
  }

  static int _compareMealItems(DiaryMealItem left, DiaryMealItem right) {
    final leftTimestamp = left.loggedAt;
    final rightTimestamp = right.loggedAt;

    if (leftTimestamp == null && rightTimestamp == null) {
      return left.name.compareTo(right.name);
    }
    if (leftTimestamp == null) return 1;
    if (rightTimestamp == null) return -1;
    return leftTimestamp.compareTo(rightTimestamp);
  }

  static double _readWaterAmountMl(Map<String, dynamic> item) {
    final servingSize = _readServingSizeValue(item['serving_size'])?.toDouble();
    final quantity = _parseNullableDouble(item['quantity']) ?? 1;
    if (servingSize == null || servingSize <= 0 || quantity <= 0) {
      return 0;
    }
    return servingSize * quantity;
  }
}

class DiaryDayData {
  const DiaryDayData({required this.date, required this.sections});

  final DateTime date;
  final List<DiaryMealSection> sections;

  factory DiaryDayData.empty(DateTime date) {
    return DiaryDayData(
      date: date,
      sections: MealLoggingService.mealTypes
          .map(
            (mealType) => DiaryMealSection(mealType: mealType, items: const []),
          )
          .toList(growable: false),
    );
  }

  double get totalCalories =>
      sections.fold(0, (sum, section) => sum + section.totalCalories);

  double get totalProtein =>
      sections.fold(0, (sum, section) => sum + section.totalProtein);

  double get totalCarbs =>
      sections.fold(0, (sum, section) => sum + section.totalCarbs);

  double get totalFat =>
      sections.fold(0, (sum, section) => sum + section.totalFat);

  double get totalFibre =>
      sections.fold(0, (sum, section) => sum + section.totalFibre);

  double get totalSugar =>
      sections.fold(0, (sum, section) => sum + section.totalSugar);

  double get totalWaterCups =>
      sections.fold(0, (sum, section) => sum + section.totalWaterCups);

  double get totalWaterMl =>
      sections.fold(0, (sum, section) => sum + section.totalWaterMl);

  int get totalItems =>
      sections.fold(0, (sum, section) => sum + section.items.length);

  int get mealsLogged => sections
      .where((section) => !section.isWaterSection && section.items.isNotEmpty)
      .length;
}

class DiaryMealSection {
  const DiaryMealSection({required this.mealType, required this.items});

  final String mealType;
  final List<DiaryMealItem> items;

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

  double get totalWaterCups =>
      items.fold(0, (sum, item) => sum + (item.waterCupsLogged ?? 0));

  double get totalWaterMl =>
      items.fold(0, (sum, item) => sum + (item.waterMillilitresLogged ?? 0));

  bool get isWaterSection => mealType == MealLoggingService.waterMealType;

  String get loggedSummary {
    if (isWaterSection) {
      if (items.isEmpty) {
        return 'No water logged';
      }

      final mlLabel = totalWaterMl == totalWaterMl.roundToDouble()
          ? totalWaterMl.toStringAsFixed(0)
          : totalWaterMl.toStringAsFixed(1);
      return '$mlLabel ml logged';
    }

    final caloriesLabel = totalCalories == totalCalories.roundToDouble()
        ? totalCalories.toStringAsFixed(0)
        : totalCalories.toStringAsFixed(1);

    if (items.isEmpty) {
      return 'No items logged';
    }

    final itemLabel = items.length == 1 ? 'item' : 'items';
    return '$caloriesLabel kcal across ${items.length} $itemLabel';
  }
}

class DiaryMealItem {
  const DiaryMealItem({
    required this.id,
    required this.mealLogId,
    required this.mealType,
    required this.name,
    this.mealGroupId,
    this.mealGroupName,
    Object? servingSize,
    this.quantity,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.fibre,
    this.sugar,
    this.loggedAt,
  }) : _servingSize = servingSize;

  final int id;
  final int mealLogId;
  final String mealType;
  final String name;
  final String? mealGroupId;
  final String? mealGroupName;
  final Object? _servingSize;
  final double? quantity;
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? fibre;
  final double? sugar;
  final DateTime? loggedAt;

  int? get servingSize => _readServingSizeValue(_servingSize);

  bool get isWaterEntry => mealType == MealLoggingService.waterMealType;
  bool get isGroupedSavedMealItem =>
      mealGroupId != null &&
      mealGroupId!.trim().isNotEmpty &&
      mealGroupName != null &&
      mealGroupName!.trim().isNotEmpty;

  double? get waterMillilitresLogged {
    if (!isWaterEntry) return null;
    return totalGramsLogged;
  }

  double? get waterCupsLogged {
    final totalAmount = waterMillilitresLogged;
    if (totalAmount == null || totalAmount <= 0) return null;
    return totalAmount / MealLoggingService.waterCupMl;
  }

  String? get waterAmountLabel {
    final millilitres = waterMillilitresLogged;
    if (millilitres == null || millilitres <= 0) return null;
    final label = millilitres == millilitres.roundToDouble()
        ? millilitres.toStringAsFixed(0)
        : millilitres.toStringAsFixed(1);
    return '$label ml';
  }

  factory DiaryMealItem.fromApi(
    Map<String, dynamic> json, {
    required int mealLogId,
    required String mealType,
  }) {
    final id = MealLoggingService._readNullableInt(json['meal_item_id']);
    final name = json['meal_name']?.toString().trim() ?? '';
    if (id == null || name.isEmpty) {
      throw const ApiFailure('The server returned an invalid meal item.');
    }

    return DiaryMealItem(
      id: id,
      mealLogId:
          MealLoggingService._readNullableInt(json['meal_log_id']) ?? mealLogId,
      mealType:
          MealLoggingService._normalizeMealType(
            json['meal_type']?.toString(),
          ) ??
          mealType,
      name: name,
      mealGroupId: _parseNullableString(json['meal_group_id']),
      mealGroupName: _parseNullableString(json['meal_group_name']),
      servingSize: json['serving_size'],
      quantity: _parseNullableDouble(json['quantity']),
      calories: _parseNullableDouble(json['calories']),
      protein: _parseNullableDouble(json['protein']),
      carbs: _parseNullableDouble(json['carbs']),
      fat: _parseNullableDouble(json['fat']),
      fibre: _parseNullableDouble(json['fibre']),
      sugar: _parseNullableDouble(json['sugar']),
      loggedAt: MealLoggingService._parseDateTime(json['meal_logged_at']),
    );
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

  String get defaultServingSize {
    final value = servingSize;
    if (value == null || value <= 0) {
      return '';
    }
    return '${value}g';
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

  ResolvedFoodNutrients resolveNutrientsForServingSize(
    String servingSize,
    double servingQuantity,
  ) {
    final grams = parseServingSizeGrams(servingSize);
    if (grams == null || grams <= 0 || servingQuantity <= 0) {
      return const ResolvedFoodNutrients();
    }

    final factor = (grams * servingQuantity) / 100;
    final per100g = nutrientsPer100g;
    return ResolvedFoodNutrients(
      calories: _scaleNullable(per100g.calories, factor),
      protein: _scaleNullable(per100g.protein, factor),
      carbs: _scaleNullable(per100g.carbs, factor),
      fat: _scaleNullable(per100g.fat, factor),
      fibre: _scaleNullable(per100g.fibre, factor),
      sugar: _scaleNullable(per100g.sugar, factor),
    );
  }
}

String? _parseNullableString(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) {
    return null;
  }
  return text;
}

double? _parseNullableDouble(Object? value) {
  return switch (value) {
    int number => number.toDouble(),
    double number => number,
    String number => double.tryParse(number),
    _ => null,
  };
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
  final grams = DiaryMealItem.parseServingSizeGrams(servingSize);
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
      final grams = DiaryMealItem.parseServingSizeGrams(trimmed);
      return grams?.round();
    }(),
    _ => null,
  };
}
