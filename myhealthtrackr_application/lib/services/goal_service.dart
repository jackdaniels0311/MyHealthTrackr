import 'package:myhealthtrackr/config/app_config.dart';
import 'package:myhealthtrackr/services/api_client.dart';
import 'package:myhealthtrackr/services/auth_service.dart';

class UserGoal {
  const UserGoal({
    this.goalId,
    this.userId,
    required this.goalType,
    required this.goalWeightKg,
    required this.goalDate,
    required this.goalStartWeightKg,
    required this.weeklyGoal,
    this.goalStartDate,
  });

  final int? goalId;
  final int? userId;
  final String goalType;
  final double goalWeightKg;
  final DateTime goalDate;
  final double goalStartWeightKg;
  final double weeklyGoal;
  final DateTime? goalStartDate;

  static const List<String> goalTypes = <String>[
    'Gain Weight',
    'Maintain Weight',
    'Lose Weight',
  ];

  static const List<double> weeklyGoalValues = <double>[
    -1.0,
    -0.75,
    -0.5,
    -0.25,
    0.0,
    0.25,
    0.5,
    0.75,
    1.0,
  ];

  UserGoal copyWith({
    int? goalId,
    int? userId,
    String? goalType,
    double? goalWeightKg,
    DateTime? goalDate,
    double? goalStartWeightKg,
    double? weeklyGoal,
    DateTime? goalStartDate,
  }) {
    return UserGoal(
      goalId: goalId ?? this.goalId,
      userId: userId ?? this.userId,
      goalType: goalType ?? this.goalType,
      goalWeightKg: goalWeightKg ?? this.goalWeightKg,
      goalDate: goalDate ?? this.goalDate,
      goalStartWeightKg: goalStartWeightKg ?? this.goalStartWeightKg,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
      goalStartDate: goalStartDate ?? this.goalStartDate,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'goal_type': goalType,
      'goal_weight': goalWeightKg,
      'goal_date': _formatDateForApi(goalDate),
      'goal_start_weight': goalStartWeightKg,
      'weekly_goal': weeklyGoal,
    };
  }

  Map<String, dynamic> toUpdateJson() => toCreateJson();

  static UserGoal fromApi(Map<String, dynamic> json) {
    final goalDate = _parseDate(json['goal_date']?.toString());
    if (goalDate == null) {
      throw const ApiFailure(
        'The server returned a goal without a target date.',
      );
    }

    final goalWeight = _readNullableDouble(json['goal_weight']);
    if (goalWeight == null) {
      throw const ApiFailure(
        'The server returned a goal without a target weight.',
      );
    }

    final goalStartWeight = _readNullableDouble(json['goal_start_weight']);
    if (goalStartWeight == null) {
      throw const ApiFailure(
        'The server returned a goal without a starting weight.',
      );
    }

    final weeklyGoal = _readNullableDouble(json['weekly_goal']);
    if (weeklyGoal == null) {
      throw const ApiFailure(
        'The server returned a goal without a weekly goal.',
      );
    }

    return UserGoal(
      goalId: _readNullableInt(json['goal_id']),
      userId: _readNullableInt(json['user_id']),
      goalType: json['goal_type']?.toString() ?? '',
      goalWeightKg: goalWeight,
      goalDate: goalDate,
      goalStartWeightKg: goalStartWeight,
      weeklyGoal: weeklyGoal,
      goalStartDate: _parseDate(json['goal_start_date']?.toString()),
    );
  }

  static int _readInt(Object? value) {
    return switch (value) {
      int number => number,
      String number => int.tryParse(number) ?? 0,
      _ => 0,
    };
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

  static DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static String _formatDateForApi(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String get weeklyGoalLabel {
    if (weeklyGoal == 0) {
      return 'Maintain current weight';
    }

    final direction = weeklyGoal < 0 ? 'Lose' : 'Gain';
    return '$direction ${weeklyGoal.abs().toStringAsFixed(2)} kg / week';
  }

  String get targetSummary {
    return '$goalType to ${formatWeight(goalWeightKg)} kg by ${formatDate(goalDate)}';
  }

  static String formatWeight(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  static String formatDate(DateTime value) {
    const months = <String>[
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

    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }
}

class GoalService {
  const GoalService({ApiClient? apiClient})
    : _apiClient = apiClient ?? const ApiClient();

  final ApiClient _apiClient;

  Future<UserGoal?> fetchCurrentGoal({required AuthSession session}) async {
    final userId = await _fetchCurrentUserId(session: session);
    final goals = await _apiClient.getJsonList(
      AppConfig.userGoalsUri(userId),
      session: session,
    );

    if (goals.isEmpty) return null;

    return UserGoal.fromApi(goals.last);
  }

  Future<UserGoal> saveGoal({
    required AuthSession session,
    required UserGoal goal,
  }) async {
    final userId = await _fetchCurrentUserId(session: session);
    final goalId = goal.goalId;

    final responseJson = goalId == null
        ? await _apiClient.postJson(
            AppConfig.userGoalsUri(userId),
            session: session,
            body: goal.toCreateJson(),
          )
        : await _apiClient.putJson(
            AppConfig.userGoalUri(userId, goalId),
            session: session,
            body: goal.toUpdateJson(),
          );

    if (responseJson == null) {
      throw const ApiFailure('The server returned an empty goal response.');
    }

    return UserGoal.fromApi(responseJson);
  }

  Future<int> _fetchCurrentUserId({required AuthSession session}) async {
    final userJson = await _apiClient.getJson(
      AppConfig.userMeUri(),
      session: session,
    );

    if (userJson == null) {
      throw const ApiFailure('The server returned an empty user response.');
    }

    final userId = UserGoal._readInt(userJson['id']);
    if (userId <= 0) {
      throw const ApiFailure('The server returned an invalid user id.');
    }

    return userId;
  }
}
