import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/club_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import 'package:mobile/features/admin/presentation/screens/admin_hub_screen.dart';
import 'create_child_profile_screen.dart';
import 'invite_member_screen.dart';
import 'invitations_screen.dart';
import '../../../notifications/providers/notification_provider.dart';
import '../../../notifications/presentation/screens/notification_screen.dart';
import '../../../media/presentation/screens/media_gallery_screen.dart';
import 'academy_management_screen.dart';
import 'team_management_screen.dart';

class ClubDashboardScreen extends StatefulWidget {
  final bool isHome;
  final String? clubId;
  const ClubDashboardScreen({super.key, this.isHome = false, this.clubId});

  @override
  State<ClubDashboardScreen> createState() => _ClubDashboardScreenState();
}

class _ClubDashboardScreenState extends State<ClubDashboardScreen> {
  @override
  void initState() {
    super.initState();
    final clubProvider = context.read<ClubProvider>();
    final notifProvider = context.read<NotificationProvider>();
    Future.microtask(() {
      clubProvider.fetchClubDashboard(widget.isHome ? null : widget.clubId);
      notifProvider.fetchNotifications();
    });
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      body: Consumer<ClubProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.dashboard == null) {
            return Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen));
          }

          if (provider.error != null && provider.dashboard == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchClubDashboard(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final dashboard = provider.dashboard;
          if (dashboard == null) {
            final user = context.read<AuthProvider>().user;
            final isAdmin = user?.roles?.contains('ADMIN') ?? false;

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.business_center, size: 80, color: Colors.white10),
                    const SizedBox(height: 24),
                    const Text(
                      'You don\'t have a club registered yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 32),
                    _buildEmptyClubCard(context),
                    if (isAdmin) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const AdminHubScreen())),
                        icon: const Icon(Icons.admin_panel_settings, color: Colors.white54),
                        label: const Text('Admin: Moderation Panel',
                            style: TextStyle(color: Colors.white54)),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          if (widget.isHome) {
            return _buildHomeDashboard(context, dashboard);
          }

          return _buildManageHub(context, dashboard);
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HOME DASHBOARD
  // ─────────────────────────────────────────────

  Widget _buildHomeDashboard(BuildContext context, dynamic dashboard) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHomeHeader(context, dashboard)),
        SliverToBoxAdapter(child: _buildOverviewSection(context, dashboard)),
        SliverToBoxAdapter(child: _buildLiveMatchCard(dashboard)),
        SliverToBoxAdapter(child: _buildMonthlyGrowthSection(dashboard)),
        SliverToBoxAdapter(child: _buildInvitationsSection(context, dashboard)),
        SliverToBoxAdapter(child: _buildUpcomingFixturesSection(dashboard)),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }

  Widget _buildHomeHeader(BuildContext context, dynamic dashboard) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [const Color(0xFF1A3A6B), const Color(0xFF0A1220), PremiumTheme.surfaceBase(context)],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Icon(
              Icons.sports_soccer_rounded,
              size: 200,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'CLUB · DASHBOARD',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white54,
                          letterSpacing: 2,
                        ),
                      ),
                      const Spacer(),
                      Consumer<NotificationProvider>(
                        builder: (context, np, _) => GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const NotificationScreen())),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(Icons.notifications_outlined,
                                    color: Colors.white70, size: 20),
                                if (np.unreadCount > 0)
                                  Positioned(
                                    right: 6,
                                    top: 6,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: const BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${np.unreadCount}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.more_vert_rounded,
                            color: Colors.white70, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: PremiumTheme.neonGreen,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.sports_soccer_rounded,
                            color: Colors.black, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dashboard.club.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 12, color: Colors.white38),
                                const SizedBox(width: 4),
                                Text(
                                  '${dashboard.club.city} · Est. ${dashboard.club.createdAt.year}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.white38),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _copyToClipboard(dashboard.club.id, 'Club ID'),
                        child: Text(
                          'ID: ${dashboard.club.id.substring(0, 8)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white24,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection(BuildContext context, dynamic dashboard) {
    final playerCount = dashboard.playersCount + dashboard.childProfiles.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'OVERVIEW',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white38,
                    letterSpacing: 2),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ClubDashboardScreen(isHome: false))),
                child: Row(
                  children: [
                    Text(
                      'MANAGE HUB',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: PremiumTheme.neonGreen,
                          letterSpacing: 1),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded,
                        color: PremiumTheme.neonGreen, size: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.account_balance_rounded,
                  iconColor: PremiumTheme.neonGreen,
                  status: 'ACTIVE',
                  statusColor: PremiumTheme.neonGreen,
                  value: '${dashboard.academies.length}',
                  label: 'ACADEMIES',
                  bg: const Color(0xFF0A1F0D),
                  border: const Color(0xFF1A3320),
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideX(begin: -0.1, end: 0),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.shield_rounded,
                  iconColor: PremiumTheme.electricBlue,
                  status: 'COMPETING',
                  statusColor: PremiumTheme.electricBlue,
                  value: '${dashboard.teams.length}',
                  label: 'TEAMS',
                  bg: const Color(0xFF0D1627),
                  border: const Color(0xFF1A2D4A),
                ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideX(begin: 0.1, end: 0),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.sports_soccer_rounded,
                  iconColor: PremiumTheme.neonGreen,
                  status: 'REGISTERED',
                  statusColor: PremiumTheme.neonGreen,
                  value: '$playerCount',
                  label: 'PLAYERS',
                  bg: const Color(0xFF0A1F0D),
                  border: const Color(0xFF1A3320),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideX(begin: -0.1, end: 0),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.key_rounded,
                  iconColor: PremiumTheme.electricBlue,
                  status: 'ON STAFF',
                  statusColor: PremiumTheme.electricBlue,
                  value: '${dashboard.coachesCount}',
                  label: 'COACHES',
                  bg: const Color(0xFF0D1627),
                  border: const Color(0xFF1A2D4A),
                ).animate().fadeIn(delay: 250.ms, duration: 400.ms).slideX(begin: 0.1, end: 0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String status,
    required Color statusColor,
    required String value,
    required String label,
    required Color bg,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 20),
              Text(
                status,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: iconColor,
              letterSpacing: -1,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white38,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMatchCard(dynamic dashboard) {
    // Find a live or recent match from teams
    dynamic liveMatch;
    String? homeTeamName;

    for (final team in dashboard.teams) {
      for (final match in team.recentMatches) {
        if (match.status == 'LIVE' || match.status == 'IN_PROGRESS') {
          liveMatch = match;
          homeTeamName = team.name;
          break;
        }
      }
      if (liveMatch != null) break;
    }

    if (liveMatch == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A0A0A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25), width: 1),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Colors.redAccent, shape: BoxShape.circle),
                ).animate(onPlay: (c) => c.repeat())
                  .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 600.ms)
                  .then()
                  .scale(begin: const Offset(1.3, 1.3), end: const Offset(1, 1), duration: 600.ms),
                const SizedBox(width: 6),
                const Text(
                  'LIVE',
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 1),
                ),
                const Spacer(),
                Text(
                  dashboard.teams.isNotEmpty
                      ? '${dashboard.academies.isNotEmpty ? dashboard.academies.first.name : ""}'
                      : '',
                  style: const TextStyle(fontSize: 11, color: Colors.white38),
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
                        homeTeamName ?? 'Home',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.white),
                      ),
                      const Text('Home',
                          style: TextStyle(fontSize: 11, color: Colors.white38)),
                    ],
                  ),
                ),
                Text(
                  '${liveMatch.homeScore ?? 0} : ${liveMatch.awayScore ?? 0}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Away',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.white)),
                      const Text('Away',
                          style: TextStyle(fontSize: 11, color: Colors.white38)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyGrowthSection(dynamic dashboard) {
    final stats = dashboard.statistics as Map<String, dynamic>;
    final newPlayers = stats['monthly_players_delta'] ?? 0;
    final newCoaches = stats['monthly_coaches_delta'] ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MONTHLY GROWTH · 30D',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.white38,
                letterSpacing: 2),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildGrowthCard(
                  label: 'NEW PLAYERS',
                  value: newPlayers >= 0 ? '+$newPlayers' : '$newPlayers',
                  color: PremiumTheme.neonGreen,
                  bg: const Color(0xFF0A1F0D),
                  border: const Color(0xFF1A3320),
                  sparklineData: [1.0, 3.0, 2.0, 4.0, 3.0, 5.0, 4.0, 6.0, 5.0, 7.0, 8.0, 9.0 + newPlayers.toDouble().clamp(0.0, 10.0)],
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildGrowthCard(
                  label: 'NEW COACHES',
                  value: newCoaches >= 0 ? '+$newCoaches' : '$newCoaches',
                  color: Colors.amber,
                  bg: const Color(0xFF1F1A0A),
                  border: const Color(0xFF332A1A),
                  sparklineData: [2.0, 2.0, 3.0, 2.0, 3.0, 3.0, 4.0, 3.0, 4.0, 4.0, 5.0, 4.0 + newCoaches.toDouble().clamp(0.0, 5.0)],
                ).animate().fadeIn(delay: 350.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthCard({
    required String label,
    required String value,
    required Color color,
    required Color bg,
    required Color border,
    List<double>? sparklineData,
  }) {
    // Generate sample sparkline data if not provided
    final data = sparklineData ?? [2, 4, 3, 5, 4, 6, 5, 7, 6, 8, 7, 9];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.trending_up_rounded, color: color, size: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '30D',
                  style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white38,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 30,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: color,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withValues(alpha: 0.3),
                          color.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                minY: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationsSection(BuildContext context, dynamic dashboard) {
    final pending = (dashboard.pendingInvitations as List)
        .where((i) => !i.isApproved)
        .toList();
    final pendingCount = pending.length;
    if (pendingCount == 0) return const SizedBox.shrink();

    final previewIds = pending
        .take(3)
        .map((i) => i.invitedUserId.substring(0, 5))
        .join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('CLUB INVITATIONS · $pendingCount PENDING', accentColor: Colors.redAccent),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const InvitationsScreen())),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mail_outline_rounded,
                        color: Colors.redAccent, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Approvals waiting',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          previewIds,
                          style: const TextStyle(fontSize: 12, color: Colors.white38),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingFixturesSection(dynamic dashboard) {
    final now = DateTime.now();
    final List<_FixtureItem> fixtures = [];

    for (final team in dashboard.teams) {
      for (final match in team.recentMatches) {
        final scheduled = DateTime.tryParse(match.scheduledAt);
        if (scheduled != null && scheduled.isAfter(now) &&
            (match.status == 'SCHEDULED' || match.status == 'UPCOMING')) {
          final opponentId = match.homeTeamId == team.id
              ? match.awayTeamId
              : match.homeTeamId;
          final opponent = dashboard.teams
              .cast<dynamic>()
              .firstWhere((t) => t.id == opponentId,
                  orElse: () => null);
          fixtures.add(_FixtureItem(
            date: scheduled,
            homeTeamName: team.name,
            opponentName: opponent?.name ?? 'Opponent',
            isHome: match.homeTeamId == team.id,
            academyName: team.academyName ?? '',
          ));
        }
      }
    }

    if (fixtures.isEmpty) return const SizedBox.shrink();

    fixtures.sort((a, b) => a.date.compareTo(b.date));
    final shown = fixtures.take(5).toList();

    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('UPCOMING FIXTURES', accentColor: Colors.amber),
          const SizedBox(height: 12),
          ...shown.map((f) {
            final dayLabel = days[f.date.weekday - 1];
            final timeStr =
                '${f.date.hour.toString().padLeft(2, '0')}:${f.date.minute.toString().padLeft(2, '0')}';
            return GestureDetector(
              onTap: () {},
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.07), width: 1),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            dayLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: PremiumTheme.electricBlue,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '${f.date.day}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700),
                              children: [
                                TextSpan(
                                  text: f.homeTeamName,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const TextSpan(
                                  text: ' vs ',
                                  style: TextStyle(
                                      color: Colors.white38,
                                      fontWeight: FontWeight.w400),
                                ),
                                TextSpan(
                                  text: f.opponentName,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$timeStr  ·  ${f.academyName}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white38),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: Colors.white12, size: 18),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // MANAGE HUB (tabs)
  // ─────────────────────────────────────────────

  Widget _buildManageHub(BuildContext context, dynamic dashboard) {
    return DefaultTabController(
      length: 6,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: PremiumTheme.surfaceBase(context),
            elevation: 0,
            actions: [
              if (context.read<AuthProvider>().user?.roles?.contains('ADMIN') ?? false)
                IconButton(
                  icon: const Icon(Icons.admin_panel_settings, color: Colors.white70),
                  onPressed: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const AdminHubScreen())),
                ),
              IconButton(
                icon: const Icon(Icons.person_add_alt_1, color: Colors.white70),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            CreateChildProfileScreen(clubId: dashboard.club.id))),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 60),
              title: Text(
                dashboard.club.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: -0.3,
                    color: Colors.white),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [const Color(0xFF1A3A6B), PremiumTheme.surfaceBase(context)],
                      ),
                    ),
                  ),
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(Icons.sports_soccer_rounded,
                        size: 180, color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  Positioned(
                    left: 20,
                    top: 60,
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: PremiumTheme.neonGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.sports_soccer_rounded,
                              color: Colors.black, size: 22),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _copyToClipboard(dashboard.club.id, 'Club ID'),
                          child: Text(
                            'ID: ${dashboard.club.id.substring(0, 8)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white38,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottom: const TabBar(
              isScrollable: true,
              indicatorColor: PremiumTheme.neonGreen,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
              tabs: [
                Tab(text: 'ACADEMIES'),
                Tab(text: 'TEAMS'),
                Tab(text: 'PLAYERS'),
                Tab(text: 'COACHES'),
                Tab(text: 'MEDIA'),
                Tab(text: 'PENDING'),
              ],
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              children: [
                _buildAcademiesList(dashboard),
                _buildTeamsList(dashboard),
                _buildPlayersList(dashboard),
                _buildCoachesList(dashboard),
                MediaGalleryScreen(clubId: dashboard.club.id),
                _buildPendingInvitesList(dashboard),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB CONTENT
  // ─────────────────────────────────────────────

  Widget _buildAcademiesList(dynamic dashboard) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('CLUB BRANCHES'),
              IconButton(
                onPressed: () => _showCreateAcademyDialog(context),
                icon: const Icon(Icons.add_circle_outline, color: PremiumTheme.neonGreen),
              ),
            ],
          ),
        ),
        Expanded(
          child: dashboard.academies.isEmpty
              ? _buildEmptyState(Icons.account_balance_rounded, 'NO ACADEMIES')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: dashboard.academies.length,
                  itemBuilder: (context, index) {
                    final academy = dashboard.academies[index];
                    return _buildListCard(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => AcademyManagementScreen(
                                  academy: academy, dashboard: dashboard))),
                      leading: _buildEntityIcon(Icons.account_balance_rounded,
                          PremiumTheme.electricBlue),
                      title: academy.name,
                      subtitle: academy.city,
                      subtitleIcon: Icons.location_on_outlined,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTeamsList(dynamic dashboard) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            children: [
              _buildSectionLabel('ACTIVE TEAMS · ${dashboard.teams.length}'),
              const Spacer(),
              IconButton(
                onPressed: () => _showCreateTeamDialog(context),
                icon: const Icon(Icons.add_circle_outline, color: PremiumTheme.neonGreen),
              ),
            ],
          ),
        ),
        Expanded(
          child: dashboard.teams.isEmpty
              ? _buildEmptyState(Icons.shield_rounded, 'NO TEAMS')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: dashboard.teams.length,
                  itemBuilder: (context, index) {
                    final team = dashboard.teams[index];
                    return _buildTeamCard(context, team, dashboard);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTeamCard(BuildContext context, dynamic team, dynamic dashboard) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => TeamManagementScreen(
                  team: team, availableCoaches: dashboard.coaches))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildEntityIcon(Icons.shield_rounded, PremiumTheme.electricBlue),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(team.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
                      const SizedBox(height: 3),
                      Text(
                        '${team.academyName ?? ''} · ${team.ageCategory ?? ''}',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white12, size: 14),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTeamStat('RATING', '${team.rating}', Colors.amber),
                  _buildStatDivider(),
                  _buildTeamStat('W', '${team.wins}', PremiumTheme.neonGreen),
                  _buildStatDivider(),
                  _buildTeamStat('D', '${team.draws}', Colors.white54),
                  _buildStatDivider(),
                  _buildTeamStat('L', '${team.losses}', Colors.redAccent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 16, color: color, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 9, color: Colors.white24, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 20, color: Colors.white.withValues(alpha: 0.06));
  }

  Widget _buildPlayersList(dynamic dashboard) {
    final totalLinked = dashboard.players.length;
    final totalUnlinked = dashboard.childProfiles.length;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildMiniStatBox('TOTAL', '${totalLinked + totalUnlinked}', PremiumTheme.electricBlue)),
            const SizedBox(width: 10),
            Expanded(child: _buildMiniStatBox('LINKED', '$totalLinked', PremiumTheme.neonGreen)),
            const SizedBox(width: 10),
            Expanded(child: _buildMiniStatBox('UNLINKED', '$totalUnlinked', Colors.amber)),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionLabel('LINKED PLAYERS'),
        const SizedBox(height: 2),
        Container(
          height: 1,
          color: PremiumTheme.electricBlue.withValues(alpha: 0.2),
          margin: const EdgeInsets.only(bottom: 12),
        ),
        if (totalLinked == 0)
          _buildInlineEmpty('No linked players yet')
        else
          ...dashboard.players.map<Widget>((player) => _buildListCard(
            leading: _buildNumberAvatar(player.jerseyNumber?.toString() ?? '?', PremiumTheme.neonGreen),
            title: player.name,
            subtitle: '${player.position ?? ''} · ${player.jerseyNumber != null ? "${player.jerseyNumber}G" : "0G"}',
            subtitleBadge: player.position,
          )),
        const SizedBox(height: 24),
        _buildSectionLabel('UNLINKED PROFILES'),
        const SizedBox(height: 2),
        Container(
          height: 1,
          color: Colors.amber.withValues(alpha: 0.2),
          margin: const EdgeInsets.only(bottom: 12),
        ),
        if (totalUnlinked == 0)
          _buildInlineEmpty('No unlinked profiles')
        else
          ...dashboard.childProfiles.map<Widget>((child) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline_rounded, color: Colors.amber, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(child.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          _buildBadge('OFFLINE', Colors.amber),
                          const SizedBox(width: 6),
                          if (child.birthYear != null) _buildBadge('B. ${child.birthYear}', Colors.amber),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: PremiumTheme.neonGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.2)),
                  ),
                  child: const Text('INVITE',
                      style: TextStyle(
                          color: PremiumTheme.neonGreen, fontSize: 11, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          )),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildCoachesList(dynamic dashboard) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              Expanded(child: _buildMiniStatBox('COACHES', '${dashboard.coaches.length}', PremiumTheme.electricBlue)),
              const SizedBox(width: 10),
              Expanded(child: _buildMiniStatBox('TEAMS', '${dashboard.teams.length}', PremiumTheme.neonGreen)),
              const SizedBox(width: 10),
              Expanded(child: _buildMiniStatBox('AVG RATING', '4.8', Colors.amber)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionLabel('COACHING STAFF'),
              GestureDetector(
                onTap: () => _showInviteStaffDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add_alt_1_rounded, color: PremiumTheme.neonGreen, size: 14),
                      SizedBox(width: 6),
                      Text('ADD',
                          style: TextStyle(
                              color: PremiumTheme.neonGreen, fontSize: 10, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: dashboard.coaches.isEmpty
              ? _buildEmptyState(Icons.sports_rounded, 'NO COACHES')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: dashboard.coaches.length,
                  itemBuilder: (context, index) {
                    final coach = dashboard.coaches[index];
                    final initials = _getInitials(coach.name);
                    final coachTeams = dashboard.teams
                        .where((t) => t.coachId == coach.userId)
                        .toList();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: PremiumTheme.electricBlue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(coach.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: Colors.white)),
                                    const SizedBox(height: 3),
                                    Text(
                                      'ID: ${coach.userId.substring(0, 8)}',
                                      style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.25),
                                          fontSize: 10,
                                          fontFamily: 'monospace'),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _buildBadge('COACH', PremiumTheme.electricBlue),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded,
                                          color: Colors.amber, size: 12),
                                      const SizedBox(width: 3),
                                      const Text('4.8',
                                          style: TextStyle(
                                              color: Colors.amber,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (coachTeams.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.shield_outlined,
                                      size: 14, color: Colors.white.withValues(alpha: 0.3)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      coachTeams.map((t) => t.name).join(', '),
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white.withValues(alpha: 0.5),
                                          fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPendingInvitesList(dynamic dashboard) {
    if (dashboard.pendingInvitations.isEmpty) {
      return _buildEmptyState(Icons.hourglass_empty_rounded, 'NO PENDING INVITES');
    }

    final pending = (dashboard.pendingInvitations as List).where((i) => !i.isApproved).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: _buildSectionLabel('AWAITING ACTION · ${pending.length}'),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: dashboard.pendingInvitations.length,
            itemBuilder: (context, index) {
              final invite = dashboard.pendingInvitations[index];
              return _buildPendingCard(context, invite);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPendingCard(BuildContext context, dynamic invite) {
    final isApproved = invite.isApproved;
    final role = invite.role.toString().split('.').last;

    Color roleColor;
    switch (role) {
      case 'COACH':
        roleColor = Colors.amber;
        break;
      case 'PLAYER':
        roleColor = PremiumTheme.neonGreen;
        break;
      default:
        roleColor = Colors.purple;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isApproved
                  ? PremiumTheme.neonGreen.withValues(alpha: 0.1)
                  : Colors.amber.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isApproved ? Icons.check_circle_rounded : Icons.send_rounded,
              color: isApproved ? PremiumTheme.neonGreen : Colors.amber,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invite.invitedName ?? 'User ${invite.invitedUserId.substring(0, 8)}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
                ),
                const SizedBox(height: 4),
                _buildBadge(role, roleColor),
              ],
            ),
          ),
          if (!isApproved)
            GestureDetector(
              onTap: () => context.read<ClubProvider>().approveInvitation(invite.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: PremiumTheme.neonGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('APPROVE',
                    style: TextStyle(
                        color: Colors.black, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, color: PremiumTheme.neonGreen, size: 14),
                  const SizedBox(width: 4),
                  const Text('DONE',
                      style: TextStyle(
                          color: PremiumTheme.neonGreen, fontSize: 10, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SHARED HELPERS
  // ─────────────────────────────────────────────

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  Widget _buildEntityIcon(IconData icon, Color color) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildNumberAvatar(String number, Color color) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          number,
          style: const TextStyle(
              fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildListCard({
    VoidCallback? onTap,
    required Widget leading,
    required String title,
    String? subtitle,
    IconData? subtitleIcon,
    String? subtitleBadge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07), width: 1),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (subtitleIcon != null)
                          Icon(subtitleIcon, size: 12, color: Colors.white38),
                        if (subtitleIcon != null) const SizedBox(width: 4),
                        Text(subtitle,
                            style: const TextStyle(fontSize: 12, color: Colors.white38)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white12, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white24, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 2),
    );
  }

  Widget _buildSectionLabel(String title, {Color accentColor = PremiumTheme.neonGreen}) {
    return Row(
      children: [
        Container(width: 3, height: 14, color: accentColor,
            margin: const EdgeInsets.only(right: 8)),
        Text(
          title,
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white54, letterSpacing: 2),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: color, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildInlineEmpty(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(text,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.15), fontSize: 12)),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String label) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 44, color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 14),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.12),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _buildEmptyClubCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _showRequestClubDialog(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send_rounded, color: PremiumTheme.neonGreen),
            const SizedBox(width: 12),
            const Text('Request to Create a Club',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // DIALOGS
  // ─────────────────────────────────────────────

  void _showRequestClubDialog(BuildContext context) {
    final nameController = TextEditingController();
    final cityController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PremiumTheme.surfaceCard(context),
        title: const Text('Request Club Creation', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Club Name')),
              TextField(controller: cityController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'City')),
              TextField(controller: addressController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Address')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && cityController.text.isNotEmpty) {
                final success = await context.read<ClubProvider>().submitClubRequest({
                  'name': nameController.text,
                  'city': cityController.text,
                  'address': addressController.text,
                });
                if (success && context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }

  void _showCreateAcademyDialog(BuildContext context) {
    final nameController = TextEditingController();
    final cityController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PremiumTheme.surfaceCard(context),
        title: const Text('Add New Academy', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: cityController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'City')),
            TextField(controller: addressController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Address')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final clubId = context.read<ClubProvider>().dashboard?.club.id;
              if (clubId != null) {
                final success = await context.read<ClubProvider>().createAcademy(
                  clubId, nameController.text, cityController.text, addressController.text,
                );
                if (success && context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showCreateTeamDialog(BuildContext context) {
    final nameController = TextEditingController();
    final birthYearController = TextEditingController();
    final coachIdController = TextEditingController();
    String? selectedAcademyId;
    final academies = context.read<ClubProvider>().dashboard?.academies ?? [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: PremiumTheme.surfaceCard(context),
          title: const Text('Create New Team', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  dropdownColor: PremiumTheme.surfaceCard(context),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Academy'),
                  items: academies.map((a) => DropdownMenuItem(value: a.id.toString(), child: Text(a.name))).toList(),
                  onChanged: (val) => setDialogState(() => selectedAcademyId = val),
                ),
                TextField(controller: nameController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Team Name')),
                TextField(controller: birthYearController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Birth Year'), keyboardType: TextInputType.number),
                TextField(controller: coachIdController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Coach User ID')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (selectedAcademyId != null && nameController.text.isNotEmpty) {
                  final success = await context.read<ClubProvider>().createTeam(
                    selectedAcademyId!, nameController.text,
                    int.parse(birthYearController.text), coachIdController.text,
                  );
                  if (success && context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteStaffDialog(BuildContext context) {
    final clubId = context.read<ClubProvider>().dashboard?.club.id;
    if (clubId != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => InviteMemberScreen(clubId: clubId)));
    }
  }
}

class _FixtureItem {
  final DateTime date;
  final String homeTeamName;
  final String opponentName;
  final bool isHome;
  final String academyName;

  _FixtureItem({
    required this.date,
    required this.homeTeamName,
    required this.opponentName,
    required this.isHome,
    required this.academyName,
  });
}
