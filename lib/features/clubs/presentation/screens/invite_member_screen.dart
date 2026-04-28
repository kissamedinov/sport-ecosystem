import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/club_provider.dart';
import '../../data/models/invitation.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';

class InviteMemberScreen extends StatefulWidget {
  final String clubId;
  final String? initialTeamId;
  const InviteMemberScreen({super.key, required this.clubId, this.initialTeamId});

  @override
  State<InviteMemberScreen> createState() => _InviteMemberScreenState();
}

class _InviteMemberScreenState extends State<InviteMemberScreen> {
  final _contactController = TextEditingController();
  final _childProfileIdController = TextEditingController();
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
    final authProvider = context.read<AuthProvider>();
    final userRoleStr = authProvider.user?.roles?.first.toUpperCase() ?? 'PLAYER_ADULT';
    
    ClubRole userRole;
    if (userRoleStr == 'CLUB_OWNER' || userRoleStr == 'ADMIN') {
      userRole = ClubRole.owner;
    } else if (userRoleStr == 'CLUB_MANAGER') {
      userRole = ClubRole.manager;
    } else if (userRoleStr == 'COACH') {
      userRole = ClubRole.coach;
    } else {
      userRole = ClubRole.player;
    }

    final availableRoles = ClubRole.values.where((r) {
      if (userRole == ClubRole.owner) return r != ClubRole.owner;
      if (userRole == ClubRole.manager) return r == ClubRole.coach || r == ClubRole.player;
      if (userRole == ClubRole.coach) return r == ClubRole.player;
      return false;
    }).toList();

    final clubName = dashboard?.club.name ?? 'Club';
    final clubCode = 'AIBARS-2026';
    final teams = dashboard?.teams ?? [];

    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
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
          // Header logic
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: PremiumTheme.electricBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PremiumTheme.electricBlue.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: PremiumTheme.electricBlue, size: 18),
                const SizedBox(width: 10),
                Text(
                  'Inviting as ${userRole.name.toUpperCase()}',
                  style: const TextStyle(color: PremiumTheme.electricBlue, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
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

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (availableRoles.contains(ClubRole.coach))
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 52) / 2,
                  child: _buildRoleCard(
                    role: ClubRole.coach,
                    icon: Icons.sports_rounded,
                    title: 'Coach',
                    subtitle: 'Can manage teams',
                    color: PremiumTheme.electricBlue,
                  ),
                ),
              if (availableRoles.contains(ClubRole.player))
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 52) / 2,
                  child: _buildRoleCard(
                    role: ClubRole.player,
                    icon: Icons.location_on_rounded,
                    title: 'Player',
                    subtitle: 'Linked to roster',
                    color: PremiumTheme.neonGreen,
                  ),
                ),
              if (availableRoles.contains(ClubRole.manager))
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 52) / 2,
                  child: _buildRoleCard(
                    role: ClubRole.manager,
                    icon: Icons.people_alt_rounded,
                    title: 'Manager',
                    subtitle: 'Club management',
                    color: Colors.amber,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),

          // Team Selection (integrated)
          if (_selectedRole == ClubRole.player || _selectedRole == ClubRole.coach) ...[
            _buildSectionLabel('ASSIGN TO TEAM', accentColor: PremiumTheme.electricBlue),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: DropdownButtonFormField<String>(
                value: _selectedTeamId,
                dropdownColor: PremiumTheme.surfaceCard(context),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white38),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text('No Team', style: TextStyle(color: Colors.white54))),
                  ...teams.map((t) => DropdownMenuItem(value: t.id.toString(), child: Text(t.name))),
                ],
                onChanged: (val) => setState(() => _selectedTeamId = val),
              ),
            ),
            const SizedBox(height: 28),
          ],

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
          PremiumButton(
            text: 'SEND INVITATION',
            icon: Icons.send_rounded,
            onPressed: () => _sendInvitation(),
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
