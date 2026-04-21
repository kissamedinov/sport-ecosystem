import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  String _getRoleDisplayName(String role) {
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
    final isVerified = user.roles?.any((r) => r.contains('OWNER') || r.contains('ADMIN') || r.contains('MANAGER')) ?? false;

    return Stack(
      children: [
        // Background with subtle arc decoration
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 72, 24, 36),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A0E12), Color(0xFF161B22), Color(0xFF0A0E12)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(48),
              bottomRight: Radius.circular(48),
            ),
          ),
          child: Column(
            children: [
              // Avatar with glowing ring
              _buildAvatar(),
              const SizedBox(height: 20),
              // Name row with verification badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 26, 
                      color: Colors.white, 
                      fontWeight: FontWeight.w900, 
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (isVerified) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.verified_rounded, color: PremiumTheme.neonGreen, size: 20),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              // Email
              Text(
                user.email,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13, 
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.3,
                ),
              ),
              if (user.bio?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    user.bio!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Divider shimmer line
              Container(
                height: 1,
                width: 60,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, PremiumTheme.neonGreen, Colors.transparent],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Role badges
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: (user.roles ?? []).map((role) => _buildRoleBadge(role)).toList(),
              ),
              if (clubName != null) ...[
                const SizedBox(height: 12),
                _buildClubBadge(),
              ],
              const SizedBox(height: 20),
              // ID Card
              _buildUserIdCard(context),
            ],
          ),
        ),
        // Top glow effect
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 2,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, PremiumTheme.neonGreen, Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow ring
        Container(
          width: 124,
          height: 124,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                PremiumTheme.neonGreen.withValues(alpha: 0.4),
                PremiumTheme.electricBlue.withValues(alpha: 0.2),
                Colors.transparent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // Middle ring
        Container(
          width: 116,
          height: 116,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: PremiumTheme.neonGreen.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
        ),
        // Avatar itself
        Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: user.avatarUrl != null 
              ? DecorationImage(image: NetworkImage(user.avatarUrl!), fit: BoxFit.cover)
              : null,
            gradient: user.avatarUrl == null 
              ? const LinearGradient(
                  colors: [Color(0xFF1E2734), Color(0xFF161B22)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          ),
          child: user.avatarUrl == null 
            ? Center(
                child: Text(
                  _getInitials(user.name),
                  style: const TextStyle(
                    fontSize: 42,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              )
            : null,
        ),
        // Online indicator
        Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: PremiumTheme.neonGreen,
              shape: BoxShape.circle,
              border: Border.all(color: PremiumTheme.deepNavy, width: 2),
            ),
          ),
        ),
        // Edit button overlay
        if (onEdit != null)
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: PremiumTheme.cardNavy,
                  shape: BoxShape.circle,
                  border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: PremiumTheme.neonGreen.withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.edit_rounded, size: 16, color: PremiumTheme.neonGreen),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRoleBadge(String role) {
    final displayName = _getRoleDisplayName(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: PremiumTheme.electricBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PremiumTheme.electricBlue.withValues(alpha: 0.3)),
      ),
      child: Text(
        displayName.toUpperCase(),
        style: const TextStyle(
          color: PremiumTheme.electricBlue,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildClubBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_user_rounded, color: PremiumTheme.neonGreen, size: 14),
          const SizedBox(width: 8),
          Text(
            clubName!.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserIdCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fingerprint_rounded, color: Colors.white.withValues(alpha: 0.3), size: 16),
          const SizedBox(width: 10),
          Text(
            user.id.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              fontFamily: 'monospace',
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: user.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User ID copied to clipboard')),
              );
            },
            child: Icon(Icons.copy_rounded, color: PremiumTheme.neonGreen.withValues(alpha: 0.6), size: 14),
          ),
        ],
      ),
    );
  }
}
