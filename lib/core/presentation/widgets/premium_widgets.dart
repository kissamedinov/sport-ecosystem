import 'package:flutter/material.dart';
import '../../theme/premium_theme.dart';

class PremiumCard extends StatelessWidget {
  final Widget child;
  final double? height;
  final double? width;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const PremiumCard({
    super.key,
    required this.child,
    this.height,
    this.width,
    this.onTap,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: PremiumTheme.glassDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: PremiumTheme.glassEffect(
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class PremiumStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const PremiumStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(fontSize: 10, color: Colors.white54),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.white54,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const PremiumHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              if (subtitle != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    subtitle!.toUpperCase(),
                    style: const TextStyle(
                      color: PremiumTheme.neonGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
            ],
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class PremiumButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color? color;
  final bool isLoading;

  const PremiumButton({
    super.key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color ?? PremiumTheme.neonGreen,
            (color ?? PremiumTheme.neonGreen).withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (color ?? PremiumTheme.neonGreen).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.black, size: 20),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    text.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
