import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../widgets/orleon_ambient_background.dart';
import '../widgets/orleon_field.dart';
import '../widgets/orleon_logo.dart';
import '../widgets/orleon_primary_button.dart';

const _kNavy = Color(0xFF0A0E12);
const _kGold = Color(0xFFF5C518);
const _kGreen = Color(0xFF00E676);
const _kRed = Color(0xFFFF5252);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePass = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final success = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Login failed'),
          backgroundColor: _kRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      backgroundColor: isDark ? _kNavy : Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const OrleonAmbientBackground(),
          SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const OrleonBrandHeader(subtitle: 'Welcome back'),
                    const SizedBox(height: 28),
                    OrleonField(
                      label: 'Email',
                      controller: _emailCtrl,
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    OrleonField(
                      label: 'Password',
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
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Password is required' : null,
                    ),
                    // Remember me + Forgot password row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 12, 4, 22),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(5),
                            onTap: () =>
                                setState(() => _rememberMe = !_rememberMe),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: _rememberMe
                                        ? _kGreen.withValues(alpha: 0.16)
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: _rememberMe
                                          ? _kGreen
                                          : onSurface.withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: _rememberMe
                                      ? const Icon(
                                          Icons.check,
                                          size: 12,
                                          color: _kGreen,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Remember me',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/forgot-password'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Forgot password?',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _kGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) => OrleonPrimaryButton(
                        label: auth.isLoading ? 'SIGNING IN…' : 'LOG IN',
                        loading: auth.isLoading,
                        onPressed: auth.isLoading ? null : () => _login(auth),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // OR divider
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: onSurface.withValues(alpha: 0.07),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR',
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              color: onSurface.withValues(alpha: 0.38),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: onSurface.withValues(alpha: 0.07),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Social buttons
                    Row(
                      children: [
                        Expanded(
                          child: _SocialButton(
                            icon: Icons.g_mobiledata,
                            label: 'Google',
                            onTap: () async {
                              final auth = context.read<AuthProvider>();
                              final success = await auth.signInWithGoogle();
                              if (!mounted) return;
                              if (success) {
                                Navigator.pushReplacementNamed(context, '/home');
                              } else if (auth.error != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(auth.error!),
                                    backgroundColor: _kRed,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SocialButton(
                            icon: Icons.apple,
                            label: 'Apple',
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'New to OrleOn?  ',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(
                              context, '/register'),
                          child: Text(
                            'Create account',
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
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: onSurface.withValues(alpha: 0.04),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: onSurface.withValues(alpha: 0.08)),
        ),
      ),
      icon: Icon(
        icon,
        color: onSurface.withValues(alpha: 0.7),
        size: 22,
      ),
      label: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 13,
          color: onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
