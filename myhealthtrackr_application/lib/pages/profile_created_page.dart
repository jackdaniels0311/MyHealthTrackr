import 'package:flutter/material.dart';
import 'package:myhealthtrackr/themes/app_icons.dart';
import 'package:myhealthtrackr/pages/goals_setup_page.dart';
import 'package:myhealthtrackr/pages/home_page.dart';
import 'package:myhealthtrackr/services/profile_service.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';
import 'package:myhealthtrackr/themes/app_text_styles.dart';
import 'package:myhealthtrackr/widgets/app_snack.dart';

class ProfileCreatedPage extends StatefulWidget {
  const ProfileCreatedPage({super.key, this.successMessage, this.profile});

  final String? successMessage;
  final UserProfile? profile;

  @override
  State<ProfileCreatedPage> createState() => _ProfileCreatedPageState();
}

class _ProfileCreatedPageState extends State<ProfileCreatedPage> {
  bool _hasShownSuccessMessage = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasShownSuccessMessage || widget.successMessage == null) return;

    _hasShownSuccessMessage = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppSnack.success(context, widget.successMessage!);
    });
  }

  void _continueToHome() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      HomePage.routeName,
      (_) => false,
    );
  }

  void _goToGoalsSetup() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            GoalsSetupPage(initialStartingWeightKg: widget.profile?.weightKg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColours.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColours.primary.withValues(alpha: 0.16),
                  border: Border.all(
                    color: AppColours.primary.withValues(alpha: 0.26),
                  ),
                ),
                child: const Icon(
                  AppIcons.checkRounded,
                  color: AppColours.primary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Profile created successfully',
                style: AppTextStyles.headline.copyWith(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Your profile has been created successfully. Would you like to set goals now or continue to the home page?',
                style: AppTextStyles.bodyMuted.copyWith(
                  color: AppColours.textMuted,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _goToGoalsSetup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColours.primary,
                    foregroundColor: AppColours.onDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Set goals now',
                    style: AppTextStyles.button.copyWith(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _continueToHome,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColours.onDark,
                    side: BorderSide(color: AppColours.borderLight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Continue to home page',
                    style: AppTextStyles.button.copyWith(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
