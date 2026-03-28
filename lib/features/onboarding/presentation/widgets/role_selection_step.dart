import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';

class RoleSelectionScreen extends StatelessWidget {
  final VoidCallback onNext;

  const RoleSelectionScreen({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final primaryRole = user?.roles?.first ?? 'PLAYER_ADULT';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_pin, size: 80, color: Color(0xFF00E676)),
          const SizedBox(height: 24),
          Text(
            'Confirm Your Role',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'You are registered as a ${primaryRole.replaceAll('_', ' ').toUpperCase()}. Is this correct?',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 40),
          _buildRoleCard(context, primaryRole),
          const Spacer(),
          ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              backgroundColor: const Color(0xFF00E676),
            ),
            child: const Text('YES, CONTINUE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              // In a real app, maybe allow changing role or contact support
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please contact support to change your role.')),
              );
            },
            child: const Text('Change Role', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, String role) {
    IconData icon;
    String description;

    if (role.contains('PLAYER')) {
      icon = Icons.sports_soccer;
      description = 'Access to matches, stats, and training.';
    } else if (role == 'PARENT') {
      icon = Icons.family_restroom;
      description = 'Track your children performances and schedules.';
    } else if (role == 'COACH') {
      icon = Icons.sports;
      description = 'Manage teams, lineups, and sessions.';
    } else if (role == 'CLUB_OWNER') {
      icon = Icons.business;
      description = 'Manage multiple academies and high-level stats.';
    } else {
      icon = Icons.person;
      description = 'General access to the ecosystem.';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: const Color(0xFF00E676)),
          const SizedBox(height: 16),
          Text(
            role.replaceAll('_', ' ').toUpperCase(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
