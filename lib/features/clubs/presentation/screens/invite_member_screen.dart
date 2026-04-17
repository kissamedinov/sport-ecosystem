import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/club_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/invitation.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';

class InviteMemberScreen extends StatefulWidget {
  final String clubId;
  final String? initialTeamId;
  const InviteMemberScreen({super.key, required this.clubId, this.initialTeamId});

  @override
  State<InviteMemberScreen> createState() => _InviteMemberScreenState();
}

class _InviteMemberScreenState extends State<InviteMemberScreen> {
  final _userIdController = TextEditingController();
  final _childProfileIdController = TextEditingController();
  ClubRole _selectedRole = ClubRole.player;
  String? _selectedTeamId;

  @override
  void initState() {
    super.initState();
    _selectedTeamId = widget.initialTeamId;
  }

  @override
  Widget build(BuildContext context) {
    final clubProvider = context.watch<ClubProvider>();
    final authProvider = context.watch<AuthProvider>();
    final dashboard = clubProvider.dashboard;

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

    final teams = dashboard?.teams ?? [];

    return Scaffold(
      backgroundColor: PremiumTheme.deepNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white70),
        title: const Text(
          'INVITE MEMBER',
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
          // Your role badge
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
          const SizedBox(height: 8),
          Text(
            'Invite a new member to your club.',
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 28),

          // Role dropdown
          _buildSectionLabel('ROLE'),
          const SizedBox(height: 8),
          Container(
            decoration: PremiumTheme.glassDecoration(radius: 16),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: DropdownButtonFormField<ClubRole>(
              value: _selectedRole,
              dropdownColor: PremiumTheme.cardNavy,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white38),
              decoration: PremiumTheme.inputDecoration('Select Role', prefixIcon: Icons.badge_rounded),
              items: availableRoles
                  .map((r) => DropdownMenuItem(value: r, child: Text(r.name.toUpperCase())))
                  .toList(),
              onChanged: (val) => setState(() {
                _selectedRole = val!;
                if (_selectedRole != ClubRole.player) {
                  _selectedTeamId = null;
                  _childProfileIdController.clear();
                }
              }),
            ),
          ),
          const SizedBox(height: 20),

          // Team dropdown
          if (_selectedRole == ClubRole.player || _selectedRole == ClubRole.coach) ...[
            _buildSectionLabel('TEAM (OPTIONAL)'),
            const SizedBox(height: 8),
            Container(
              decoration: PremiumTheme.glassDecoration(radius: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: DropdownButtonFormField<String>(
                value: _selectedTeamId,
                dropdownColor: PremiumTheme.cardNavy,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white38),
                decoration: PremiumTheme.inputDecoration('Assign to Team', prefixIcon: Icons.group_rounded),
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text('No Team', style: TextStyle(color: Colors.white54))),
                  ...teams.map((t) => DropdownMenuItem(value: t.id.toString(), child: Text(t.name))),
                ],
                onChanged: (val) => setState(() => _selectedTeamId = val),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // User ID
          _buildSectionLabel('USER ID'),
          const SizedBox(height: 8),
          TextField(
            controller: _userIdController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: PremiumTheme.inputDecoration('User ID of invited person', prefixIcon: Icons.fingerprint_rounded),
          ),
          const SizedBox(height: 20),

          // Child Profile ID
          if (_selectedRole == ClubRole.player) ...[
            _buildSectionLabel('CHILD PROFILE ID (OPTIONAL)'),
            const SizedBox(height: 8),
            TextField(
              controller: _childProfileIdController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: PremiumTheme.inputDecoration('Link to child profile', prefixIcon: Icons.child_care_rounded),
            ),
            const SizedBox(height: 28),
          ],

          const SizedBox(height: 12),
          PremiumButton(
            text: 'SEND INVITATION',
            icon: Icons.send_rounded,
            onPressed: () async {
              if (_userIdController.text.isNotEmpty) {
                final Map<String, dynamic> data = {
                  'club_id': widget.clubId,
                  'invited_user_id': _userIdController.text,
                  'role': _selectedRole.name.toUpperCase(),
                };
                if (_selectedRole == ClubRole.player && _childProfileIdController.text.isNotEmpty) {
                  data['child_profile_id'] = _childProfileIdController.text;
                }
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
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: Colors.white38,
        letterSpacing: 1.5,
      ),
    );
  }
}
