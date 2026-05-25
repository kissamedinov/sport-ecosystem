import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kGreen = Color(0xFF00E676);
const _kGreenDeep = Color(0xFF00C853);

class OrleonPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const OrleonPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 54,
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_kGreen, _kGreenDeep],
                )
              : null,
          color: enabled ? null : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: _kGreen.withValues(alpha: 0.36),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 18,
                        color: enabled
                            ? Colors.black
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: enabled
                            ? Colors.black
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
