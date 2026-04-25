import 'package:flutter/material.dart';
import 'package:myhealthtrackr/themes/app_icons.dart';
import 'package:myhealthtrackr/pages/create_account_page.dart';
import 'package:myhealthtrackr/pages/home_page.dart';
import 'package:myhealthtrackr/services/auth_scope.dart';
import 'package:myhealthtrackr/services/auth_service.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';
import 'package:myhealthtrackr/themes/app_text_styles.dart';
import 'package:myhealthtrackr/widgets/app_snack.dart';

// Stateful widget that represents the sign-in screen.
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  static const routeName = '/sign-in';

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  // default password to be hidden when entering
  bool _obscurePassword = true;
  // default login button to be disabled
  bool _canSubmit = false;
  //  Prevent double-taps + allow showing loading UI
  bool _isSigningIn = false;

  // Ensure valid email is entered so login button can be enabled
  bool _isValidEmail(String email) {
    final trimmed = email.trim();
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(trimmed);
  }

  // function to check that email is valid & password is provided to enable login
  void _updateCanSubmit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final emailValid = _isValidEmail(email);
    final passwordFilled = password.isNotEmpty;

    setState(() {
      _canSubmit = emailValid && passwordFilled;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _emailFocusNode.addListener(_onFocusChange);
    _passwordFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {});
  }

  ///  Called when the Log In button is pressed
  Future<void> _handleLogin() async {
    // Do nothing if not ready or already signing in
    if (!_canSubmit || _isSigningIn) return;

    // Validate the form fields (email validator + any others)
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _isSigningIn = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final authController = AuthScope.of(context);
      await authController.login(email: email, password: password);

      if (!mounted) return;

      // Navigate to Home and remove everything else from the stack.
      Navigator.pushNamedAndRemoveUntil(
        context,
        HomePage.routeName,
        (_) => false,
      );
    } on AuthFailure catch (e) {
      if (!mounted) return;
      AppSnack.error(context, e.message);
    } catch (e) {
      if (!mounted) return;
      AppSnack.error(context, 'Sign in error: $e');
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundCacheWidth =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round();

    // Scaffold with a Stack so we can layer background, overlay, top content and
    // a bottom sheet-like login form.
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          /// Background image
          Image.asset(
            'assets/images/background.jpg',
            fit: BoxFit.cover,
            cacheWidth: backgroundCacheWidth,
            filterQuality: FilterQuality.low,
          ),

          /// Gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColours.overlayLight,
                  AppColours.transparent,
                  AppColours.overlayDark,
                ],
              ),
            ),
          ),

          /// Top content (SafeArea only here)
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Column(
                children: [
                  /// Back button with background
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColours.secondary,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            AppIcons.arrowBack,
                            color: AppColours.onDark,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// Logo
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: "MyHealthTrackr",
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 45,
                                fontWeight: FontWeight.bold,
                                color: AppColours.onDark,
                              ),
                            ),
                            TextSpan(
                              text: ".",
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 45,
                                fontWeight: FontWeight.bold,
                                color: AppColours.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// Login form pinned to bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.82,
              ),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColours.secondary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(45)),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: _buildLoginForm(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Builds the vertical login form: title, inputs, actions, and social buttons.
  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              "Welcome back!",
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColours.onDark,
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "Email",
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: AppColours.onDark,
            ),
          ),
          const SizedBox(height: 8),

          TextFormField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: AppColours.onDark,
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) {
              final v = value?.trim() ?? '';
              if (v.isEmpty) return 'Email is required';
              if (!_isValidEmail(v)) return 'Enter a valid email';
              return null;
            },
            onChanged: (_) => _updateCanSubmit(),
            onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColours.inputFill,
              prefixIcon: const Icon(
                AppIcons.email,
                color: AppColours.textMuted,
              ),
              hintText: 'Enter email',
              hintStyle: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: AppColours.textFaint,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: AppColours.primary,
                  width: 2,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "Password",
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: AppColours.onDark,
            ),
          ),
          const SizedBox(height: 8),

          TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: AppColours.onDark,
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) {
              final v = value ?? '';
              if (v.isEmpty) return 'Password is required';
              if (v.trim().length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
            onChanged: (_) => _updateCanSubmit(),
            onFieldSubmitted: (_) => _handleLogin(),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColours.inputFill,
              prefixIcon: const Icon(
                AppIcons.lock,
                color: AppColours.textMuted,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? AppIcons.visibility
                      : AppIcons.visibilityOff,
                  color: AppColours.textMuted,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              hintText: 'Enter password',
              hintStyle: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: AppColours.textFaint,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: AppColours.primary,
                  width: 2,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text(
                "Forgot Password?",
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: AppColours.onDark,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _canSubmit
                    ? AppColours.primaryActive
                    : AppColours.primaryPressed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: _canSubmit ? 2 : 0,
              ),
              //  Use the new handler. Disable while signing in.
              onPressed: _isSigningIn ? null : _handleLogin,
              child: _isSigningIn
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColours.onDark,
                      ),
                    )
                  : const Text(
                      "Log In",
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 16,
                        color: AppColours.onDark,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          const Center(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: AppColours.onDark,
                ),
                children: [TextSpan(text: "Don’t have an account? ")],
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, CreateAccountPage.routeName);
            },
            child: const Center(
              child: Text(
                'Create Account',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: AppColours.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Center(
            child: Text(
              "Continue with:",
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: AppColours.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialButton('assets/icons/apple.png'),
              const SizedBox(width: 12),
              _buildSocialButton('assets/icons/google.png'),
              const SizedBox(width: 12),
              _buildSocialButton('assets/icons/facebook.png'),
            ],
          ),
        ],
      ),
    );
  }

  // Small helper builder for social sign-in buttons.
  Widget _buildSocialButton(String assetPath) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColours.inputFill,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Image.asset(assetPath, width: 32, height: 32),
    );
  }
}
