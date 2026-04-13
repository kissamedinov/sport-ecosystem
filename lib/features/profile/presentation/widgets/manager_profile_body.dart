import 'package:flutter/material.dart';
import 'package:mobile/core/api/profile_api_service.dart';
import 'package:mobile/features/teams/data/models/team.dart';
import 'package:mobile/features/matches/data/models/match.dart';
import 'package:mobile/features/matches/presentation/screens/match_events_screen.dart';
import 'package:mobile/features/academies/presentation/screens/academy_dashboard_screen.dart';

class ManagerProfileBody extends StatefulWidget {
  const ManagerProfileBody({super.key});

  @override
  State<ManagerProfileBody> createState() => _ManagerProfileBodyState();
}

class _ManagerProfileBodyState extends State<ManagerProfileBody> {
  final ProfileApiService _profileApi = ProfileApiService();
  late Future<List<Team>> _teamsFuture;
  late Future<List<MatchModel>> _matchesFuture;

  @override
  void initState() {
    super.initState();
    _teamsFuture = _profileApi.getManagedTeams();
    _matchesFuture = _profileApi.getRecentMatches();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("OPERATIONAL TEAMS"),
        _buildTeamsList(),
        const SizedBox(height: 24),
        _buildSectionTitle("RECENT MATCH LOGS"),
        _buildMatchesList(),
        const SizedBox(height: 24),
        _buildSectionTitle("MANAGER CONTROLS"),
        _buildActionCard(context, "Academy CRM Management", Icons.school_rounded, Colors.blue, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AcademyDashboardScreen()));
        }),
        _buildActionCard(context, "Register Team for Tournament", Icons.emoji_events, Colors.amber, () {}),
        _buildActionCard(context, "Coordinate Field Schedules", Icons.stadium, Colors.green, () {}),
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
            child: Text("No teams under management.", style: TextStyle(color: Colors.grey)),
          );
        }

        return SizedBox(
          height: 90,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final team = snapshot.data![index];
              return Container(
                width: 140,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(team.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(team.ageCategory ?? "Academy", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMatchesList() {
    return FutureBuilder<List<MatchModel>>(
      future: _matchesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("No recent match activity.", style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.length > 3 ? 3 : snapshot.data!.length,
          itemBuilder: (context, index) {
            final match = snapshot.data![index];
            return ListTile(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MatchEventsScreen(matchId: match.id))),
              leading: const Icon(Icons.history, size: 20),
              title: Text("Match vs ${match.awayTeamId.substring(0, 4)}..."),
              subtitle: Text(match.status),
              trailing: const Icon(Icons.chevron_right, size: 16),
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
