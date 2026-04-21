import 'package:flutter/material.dart';
import 'package:mobile/features/auth/data/models/user.dart';
import 'package:mobile/core/theme/premium_theme.dart';

class ProfileHeader extends StatelessWidget {
  final User user;
  final String? clubName;
  final bool canPop;
  final VoidCallback? onMenu;
  final VoidCallback? onEdit;

  const ProfileHeader({
    super.key,
    required this.user,
    this.clubName,
    this.canPop = false,
    this.onMenu,
    this.onEdit,
  });

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _roleLabel(List<String>? roles) {
    if (roles == null || roles.isEmpty) return 'Member';
    final r = roles.first;
    if (r.contains('OWNER')) return 'Club Owner';
    if (r.contains('MANAGER')) return 'Club Manager';
    if (r.contains('COACH')) return 'Coach';
    if (r.contains('ADMIN')) return 'Administrator';
    if (r.contains('PLAYER')) return 'Player';
    if (r.contains('PARENT')) return 'Parent';
    return r.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;
    final initials = _initials(user.name);
    final roleLabel = _roleLabel(user.roles);
    final isVerified = user.roles?.any(
          (r) => r.contains('OWNER') || r.contains('ADMIN') || r.contains('MANAGER'),
        ) ??
        false;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D2E14), Color(0xFF0A0E12)],
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, safeTop + 12, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── top nav row ──────────────────────────────────
          Row(
            children: [
              if (canPop)
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: _iconBtn(Icons.chevron_left_rounded),
                )
              else
                const SizedBox(width: 40),
              const Expanded(
                child: Text(
                  'MY PROFILE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: PremiumTheme.neonGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
              if (onMenu != null)
                GestureDetector(
                  onTap: onMenu,
                  child: _iconBtn(Icons.more_horiz_rounded),
                )
              else
                const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 24),
          // ── profile row ──────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  gradient: PremiumTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: PremiumTheme.neonShadow(),
                ),
                child: user.avatarUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(user.avatarUrl!, fit: BoxFit.cover),
                      )
                    : Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      clubName != null ? '$roleLabel  ·  $clubName' : roleLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _tag(roleLabel.toUpperCase(), PremiumTheme.neonGreen),
                        if (isVerified)
                          _tag('VERIFIED', PremiumTheme.electricBlue,
                              icon: Icons.verified_rounded),
                        if (onEdit != null)
                          GestureDetector(
                            onTap: onEdit,
                            child: _tag('EDIT', Colors.white54,
                                icon: Icons.edit_rounded),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white70, size: 22),
    );
  }

  Widget _tag(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
