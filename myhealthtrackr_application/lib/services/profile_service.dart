import 'package:myhealthtrackr/config/app_config.dart';
import 'package:myhealthtrackr/services/api_client.dart';
import 'package:myhealthtrackr/services/auth_service.dart';

class UserProfile {
  const UserProfile({
    required this.userId,
    required this.email,
    required this.isActive,
    this.profileId,
    this.fullName,
    this.dateOfBirth,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.activityLevel,
    this.dietaryPreferences,
    this.allergies,
  });

  final int userId;
  final int? profileId;
  final String email;
  final bool isActive;
  final String? fullName;
  final DateTime? dateOfBirth;
  final String? gender;
  final double? heightCm;
  final double? weightKg;
  final String? activityLevel;
  final String? dietaryPreferences;
  final String? allergies;

  static const List<String> activityLevels = <String>[
    'Not Active',
    'Lightly Active',
    'Active',
    'Very Active',
  ];

  String get displayName {
    final trimmedName = fullName?.trim() ?? '';
    if (trimmedName.isNotEmpty) return trimmedName;
    return _nameFromEmail(email);
  }

  String get initials {
    final parts = displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  int? get age {
    final dob = dateOfBirth;
    if (dob == null) return null;

    final now = DateTime.now();
    var years = now.year - dob.year;
    final hadBirthday =
        now.month > dob.month || (now.month == dob.month && now.day >= dob.day);
    if (!hadBirthday) years -= 1;
    return years < 0 ? null : years;
  }

  double get completionRatio {
    final fields = <Object?>[
      fullName,
      dateOfBirth,
      gender,
      heightCm,
      weightKg,
      activityLevel,
      dietaryPreferences,
      allergies,
    ];

    final completed = fields.where((field) {
      if (field == null) return false;
      if (field is String) return field.trim().isNotEmpty;
      return true;
    }).length;

    return completed / fields.length;
  }

  bool get isProfileComplete => completionRatio >= 1.0;

  UserProfile copyWith({
    int? userId,
    int? profileId,
    String? email,
    bool? isActive,
    String? fullName,
    DateTime? dateOfBirth,
    String? gender,
    double? heightCm,
    double? weightKg,
    String? activityLevel,
    String? dietaryPreferences,
    String? allergies,
    bool clearDateOfBirth = false,
    bool clearGender = false,
    bool clearHeightCm = false,
    bool clearWeightKg = false,
    bool clearActivityLevel = false,
    bool clearDietaryPreferences = false,
    bool clearAllergies = false,
    bool clearFullName = false,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      profileId: profileId ?? this.profileId,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      fullName: clearFullName ? null : (fullName ?? this.fullName),
      dateOfBirth: clearDateOfBirth ? null : (dateOfBirth ?? this.dateOfBirth),
      gender: clearGender ? null : (gender ?? this.gender),
      heightCm: clearHeightCm ? null : (heightCm ?? this.heightCm),
      weightKg: clearWeightKg ? null : (weightKg ?? this.weightKg),
      activityLevel: clearActivityLevel
          ? null
          : (activityLevel ?? this.activityLevel),
      dietaryPreferences: clearDietaryPreferences
          ? null
          : (dietaryPreferences ?? this.dietaryPreferences),
      allergies: clearAllergies ? null : (allergies ?? this.allergies),
    );
  }

  Map<String, dynamic> toUserUpdateJson() {
    final trimmedName = fullName?.trim();
    return {
      'name': trimmedName == null || trimmedName.isEmpty ? null : trimmedName,
    };
  }

  Map<String, dynamic> toProfileUpdateJson() {
    return {
      'date_of_birth': _formatDateForApi(dateOfBirth),
      'gender': _nullIfBlank(gender),
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'activity_level': _nullIfBlank(activityLevel),
      'dietary_preferences': _nullIfBlank(dietaryPreferences),
      'allergies': _nullIfBlank(allergies),
    };
  }

  static UserProfile fromApi({
    required Map<String, dynamic> userJson,
    Map<String, dynamic>? profileJson,
  }) {
    return UserProfile(
      userId: _readInt(userJson['id']),
      profileId: _readNullableInt(profileJson?['profile_id']),
      email: userJson['email']?.toString() ?? '',
      isActive: userJson['is_active'] == true,
      fullName: _nullIfBlank(userJson['name']?.toString()),
      dateOfBirth: _parseDate(profileJson?['date_of_birth']?.toString()),
      gender: _nullIfBlank(profileJson?['gender']?.toString()),
      heightCm: _readNullableDouble(profileJson?['height_cm']),
      weightKg: _readNullableDouble(profileJson?['weight_kg']),
      activityLevel: _nullIfBlank(profileJson?['activity_level']?.toString()),
      dietaryPreferences: _nullIfBlank(
        profileJson?['dietary_preferences']?.toString(),
      ),
      allergies: _nullIfBlank(profileJson?['allergies']?.toString()),
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

  static String? _nullIfBlank(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? _formatDateForApi(DateTime? value) {
    if (value == null) return null;
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  static String _nameFromEmail(String email) {
    final localPart = email.split('@').first.trim();
    if (localPart.isEmpty) return 'Health Tracker';

    final words = localPart
        .split(RegExp(r'[._-]+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .toList();

    return words.isEmpty ? 'Health Tracker' : words.join(' ');
  }
}

class ProfileService {
  const ProfileService({ApiClient? apiClient})
    : _apiClient = apiClient ?? const ApiClient();

  final ApiClient _apiClient;

  Future<UserProfile> fetchProfile({required AuthSession session}) async {
    final userJson = await _apiClient.getJson(
      AppConfig.userMeUri(),
      session: session,
    );

    if (userJson == null) {
      throw const ApiFailure('The server returned an empty user response.');
    }

    Map<String, dynamic>? profileJson;

    try {
      profileJson = await _apiClient.getJson(
        AppConfig.userProfileUri(),
        session: session,
      );
    } on ApiFailure catch (error) {
      if (error.statusCode != 404) rethrow;
    }

    return UserProfile.fromApi(userJson: userJson, profileJson: profileJson);
  }

  Future<UserProfile> updateProfile({
    required AuthSession session,
    required UserProfile profile,
  }) async {
    final userJson = await _apiClient.putJson(
      AppConfig.userMeUri(),
      session: session,
      body: profile.toUserUpdateJson(),
    );

    final profileJson = await _apiClient.putJson(
      AppConfig.userProfileUri(),
      session: session,
      body: profile.toProfileUpdateJson(),
    );

    if (userJson == null) {
      throw const ApiFailure('The server returned an empty user response.');
    }

    return UserProfile.fromApi(userJson: userJson, profileJson: profileJson);
  }
}
