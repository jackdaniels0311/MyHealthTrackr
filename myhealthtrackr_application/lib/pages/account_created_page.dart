import 'package:flutter/material.dart';
import 'package:myhealthtrackr/themes/app_icons.dart';
import 'package:myhealthtrackr/pages/profile_creation_loading_page.dart';
import 'package:myhealthtrackr/pages/start_page.dart';
import 'package:myhealthtrackr/services/api_client.dart';
import 'package:myhealthtrackr/services/auth_scope.dart';
import 'package:myhealthtrackr/services/auth_service.dart';
import 'package:myhealthtrackr/services/profile_service.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';
import 'package:myhealthtrackr/themes/app_text_styles.dart';
import 'package:myhealthtrackr/widgets/app_snack.dart';

class AccountCreatedPage extends StatefulWidget {
  const AccountCreatedPage({
    super.key,
    required this.email,
    required this.name,
    this.successMessage,
    this.isEditingProfile = false,
  });

  static const routeName = '/account-created';

  final String email;
  final String name;
  final String? successMessage;
  final bool isEditingProfile;

  @override
  State<AccountCreatedPage> createState() => _AccountCreatedPageState();
}

class _AccountCreatedPageState extends State<AccountCreatedPage> {
  static const List<String> _genderOptions = <String>[
    'Female',
    'Male',
    'Non-binary',
    'Prefer not to say',
  ];

  static const List<String> _allergyOptions = <String>[
    'None',
    'Peanuts',
    'Dairy',
    'Eggs',
    'Wheat',
    'Gluten',
    'Fish',
    'Shellfish',
  ];

  static const List<String> _dietaryPreferenceOptions = <String>[
    'None',
    'Vegetarian',
    'Vegan',
    'Pescatarian',
    'Halal',
    'Gluten-free',
    'Dairy-free',
  ];

  static const Map<String, String> _activityLevelDescriptions =
      <String, String>{
        'Not Active': 'Mostly seated with very little exercise.',
        'Lightly Active': 'Some walking or light workouts most days.',
        'Active': 'Regular exercise or a generally active routine.',
        'Very Active': 'Hard training or physically demanding days.',
      };

  final ProfileService _profileService = const ProfileService();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _dietaryPreferencesController =
      TextEditingController();

  bool _hasLoadedProfile = false;
  bool _hasShownSuccessMessage = false;
  bool _isLoadingProfile = true;
  bool _isSubmitting = false;
  int _currentStep = 0;

  String? _loadError;
  UserProfile? _baseProfile;
  DateTime? _selectedDateOfBirth;
  String? _selectedGender;
  String? _selectedActivityLevel;

  @override
  void initState() {
    super.initState();
    _fullNameController.text = widget.name;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasShownSuccessMessage && widget.successMessage != null) {
      _hasShownSuccessMessage = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AppSnack.success(context, widget.successMessage!);
      });
    }

    if (_hasLoadedProfile) return;
    _hasLoadedProfile = true;
    _loadExistingProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _allergiesController.dispose();
    _dietaryPreferencesController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingProfile() async {
    final authController = AuthScope.of(context);

    setState(() {
      _isLoadingProfile = true;
      _loadError = null;
    });

    try {
      final profile = await authController.withAuthenticatedSession(
        (session) => _profileService.fetchProfile(session: session),
      );
      if (!mounted) return;

      setState(() {
        _baseProfile = profile;
        _fullNameController.text = profile.fullName ?? widget.name;
        _selectedDateOfBirth = profile.dateOfBirth;
        _selectedGender = _sanitizeText(profile.gender);
        _selectedActivityLevel =
            UserProfile.activityLevels.contains(profile.activityLevel)
            ? profile.activityLevel
            : null;
        _heightController.text = _formatDecimal(profile.heightCm);
        _weightController.text = _formatDecimal(profile.weightKg);
        _allergiesController.text = profile.allergies ?? '';
        _dietaryPreferencesController.text = profile.dietaryPreferences ?? '';
        _isLoadingProfile = false;
      });
    } on AuthFailure catch (error) {
      await _handleUnauthorizedSession(message: error.message);
    } on ApiFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.message;
        _isLoadingProfile = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Unable to open profile setup: $error';
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _pickDateOfBirth() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColours.primary,
              surface: AppColours.secondary,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColours.secondary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate == null) return;

    setState(() {
      _selectedDateOfBirth = selectedDate;
    });
  }

  void _goBack() {
    if (_currentStep == 0) return;
    setState(() => _currentStep -= 1);
  }

  Future<void> _goNext() async {
    if (_isSubmitting) return;

    final validationMessage = _validateStep(_currentStep);
    if (validationMessage != null) {
      AppSnack.warning(context, validationMessage);
      return;
    }

    if (_currentStep == _steps.length - 1) {
      await _submitProfile();
      return;
    }

    setState(() => _currentStep += 1);
  }

  bool get _canAdvanceToNextStep => _validateStep(_currentStep) == null;

  String? _validateStep(int stepIndex) {
    switch (stepIndex) {
      case 0:
        return null;
      case 1:
        return _selectedDateOfBirth == null
            ? 'Please select your date of birth.'
            : null;
      case 2:
        return _sanitizeText(_selectedGender) == null
            ? 'Please select your gender.'
            : null;
      case 3:
        return _validateNumberField(
          label: 'Height',
          value: _heightController.text,
          min: 30,
          max: 300,
        );
      case 4:
        return _validateNumberField(
          label: 'Weight',
          value: _weightController.text,
          min: 2,
          max: 700,
        );
      case 5:
        return _sanitizeText(_selectedActivityLevel) == null
            ? 'Please choose your current activity level.'
            : null;
      case 6:
        return _requireListValue(
          _allergiesController.text,
          emptyMessage: 'Please enter your allergies or type None.',
        );
      case 7:
        return _requireListValue(
          _dietaryPreferencesController.text,
          emptyMessage: 'Please enter your dietary preferences or type None.',
        );
      default:
        return null;
    }
  }

  Future<void> _submitProfile() async {
    final baseProfile =
        _baseProfile ??
        UserProfile(
          userId: 0,
          email: widget.email,
          isActive: true,
          fullName: widget.name,
        );

    final updatedProfile = baseProfile.copyWith(
      fullName: _sanitizeText(_fullNameController.text),
      dateOfBirth: _selectedDateOfBirth,
      gender: _sanitizeText(_selectedGender),
      heightCm: double.tryParse(_heightController.text.trim()),
      weightKg: double.tryParse(_weightController.text.trim()),
      activityLevel: _sanitizeText(_selectedActivityLevel),
      allergies: _normalizeCommaSeparatedValue(_allergiesController.text),
      dietaryPreferences: _normalizeCommaSeparatedValue(
        _dietaryPreferencesController.text,
      ),
      clearFullName: _sanitizeText(_fullNameController.text) == null,
    );

    setState(() => _isSubmitting = true);

    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (_) => ProfileCreationLoadingPage(
          profile: updatedProfile,
          isEditingProfile: widget.isEditingProfile,
        ),
      ),
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (result is UserProfile) {
      Navigator.pop(context, result);
      return;
    }

    if (result is String) {
      AppSnack.error(context, result);
    }
  }

  List<_ProfileSetupStep> get _steps => <_ProfileSetupStep>[
    _ProfileSetupStep(
      title: widget.isEditingProfile ? 'Update profile' : 'Account created',
      subtitle: widget.isEditingProfile
          ? 'Review your account details before updating your health profile.'
          : 'Continue to set up your profile.',
    ),
    const _ProfileSetupStep(
      title: 'Date of birth',
      subtitle: 'Let us know your birthday.',
    ),
    const _ProfileSetupStep(
      title: 'Gender',
      subtitle: 'Select the option that fits you best.',
    ),
    const _ProfileSetupStep(
      title: 'Height',
      subtitle: 'Enter your current height in centimetres.',
    ),
    const _ProfileSetupStep(
      title: 'Weight',
      subtitle: 'Enter your current weight in kilograms.',
    ),
    const _ProfileSetupStep(
      title: 'Activity level',
      subtitle: 'Choose the option that matches your routine.',
    ),
    const _ProfileSetupStep(
      title: 'Allergies',
      subtitle: 'Select quick options or enter your own.',
    ),
    const _ProfileSetupStep(
      title: 'Dietary preferences',
      subtitle: 'Tell us how you prefer to eat.',
    ),
  ];

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
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingProfile) {
      return const Center(
        child: CircularProgressIndicator(color: AppColours.primary),
      );
    }

    if (_loadError != null) {
      return _buildLoadError();
    }

    final step = _steps[_currentStep];
    final canAdvance = !_isSubmitting && _canAdvanceToNextStep;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isEditingProfile ? 'Update profile' : 'Profile setup',
          style: AppTextStyles.headline.copyWith(
            fontSize: 34,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Step ${_currentStep + 1} of ${_steps.length}',
          style: AppTextStyles.bodyMuted.copyWith(
            color: AppColours.textMuted,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 18),
        _buildProgressBar(),
        const SizedBox(height: 22),
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColours.secondary.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppColours.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: AppTextStyles.title.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    step.subtitle,
                    style: AppTextStyles.bodyMuted.copyWith(
                      color: AppColours.textMuted,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildStepContent(),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : _goBack,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColours.onDark,
                      side: BorderSide(color: AppColours.borderLight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Back',
                      style: AppTextStyles.button.copyWith(fontSize: 16),
                    ),
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 14),
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: canAdvance ? _goNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColours.primary,
                    foregroundColor: AppColours.onDark,
                    disabledBackgroundColor: AppColours.primary.withValues(
                      alpha: 0.5,
                    ),
                    disabledForegroundColor: AppColours.textHigh,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppColours.onDark,
                          ),
                        )
                      : Text(
                          _currentStep == _steps.length - 1
                              ? (widget.isEditingProfile
                                    ? 'Update Profile'
                                    : 'Create Profile')
                              : 'Next',
                          style: AppTextStyles.button.copyWith(fontSize: 16),
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColours.secondary.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColours.primary.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              AppIcons.cloudOffRounded,
              color: AppColours.primary,
              size: 44,
            ),
            const SizedBox(height: 18),
            Text(
              'Unable to load profile setup',
              textAlign: TextAlign.center,
              style: AppTextStyles.title.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted.copyWith(
                color: AppColours.textMuted,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loadExistingProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColours.primary,
                  foregroundColor: AppColours.onDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
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
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: List<Widget>.generate(_steps.length, (index) {
        final isActive = index <= _currentStep;
        return Expanded(
          child: Container(
            height: 8,
            margin: EdgeInsets.only(right: index == _steps.length - 1 ? 0 : 8),
            decoration: BoxDecoration(
              color: isActive ? AppColours.primary : AppColours.dividerLight,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildIntroStep();
      case 1:
        return _buildDateOfBirthStep();
      case 2:
        return _buildGenderStep();
      case 3:
        return _buildMeasurementStep(
          controller: _heightController,
          label: 'Height',
          hintText: 'Enter your height',
          suffixText: 'cm',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          helperText: 'We use this to personalise your health profile.',
        );
      case 4:
        return _buildMeasurementStep(
          controller: _weightController,
          label: 'Weight',
          hintText: 'Enter your weight',
          suffixText: 'kg',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          helperText: 'This helps us tailor your recommendations.',
        );
      case 5:
        return _buildActivityLevelStep();
      case 6:
        return _buildSelectableTextStep(
          controller: _allergiesController,
          label: 'Allergies',
          hintText: 'Enter allergies separated by commas',
          helperText: 'Select None if you do not have any allergies.',
          quickOptions: _allergyOptions,
        );
      case 7:
        return _buildSelectableTextStep(
          controller: _dietaryPreferencesController,
          label: 'Dietary preferences',
          hintText: 'Enter dietary preferences separated by commas',
          helperText: 'Select None if you do not have any dietary preferences.',
          quickOptions: _dietaryPreferenceOptions,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIntroStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColours.primary.withValues(alpha: 0.16),
            border: Border.all(
              color: AppColours.primary.withValues(alpha: 0.24),
            ),
          ),
          child: const Icon(
            AppIcons.checkRounded,
            color: AppColours.primary,
            size: 38,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          widget.isEditingProfile
              ? 'Update your profile details'
              : 'Welcome, ${widget.name}!',
          style: AppTextStyles.title.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.isEditingProfile
              ? 'Your account is linked to ${widget.email}. Use this guided flow to review and update your saved profile details.'
              : 'Your account is ready for ${widget.email}. Next, we will walk through a few quick profile details.',
          style: AppTextStyles.body.copyWith(
            color: AppColours.textHigh,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Display name',
          style: AppTextStyles.label.copyWith(
            color: AppColours.onDark,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _fullNameController,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: AppColours.onDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColours.inputFill,
            hintText: 'Enter your display name',
            hintStyle: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: AppColours.textFaint,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(
                color: AppColours.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Email',
          style: AppTextStyles.label.copyWith(
            color: AppColours.onDark,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: AppColours.inputFill.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(
            widget.email,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: AppColours.textMuted,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateOfBirthStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _pickDateOfBirth,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColours.inputFill,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _selectedDateOfBirth == null
                    ? AppColours.transparent
                    : AppColours.primary.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColours.primary.withValues(alpha: 0.14),
                  ),
                  child: const Icon(
                    AppIcons.calendarMonthRounded,
                    color: AppColours.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedDateOfBirth == null
                            ? 'Select date of birth'
                            : _formatDate(_selectedDateOfBirth!),
                        style: AppTextStyles.title.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to choose your date of birth',
                        style: AppTextStyles.bodyMuted.copyWith(
                          color: AppColours.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: AppTextStyles.label.copyWith(
            color: AppColours.onDark,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _selectedGender,
          dropdownColor: AppColours.secondary,
          iconEnabledColor: AppColours.textMuted,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: AppColours.onDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          items: _genderOptions
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() => _selectedGender = value);
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColours.inputFill,
            hintText: 'Select gender',
            hintStyle: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: AppColours.textFaint,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(
                color: AppColours.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeasurementStep({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required String suffixText,
    required TextInputType keyboardType,
    required String helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: AppColours.onDark,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => FocusScope.of(context).unfocus(),
          onEditingComplete: () => FocusScope.of(context).unfocus(),
          onChanged: (_) => setState(() {}),
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: AppColours.onDark,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColours.inputFill,
            hintText: hintText,
            hintStyle: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: AppColours.textFaint,
            ),
            suffixText: suffixText,
            suffixStyle: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: AppColours.textMuted,
              fontWeight: FontWeight.w700,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(
                color: AppColours.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          helperText,
          style: AppTextStyles.bodyMuted.copyWith(
            color: AppColours.textMuted,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityLevelStep() {
    return Column(
      children: UserProfile.activityLevels.map((level) {
        final isSelected = _selectedActivityLevel == level;
        final description =
            _activityLevelDescriptions[level] ?? 'Choose the best fit for you.';
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () {
              setState(() => _selectedActivityLevel = level);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColours.inputFill,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected
                      ? AppColours.primary
                      : AppColours.dividerLightSubtle,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          level,
                          style: AppTextStyles.body.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: AppTextStyles.bodyMuted.copyWith(
                            color: AppColours.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      isSelected
                          ? AppIcons.radioButtonCheckedRounded
                          : AppIcons.radioButtonOffRounded,
                      color: isSelected
                          ? AppColours.primary
                          : AppColours.textFaint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSelectableTextStep({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required String helperText,
    required List<String> quickOptions,
  }) {
    final selectedValues = _splitCommaSeparated(controller.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick options:',
          style: AppTextStyles.label.copyWith(
            color: AppColours.onDark,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: quickOptions.map((option) {
            final isSelected = selectedValues.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (_) => _toggleCommaSeparatedValue(controller, option),
              labelStyle: AppTextStyles.body.copyWith(
                color: AppColours.onDark,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: AppColours.inputFill,
              selectedColor: AppColours.primary.withValues(alpha: 0.28),
              checkmarkColor: AppColours.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: isSelected
                      ? AppColours.primary
                      : AppColours.dividerLightMuted,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 22),
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: AppColours.onDark,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: AppColours.onDark,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColours.inputFill,
            hintText: hintText,
            hintStyle: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: AppColours.textFaint,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(
                color: AppColours.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          helperText,
          style: AppTextStyles.bodyMuted.copyWith(
            color: AppColours.textMuted,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  void _toggleCommaSeparatedValue(
    TextEditingController controller,
    String value,
  ) {
    final selections = _splitCommaSeparated(controller.text).toList();
    if (value == 'None') {
      if (selections.contains('None') && selections.length == 1) {
        controller.text = '';
      } else {
        controller.text = 'None';
      }
      setState(() {});
      return;
    }

    selections.remove('None');
    if (selections.contains(value)) {
      selections.remove(value);
    } else {
      selections.add(value);
    }

    controller.text = selections.join(', ');
    setState(() {});
  }

  List<String> _splitCommaSeparated(String value) {
    final entries = value
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    final uniqueEntries = <String>[];
    for (final entry in entries) {
      if (!uniqueEntries.contains(entry)) {
        uniqueEntries.add(entry);
      }
    }
    return uniqueEntries;
  }

  String? _requireListValue(String value, {required String emptyMessage}) {
    return _normalizeCommaSeparatedValue(value) == null ? emptyMessage : null;
  }

  String? _normalizeCommaSeparatedValue(String value) {
    final values = _splitCommaSeparated(value);
    if (values.isEmpty) return null;
    return values.join(', ');
  }

  String? _sanitizeText(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _validateNumberField({
    required String label,
    required String value,
    required double min,
    required double max,
  }) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '$label is required.';

    final parsed = double.tryParse(trimmed);
    if (parsed == null) return '$label must be a number.';
    if (parsed < min || parsed > max) {
      return '$label must be between ${_formatDecimal(min)} and ${_formatDecimal(max)}.';
    }

    return null;
  }

  String _formatDecimal(double? value) {
    if (value == null) return '';
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  String _formatDate(DateTime value) {
    final month = _monthName(value.month);
    return '$month ${value.day}, ${value.year}';
  }

  String _monthName(int month) {
    return switch (month) {
      1 => 'January',
      2 => 'February',
      3 => 'March',
      4 => 'April',
      5 => 'May',
      6 => 'June',
      7 => 'July',
      8 => 'August',
      9 => 'September',
      10 => 'October',
      11 => 'November',
      12 => 'December',
      _ => '',
    };
  }
}

class _ProfileSetupStep {
  const _ProfileSetupStep({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}
