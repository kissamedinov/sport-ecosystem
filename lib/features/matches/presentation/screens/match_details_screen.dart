import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import '../../../lineups/providers/lineup_provider.dart';
import '../../../lineups/models/lineup.dart';
import '../../../tournaments/data/models/tournament_match.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../lineups/presentation/screens/match_lineup_screen.dart';
import '../../presentation/screens/match_events_screen.dart';
import '../../../player_stats/presentation/screens/player_stats_screen.dart';

class MatchDetailsScreen extends StatefulWidget {
  final TournamentMatch match;
  final String homeTeamName;
  final String awayTeamName;

  const MatchDetailsScreen({
    super.key,
    required this.match,
    required this.homeTeamName,
    required this.awayTeamName,
  });

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<LineupProvider>();
      provider.fetchTeamLineup(widget.match.id, widget.match.homeTeamId);
      provider.fetchTeamLineup(widget.match.id, widget.match.awayTeamId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lineupProvider = context.watch<LineupProvider>();
    final user = context.watch<AuthProvider>().user;
    final isCoach = user?.roles?.any((r) => r == 'COACH' || r == 'TEAM_OWNER') ?? false;

    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('MATCH CENTER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 14)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildScoreBoard(),
            const SizedBox(height: 12),
            _buildTabSection(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildLineupSection(
                    context,
                    widget.homeTeamName,
                    widget.match.homeTeamId,
                    lineupProvider.getLineupForMatch(widget.match.id, widget.match.homeTeamId),
                    isCoach,
                    true,
                  ),
                  const SizedBox(height: 24),
                  _buildLineupSection(
                    context,
                    widget.awayTeamName,
                    widget.match.awayTeamId,
                    lineupProvider.getLineupForMatch(widget.match.id, widget.match.awayTeamId),
                    isCoach,
                    false,
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [PremiumTheme.surfaceBase(context), Colors.black],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTeamHeader(widget.homeTeamName, Colors.redAccent),
              _buildMiddleScore(),
              _buildTeamHeader(widget.awayTeamName, Colors.blueAccent),
            ],
          ),
          const SizedBox(height: 32),
          _buildMatchMeta(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildMiddleScore() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Text(
            '${widget.match.homeScore} : ${widget.match.awayScore}',
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: widget.match.status == 'LIVE' ? Colors.redAccent.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.match.status,
            style: TextStyle(
              color: widget.match.status == 'LIVE' ? Colors.redAccent : Colors.orange,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamHeader(String name, Color color) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 2),
            ],
          ),
          child: Icon(Icons.shield_rounded, size: 40, color: color),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 100,
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchMeta() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white38),
        const SizedBox(width: 8),
        Text(
          widget.match.matchDate?.toString().substring(0, 16) ?? 'TIME TBD',
          style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 20),
        Icon(Icons.location_on_outlined, size: 14, color: Colors.white38),
        const SizedBox(width: 8),
        const Text(
          'ARENA CENTER',
          style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCircleAction(Icons.analytics_outlined, 'STATS', () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => MatchEventsScreen(matchId: widget.match.id)));
        }),
        const SizedBox(width: 24),
        _buildCircleAction(Icons.videocam_outlined, 'REPLAY', null),
        const SizedBox(width: 24),
        _buildCircleAction(Icons.share_outlined, 'SHARE', null),
      ],
    );
  }

  Widget _buildCircleAction(IconData icon, String label, VoidCallback? onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            child: Icon(icon, color: onTap != null ? Colors.white : Colors.white24, size: 20),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: onTap != null ? Colors.white54 : Colors.white24, fontSize: 9, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildTabSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTab('LINEUPS', true),
          const SizedBox(width: 12),
          _buildTab('TIMELINE', false),
          const SizedBox(width: 12),
          _buildTab('INFO', false),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: active ? PremiumTheme.neonGreen : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? PremiumTheme.neonGreen : Colors.white10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.black : Colors.white38,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildLineupSection(BuildContext context, String teamName, String teamId, MatchLineup? lineup, bool isCoach, bool isHome) {
    final color = isHome ? Colors.redAccent : Colors.blueAccent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(width: 3, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 10),
                Text(
                  '$teamName LINEUP',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ],
            ),
            if (lineup != null)
              const Icon(Icons.check_circle_rounded, color: PremiumTheme.neonGreen, size: 18)
            else
              const Text('PENDING', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 16),
        if (lineup == null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                const Icon(Icons.groups_3_outlined, color: Colors.white10, size: 40),
                const SizedBox(height: 12),
                const Text('No lineup submitted yet', style: TextStyle(color: Colors.white24, fontSize: 12)),
                if (isCoach) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MatchLineupScreen(matchId: widget.match.id, teamId: teamId),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color.withValues(alpha: 0.1),
                      foregroundColor: color,
                      side: BorderSide(color: color.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('SUBMIT LINEUP', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                ],
              ],
            ),
          ),
        ] else
          _buildLineupList(lineup),
      ],
    );
  }

  Widget _buildLineupList(MatchLineup lineup) {
    final starters = lineup.players.where((p) => p.isStarting).toList();
    final bench = lineup.players.where((p) => !p.isStarting).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSquadCategory('STARTING XI', starters),
        const SizedBox(height: 16),
        _buildSquadCategory('SUBSTITUTES', bench),
      ],
    );
  }

  Widget _buildSquadCategory(String title, List<LineupPlayer> players) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 8),
        ...players.map((p) => _buildPlayerTile(p)),
      ],
    );
  }

  Widget _buildPlayerTile(LineupPlayer p) {
    final id = p.playerId ?? p.childProfileId ?? 'Unknown';
    final onSurface = Theme.of(context).colorScheme.onSurface;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerStatsScreen(playerId: id)));
        },
        dense: true,
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            p.position ?? '?',
            style: const TextStyle(color: PremiumTheme.neonGreen, fontSize: 10, fontWeight: FontWeight.w900),
          ),
        ),
        title: Text(
          'Player ${id.length > 8 ? id.substring(0, 8) : id}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        trailing: p.jerseyNumber != null 
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
              child: Text('#${p.jerseyNumber}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10)),
            )
          : null,
      ),
    );
  }
}
