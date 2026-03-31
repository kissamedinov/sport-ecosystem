import 'package:flutter/material.dart';
import 'package:mobile/core/api/profile_api_service.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';

class CoachProfileBody extends StatefulWidget {
  final String coachId;

  const CoachProfileBody({super.key, required this.coachId});

  @override
  State<CoachProfileBody> createState() => _CoachProfileBodyState();
}

class _CoachProfileBodyState extends State<CoachProfileBody> {
  final ProfileApiService _profileApi = ProfileApiService();
  late Future<Map<String, dynamic>> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _profileApi.getCoachDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: Column(
                children: [
                  CircularProgressIndicator(color: PremiumTheme.neonGreen, strokeWidth: 2),
                  SizedBox(height: 16),
                  Text("Loading dashboard...", style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 1)),
                ],
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 12),
                  Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white54), textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }
        
        final data = snapshot.data!;
        final perf = data['performance_stats'] ?? {};
        final matches = data['upcoming_matches'] as List? ?? [];
        final teams = data['teams'] as List? ?? [];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildSectionLabel("PERFORMANCE OVERVIEW"),
              const SizedBox(height: 12),
              _buildPerformanceStats(perf),
              const SizedBox(height: 28),
              _buildSectionLabel("UPCOMING MATCHES"),
              const SizedBox(height: 12),
              _buildUpcomingMatches(matches),
              const SizedBox(height: 28),
              _buildSectionLabel("MY TEAMS  •  ${teams.length}"),
              const SizedBox(height: 12),
              _buildTeamsList(teams),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionLabel(String text) {
    return Row(
      children: [
        Container(width: 3, height: 16, decoration: BoxDecoration(color: PremiumTheme.neonGreen, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white54, letterSpacing: 2),
        ),
      ],
    );
  }

  Widget _buildPerformanceStats(Map<String, dynamic> perf) {
    final wins = perf['wins'] ?? 0;
    final total = perf['matches_played'] ?? 0;
    final winRate = total > 0 ? (wins / total * 100).toStringAsFixed(1) : "0";

    return Row(
      children: [
        Expanded(child: _buildStatCard("Win Rate", "$winRate%", Icons.trending_up_rounded, PremiumTheme.neonGreen, subtitle: "Overall")),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard("Goals", "${perf['goals_scored'] ?? 0}", Icons.sports_soccer_rounded, PremiumTheme.electricBlue, subtitle: "Scored")),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard("Shutouts", "${perf['clean_sheets'] ?? 0}", Icons.shield_rounded, Colors.orangeAccent, subtitle: "Clean")),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.12), color.withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 14, color: color),
              ),
              if (subtitle != null)
                Text(subtitle, style: TextStyle(fontSize: 8, color: color.withOpacity(0.7), fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5)),
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
        ],
      ),
    );
  }

  Widget _buildUpcomingMatches(List matches) {
    if (matches.isEmpty) {
      return _buildEmptyState("No upcoming matches scheduled", Icons.event_busy_rounded);
    }
    return Column(
      children: matches.map((match) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: PremiumTheme.electricBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.event_rounded, color: PremiumTheme.electricBlue, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${match['home_team_name']} vs ${match['away_team_name']}",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      match['tournament_name'] ?? "Friendly Match",
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: PremiumTheme.neonGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  match['scheduled_at'] != null 
                    ? match['scheduled_at'].toString().split('T').first 
                    : "TBD",
                  style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.w800, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildTeamsList(List teams) {
    if (teams.isEmpty) {
      return _buildEmptyState("No teams assigned yet", Icons.group_off_rounded);
    }
    return Column(
      children: teams.map((team) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orangeAccent.withOpacity(0.8), Colors.orange.withOpacity(0.4)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Icon(Icons.shield_rounded, color: Colors.white, size: 20)),
            ),
            title: Text(team['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text("${(team['players'] as List).length} Active Players", style: const TextStyle(color: Colors.white38, fontSize: 11)),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white12, size: 20),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white24, size: 24),
          const SizedBox(width: 12),
          Text(message, style: const TextStyle(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }
}
