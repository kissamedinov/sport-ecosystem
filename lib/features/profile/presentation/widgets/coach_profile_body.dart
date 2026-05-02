import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/api/profile_api_service.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:provider/provider.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/features/clubs/providers/club_provider.dart';
import 'package:mobile/core/presentation/widgets/orleon_widgets.dart';
import 'package:mobile/features/matches/presentation/screens/live_match_screen.dart';
import 'package:mobile/features/academies/presentation/screens/academy_dashboard_screen.dart';
import 'package:mobile/features/coaches/presentation/screens/coach_dashboard_screen.dart';
import 'package:mobile/features/coaches/presentation/screens/coach_teams_screen.dart';
import 'package:mobile/features/coaches/presentation/screens/coach_performance_screen.dart';
import 'package:mobile/features/coaches/presentation/screens/coach_attendance_screen.dart';

class CoachProfileBody extends StatefulWidget {
  final String coachId;

  const CoachProfileBody({super.key, required this.coachId});

  @override
  State<CoachProfileBody> createState() => _CoachProfileBodyState();
}

class _CoachProfileBodyState extends State<CoachProfileBody> {
  late Future<void> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = context.read<ClubProvider>().fetchCoachDashboard();
  }

  void _refresh() {
    setState(() {
      _dashboardFuture = context.read<ClubProvider>().fetchCoachDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }
        
        final data = context.watch<ClubProvider>().coachDashboard ?? {};
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
              _buildCoachIdCard(context),
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
              Text(
                "SYSTEM ERROR",
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
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
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.2),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.emoji_events_rounded, size: 10, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          (match['tournament_name'] ?? "REGULAR MATCH").toString().toUpperCase(),
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
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
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700, fontSize: 12),
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
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          "${(team['players'] as List).length} ACTIVE PLAYERS",
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 18),
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
                Expanded(
                  child: _quickActionCard(
                    icon: Icons.how_to_reg_rounded,
                    color: PremiumTheme.neonGreen,
                    title: 'ATTENDANCE',
                    subtitle: 'Track Training',
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CoachAttendanceScreen(teams: teams)),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _quickActionCard(
                    icon: Icons.architecture_rounded,
                    color: PremiumTheme.electricBlue,
                    title: 'TACTICS',
                    subtitle: 'Formations',
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      // Navigate
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _quickActionCard(
                    icon: Icons.calendar_month_rounded,
                    color: Colors.amber,
                    title: 'PLANNER',
                    subtitle: 'Daily Agenda',
                    onTap: () {
                      HapticFeedback.heavyImpact();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _quickActionCard(
                    icon: Icons.dashboard_rounded,
                    color: Colors.purpleAccent,
                    title: 'DASHBOARD',
                    subtitle: 'Stats & Fixtures',
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CoachDashboardScreen()),
                      );
                    },
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: color.withValues(alpha: 0.1),
        highlightColor: color.withValues(alpha: 0.05),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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
              Text(
                "ABOUT ME",
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            user.bio?.isNotEmpty == true ? user.bio! : "No biography provided yet. Tap 'Edit' to add one.",
            style: TextStyle(
              color: user.bio?.isNotEmpty == true
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
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

  Widget _buildCoachIdCard(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final String code = user?.uniqueCode ?? "ID-PENDING";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PremiumTheme.neonGreen.withValues(alpha: 0.15),
            PremiumTheme.neonGreen.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.badge_rounded, color: PremiumTheme.neonGreen, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "UNIQUE COACH ID",
                  style: TextStyle(color: PremiumTheme.neonGreen, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Text(
                  code,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Use this ID to be invited to a team",
                  style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          _circleIconButton(
            icon: Icons.copy_all_rounded,
            onTap: () {
              Clipboard.setData(ClipboardData(text: code));
              HapticFeedback.heavyImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("ID COPIED TO CLIPBOARD"),
                  backgroundColor: PremiumTheme.neonGreen,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _circleIconButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white10),
          ),
          child: Icon(icon, color: Colors.white70, size: 18),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message, IconData icon) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return OrleonCard(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: muted.withValues(alpha: 0.4), size: 32),
            const SizedBox(height: 12),
            Text(
              message.toUpperCase(),
              style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
