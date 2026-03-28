import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/features/auth/data/models/user.dart';

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[900]!, Colors.indigo[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white24,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: (user.roles ?? []).map((role) => _buildRoleBadge(role)).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.fingerprint, size: 12, color: Colors.white70),
                    const SizedBox(width: 8),
                    SelectableText(
                      'User ID: ${user.id}',
                      style: const TextStyle(fontSize: 10, color: Colors.white70, fontFamily: 'monospace'),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: user.id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('User ID copied'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)),
                        );
                      },
                      child: const Icon(Icons.copy, size: 12, color: Colors.white38),
                    ),
                  ],
                ),
                if (user.playerProfileId != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.badge, size: 12, color: Colors.orangeAccent),
                      const SizedBox(width: 8),
                      SelectableText(
                        'Profile ID: ${user.playerProfileId}',
                        style: const TextStyle(fontSize: 10, color: Colors.white70, fontFamily: 'monospace'),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: user.playerProfileId!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile ID copied'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)),
                          );
                        },
                        child: const Icon(Icons.copy, size: 12, color: Colors.white38),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (clubName != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield, color: Colors.orangeAccent, size: 16),
                const SizedBox(width: 6),
                Text(
                  clubName!,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        role.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
