import 'package:flutter/material.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:provider/provider.dart';
import 'package:mobile/features/clubs/providers/club_provider.dart';

class CoachTeamsScreen extends StatefulWidget {
  final List? teams;
  final bool embedded;

  const CoachTeamsScreen({super.key, this.teams, this.embedded = false});

  @override
  State<CoachTeamsScreen> createState() => _CoachTeamsScreenState();
}

class _CoachTeamsScreenState extends State<CoachTeamsScreen> {
  final Set<int> _expanded = {0};

  List get _teams {
    if (widget.teams != null) return widget.teams!;
    final data = context.watch<ClubProvider>().coachDashboard ?? {};
    return (data['teams'] as List?) ?? const [];
  }

  int get _totalPlayers => _teams.fold<int>(
    0,
    (sum, t) => sum + ((t['players'] as List?)?.length ?? 0),
  );

  double get _avgRating {
    final all = _teams
        .expand<dynamic>((t) => (t['players'] as List?) ?? [])
        .where((p) => p['rating'] != null)
        .map<double>((p) => (p['rating'] as num).toDouble())
        .toList();
    if (all.isEmpty) return 0;
    return all.reduce((a, b) => a + b) / all.length;
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        _buildTopStats(),
        Expanded(
          child: _teams.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: _teams.length,
                  itemBuilder: (context, index) {
                    final team = _teams[index] as Map<String, dynamic>;
                    return _buildTeamCard(index, team);
                  },
                ),
        ),
      ],
    );
    if (widget.embedded) {
      return Container(
        color: PremiumTheme.deepNavy,
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8),
        child: body,
      );
    }
    return Scaffold(
      backgroundColor: PremiumTheme.deepNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'MY TEAMS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.search_rounded, color: Colors.white70, size: 18),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTopStats(),
          Expanded(
            child: _teams.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: _teams.length,
                    itemBuilder: (context, index) {
                      final team = _teams[index] as Map<String, dynamic>;
                      return _buildTeamCard(index, team);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: PremiumTheme.glassDecoration(radius: 16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              _statCell('${_teams.length}', 'TEAMS', PremiumTheme.neonGreen),
              _divider(),
              _statCell('$_totalPlayers', 'PLAYERS', PremiumTheme.electricBlue),
              _divider(),
              _statCell(
                _avgRating > 0 ? _avgRating.toStringAsFixed(1) : '—',
                'AVG RATING',
                Colors.amber,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCell(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, color: Colors.white.withValues(alpha: 0.06));

  Widget _buildTeamCard(int index, Map<String, dynamic> team) {
    final isExpanded = _expanded.contains(index);
    final name = team['name']?.toString() ?? 'Team';
    final ageGroup = team['age_group']?.toString() ?? '';
    final campus = team['campus']?.toString() ?? 'Main Campus';
    final players = (team['players'] as List?) ?? [];
    final isLive = team['is_live'] == true;
    final elo = team['elo_rating']?.toString() ?? '1800';
    final wins = team['wins'] ?? 0;
    final draws = team['draws'] ?? 0;
    final losses = team['losses'] ?? 0;
    final nextMatch = team['next_match'] as Map<String, dynamic>?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: PremiumTheme.glassDecoration(radius: 18),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expanded.remove(index);
                  } else {
                    _expanded.add(index);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.2)),
                          ),
                          child: const Icon(Icons.shield_rounded, color: PremiumTheme.neonGreen, size: 22),
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
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  if (isLive) ...[
                                    const SizedBox(width: 8),
                                    _liveBadge(),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$ageGroup · $campus · ${players.length} players',
                                style: const TextStyle(color: Colors.white38, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: Colors.white38,
                          size: 22,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          '${wins}W',
                          style: const TextStyle(color: PremiumTheme.neonGreen, fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${draws}D',
                          style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${losses}L',
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                        const SizedBox(width: 2),
                        Text(
                          elo,
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded) ...[
              Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
              if (players.isNotEmpty)
                _buildPlayerTable(players),
              if (nextMatch != null)
                _buildNextMatchRow(nextMatch),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _liveBadge() {
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
          Container(width: 5, height: 5, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
          const SizedBox(width: 3),
          const Text('LIVE', style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildPlayerTable(List players) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          const SizedBox(height: 10),
          _tableHeader(),
          const SizedBox(height: 6),
          ...players.map((p) => _tableRow(p as Map<String, dynamic>)),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: const [
          SizedBox(width: 36, child: Text('#', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w700))),
          Expanded(child: Text('PLAYER', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5))),
          SizedBox(width: 36, child: Center(child: Text('POS', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w700)))),
          SizedBox(width: 30, child: Center(child: Text('G', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w700)))),
          SizedBox(width: 30, child: Center(child: Text('A', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w700)))),
          SizedBox(width: 36, child: Center(child: Text('RTG', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w700)))),
        ],
      ),
    );
  }

  Widget _tableRow(Map<String, dynamic> player) {
    final jersey = player['jersey_number']?.toString() ?? '—';
    final name = player['name']?.toString() ?? player['player_name']?.toString() ?? 'Player';
    final pos = player['position']?.toString() ?? 'MID';
    final goals = player['goals']?.toString() ?? '0';
    final assists = player['assists']?.toString() ?? '0';
    final rating = (player['rating'] as num?)?.toStringAsFixed(1) ?? '—';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: PremiumTheme.neonGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Center(
                child: Text(
                  jersey,
                  style: const TextStyle(color: PremiumTheme.neonGreen, fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 36,
            child: Center(child: _posBadge(pos)),
          ),
          SizedBox(
            width: 30,
            child: Center(
              child: Text(goals, style: const TextStyle(color: PremiumTheme.neonGreen, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
          SizedBox(
            width: 30,
            child: Center(
              child: Text(assists, style: const TextStyle(color: PremiumTheme.electricBlue, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
          SizedBox(
            width: 36,
            child: Center(
              child: Text(rating, style: const TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _posBadge(String pos) {
    Color c;
    switch (pos.toUpperCase()) {
      case 'FOR':
      case 'FW':
        c = PremiumTheme.neonGreen;
        break;
      case 'MID':
      case 'MF':
        c = PremiumTheme.electricBlue;
        break;
      case 'DEF':
      case 'DF':
        c = Colors.amber;
        break;
      default:
        c = Colors.purple;
    }
    final label = pos.length > 3 ? pos.substring(0, 3).toUpperCase() : pos.toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w800)),
    );
  }

  Widget _buildNextMatchRow(Map<String, dynamic> match) {
    final home = match['home_team_name']?.toString() ?? '';
    final away = match['away_team_name']?.toString() ?? '';
    final iso = match['scheduled_at']?.toString() ?? '';
    DateTime? dt;
    try { dt = DateTime.parse(iso); } catch (_) {}
    final dateStr = dt != null ? '${_weekday(dt.weekday)} ${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}' : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: PremiumTheme.electricBlue.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: PremiumTheme.electricBlue, size: 13),
            const SizedBox(width: 8),
            const Text('Next: ', style: TextStyle(color: Colors.white38, fontSize: 11)),
            Text(
              '$home vs $away',
              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(dateStr, style: const TextStyle(color: PremiumTheme.electricBlue, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  String _weekday(int w) => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][w - 1];

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off_rounded, color: Colors.white12, size: 64),
          SizedBox(height: 16),
          Text(
            'NO TEAMS ASSIGNED',
            style: TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}
