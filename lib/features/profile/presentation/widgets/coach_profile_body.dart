import 'package:flutter/material.dart';
import 'package:mobile/core/api/profile_api_service.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:provider/provider.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/core/presentation/widgets/orleon_widgets.dart';
import 'package:mobile/features/matches/presentation/screens/live_match_screen.dart';
import 'package:mobile/features/academies/presentation/screens/academy_dashboard_screen.dart';
import 'package:mobile/features/coaches/presentation/screens/coach_dashboard_screen.dart';
import 'package:mobile/features/coaches/presentation/screens/coach_teams_screen.dart';
import 'package:mobile/features/coaches/presentation/screens/coach_performance_screen.dart';

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
        final perf = (data['performance_stats'] as Map<String, dynamic>?) ?? {};
        final matches = data['upcoming_matches'] as List? ?? [];
        final teams = data['teams'] as List? ?? [];
        final topPerformers = data['top_performers'] as List? ?? [];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildUserInfo(context),
              const SizedBox(height: 24),
              _buildCoachQuickActions(data, teams, perf, topPerformers),
              const SizedBox(height: 32),

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
        child: OrleonCard(
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
          child: OrleonStatCard(
            label: 'Win Rate',
            value: '$winRate%',
            icon: Icons.auto_graph_rounded,
            accent: PremiumTheme.neonGreen,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OrleonStatCard(
            label: 'Goals',
            value: '${perf['goals_scored'] ?? 0}',
            icon: Icons.sports_soccer_rounded,
            accent: PremiumTheme.electricBlue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OrleonStatCard(
            label: 'Clean',
            value: '${perf['clean_sheets'] ?? 0}',
            icon: Icons.shield_rounded,
            accent: PremiumTheme.amber,
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
        child: OrleonCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: PremiumTheme.electricBlue.withValues(alpha: 0.1),
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
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {
                      final homeId = match['home_team_id']?.toString() ?? '';
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LiveMatchScreen(
                            matchId: match['id'].toString(),
                            teamId: homeId,
                            homeTeamName: match['home_team_name']?.toString() ?? 'Home',
                            awayTeamName: match['away_team_name']?.toString() ?? 'Away',
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.redAccent, size: 6),
                          SizedBox(width: 4),
                          Text('LIVE', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                        ],
                      ),
                    ),
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
        child: OrleonCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      PremiumTheme.neonGreen.withValues(alpha: 0.18),
                      PremiumTheme.neonGreen.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.shield_rounded, color: PremiumTheme.neonGreen, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team['name'].toString().toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded, size: 12, color: Colors.white.withValues(alpha: 0.3)),
                        const SizedBox(width: 4),
                        Text(
                          "${(team['players'] as List).length} ACTIVE PLAYERS",
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.2), size: 18),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildCoachQuickActions(
    Map<String, dynamic> data,
    List teams,
    Map<String, dynamic> perf,
    List topPerformers,
  ) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final roles = auth.user?.roles ?? [];
        final isOrganizer = roles.contains('TOURNAMENT_ORGANIZER');

        return Column(
          children: [
            Row(
              children: [
                if (isOrganizer)
                  Expanded(
                    child: _quickActionCard(
                      icon: Icons.emoji_events_rounded,
                      color: PremiumTheme.neonGreen,
                      title: 'TOURNAMENT HUB',
                      subtitle: 'Manage Your Events',
                      onTap: () => Navigator.pushNamed(context, '/tournaments'),
                    ),
                  )
                else
                  Expanded(
                    child: _quickActionCard(
                      icon: Icons.dashboard_rounded,
                      color: PremiumTheme.neonGreen,
                      title: 'COACH HUB',
                      subtitle: 'Dashboard & Fixtures',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CoachDashboardScreen()),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: _quickActionCard(
                    icon: Icons.groups_rounded,
                    color: PremiumTheme.electricBlue,
                    title: 'MY TEAMS',
                    subtitle: '${teams.length} teams · Players',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CoachTeamsScreen(teams: teams)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _quickActionCard(
                    icon: Icons.analytics_rounded,
                    color: Colors.amber,
                    title: 'PERFORMANCE',
                    subtitle: 'Stats & Top Performers',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CoachPerformanceScreen(
                          perf: perf,
                          topPerformers: topPerformers,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _quickActionCard(
                    icon: Icons.school_rounded,
                    color: Colors.purpleAccent,
                    title: 'ACADEMY CRM',
                    subtitle: 'Schedule & Billing',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AcademyDashboardScreen()),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _quickActionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    return OrleonCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: PremiumTheme.neonGreen.withOpacity(0.5)),
              const SizedBox(width: 8),
              const Text(
                "ABOUT ME",
                style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            user.bio?.isNotEmpty == true ? user.bio! : "No biography provided yet. Tap 'Edit' to add one.",
            style: TextStyle(
              color: user.bio?.isNotEmpty == true ? Colors.white : Colors.white24,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (user.phone?.isNotEmpty == true) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.phone_android_rounded, size: 14, color: PremiumTheme.electricBlue.withOpacity(0.5)),
                const SizedBox(width: 8),
                Text(
                  user.phone!,
                  style: const TextStyle(color: PremiumTheme.electricBlue, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message, IconData icon) {
    return OrleonCard(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.1), size: 32),
            const SizedBox(height: 12),
            Text(
              message.toUpperCase(),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
