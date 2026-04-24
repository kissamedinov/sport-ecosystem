import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/premium_theme.dart';
import '../../../core/presentation/widgets/orleon_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../clubs/providers/club_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../notifications/presentation/screens/notification_screen.dart';
import '../../matches/presentation/screens/live_match_screen.dart';
import '../../coaches/presentation/screens/coach_teams_screen.dart';
import '../../stats/presentation/screens/performance_screen.dart';
import '../../lineups/presentation/screens/lineup_screen.dart';
import '../../tournaments/presentation/screens/tournament_announcements_screen.dart';
import 'package:mobile/features/profile/presentation/screens/profile_screen.dart';

class CoachDashboardScreen extends StatefulWidget {
  const CoachDashboardScreen({super.key});

  @override
  State<CoachDashboardScreen> createState() => _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends State<CoachDashboardScreen>
    with SingleTickerProviderStateMixin {
  int _tabIndex = 0;
  late final AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..forward();
    Future.microtask(() {
      if (!mounted) return;
      context.read<ClubProvider>().fetchCoachDashboard();
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _goTab(int idx) async {
    if (idx == _tabIndex) return;
    _fadeCtrl.reset();
    setState(() => _tabIndex = idx);
    _fadeCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _HomeTab(),
      const CoachTeamsScreen(embedded: true),
      const TournamentAnnouncementsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: PremiumTheme.deepNavy,
      extendBody: true,
      body: FadeTransition(
        opacity: CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut),
        child: pages[_tabIndex],
      ),
      bottomNavigationBar: _CoachBottomNav(
        index: _tabIndex,
        onChanged: _goTab,
        onFabTap: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const LineupScreen(),
              transitionsBuilder: (_, a, __, c) =>
                  FadeTransition(opacity: a, child: c),
              transitionDuration: const Duration(milliseconds: 220),
            ),
          );
        },
      ),
    );
  }
}

/// ─────────────────────────── HOME TAB ───────────────────────────
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return Consumer2<ClubProvider, NotificationProvider>(
      builder: (context, club, notif, _) {
        final data = club.coachDashboard ?? {};
        final user = context.watch<AuthProvider>().user;

        if (club.isLoading && data.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              color: PremiumTheme.neonGreen,
              strokeWidth: 2,
            ),
          );
        }

        final perf = (data['performance_stats'] as Map<String, dynamic>?) ?? {};
        final matches = (data['upcoming_matches'] as List?) ?? [];
        final teams = (data['teams'] as List?) ?? [];
        final trainings = (data['trainings'] as List?) ?? [];

        final liveMatch = matches.isNotEmpty &&
                (matches.first['status']?.toString().toUpperCase() == 'IN_PROGRESS')
            ? matches.first as Map<String, dynamic>
            : null;
        final needsLineup = matches.isNotEmpty && liveMatch == null
            ? matches.first as Map<String, dynamic>
            : null;

        return RefreshIndicator(
          onRefresh: () async {
            await club.fetchCoachDashboard();
            await notif.fetchNotifications();
          },
          color: PremiumTheme.neonGreen,
          backgroundColor: PremiumTheme.cardNavy,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _HeroBlock(
                  user: user,
                  notif: notif,
                  perf: perf,
                  name: _coachName(user),
                  specialty: (data['specialty'] ?? 'FOOTBALL TACTICS').toString(),
                  rating: _toDouble(data['coach_rating'] ?? data['rating'] ?? 4.8),
                ),
              ),
              if (liveMatch != null)
                SliverToBoxAdapter(
                  child: _section(
                    child: OrleonLiveMatchCard(
                      homeTeam: (liveMatch['team_name'] ?? 'MY TEAM').toString(),
                      awayTeam: (liveMatch['opponent'] ?? 'OPPONENT').toString(),
                      homeScore: _toInt(liveMatch['home_score']),
                      awayScore: _toInt(liveMatch['away_score']),
                      minute: (liveMatch['minute'] ?? '0\'').toString(),
                      competition: (liveMatch['competition'] ?? 'LEAGUE').toString(),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LiveMatchScreen(
                            matchId: liveMatch['id'].toString(),
                            teamId: (liveMatch['team_id'] ?? '').toString(),
                            homeTeamName: (liveMatch['team_name'] ?? 'My Team').toString(),
                            awayTeamName: (liveMatch['opponent'] ?? 'Opponent').toString(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (needsLineup != null)
                SliverToBoxAdapter(
                  child: _section(child: _LineupAlertCard(match: needsLineup)),
                ),
              SliverToBoxAdapter(
                child: OrleonSectionHeader(
                  title: 'My Teams',
                  action: 'See all',
                  onAction: () {},
                ),
              ),
              SliverToBoxAdapter(child: _TeamsList(teams: teams)),
              const SliverToBoxAdapter(
                child: OrleonSectionHeader(title: 'Upcoming Fixtures'),
              ),
              SliverToBoxAdapter(child: _FixturesList(matches: matches)),
              const SliverToBoxAdapter(
                child: OrleonSectionHeader(title: 'Trainings This Week'),
              ),
              SliverToBoxAdapter(child: _TrainingsList(trainings: trainings)),
              const SliverToBoxAdapter(
                child: OrleonSectionHeader(title: 'Coaching Tools'),
              ),
              const SliverToBoxAdapter(child: _CoachingToolsGrid()),
              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          ),
        );
      },
    );
  }

  static Widget _section({required Widget child}) =>
      Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 0), child: child);

  static String _coachName(dynamic user) {
    final name = (user?.name?.toString() ?? '').trim();
    return name.isEmpty ? (user?.email?.toString() ?? 'Coach') : name;
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }

  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}

/// ─────────────────────────── HERO BLOCK ───────────────────────────
class _HeroBlock extends StatelessWidget {
  final dynamic user;
  final NotificationProvider notif;
  final Map<String, dynamic> perf;
  final String name;
  final String specialty;
  final double rating;

  const _HeroBlock({
    required this.user,
    required this.notif,
    required this.perf,
    required this.name,
    required this.specialty,
    required this.rating,
  });

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  String _pct(dynamic v) {
    final d = v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
    final pct = d > 1 ? d : d * 100;
    return '${pct.toStringAsFixed(0)}%';
  }

  void _showDashboardMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _menuItem(ctx, Icons.person_outline_rounded, 'My Profile', Colors.white70, () {
              Navigator.pop(ctx);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            }),
            _menuItem(ctx, Icons.notifications_outlined, 'Notifications', Colors.white70, () {
              Navigator.pop(ctx);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            }),
            _menuItem(ctx, Icons.settings_outlined, 'Settings', Colors.white70, () {
              Navigator.pop(ctx);
            }),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(BuildContext ctx, IconData icon, String label, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 16),
              Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unread = notif.notifications.where((n) => !n.isRead).length;
    final safeTop = MediaQuery.of(context).padding.top;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D2E14), Color(0xFF0A0E12)],
          stops: [0.0, 1.0],
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, safeTop + 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (Navigator.of(context).canPop()) ...[
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ],
              const Expanded(
                child: Text(
                  'COACH  ·  DASHBOARD',
                  style: TextStyle(
                    color: PremiumTheme.neonGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationScreen()),
                ),
                child: _HeroIconButton(
                  icon: Icons.notifications_outlined,
                  badge: unread,
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _showDashboardMenu(context),
                child: const _HeroIconButton(icon: Icons.more_horiz_rounded),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: PremiumTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: PremiumTheme.neonShadow(),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
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
                        Expanded(
                          child: Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: PremiumTheme.neonGreen.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: PremiumTheme.neonGreen.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Text(
                            'CERT',
                            style: TextStyle(
                              color: PremiumTheme.neonGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specialty.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: PremiumTheme.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'coach rating',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OrleonStatCard(
                  icon: Icons.auto_graph_rounded,
                  label: 'Win Rate',
                  value: _pct(perf['win_rate'] ?? perf['winRate']),
                  accent: PremiumTheme.neonGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OrleonStatCard(
                  icon: Icons.sports_soccer_outlined,
                  label: 'Matches',
                  value: (perf['matches_played'] ?? perf['matches'] ?? 0).toString(),
                  accent: Colors.white54,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OrleonStatCard(
                  icon: Icons.sports_soccer,
                  label: 'Goals',
                  value: (perf['goals_scored'] ?? perf['goals'] ?? 0).toString(),
                  accent: PremiumTheme.electricBlue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OrleonStatCard(
                  icon: Icons.shield_rounded,
                  label: 'Clean',
                  value: (perf['clean_sheets'] ?? 0).toString(),
                  accent: PremiumTheme.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  final IconData icon;
  final int badge;
  const _HeroIconButton({required this.icon, this.badge = 0});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        if (badge > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: PremiumTheme.danger,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$badge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// ─────────────────────────── LINEUP ALERT ───────────────────────────
class _LineupAlertCard extends StatelessWidget {
  final Map<String, dynamic> match;
  const _LineupAlertCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final opponent = (match['opponent'] ?? 'Opponent').toString();
    final when = (match['scheduled_at'] ?? match['date'] ?? 'soon').toString();
    return OrleonCard(
      padding: const EdgeInsets.all(16),
      background: PremiumTheme.amber.withValues(alpha: 0.08),
      borderColor: PremiumTheme.amber.withValues(alpha: 0.45),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: PremiumTheme.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: PremiumTheme.amber, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LINEUP REQUIRED',
                  style: TextStyle(
                    color: PremiumTheme.amber,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'vs $opponent · $when',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LineupScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: PremiumTheme.amber,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'SUBMIT',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    ).pad();
  }
}

extension on Widget {
  Widget pad() => Padding(padding: EdgeInsets.zero, child: this);
}

/// ─────────────────────────── TEAMS LIST ───────────────────────────
class _TeamsList extends StatelessWidget {
  final List teams;
  const _TeamsList({required this.teams});

  @override
  Widget build(BuildContext context) {
    if (teams.isEmpty) {
      return _EmptyPlaceholder(
        icon: Icons.shield_outlined,
        label: 'No teams assigned yet',
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: teams.take(4).map((t) {
          final team = (t as Map).cast<String, dynamic>();
          final form = (team['form'] as List?)?.cast<dynamic>() ?? const [];
          final isLive = team['is_live'] == true;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OrleonCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: PremiumTheme.electricBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: PremiumTheme.electricBlue.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(Icons.shield,
                        color: PremiumTheme.electricBlue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                (team['name'] ?? 'Team').toString(),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (isLive) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: PremiumTheme.danger.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    OrleonPulseDot(size: 5),
                                    SizedBox(width: 4),
                                    Text(
                                      'LIVE',
                                      style: TextStyle(
                                        color: PremiumTheme.danger,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${team['category'] ?? 'U-18'} · ${team['players_count'] ?? 0} players',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: form
                        .take(5)
                        .map((f) => Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: OrleonFormChip(f.toString()),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// ─────────────────────────── FIXTURES ───────────────────────────
class _FixturesList extends StatelessWidget {
  final List matches;
  const _FixturesList({required this.matches});

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return _EmptyPlaceholder(
        icon: Icons.event_outlined,
        label: 'No upcoming fixtures',
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: matches.take(3).map((m) {
          final match = (m as Map).cast<String, dynamic>();
          final d = _parseDate(match['scheduled_at'] ?? match['date']);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OrleonFixtureRow(
              opponent: (match['opponent'] ?? 'Opponent').toString(),
              day: d.$1,
              month: d.$2,
              time: d.$3,
              venue: (match['venue'] ?? match['location'])?.toString(),
              competition: match['competition']?.toString(),
              onTap: () {},
            ),
          );
        }).toList(),
      ),
    );
  }

  (String, String, String) _parseDate(dynamic raw) {
    if (raw == null) return ('--', '---', '--:--');
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return ('--', '---', raw.toString());
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
                    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return (
      dt.day.toString().padLeft(2, '0'),
      months[dt.month - 1],
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
    );
  }
}

/// ─────────────────────────── TRAININGS ───────────────────────────
class _TrainingsList extends StatelessWidget {
  final List trainings;
  const _TrainingsList({required this.trainings});

  @override
  Widget build(BuildContext context) {
    final sample = trainings.isNotEmpty
        ? trainings
        : [
            {'title': 'Team Training', 'day': 'Mon', 'time': '18:00', 'venue': 'Main Field'},
            {'title': 'Tactical Drill', 'day': 'Wed', 'time': '19:00', 'venue': 'Indoor Hall'},
            {'title': 'Match Prep', 'day': 'Fri', 'time': '17:30', 'venue': 'Main Field'},
          ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: sample.take(3).map<Widget>((t) {
          final tr = t is Map ? t.cast<String, dynamic>() : <String, dynamic>{};
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OrleonCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: PremiumTheme.neonGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.sports, color: PremiumTheme.neonGreen),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (tr['title'] ?? 'Training').toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${tr['day'] ?? ''} · ${tr['time'] ?? ''} · ${tr['venue'] ?? ''}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white38),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// ─────────────────────────── COACHING TOOLS ───────────────────────────
class _CoachingToolsGrid extends StatelessWidget {
  const _CoachingToolsGrid();

  @override
  Widget build(BuildContext context) {
    final items = <_ToolItem>[
      _ToolItem('Lineup', Icons.grid_view_rounded, PremiumTheme.neonGreen,
          () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LineupScreen()),
              )),
      _ToolItem('Training Plan', Icons.assignment_outlined, PremiumTheme.electricBlue,
          () {}),
      _ToolItem('Performance', Icons.insights_outlined, PremiumTheme.amber,
          () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PerformanceScreen()),
              )),
      _ToolItem('Messages', Icons.chat_bubble_outline, Colors.purpleAccent, () {}),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
        children: items
            .map((i) => OrleonCard(
                  onTap: i.onTap,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: i.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(i.icon, color: i.color, size: 20),
                      ),
                      Text(
                        i.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _ToolItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _ToolItem(this.label, this.icon, this.color, this.onTap);
}

class _EmptyPlaceholder extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmptyPlaceholder({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: OrleonCard(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white38, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────── INBOX TAB ───────────────────────────
class _InboxTab extends StatelessWidget {
  const _InboxTab();

  @override
  Widget build(BuildContext context) {
    return const NotificationScreen();
  }
}

/// ─────────────────────────── BOTTOM NAV + FAB ───────────────────────────
class _CoachBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final VoidCallback onFabTap;
  const _CoachBottomNav({
    required this.index,
    required this.onChanged,
    required this.onFabTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 10 + bottomPadding),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _NavItem(
                icon: Icons.home_rounded,
                label: 'HOME',
                active: index == 0,
                onTap: () => onChanged(0),
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.shield_rounded,
                label: 'TEAMS',
                active: index == 1,
                onTap: () => onChanged(1),
              ),
            ),
            _CoachFab(onTap: onFabTap),
            Expanded(
              child: _NavItem(
                icon: Icons.event_available_rounded,
                label: 'EVENTS',
                active: index == 2,
                onTap: () => onChanged(2),
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.person_rounded,
                label: 'PROFILE',
                active: index == 3,
                onTap: () => onChanged(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? const Color(0xFF00E676)
        : Colors.white.withValues(alpha: 0.54);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachFab extends StatelessWidget {
  final VoidCallback onTap;
  const _CoachFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00E676), Color(0xFF00C853)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E676).withValues(alpha: 0.45),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.flash_on, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}
