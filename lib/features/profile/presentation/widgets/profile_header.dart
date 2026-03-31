import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/features/auth/data/models/user.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'dart:math' as math;

class ProfileHeader extends StatelessWidget {
  final User user;
  final String? clubName;

  const ProfileHeader({
    super.key,
    required this.user,
    this.clubName,
  });

  @override
  Widget build(BuildContext context) {
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
              // Name
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 26, 
                  color: Colors.white, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              // Email
              Text(
                user.email,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 13, 
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.3,
                ),
              ),
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
                PremiumTheme.neonGreen.withOpacity(0.4),
                PremiumTheme.electricBlue.withOpacity(0.2),
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
              color: PremiumTheme.neonGreen.withOpacity(0.5),
              width: 2,
            ),
          ),
        ),
        // Avatar itself
        Container(
          width: 108,
          height: 108,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF1E2734), Color(0xFF161B22)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 46,
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
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
      ],
    );
  }

  Widget _buildClubBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orangeAccent.withOpacity(0.15),
            Colors.orange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield, color: Colors.orangeAccent, size: 14),
          const SizedBox(width: 8),
          Text(
            clubName!,
            style: const TextStyle(
              color: Colors.orangeAccent, 
              fontWeight: FontWeight.bold, 
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserIdCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: PremiumTheme.neonGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.fingerprint, size: 16, color: PremiumTheme.neonGreen),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'ID: ${user.id.length > 16 ? "${user.id.substring(0, 8)}...${user.id.substring(user.id.length - 4)}" : user.id}',
              style: const TextStyle(
                fontSize: 11, 
                color: Colors.white54, 
                fontFamily: 'monospace', 
                letterSpacing: 0.8,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: user.id));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('✓  ID copied'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: PremiumTheme.cardNavy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Icon(Icons.copy_rounded, size: 16, color: Colors.white24),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    // Pick color based on role
    Color color;
    IconData icon;
    if (role.contains('OWNER')) {
      color = Colors.amber;
      icon = Icons.star_rounded;
    } else if (role.contains('COACH')) {
      color = Colors.orangeAccent;
      icon = Icons.sports;
    } else if (role.contains('MANAGER') || role.contains('ADMIN')) {
      color = Colors.purpleAccent;
      icon = Icons.admin_panel_settings;
    } else if (role.contains('PLAYER')) {
      color = PremiumTheme.neonGreen;
      icon = Icons.sports_soccer;
    } else {
      color = PremiumTheme.electricBlue;
      icon = Icons.person;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 5),
          Text(
            role.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(
              color: color, 
              fontSize: 9, 
              fontWeight: FontWeight.w900, 
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
