import 'package:flutter/material.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';
import '../../../academies/data/models/academy.dart';
import '../../data/models/club_dashboard.dart';
import 'team_management_screen.dart';

class AcademyManagementScreen extends StatelessWidget {
  final Academy academy;
  final ClubDashboard dashboard;

  const AcademyManagementScreen({
    super.key, 
    required this.academy,
    required this.dashboard,
  });

  @override
  Widget build(BuildContext context) {
    final academyTeams = dashboard.teams.where((t) => t.academyName == academy.name).toList();

    return Scaffold(
      backgroundColor: PremiumTheme.deepNavy,
      appBar: AppBar(
        title: Text(academy.name.toUpperCase()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildAcademyDetails(),
          const SizedBox(height: 32),
          const Text('TEAMS IN THIS BRANCH', 
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 2)),
          const SizedBox(height: 16),
          if (academyTeams.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text('No teams registered in this academy yet.', style: TextStyle(color: Colors.white24)),
            ))
          else
            ...academyTeams.map((team) => _buildTeamCard(context, team)),
        ],
      ),
    );
  }

  Widget _buildAcademyDetails() {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_city, color: Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(academy.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('${academy.city}, ${academy.address}', style: const TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white10),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSimpleStat('TEAMS', academyTeamsCount.toString()),
              _buildSimpleStat('PLAYERS', academy.playersCount?.toString() ?? '0'),
            ],
          ),
        ],
      ),
    );
  }

  int get academyTeamsCount => academy.teamsCount ?? 0;

  Widget _buildSimpleStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PremiumTheme.neonGreen)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildTeamCard(BuildContext context, dynamic team) {
    return PremiumCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeamManagementScreen(teamId: team.id, clubId: academy.clubId),
          ),
        );
      },
      child: Row(
        children: [
          const Icon(Icons.group, color: Colors.green),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(team.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(team.ageCategory ?? 'N/A', style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white10),
        ],
      ),
    );
  }
}
