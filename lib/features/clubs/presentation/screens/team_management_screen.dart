import 'package:flutter/material.dart';
import 'package:mobile/features/teams/data/models/team.dart';
import 'package:mobile/features/teams/data/models/player_team.dart';
import 'package:mobile/core/api/profile_api_service.dart';
import 'package:mobile/features/clubs/data/models/player_info.dart';

class TeamManagementScreen extends StatefulWidget {
  final Team team;
  final List<PlayerInfo> availableCoaches;

  const TeamManagementScreen({
    super.key,
    required this.team,
    required this.availableCoaches,
  });

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  final ProfileApiService _profileApi = ProfileApiService();
  late Future<List<PlayerTeam>> _rosterFuture;
  String? _selectedCoachId;

  @override
  void initState() {
    super.initState();
    _rosterFuture = _fetchRoster();
    _selectedCoachId = widget.team.coachId;
  }

  Future<List<PlayerTeam>> _fetchRoster() async {
    return widget.team.players;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage: ${widget.team.name}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveTeamChanges(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCoachAssignment(),
            const Divider(),
            _buildSectionTitle("CURRENT ROSTER (${widget.team.players.length})"),
            _buildRosterList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Integration with Invitation system coming soon.")),
          );
        },
        label: const Text("ADD PLAYER"),
        icon: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildCoachAssignment() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Assigned Coach", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedCoachId,
            items: widget.availableCoaches.map((c) {
              return DropdownMenuItem(
                value: c.userId,
                child: Text(c.name),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedCoachId = val),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRosterList() {
    final players = widget.team.players;
    if (players.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text("No players in this team.")));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final pt = players[index];
        final name = pt.player?.name ?? "Unknown Player";
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: const Icon(Icons.person, color: Colors.blue, size: 20),
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text("Player"),
          trailing: IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Removing player...")));
            },
          ),
        );
      },
    );
  }

  void _saveTeamChanges(BuildContext context) async {
    if (_selectedCoachId == widget.team.coachId) {
      Navigator.pop(context);
      return;
    }

    // Logic to call backend PATCH /clubs/teams/{id}/coach
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saving changes...")));
    // Success simulation
    Navigator.pop(context);
  }
}
