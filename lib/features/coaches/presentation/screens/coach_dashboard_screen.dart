import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/api/profile_api_service.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/features/matches/presentation/screens/live_match_screen.dart';
import 'package:mobile/features/notifications/presentation/screens/notification_screen.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'coach_teams_screen.dart';
import 'coach_attendance_screen.dart';

class CoachDashboardScreen extends StatefulWidget {
  const CoachDashboardScreen({super.key});

  @override
  State<CoachDashboardScreen> createState() => _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends State<CoachDashboardScreen> {
  final ProfileApiService _api = ProfileApiService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.getCoachDashboard();
  }

  void _refresh() => setState(() => _future = _api.getCoachDashboard());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          }
          if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          }
          final data = snapshot.data ?? {};
          return _buildBody(data);
        },
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: PremiumTheme.neonGreen,
        strokeWidth: 2,
      ),
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          Text(
            msg,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _refresh,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 18,
              color: PremiumTheme.neonGreen,
            ),
            label: const Text(
              'RETRY',
              style: TextStyle(color: PremiumTheme.neonGreen, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(Map<String, dynamic> data) {
    final perf = data['performance_stats'] as Map<String, dynamic>? ?? {};
    final matches = data['upcoming_matches'] as List? ?? [];
    final teams = data['teams'] as List? ?? [];
    final liveMatch =
        matches.isNotEmpty &&
            (matches.first['status']?.toString().toUpperCase() == 'IN_PROGRESS')
        ? matches.first
        : null;
    final needsLineup = matches.isNotEmpty && liveMatch == null
        ? matches.first
        : null;

    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      color: PremiumTheme.neonGreen,
      backgroundColor: PremiumTheme.surfaceCard(context),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildCoachCard(data)),
          SliverToBoxAdapter(child: _buildStatsRow(perf)),
          if (liveMatch != null)
            SliverToBoxAdapter(child: _buildLiveMatchCard(liveMatch)),
          if (needsLineup != null)
            SliverToBoxAdapter(child: _buildLineupActionCard(needsLineup)),
          SliverToBoxAdapter(child: _buildActionGrid(teams)),
          SliverToBoxAdapter(child: _buildTeamsSection(teams)),
          SliverToBoxAdapter(child: _buildUpcomingFixtures(matches)),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [const Color(0xFF0D2A1A), const Color(0xFF0A1510), PremiumTheme.surfaceBase(context)],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 16, 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chevron_left_rounded, color: Colors.white70, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'COACH · DASHBOARD',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white54,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              _buildIconBtn(
                Icons.notifications_none_rounded,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildIconBtn(
                Icons.more_horiz_rounded,
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showDashboardMenu(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDashboardMenu(BuildContext context) {
    final auth = context.read<AuthProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF0F1720),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            _menuItem(
              icon: Icons.edit_rounded,
              title: 'Edit Profile',
              onTap: () {
                Navigator.pop(context);
                // Navigate to edit profile if needed
              },
            ),
            _menuItem(
              icon: Icons.logout_rounded,
              title: 'Logout',
              color: Colors.redAccent,
              onTap: () {
                Navigator.pop(context);
                auth.logout();
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white70),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  // ─── ACTION GRID ──────────────────────────────────────────────────────────
  
  Widget _buildActionGrid(List teams) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUICK ACTIONS',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _actionBtn(
                icon: Icons.how_to_reg_rounded,
                label: 'ATTENDANCE',
                color: PremiumTheme.neonGreen,
                onTap: () {
                  HapticFeedback.heavyImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CoachAttendanceScreen(teams: teams)),
                  );
                },
              ),
              const SizedBox(width: 12),
              _actionBtn(
                icon: Icons.tactic_rounded, // Assuming tactic_rounded or similar exists
                fallbackIcon: Icons.architecture_rounded,
                label: 'TACTICS',
                color: PremiumTheme.electricBlue,
                onTap: () {
                  HapticFeedback.heavyImpact();
                  // TODO: Navigate to Tactics Board
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _actionBtn(
                icon: Icons.calendar_month_rounded,
                label: 'PLANNER',
                color: Colors.amber,
                onTap: () {
                  HapticFeedback.heavyImpact();
                  // TODO: Navigate to Training Planner
                },
              ),
              const SizedBox(width: 12),
              _actionBtn(
                icon: Icons.star_outline_rounded,
                label: 'SCOUTING',
                color: Colors.purpleAccent,
                onTap: () {
                  HapticFeedback.heavyImpact();
                  // TODO: Navigate to Scouting/Evaluation
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    IconData? fallbackIcon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: PremiumTheme.glassDecorationOf(context, radius: 18).copyWith(
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }

  // ─── COACH CARD ───────────────────────────────────────────────────────────

  Widget _buildCoachCard(Map<String, dynamic> data) {
    final name = data['name']?.toString() ?? 'Coach';
    final specialty = data['specialty']?.toString() ?? 'Head Coach';
    final club = data['club_name']?.toString() ?? '';
    final rating = data['rating']?.toString() ?? '0.0';
    final isCertified = data['is_certified'] == true;
    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0])
        .join()
        .toUpperCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: PremiumTheme.glassDecorationOf(context, radius: 20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: PremiumTheme.neonGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCertified) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: PremiumTheme.neonGreen.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: PremiumTheme.neonGreen.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_rounded,
                                color: PremiumTheme.neonGreen,
                                size: 10,
                              ),
                              SizedBox(width: 2),
                              Text(
                                'CERT',
                                style: TextStyle(
                                  color: PremiumTheme.neonGreen,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    club.isNotEmpty ? '$specialty · $club' : specialty,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 14,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      rating,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Text(
                  'RATING',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── STATS ROW ────────────────────────────────────────────────────────────

  Widget _buildStatsRow(Map<String, dynamic> perf) {
    final wins = (perf['wins'] ?? 0) as num;
    final total = (perf['matches_played'] ?? 0) as num;
    final winRate = total > 0
        ? '${(wins / total * 100).toStringAsFixed(0)}%'
        : '0%';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: PremiumTheme.glassDecorationOf(context, radius: 16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              _buildStatCell(winRate, 'WIN RATE', PremiumTheme.neonGreen),
              _buildDivider(),
              _buildStatCell(
                '${perf['matches_played'] ?? 0}',
                'MATCHES',
                Theme.of(context).colorScheme.onSurface,
              ),
              _buildDivider(),
              _buildStatCell(
                '${perf['goals_scored'] ?? 0}',
                'GOALS',
                PremiumTheme.electricBlue,
              ),
              _buildDivider(),
              _buildStatCell(
                '${perf['clean_sheets'] ?? 0}',
                'CLEAN',
                Colors.amber,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCell(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08));
  }

  // ─── LIVE MATCH CARD ──────────────────────────────────────────────────────

  Widget _buildLiveMatchCard(Map<String, dynamic> match) {
    final homeTeam = match['home_team_name']?.toString() ?? '';
    final awayTeam = match['away_team_name']?.toString() ?? '';
    final homeScore = match['home_score'] ?? 0;
    final awayScore = match['away_score'] ?? 0;
    final minute = match['minute']?.toString() ?? '67';
    final location = match['location']?.toString() ?? 'Main Campus · Pitch 1';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LiveMatchScreen(
              matchId: match['id']?.toString() ?? '',
              teamId: match['home_team_id']?.toString() ?? '',
              homeTeamName: homeTeam,
              awayTeamName: awayTeam,
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'LIVE · $minute\'',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    location,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          homeTeam,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'My team',
                          style: TextStyle(
                            color: PremiumTheme.neonGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$homeScore : $awayScore',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          awayTeam,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Opponent',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── LINEUP ACTION CARD ───────────────────────────────────────────────────

  Widget _buildLineupActionCard(Map<String, dynamic> match) {
    final homeTeam = match['home_team_name']?.toString() ?? '';
    final awayTeam = match['away_team_name']?.toString() ?? '';
    final scheduledAt = match['scheduled_at']?.toString() ?? '';
    final matchLabel =
        '$homeTeam vs $awayTeam · ${_formatMatchDate(scheduledAt)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: Colors.amber,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lineup required',
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    matchLabel,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'SUBMIT',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TEAMS SECTION ────────────────────────────────────────────────────────

  Widget _buildTeamsSection(List teams) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'MY TEAMS · ${teams.length}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CoachTeamsScreen(teams: teams),
                  ),
                ),
                child: const Text(
                  'ALL TEAMS →',
                  style: TextStyle(
                    color: PremiumTheme.neonGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...teams.take(3).map((team) => _buildTeamCard(team)),
        ],
      ),
    );
  }

  Widget _buildTeamCard(Map<String, dynamic> team) {
    final name = team['name']?.toString() ?? 'Team';
    final ageGroup = team['age_category']?.toString() ?? team['birth_year']?.toString() ?? '';
    final players = (team['players'] as List?)?.length ?? 0;
    final isLive = team['is_live'] == true;
    final elo = team['elo_rating']?.toString() ?? '1200';
    final form = (team['form'] as List?)?.cast<String>() ?? [];
    final wins = team['wins'] ?? 0;
    final draws = team['draws'] ?? 0;
    final losses = team['losses'] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: PremiumTheme.glassDecorationOf(context, radius: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: PremiumTheme.neonGreen.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: PremiumTheme.neonGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (ageGroup.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              'U$ageGroup',
                              style: const TextStyle(color: PremiumTheme.neonGreen, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                          if (isLive) ...[
                            const SizedBox(width: 8),
                            _buildLiveBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$players players · $wins W - $draws D - $losses L',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      elo,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    const Text('ELO', style: TextStyle(color: PremiumTheme.neonGreen, fontSize: 8, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ...form.take(7).map((r) => _buildFormChip(r)),
                const Spacer(),
                Text(
                  '${wins}W ${draws}D ${losses}L',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 3),
          const Text(
            'LIVE',
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormChip(String result) {
    Color bg;
    Color text;
    switch (result.toUpperCase()) {
      case 'W':
        bg = PremiumTheme.neonGreen.withValues(alpha: 0.2);
        text = PremiumTheme.neonGreen;
        break;
      case 'D':
        bg = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1);
        text = Theme.of(context).colorScheme.onSurfaceVariant;
        break;
      default:
        bg = Colors.redAccent.withValues(alpha: 0.2);
        text = Colors.redAccent;
    }
    return Container(
      width: 26,
      height: 26,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          result.toUpperCase(),
          style: TextStyle(
            color: text,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  // ─── UPCOMING FIXTURES ────────────────────────────────────────────────────

  Widget _buildUpcomingFixtures(List matches) {
    final upcoming = matches
        .where(
          (m) => (m['status']?.toString().toUpperCase() ?? '') != 'IN_PROGRESS',
        )
        .take(5)
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 3, height: 16, color: PremiumTheme.neonGreen),
              const SizedBox(width: 8),
              Text(
                'UPCOMING FIXTURES',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (upcoming.isEmpty)
            _buildEmptyFixtures()
          else
            ...upcoming.map((m) => _buildFixtureRow(m)),
        ],
      ),
    );
  }

  Widget _buildEmptyFixtures() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: PremiumTheme.glassDecorationOf(context, radius: 16),
      child: Center(
        child: Text(
          'NO UPCOMING FIXTURES',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildFixtureRow(Map<String, dynamic> match) {
    final homeTeam = match['home_team_name']?.toString() ?? '';
    final awayTeam = match['away_team_name']?.toString() ?? '';
    final scheduledAt = match['scheduled_at']?.toString() ?? '';
    final location = match['location']?.toString() ?? 'Main';
    final pitch = match['pitch']?.toString() ?? '';

    DateTime? dt;
    try {
      dt = DateTime.parse(scheduledAt);
    } catch (_) {}
    final dayName = dt != null ? _weekdayShort(dt.weekday) : '';
    final dayNum = dt?.day.toString() ?? '--';
    final timeStr = dt != null
        ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
        : '';
    final locationStr = [
      location,
      pitch,
    ].where((s) => s.isNotEmpty).join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: PremiumTheme.glassDecorationOf(context, radius: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: PremiumTheme.electricBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: const TextStyle(
                      color: PremiumTheme.electricBlue,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    dayNum,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: homeTeam,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: ' vs ',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11),
                        ),
                        TextSpan(
                          text: awayTeam,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$timeStr · $locationStr',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _weekdayShort(int w) =>
      ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][w - 1];

  String _formatMatchDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${_weekdayShort(dt.weekday)} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
