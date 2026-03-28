import 'package:flutter/material.dart';
import 'package:mobile/core/api/profile_api_service.dart';
import 'package:mobile/features/teams/data/models/team.dart';

class CoachProfileBody extends StatefulWidget {
  final String coachId;

  const CoachProfileBody({super.key, required this.coachId});

  @override
  State<CoachProfileBody> createState() => _CoachProfileBodyState();
}

class _CoachProfileBodyState extends State<CoachProfileBody> {
  final ProfileApiService _profileApi = ProfileApiService();
  late Future<List<Team>> _teamsFuture;

  @override
  void initState() {
    super.initState();
    _teamsFuture = _profileApi.getManagedTeams();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("MY TEAMS"),
        _buildTeamsList(),
        const SizedBox(height: 24),
        _buildSectionTitle("COACH DASHBOARD"),
        _buildActionCard(
          context,
          "Manage Team Rosters",
          Icons.people,
          Colors.orange,
          () {},
        ),
        _buildActionCard(
          context,
          "Team Training Schedules",
          Icons.calendar_month,
          Colors.blue,
          () {},
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildTeamsList() {
    return FutureBuilder<List<Team>>(
      future: _teamsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("No teams assigned yet.", style: TextStyle(color: Colors.grey)),
          );
        }

        final teams = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: teams.length,
          itemBuilder: (context, index) {
            final team = teams[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.withOpacity(0.1),
                        child: const Icon(Icons.shield, color: Colors.orange),
                      ),
                      title: Text(team.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${team.players.length} Players • ${team.ageCategory ?? "All ages"}"),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {},
                            child: const Text("VIEW TEAM"),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              // Example match navigation
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Select a match to submit lineup for.")),
                              );
                            },
                            child: const Text("SUBMIT LINEUP"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
