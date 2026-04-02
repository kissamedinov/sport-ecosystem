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

  void _refresh() {
    setState(() {
      _dashboardFuture = _profileApi.getCoachDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }
        
        final data = snapshot.data ?? {};
        final perf = data['performance_stats'] ?? {};
        final matches = data['upcoming_matches'] as List? ?? [];
        final teams = data['teams'] as List? ?? [];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildSectionHeader("PERFORMANCE OVERVIEW", Icons.analytics_rounded),
              const SizedBox(height: 16),
              _buildPerformanceStats(perf),
              const SizedBox(height: 32),
              
              _buildSectionHeader("UPCOMING MATCHES", Icons.event_available_rounded),
              const SizedBox(height: 16),
              _buildUpcomingMatches(matches),
              const SizedBox(height: 32),
              
              _buildSectionHeader("TEAMS COACHED  •  ${teams.length}", Icons.groups_rounded),
              const SizedBox(height: 16),
              _buildTeamsList(teams),
              const SizedBox(height: 48),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(60),
        child: Column(
          children: [
            const CircularProgressIndicator(color: PremiumTheme.neonGreen, strokeWidth: 2),
            const SizedBox(height: 20),
            Text(
              "SYNCING DATA...", 
              style: TextStyle(
                color: PremiumTheme.neonGreen.withOpacity(0.5), 
                fontSize: 10, 
                fontWeight: FontWeight.w900,
                letterSpacing: 2
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: PremiumCard(
          child: Column(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
              const SizedBox(height: 16),
              const Text(
                "SYSTEM ERROR",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              Text(
                error, 
                style: const TextStyle(color: Colors.white38, fontSize: 12), 
                textAlign: TextAlign.center
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text("RETRY CONNECTION"),
                style: TextButton.styleFrom(foregroundColor: PremiumTheme.neonGreen),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: PremiumTheme.neonGreen.withOpacity(0.5)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11, 
            fontWeight: FontWeight.w900, 
            color: Colors.white54, 
            letterSpacing: 2,
          ),
        ),
        const Spacer(),
        Container(
          width: 40,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [PremiumTheme.neonGreen.withOpacity(0.3), Colors.transparent],
            ),
          ),
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
        Expanded(
          child: PremiumStatCard(
            title: "WIN RATE",
            value: "$winRate%",
            icon: Icons.auto_graph_rounded,
            color: PremiumTheme.neonGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PremiumStatCard(
            title: "GOALS",
            value: "${perf['goals_scored'] ?? 0}",
            icon: Icons.sports_soccer_rounded,
            color: PremiumTheme.electricBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PremiumStatCard(
            title: "CLEAN SHEETS",
            value: "${perf['clean_sheets'] ?? 0}",
            icon: Icons.shield_rounded,
            color: Colors.orangeAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingMatches(List matches) {
    if (matches.isEmpty) {
      return _buildEmptyCard("No upcoming matches scheduled", Icons.event_busy_rounded);
    }
    return Column(
      children: matches.map((match) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: PremiumCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: PremiumTheme.electricBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.sports_soccer_rounded, color: PremiumTheme.electricBlue, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${match['home_team_name']} VS ${match['away_team_name']}",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.2),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.emoji_events_rounded, size: 10, color: Colors.white.withOpacity(0.3)),
                        const SizedBox(width: 4),
                        Text(
                          (match['tournament_name'] ?? "REGULAR MATCH").toString().toUpperCase(),
                          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    match['scheduled_at'] != null 
                      ? match['scheduled_at'].toString().split('T').first 
                      : "TBD",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "KICK-OFF",
                    style: TextStyle(color: PremiumTheme.neonGreen.withOpacity(0.7), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ],
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildTeamsList(List teams) {
    if (teams.isEmpty) {
      return _buildEmptyCard("No teams currently assigned", Icons.group_off_rounded);
    }
    return Column(
      children: teams.map((team) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: PremiumCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Stack(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [PremiumTheme.neonGreen.withOpacity(0.2), PremiumTheme.neonGreen.withOpacity(0.05)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: PremiumTheme.neonGreen.withOpacity(0.1)),
                  ),
                  child: const Icon(Icons.shield_rounded, color: PremiumTheme.neonGreen, size: 24),
                ),
              ],
            ),
            title: Text(
              team['name'].toString().toUpperCase(), 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.person_outline_rounded, size: 12, color: Colors.white.withOpacity(0.3)),
                  const SizedBox(width: 4),
                  Text(
                    "${(team['players'] as List).length} ACTIVE PLAYERS", 
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11, fontWeight: FontWeight.w500)
                  ),
                ],
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_right_rounded, color: PremiumTheme.neonGreen, size: 20),
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildEmptyCard(String message, IconData icon) {
    return PremiumCard(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.1), size: 32),
            const SizedBox(height: 12),
            Text(
              message.toUpperCase(), 
              style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
