import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/club_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/invitation.dart';

class InviteMemberScreen extends StatefulWidget {
  final String clubId;
  const InviteMemberScreen({super.key, required this.clubId});

  @override
  State<InviteMemberScreen> createState() => _InviteMemberScreenState();
}

class _InviteMemberScreenState extends State<InviteMemberScreen> {
  final _userIdController = TextEditingController();
  final _childProfileIdController = TextEditingController();
  ClubRole _selectedRole = ClubRole.player;
  String? _selectedTeamId;

  @override
  Widget build(BuildContext context) {
    final clubProvider = context.watch<ClubProvider>();
    final authProvider = context.watch<AuthProvider>();
    final dashboard = clubProvider.dashboard;
    
    // Get user's club role
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
      appBar: AppBar(title: const Text('Send Invitation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Inviting as: ${userRole.name.toUpperCase()}', 
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 16),
            const Text('Invite a new member to your club.', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 24),
            DropdownButtonFormField<ClubRole>(
              value: _selectedRole,
              decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
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
            const SizedBox(height: 16),
            if (_selectedRole == ClubRole.player || _selectedRole == ClubRole.coach)
              DropdownButtonFormField<String>(
                value: _selectedTeamId,
                decoration: const InputDecoration(labelText: 'Assign to Team (Optional)', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text('No Team')),
                  ...teams.map((t) => DropdownMenuItem(value: t.id.toString(), child: Text(t.name))),
                ],
                onChanged: (val) => setState(() => _selectedTeamId = val),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _userIdController,
              decoration: const InputDecoration(
                labelText: 'User ID (Invited User)',
                border: OutlineInputBorder(),
                helperText: 'Unique ID of the user you want to invite',
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedRole == ClubRole.player)
              TextField(
                controller: _childProfileIdController,
                decoration: const InputDecoration(
                  labelText: 'Child Profile ID (Optional)',
                  border: OutlineInputBorder(),
                  helperText: 'Link this invitation to a pre-created child profile',
                ),
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
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
                child: const Text('Send Invitation'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
