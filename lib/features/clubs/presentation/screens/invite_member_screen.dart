import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/club_provider.dart';
import '../../data/models/invitation.dart';
import 'package:mobile/core/theme/premium_theme.dart';

class InviteMemberScreen extends StatefulWidget {
  final String clubId;
  final String? initialTeamId;
  const InviteMemberScreen({super.key, required this.clubId, this.initialTeamId});

  @override
  State<InviteMemberScreen> createState() => _InviteMemberScreenState();
}

class _InviteMemberScreenState extends State<InviteMemberScreen> {
  final _contactController = TextEditingController();
  ClubRole _selectedRole = ClubRole.coach;
  String? _selectedTeamId;

  @override
  void initState() {
    super.initState();
    _selectedTeamId = widget.initialTeamId;
  }

  @override
  Widget build(BuildContext context) {
    final clubProvider = context.watch<ClubProvider>();
    final dashboard = clubProvider.dashboard;
    final clubName = dashboard?.club.name ?? 'Club';
    final clubCode = 'AIBARS-2026'; // This could be generated from club data

    return Scaffold(
      backgroundColor: PremiumTheme.deepNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chevron_left_rounded, color: Colors.white70),
          ),
        ),
        title: const Text(
          'INVITE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Header
          const Text(
            'Add a person',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'They\'ll get a notification to join $clubName.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 28),

          // Role Selection
          _buildSectionLabel('SELECT ROLE', accentColor: PremiumTheme.electricBlue),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildRoleCard(
                  role: ClubRole.coach,
                  icon: Icons.sports_rounded,
                  title: 'Coach',
                  subtitle: 'Can manage teams',
                  color: PremiumTheme.electricBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRoleCard(
                  role: ClubRole.player,
                  icon: Icons.location_on_rounded,
                  title: 'Player',
                  subtitle: 'Linked to roster',
                  color: PremiumTheme.neonGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildRoleCard(
                  role: ClubRole.manager,
                  icon: Icons.people_alt_rounded,
                  title: 'Parent',
                  subtitle: 'View child stats',
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRoleCard(
                  role: ClubRole.owner,
                  icon: Icons.verified_rounded,
                  title: 'Manager',
                  subtitle: 'Full club access',
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Contact Section
          _buildSectionLabel('CONTACT', accentColor: PremiumTheme.neonGreen),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EMAIL OR PHONE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.3),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _contactController,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Enter email or phone...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Invite Code Hint
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: PremiumTheme.electricBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PremiumTheme.electricBlue.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.mail_outline_rounded,
                    color: PremiumTheme.electricBlue.withValues(alpha: 0.6), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
                      children: [
                        const TextSpan(text: 'Or share the club invite code '),
                        TextSpan(
                          text: clubCode,
                          style: const TextStyle(
                            color: PremiumTheme.electricBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const TextSpan(text: ' — they\'ll join from the app.'),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: clubCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invite code copied!')),
                    );
                  },
                  child: Icon(Icons.copy_rounded,
                      color: PremiumTheme.electricBlue.withValues(alpha: 0.6), size: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Send Button
          GestureDetector(
            onTap: _contactController.text.isNotEmpty ? _sendInvitation : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _contactController.text.isNotEmpty
                    ? PremiumTheme.neonGreen
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  'SEND INVITATION',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _contactController.text.isNotEmpty
                        ? Colors.black
                        : Colors.white.withValues(alpha: 0.25),
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required ClubRole role,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? color : Colors.white.withValues(alpha: 0.4),
                size: 20,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title, {Color accentColor = PremiumTheme.neonGreen}) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          color: accentColor,
          margin: const EdgeInsets.only(right: 8),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Colors.white54,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Future<void> _sendInvitation() async {
    if (_contactController.text.isEmpty) return;

    final Map<String, dynamic> data = {
      'club_id': widget.clubId,
      'invited_user_id': _contactController.text,
      'role': _selectedRole.name.toUpperCase(),
    };
    if (_selectedTeamId != null) {
      data['team_id'] = _selectedTeamId;
    }

    final success = await context.read<ClubProvider>().sendInvitation(data);
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation sent!')),
      );
    }
  }
}
