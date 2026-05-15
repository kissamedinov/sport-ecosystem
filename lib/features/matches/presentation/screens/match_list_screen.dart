import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../lineups/providers/lineup_provider.dart';
import '../../../tournaments/data/models/tournament_match.dart';
import 'match_details_screen.dart';

class MatchListScreen extends StatelessWidget {
  const MatchListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final role = user?.roles?.first.toUpperCase() ?? 'PLAYER_ADULT';
    
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _getTitleForRole(role),
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 14),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        itemCount: 8,
        itemBuilder: (context, index) {
          final isLive = index < 3;
          final isMyTeam = index % 3 == 0;
          
          return _buildMatchCard(context, index, isLive, isMyTeam);
        },
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, int index, bool isLive, bool isMyTeam) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Stack(
        children: [
          PremiumCard(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MatchDetailsScreen(
                    match: TournamentMatch(
                      id: 'match_$index',
                      tournamentId: 'tournament_1',
                      homeTeamId: 'team_red',
                      awayTeamId: 'team_blue',
                      status: isLive ? 'LIVE' : 'SCHEDULED',
                      homeScore: isLive ? 2 : 0,
                      awayScore: isLive ? 1 : 0,
                      matchDate: DateTime.now().add(Duration(hours: index)),
                    ),
                    homeTeamName: 'RED DRAGONS',
                    awayTeamName: 'BLUE WOLVES',
                  ),
                ),
              );
            },
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildTeamSide('RED DRAGONS', Colors.redAccent, true)),
                    _buildScoreSection(context, isLive),
                    Expanded(child: _buildTeamSide('BLUE WOLVES', Colors.blueAccent, false)),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: Colors.white10),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emoji_events_outlined, size: 12, color: onSurface.withValues(alpha: 0.4)),
                    const SizedBox(width: 6),
                    Text(
                      'PREMIER LEAGUE • WEEK 12',
                      style: TextStyle(
                        fontSize: 10, 
                        fontWeight: FontWeight.w800, 
                        color: onSurface.withValues(alpha: 0.4),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isMyTeam)
            Positioned(
              top: 0,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: const BoxDecoration(
                  color: PremiumTheme.neonGreen,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                ),
                child: const Text(
                  'MY TEAM',
                  style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          if (isLive)
            Positioned(
              top: 12,
              right: 12,
              child: _LiveIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildTeamSide(String name, Color color, bool isHome) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
          ),
          child: Icon(Icons.shield_rounded, color: color, size: 28),
        ),
        const SizedBox(height: 10),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
      ],
    );
  }

  Widget _buildScoreSection(BuildContext context, bool isLive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            isLive ? '2 - 1' : 'VS',
            style: TextStyle(
              fontSize: isLive ? 24 : 18,
              fontWeight: FontWeight.w900,
              color: isLive ? Colors.white : Colors.white38,
            ),
          ),
          if (isLive)
            Text(
              "65'",
              style: const TextStyle(color: PremiumTheme.neonGreen, fontSize: 12, fontWeight: FontWeight.bold),
            )
          else
            const Text(
              "18:00",
              style: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  String _getTitleForRole(String role) {
    switch (role) {
      case 'PARENT':
        return 'CHILDREN MATCHES';
      case 'COACH':
        return 'TEAM FIXTURES';
      case 'FIELD_OWNER':
        return 'FIELD SCHEDULE';
      default:
        return 'LIVE MATCHES';
    }
  }
}

class _LiveIndicator extends StatefulWidget {
  @override
  State<_LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<_LiveIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 2, backgroundColor: Colors.redAccent),
            SizedBox(width: 4),
            Text('LIVE', style: TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
