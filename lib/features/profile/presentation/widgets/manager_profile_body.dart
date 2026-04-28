import 'package:flutter/material.dart';
import 'package:mobile/core/api/profile_api_service.dart';
import 'package:mobile/core/theme/premium_theme.dart';
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

  void _refresh() {
    setState(() {
      _teamsFuture = _profileApi.getManagedTeams();
      _matchesFuture = _profileApi.getRecentMatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Team>>(
      future: _teamsFuture,
      builder: (context, teamSnapshot) {
        return FutureBuilder<List<MatchModel>>(
          future: _matchesFuture,
          builder: (context, matchSnapshot) {
            final isLoading =
                teamSnapshot.connectionState == ConnectionState.waiting ||
                matchSnapshot.connectionState == ConnectionState.waiting;

            if (isLoading) return _buildLoadingState();

            if (teamSnapshot.hasError && matchSnapshot.hasError) {
              return _buildErrorState(teamSnapshot.error.toString());
            }

            final teams = teamSnapshot.data ?? [];
            final matches = matchSnapshot.data ?? [];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildSectionLabel("OVERVIEW"),
                  const SizedBox(height: 12),
                  _buildStatsRow(teams.length, matches.length),
                  const SizedBox(height: 28),
                  _buildSectionLabel("OPERATIONAL TEAMS  •  ${teams.length}"),
                  const SizedBox(height: 12),
                  _buildTeamsList(teams),
                  const SizedBox(height: 28),
                  _buildSectionLabel("RECENT MATCH LOGS"),
                  const SizedBox(height: 12),
                  _buildMatchesList(matches),
                  const SizedBox(height: 28),
                  _buildSectionLabel("QUICK ACTIONS"),
                  const SizedBox(height: 12),
                  _buildActions(),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            const CircularProgressIndicator(color: PremiumTheme.neonGreen, strokeWidth: 2),
            const SizedBox(height: 16),
            Text(
              "SYNCING DATA...",
              style: TextStyle(
                color: PremiumTheme.neonGreen.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
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
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              "Error: $error",
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text("RETRY"),
              style: TextButton.styleFrom(foregroundColor: PremiumTheme.neonGreen),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: PremiumTheme.neonGreen,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(int teamCount, int matchCount) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard("Teams", "$teamCount", Icons.shield_rounded, PremiumTheme.electricBlue, subtitle: "MANAGED"),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard("Matches", "$matchCount", Icons.sports_soccer_rounded, PremiumTheme.neonGreen, subtitle: "RECENT"),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 8,
                    color: color.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -1,
            ),
          ),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsList(List<Team> teams) {
    if (teams.isEmpty) {
      return _buildEmptyState("No teams under management", Icons.shield_outlined);
    }

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: teams.length,
        itemBuilder: (context, index) {
          final team = teams[index];
          final colors = [PremiumTheme.electricBlue, PremiumTheme.neonGreen, Colors.orangeAccent, Colors.purpleAccent];
          final color = colors[index % colors.length];

          return Container(
            width: 150,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.03)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.shield_rounded, color: color, size: 22),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      team.ageCategory ?? "Academy",
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMatchesList(List<MatchModel> matches) {
    if (matches.isEmpty) {
      return _buildEmptyState("No recent match activity", Icons.history_rounded);
    }

    final displayMatches = matches.length > 3 ? matches.take(3).toList() : matches;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      children: displayMatches.map((match) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MatchEventsScreen(matchId: match.id)),
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: onSurface.withValues(alpha: 0.07)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: PremiumTheme.electricBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.history_rounded, color: PremiumTheme.electricBlue, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Match vs ${match.awayTeamId.substring(0, 4).toUpperCase()}...",
                        style: TextStyle(
                          color: onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        match.status.toUpperCase(),
                        style: TextStyle(
                          color: match.status == 'FINISHED'
                              ? muted
                              : PremiumTheme.neonGreen.withValues(alpha: 0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: muted, size: 20),
              ],
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        _buildActionButton("Academy CRM Management", Icons.school_rounded, PremiumTheme.electricBlue, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AcademyDashboardScreen()));
        }),
        const SizedBox(height: 10),
        _buildActionButton("Register for Tournament", Icons.emoji_events_rounded, Colors.amber, () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Tournament registration coming soon")),
          );
        }),
        const SizedBox(height: 10),
        _buildActionButton("Coordinate Field Schedules", Icons.stadium_rounded, PremiumTheme.neonGreen, () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Field scheduling coming soon")),
          );
        }),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: onSurface.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: onSurface.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: muted, size: 24),
          const SizedBox(width: 12),
          Text(message, style: TextStyle(color: muted, fontSize: 13)),
        ],
      ),
    );
  }
}
