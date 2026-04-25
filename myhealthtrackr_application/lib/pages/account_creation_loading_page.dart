import 'package:flutter/material.dart';
import 'package:myhealthtrackr/pages/account_created_page.dart';
import 'package:myhealthtrackr/services/auth_scope.dart';
import 'package:myhealthtrackr/services/auth_service.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';
import 'package:myhealthtrackr/themes/app_text_styles.dart';

class AccountCreationLoadingPage extends StatefulWidget {
  const AccountCreationLoadingPage({
    super.key,
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;

  @override
  State<AccountCreationLoadingPage> createState() =>
      _AccountCreationLoadingPageState();
}

class _AccountCreationLoadingPageState
    extends State<AccountCreationLoadingPage> {
  final AuthService _authService = const AuthService();

  bool _hasStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasStarted) return;
    _hasStarted = true;
    _createAccount();
  }

  Future<void> _createAccount() async {
    try {
      await _authService.createAccount(
        name: widget.name,
        email: widget.email,
        password: widget.password,
      );

      if (!mounted) return;

      await AuthScope.of(
        context,
      ).login(email: widget.email, password: widget.password);

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => AccountCreatedPage(
            email: widget.email,
            name: widget.name,
            successMessage: 'Account created successfully',
          ),
        ),
        (_) => false,
      );
    } on AuthFailure catch (error) {
      if (!mounted) return;
      Navigator.of(context).pop<String>(error.message);
    } catch (error) {
      if (!mounted) return;
      Navigator.of(context).pop<String>('Create account error: $error');
    }
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
                    'Creating your account',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headline.copyWith(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Please wait while we create your account and prepare your profile setup.',
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
