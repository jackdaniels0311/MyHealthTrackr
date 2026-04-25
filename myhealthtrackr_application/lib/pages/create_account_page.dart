import 'package:myhealthtrackr/pages/account_creation_loading_page.dart';
import 'package:flutter/material.dart';
import 'package:myhealthtrackr/themes/app_icons.dart';
import 'package:myhealthtrackr/pages/sign_in_page.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';
import 'package:myhealthtrackr/themes/app_text_styles.dart';
import 'package:myhealthtrackr/widgets/app_snack.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  static const routeName = '/create-account';

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _canSubmit = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    _nameFocusNode.addListener(_onFocusChange);
    _emailFocusNode.addListener(_onFocusChange);
    _passwordFocusNode.addListener(_onFocusChange);
    _confirmPasswordFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {});
  }

  bool _isValidEmail(String email) {
    final trimmed = email.trim();
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(trimmed);
  }

  void _updateCanSubmit() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      _canSubmit =
          name.isNotEmpty &&
          _isValidEmail(email) &&
          password.length >= 8 &&
          password == confirmPassword;
    });
  }

  Future<void> _handleCreateAccount() async {
    if (_isSubmitting || !_canSubmit) return;

    final formIsValid = _formKey.currentState?.validate() ?? false;
    if (!formIsValid) return;

    setState(() => _isSubmitting = true);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final errorMessage = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => AccountCreationLoadingPage(
          name: name,
          email: email,
          password: password,
        ),
      ),
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (errorMessage != null) {
      AppSnack.error(context, errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundCacheWidth =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/background.jpg',
            fit: BoxFit.cover,
            cacheWidth: backgroundCacheWidth,
            filterQuality: FilterQuality.low,
          ),
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
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
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
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'MyHealthTrackr',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 45,
                                fontWeight: FontWeight.bold,
                                color: AppColours.onDark,
                              ),
                            ),
                            TextSpan(
                              text: '.',
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
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.8,
              ),
              decoration: const BoxDecoration(
                color: AppColours.secondary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(45)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                  child: _buildCreateAccountForm(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateAccountForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Create Account',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColours.onDark,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Set up your account and start tracking your health.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted.copyWith(
                color: AppColours.textMuted,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildFieldLabel('Full name'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            textInputAction: TextInputAction.next,
            hintText: 'Enter full name',
            prefixIcon: AppIcons.personOutlineRounded,
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return 'Full name is required';
              if (text.length > 255) return 'Full name is too long';
              return null;
            },
            onChanged: (_) => _updateCanSubmit(),
            onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
          ),
          const SizedBox(height: 18),
          _buildFieldLabel('Email'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            hintText: 'Enter email',
            prefixIcon: AppIcons.emailOutlined,
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return 'Email is required';
              if (!_isValidEmail(text)) return 'Enter a valid email';
              return null;
            },
            onChanged: (_) => _updateCanSubmit(),
            onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
          ),
          const SizedBox(height: 18),
          _buildFieldLabel('Password'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            hintText: 'Create password',
            prefixIcon: AppIcons.lockOutlineRounded,
            suffix: IconButton(
              icon: Icon(
                _obscurePassword ? AppIcons.visibility : AppIcons.visibilityOff,
                color: AppColours.textMuted,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
            validator: (value) {
              final text = value ?? '';
              if (text.isEmpty) return 'Password is required';
              if (text.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
            onChanged: (_) => _updateCanSubmit(),
            onFieldSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
          ),
          const SizedBox(height: 18),
          _buildFieldLabel('Confirm password'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocusNode,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            hintText: 'Confirm password',
            prefixIcon: AppIcons.lockResetRounded,
            suffix: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? AppIcons.visibility
                    : AppIcons.visibilityOff,
                color: AppColours.textMuted,
              ),
              onPressed: () {
                setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                );
              },
            ),
            validator: (value) {
              final text = value ?? '';
              if (text.isEmpty) return 'Please confirm your password';
              if (text != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            onChanged: (_) => _updateCanSubmit(),
            onFieldSubmitted: (_) => _handleCreateAccount(),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleCreateAccount,
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
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColours.onDark,
                      ),
                    )
                  : const Text(
                      'Create Account',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 16,
                        color: AppColours.onDark,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Already have an account?',
              style: AppTextStyles.body.copyWith(color: AppColours.onDark),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushReplacementNamed(context, SignInPage.routeName);
            },
            child: const Center(
              child: Text(
                'Sign In',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: AppColours.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        color: AppColours.onDark,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData prefixIcon,
    required String? Function(String?) validator,
    required ValueChanged<String> onChanged,
    required ValueChanged<String> onFieldSubmitted,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: const TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        color: AppColours.onDark,
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColours.inputFill,
        prefixIcon: Icon(prefixIcon, color: AppColours.textMuted),
        suffixIcon: suffix,
        hintText: hintText,
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
          borderSide: const BorderSide(color: AppColours.primary, width: 2),
        ),
      ),
    );
  }
}
