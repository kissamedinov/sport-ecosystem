import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../widgets/orleon_ambient_background.dart';
import '../widgets/orleon_logo.dart';

const _kNavy = Color(0xFF0A0E12);
const _kGold = Color(0xFFF5C518);
const _kGreen = Color(0xFF00E676);
const _kGreenDeep = Color(0xFF00C853);
const _kBlue = Color(0xFF1E90D4);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _shimmerCtrl;

  // Entrance animations
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _ringGlow;
  late final Animation<double> _wordmarkSlide;
  late final Animation<double> _wordmarkFade;
  late final Animation<double> _dividerWidth;
  late final Animation<double> _taglineFade;
  late final Animation<double> _loaderFade;
  late final Animation<double> _bottomFade;

  // Repeating
  late final Animation<double> _pulse;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // Logo: 0 → 55%
    _logoScale = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    // Ring glow behind logo: 0 → 50%
    _ringGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.1, 0.5, curve: Curves.easeOut),
      ),
    );

    // Wordmark: 25% → 70%
    _wordmarkSlide = Tween<double>(begin: 28.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.25, 0.68, curve: Curves.easeOutCubic),
      ),
    );
    _wordmarkFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.25, 0.62, curve: Curves.easeOut),
      ),
    );

    // Divider line: 45% → 75%
    _dividerWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.45, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    // Tagline: 55% → 85%
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
      ),
    );

    // Loader + bottom text: 72% → 100%
    _loaderFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.72, 1.0, curve: Curves.easeOut),
      ),
    );
    _bottomFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.80, 1.0, curve: Curves.easeOut),
      ),
    );

    _pulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );

    _shimmer = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );

    _entranceCtrl.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    await auth.tryAutoLogin();
    if (!mounted) return;
    if (auth.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? _kNavy : Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const OrleonAmbientBackground(accent: _kGold),
          _buildCenterContent(),
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildCenterContent() {
    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([_entranceCtrl, _pulseCtrl, _shimmerCtrl]),
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLogoSection(),
              const SizedBox(height: 40),
              _buildWordmark(),
              const SizedBox(height: 16),
              _buildDivider(),
              const SizedBox(height: 16),
              _buildTagline(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogoSection() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Static soft glow behind logo
          AnimatedBuilder(
            animation: _ringGlow,
            builder: (_, _) => Opacity(
              opacity: _ringGlow.value * 0.25,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _kGreen.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Three staggered pulse rings
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  for (int i = 0; i < 3; i++) _buildPulseRing(i),
                ],
              );
            },
          ),

          // Logo itself
          AnimatedBuilder(
            animation: _entranceCtrl,
            builder: (_, _) => Transform.scale(
              scale: _logoScale.value,
              child: Opacity(
                opacity: _logoFade.value,
                child: const OrleonLogo(size: 120),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseRing(int index) {
    const offsets = [0.0, 0.33, 0.67];
    final t = (_pulse.value + offsets[index]) % 1.0;
    final opacity = (1.0 - t) * 0.45 * _ringGlow.value;
    final size = 120.0 + t * 80.0;
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: index == 0 ? _kGreen : index == 1 ? _kGold : _kGreenDeep,
            width: 1.5 - t * 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildWordmark() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : _kNavy;
    return AnimatedBuilder(
      animation: _entranceCtrl,
      builder: (_, _) => Transform.translate(
        offset: Offset(0, _wordmarkSlide.value),
        child: Opacity(
          opacity: _wordmarkFade.value,
          child: ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) {
              final shimmerX = _shimmer.value;
              return LinearGradient(
                begin: Alignment(shimmerX - 0.6, 0),
                end: Alignment(shimmerX + 0.6, 0),
                colors: [
                  baseColor,
                  baseColor.withValues(alpha: 0.92),
                  _kGold.withValues(alpha: 0.9),
                  baseColor.withValues(alpha: 0.92),
                  baseColor,
                ],
                stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
              ).createShader(bounds);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'Orle',
                  style: GoogleFonts.outfit(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2.0,
                    color: baseColor,
                  ),
                ),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [_kGold, _kGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    'On',
                    style: GoogleFonts.outfit(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return AnimatedBuilder(
      animation: _dividerWidth,
      builder: (_, _) => SizedBox(
        width: 220,
        child: ClipRect(
          child: Align(
            alignment: Alignment.center,
            widthFactor: _dividerWidth.value,
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    _kGold,
                    _kGreen,
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagline() {
    return AnimatedBuilder(
      animation: _taglineFade,
      builder: (_, _) => Opacity(
        opacity: _taglineFade.value,
        child: Column(
          children: [
            Text(
              'SPORT ECOSYSTEM · KAZAKHSTAN',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.4,
                color: _kGold.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 2,
                  decoration: BoxDecoration(
                    color: _kBlue.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'KZ',
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: _kBlue.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 14,
                  height: 2,
                  decoration: BoxDecoration(
                    color: _kBlue.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 52,
      child: AnimatedBuilder(
        animation: _entranceCtrl,
        builder: (_, _) => Opacity(
          opacity: _loaderFade.value,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _BarLoader(),
              const SizedBox(height: 18),
              Opacity(
                opacity: _bottomFade.value,
                child: Text(
                  "Kazakhstan's sports platform",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.28),
                    letterSpacing: 0.4,
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

class _BarLoader extends StatefulWidget {
  const _BarLoader();

  @override
  State<_BarLoader> createState() => _BarLoaderState();
}

class _BarLoaderState extends State<_BarLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (i) {
            final phase = (i / 4.0);
            final t = (_anim.value - phase * 0.4 + 0.4).clamp(0.0, 1.0);
            final sin = math.sin(t * math.pi);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: 4,
              height: 4 + sin * 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: Color.lerp(
                  _kGreen.withValues(alpha: 0.25),
                  _kGreen,
                  sin,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
