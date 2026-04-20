import 'package:flutter/material.dart';
import 'package:mobile/features/auth/data/models/user.dart';
import 'package:mobile/core/theme/premium_theme.dart';

class ProfileHeader extends StatelessWidget {
  final User user;
  final String? clubName;
  final VoidCallback? onEdit;

  const ProfileHeader({
    super.key,
    required this.user,
    this.clubName,
    this.onEdit,
  });

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  String _getRoleDisplayName(List<String>? roles) {
    if (roles == null || roles.isEmpty) return 'Member';
    final role = roles.first;
    if (role.contains('OWNER')) return 'Club Owner';
    if (role.contains('MANAGER')) return 'Club Manager';
    if (role.contains('COACH')) return 'Coach';
    if (role.contains('ADMIN')) return 'Administrator';
    if (role.contains('PLAYER')) return 'Player';
    if (role.contains('PARENT')) return 'Parent';
    return role.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(user.name);
    final roleDisplay = _getRoleDisplayName(user.roles);
    final isVerified = user.roles?.any((r) => r.contains('OWNER') || r.contains('ADMIN') || r.contains('MANAGER')) ?? false;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 100, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1A2A4A).withValues(alpha: 0.6),
            PremiumTheme.deepNavy,
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar with initials
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [PremiumTheme.neonGreen, Color(0xFF00C853)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: PremiumTheme.neonGreen.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: user.avatarUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(user.avatarUrl!, fit: BoxFit.cover),
                  )
                : Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 16),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  clubName != null ? '$roleDisplay · $clubName' : roleDisplay,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 10),
                if (isVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: PremiumTheme.neonGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: PremiumTheme.neonGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, color: PremiumTheme.neonGreen, size: 14),
                        SizedBox(width: 5),
                        Text(
                          'VERIFIED',
                          style: TextStyle(
                            color: PremiumTheme.neonGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
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
