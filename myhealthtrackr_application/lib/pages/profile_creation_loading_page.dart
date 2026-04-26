import 'package:flutter/material.dart';
import 'package:myhealthtrackr/pages/profile_created_page.dart';
import 'package:myhealthtrackr/pages/start_page.dart';
import 'package:myhealthtrackr/services/api_client.dart';
import 'package:myhealthtrackr/services/auth_scope.dart';
import 'package:myhealthtrackr/services/auth_service.dart';
import 'package:myhealthtrackr/services/profile_service.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';
import 'package:myhealthtrackr/themes/app_text_styles.dart';

class ProfileCreationLoadingPage extends StatefulWidget {
  const ProfileCreationLoadingPage({
    super.key,
    required this.profile,
    this.isEditingProfile = false,
  });

  final UserProfile profile;
  final bool isEditingProfile;

  @override
  State<ProfileCreationLoadingPage> createState() =>
      _ProfileCreationLoadingPageState();
}

class _ProfileCreationLoadingPageState
    extends State<ProfileCreationLoadingPage> {
  final ProfileService _profileService = const ProfileService();

  bool _hasStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasStarted) return;
    _hasStarted = true;
    _saveProfile();
  }

  Future<void> _saveProfile() async {
    final authController = AuthScope.of(context);

    try {
      final savedProfile = await authController.withAuthenticatedSession(
        (session) => _profileService.updateProfile(
          session: session,
          profile: widget.profile,
        ),
      );

      if (!mounted) return;

      if (widget.isEditingProfile) {
        Navigator.of(context).pop<UserProfile>(savedProfile);
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => ProfileCreatedPage(
            successMessage: 'Profile created successfully',
            profile: savedProfile,
          ),
        ),
        (_) => false,
      );
    } on AuthFailure catch (error) {
      await _handleUnauthorizedSession(message: error.message);
    } on ApiFailure catch (error) {
      if (!mounted) return;
      Navigator.of(context).pop<String>(error.message);
    } catch (error) {
      if (!mounted) return;
      Navigator.of(context).pop<String>(
        widget.isEditingProfile
            ? 'Unable to update profile: $error'
            : 'Unable to create profile: $error',
      );
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
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColours.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColours.primary.withValues(alpha: 0.14),
                      border: Border.all(
                        color: AppColours.primary.withValues(alpha: 0.24),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppColours.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    widget.isEditingProfile
                        ? 'Updating your profile'
                        : 'Creating your profile',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headline.copyWith(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.isEditingProfile
                        ? 'Please wait while we save your updated profile details to the backend.'
                        : 'Please wait while we save your health profile details to the backend.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMuted.copyWith(
                      color: AppColours.textMuted,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
