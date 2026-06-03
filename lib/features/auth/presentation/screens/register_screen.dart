import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../widgets/orleon_ambient_background.dart';
import '../widgets/orleon_field.dart';
import '../widgets/orleon_logo.dart';
import '../widgets/orleon_primary_button.dart';

const _kNavy = Color(0xFF0A0E12);
const _kGold = Color(0xFFF5C518);
const _kGreen = Color(0xFF00E676);
const _kGreenDeep = Color(0xFF00C853);
const _kRed = Color(0xFFFF5252);

class _RoleInfo {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _RoleInfo(this.value, this.label, this.icon, this.color);
}

const _kRoles = [
  _RoleInfo('PLAYER_ADULT', 'auth.role_player_adult', Icons.sports_soccer_rounded, _kGreen),
  _RoleInfo('PLAYER_CHILD', 'auth.role_player_child', Icons.child_care_rounded, _kGreenDeep),
  _RoleInfo('PARENT', 'auth.role_parent', Icons.family_restroom, Color(0xFFB388FF)),
  _RoleInfo('COACH', 'auth.role_coach', Icons.sports_rounded, _kGold),
  _RoleInfo('CLUB_OWNER', 'auth.role_club_owner', Icons.shield_rounded, Color(0xFF2979FF)),
  _RoleInfo('CLUB_MANAGER', 'auth.role_club_manager', Icons.manage_accounts, Color(0xFFFF9800)),
  _RoleInfo('TOURNAMENT_ORGANIZER', 'auth.role_organizer', Icons.emoji_events, Color(0xFFFFC107)),
  _RoleInfo('FIELD_OWNER', 'auth.role_field_owner', Icons.stadium_rounded, Color(0xFF26C6DA)),
  _RoleInfo('REFEREE', 'auth.role_referee', Icons.gavel_rounded, _kRed),
];

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _step = 1;
  String _selectedRole = 'PLAYER_ADULT';
  bool _agreedToTerms = false;
  bool _obscurePass = true;
  DateTime? _dob;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();

  _RoleInfo get _currentRole =>
      _kRoles.firstWhere((r) => r.value == _selectedRole);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2005, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _kGreen,
            onPrimary: Colors.black,
            surface: Color(0xFF161B22),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dob = picked;
        _dobCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _register(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('auth.select_dob'.tr()),
        backgroundColor: _kRed,
      ));
      return;
    }
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('auth.agree_terms'.tr()),
        backgroundColor: _kRed,
      ));
      return;
    }
    FocusScope.of(context).unfocus();
    final success = await auth.register({
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'password': _passCtrl.text,
      'role': _selectedRole,
      'date_of_birth': _dob!.toIso8601String().split('T').first,
    });
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('auth.account_created'.tr())),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.error ?? 'auth.registration_failed'.tr()),
        backgroundColor: _kRed,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final role = _currentRole;
    return Scaffold(
      backgroundColor: isDark ? _kNavy : Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: role.color),
            duration: const Duration(milliseconds: 280),
            builder: (context, color, _) =>
                OrleonAmbientBackground(accent: color ?? role.color),
          ),
          SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top bar
                  SizedBox(
                    height: 38,
                    child: Row(
                      children: [
                        if (_step == 2)
                          GestureDetector(
                            onTap: () => setState(() => _step = 1),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: cs.onSurface.withValues(alpha: 0.05),
                                border: Border.all(
                                  color: cs.onSurface.withValues(alpha: 0.08),
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 16,
                                color: cs.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  OrleonBrandHeader(
                    subtitle: _step == 1
                        ? 'auth.choose_your_role'.tr()
                        : 'auth.tell_us_about_yourself'.tr(),
                  ),
                  const SizedBox(height: 16),
                  // Step indicator
                  Row(
                    children: [
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          height: 3,
                          decoration: BoxDecoration(
                            color: _kGreen,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          height: 3,
                          decoration: BoxDecoration(
                            color: _step == 2
                                ? _kGreen
                                : cs.onSurface.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.topCenter,
                      children: [...previous, if (current != null) current],
                    ),
                    child: _step == 1 ? _buildStep1() : _buildStep2(role),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'auth.already_have_account'.tr(),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushReplacementNamed(context, '/login'),
                        child: Text(
                          'auth.log_in'.tr(),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _kGold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      key: const ValueKey('step1'),
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.92,
          ),
          itemCount: _kRoles.length,
          itemBuilder: (context, index) {
            final r = _kRoles[index];
            final selected = _selectedRole == r.value;
            return GestureDetector(
              onTap: () => setState(() => _selectedRole = r.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: selected
                      ? r.color.withValues(alpha: 0.1)
                      : onSurface.withValues(alpha: 0.05),
                  border: Border.all(
                    color: selected
                        ? r.color.withValues(alpha: 0.4)
                        : onSurface.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: r.color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(r.icon, size: 18, color: r.color),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      r.label.tr(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? r.color
                            : onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 22),
        OrleonPrimaryButton(
          label: 'auth.continue_btn'.tr(),
          onPressed: () => setState(() => _step = 2),
        ),
      ],
    );
  }

  Widget _buildStep2(_RoleInfo role) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Role badge
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: role.color.withValues(alpha: 0.1),
            border: Border.all(color: role.color.withValues(alpha: 0.28)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: role.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(role.icon, size: 14, color: role.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'auth.signing_up_as'.tr(),
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    Text(
                      role.label.tr(),
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: role.color,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _step = 1),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'auth.change'.tr(),
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OrleonField(
                label: 'auth.full_name'.tr(),
                controller: _nameCtrl,
                icon: Icons.person_outline,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'auth.name_required'.tr() : null,
              ),
              const SizedBox(height: 12),
              OrleonField(
                label: 'auth.email'.tr(),
                controller: _emailCtrl,
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'auth.email_required'.tr();
                  if (!v.contains('@')) return 'auth.enter_valid_email'.tr();
                  return null;
                },
              ),
              const SizedBox(height: 12),
              OrleonField(
                label: 'auth.password_min_chars'.tr(),
                controller: _passCtrl,
                icon: Icons.lock_outline,
                obscureText: _obscurePass,
                trailing: IconButton(
                  icon: Icon(
                    _obscurePass ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: onSurface.withValues(alpha: 0.4),
                  ),
                  onPressed: () =>
                      setState(() => _obscurePass = !_obscurePass),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'auth.password_required'.tr();
                  if (v.length < 6) return 'auth.minimum_6_chars'.tr();
                  return null;
                },
              ),
              const SizedBox(height: 12),
              OrleonField(
                label: 'auth.date_of_birth'.tr(),
                controller: _dobCtrl,
                icon: Icons.cake_outlined,
                readOnly: true,
                hintText: 'dd/MM/yyyy',
                onTap: _pickDate,
              ),
              // Terms checkbox
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 22),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () =>
                      setState(() => _agreedToTerms = !_agreedToTerms),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: _agreedToTerms
                              ? _kGreen.withValues(alpha: 0.16)
                              : Colors.transparent,
                          border: Border.all(
                            color: _agreedToTerms
                                ? _kGreen
                                : onSurface.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: _agreedToTerms
                            ? const Icon(Icons.check, size: 12, color: _kGreen)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: onSurface.withValues(alpha: 0.5),
                              height: 1.5,
                            ),
                            children: [
                              TextSpan(text: 'auth.i_agree_to'.tr()),
                              TextSpan(
                                text: 'auth.terms'.tr(),
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _kGreen,
                                  height: 1.5,
                                ),
                              ),
                              TextSpan(text: 'auth.and'.tr()),
                              TextSpan(
                                text: 'auth.privacy_policy'.tr(),
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _kGreen,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Consumer<AuthProvider>(
                builder: (context, auth, _) => OrleonPrimaryButton(
                  label:
                      auth.isLoading ? 'auth.creating_account'.tr() : 'auth.create_account_btn'.tr(),
                  loading: auth.isLoading,
                  onPressed: auth.isLoading ? null : () => _register(auth),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
