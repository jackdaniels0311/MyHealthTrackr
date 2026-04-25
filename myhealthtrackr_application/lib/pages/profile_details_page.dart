import 'package:flutter/material.dart';
import 'package:myhealthtrackr/themes/app_icons.dart';
import 'package:myhealthtrackr/pages/account_created_page.dart';
import 'package:myhealthtrackr/services/profile_service.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';
import 'package:myhealthtrackr/themes/app_text_styles.dart';
import 'package:myhealthtrackr/widgets/app_snack.dart';

class ProfileDetailsPage extends StatefulWidget {
  const ProfileDetailsPage({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<ProfileDetailsPage> createState() => _ProfileDetailsPageState();
}

class _ProfileDetailsPageState extends State<ProfileDetailsPage> {
  static const Color _panelBorder = AppColours.panelBorder;
  static const Color _mutedText = AppColours.textSubtle;

  late UserProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
  }

  Future<void> _openUpdateProfileWizard() async {
    final updatedProfile = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute(
        builder: (_) => AccountCreatedPage(
          email: _profile.email,
          name: _profile.fullName ?? '',
          isEditingProfile: true,
        ),
      ),
    );

    if (!mounted || updatedProfile == null) return;

    setState(() => _profile = updatedProfile);
    AppSnack.success(context, 'Profile updated successfully');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColours.background,
      body: Stack(
        children: [
          _buildBackdropAccent(
            alignment: const Alignment(-0.95, -1.0),
            size: 220,
            colour: AppColours.primary.withValues(alpha: 0.10),
          ),
          _buildBackdropAccent(
            alignment: const Alignment(1.0, -0.45),
            size: 200,
            colour: AppColours.primary.withValues(alpha: 0.08),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 18),
                  _buildIdentityCard(),
                  const SizedBox(height: 22),
                  _buildSection(
                    title: 'Account overview',
                    subtitle: 'A summary of your account details.',
                    child: Column(
                      children: [
                        _DetailRow(
                          label: 'Display name',
                          value: _profile.displayName,
                          icon: AppIcons.badgeOutlined,
                        ),
                        const SizedBox(height: 16),
                        _DetailRow(
                          label: 'Email',
                          value: _profile.email,
                          icon: AppIcons.alternateEmailRounded,
                        ),
                        const SizedBox(height: 16),
                        _DetailRow(
                          label: 'Status',
                          value: _profile.isActive
                              ? 'Active account'
                              : 'Inactive account',
                          icon: AppIcons.shieldOutlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _buildSection(
                    title: 'Health details',
                    subtitle: 'An overview of your health details.',
                    child: Column(
                      children: [
                        _DetailRow(
                          label: 'Date of birth',
                          value: _formatDate(_profile.dateOfBirth),
                          icon: AppIcons.calendarMonthRounded,
                        ),
                        const SizedBox(height: 16),
                        _DetailRow(
                          label: 'Age',
                          value: _profile.age?.toString() ?? 'Not set',
                          icon: AppIcons.cakeOutlined,
                        ),
                        const SizedBox(height: 16),
                        _DetailRow(
                          label: 'Gender',
                          value: _displayValue(_profile.gender),
                          icon: AppIcons.wcRounded,
                        ),
                        const SizedBox(height: 16),
                        _DetailRow(
                          label: 'Height',
                          value: _profile.heightCm == null
                              ? 'Not set'
                              : '${_formatNumber(_profile.heightCm!)} cm',
                          icon: AppIcons.heightRounded,
                        ),
                        const SizedBox(height: 16),
                        _DetailRow(
                          label: 'Weight',
                          value: _profile.weightKg == null
                              ? 'Not set'
                              : '${_formatNumber(_profile.weightKg!)} kg',
                          icon: AppIcons.monitorWeightOutlined,
                        ),
                        const SizedBox(height: 16),
                        _DetailRow(
                          label: 'Activity level',
                          value: _displayValue(_profile.activityLevel),
                          icon: AppIcons.directionsRunRounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _buildSection(
                    title: 'Dietary profile',
                    subtitle: 'Your Allergies and dietary preferences .',
                    child: Column(
                      children: [
                        _DetailRow(
                          label: 'Dietary preferences',
                          value: _displayValue(_profile.dietaryPreferences),
                          icon: AppIcons.restaurantMenuRounded,
                          isMultiline: true,
                        ),
                        const SizedBox(height: 16),
                        _DetailRow(
                          label: 'Allergies',
                          value: _displayValue(_profile.allergies),
                          icon: AppIcons.warningAmberRounded,
                          isMultiline: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _openUpdateProfileWizard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColours.primary,
                        foregroundColor: AppColours.onDark,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        'Edit Profile',
                        style: AppTextStyles.button.copyWith(fontSize: 17),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColours.onDark,
                        side: BorderSide(color: AppColours.borderLight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        'Back',
                        style: AppTextStyles.button.copyWith(fontSize: 17),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppColours.background.withValues(alpha: 0.96),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColours.secondary,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _panelBorder),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                AppIcons.arrowBackRounded,
                color: AppColours.onDark,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User Profile',
                  style: AppTextStyles.headline.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'An overview of your profile details.',
                  style: AppTextStyles.bodyMuted.copyWith(
                    color: _mutedText,
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColours.secondary.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _panelBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColours.shadowMedium,
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColours.primary,
                  AppColours.primary.withValues(alpha: 0.72),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                _profile.initials,
                style: AppTextStyles.headline.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _profile.displayName,
                  style: AppTextStyles.headline.copyWith(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _profile.email,
                  style: AppTextStyles.bodyMuted.copyWith(
                    color: _mutedText,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColours.secondary.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.title.copyWith(
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTextStyles.bodyMuted.copyWith(
              color: _mutedText,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildBackdropAccent({
    required Alignment alignment,
    required double size,
    required Color colour,
  }) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [colour, AppColours.transparent]),
          ),
        ),
      ),
    );
  }

  String _displayValue(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? 'Not set' : trimmed;
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Not set';
    final month = _monthName(value.month);
    return '$month ${value.day}, ${value.year}';
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.isMultiline = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool isMultiline;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColours.background.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: isMultiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColours.primary.withValues(alpha: 0.14),
            ),
            child: Icon(icon, color: AppColours.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    color: AppColours.textSubtle,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
