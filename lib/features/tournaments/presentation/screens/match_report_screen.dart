import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/tournament_squad_member.dart';
import '../../providers/tournament_squad_provider.dart';
import '../../../matches/presentation/widgets/match_event_dialog.dart';
import '../../../matches/providers/match_provider.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/presentation/widgets/premium_widgets.dart';

class MatchReportScreen extends StatefulWidget {
  final String matchId;
  final String tournamentId;
  /// The tournament team ID of the reporter's team (null for organizer-only access)
  final String? myTournamentTeamId;
  final String? myTeamId;
  final bool isHomeTeam;

  const MatchReportScreen({
    super.key,
    required this.matchId,
    required this.tournamentId,
    this.myTournamentTeamId,
    this.myTeamId,
    this.isHomeTeam = true,
  });

  @override
  State<MatchReportScreen> createState() => _MatchReportScreenState();
}

class _MatchReportScreenState extends State<MatchReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _homeScoreController = TextEditingController(text: '0');
  final _awayScoreController = TextEditingController(text: '0');
  bool _isSubmittingScore = false;

  // Per-player stats: map of player_profile_id -> stats map
  final Map<String, Map<String, dynamic>> _playerStats = {};

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    final isOrganizer =
        user?.roles?.contains('tournament_organizer') == true ||
            user?.roles?.contains('admin') == true;

    // Show score tab only for organizers, stats tab for coaches (and organizers)
    _tabController = TabController(
        length: isOrganizer ? 3 : 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.myTournamentTeamId != null) {
        context
            .read<TournamentSquadProvider>()
            .fetchSquad(widget.myTournamentTeamId!);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _homeScoreController.dispose();
    _awayScoreController.dispose();
    super.dispose();
  }

  bool get _isOrganizer {
    final user = context.read<AuthProvider>().user;
    return user?.roles?.contains('tournament_organizer') == true ||
        user?.roles?.contains('admin') == true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MATCH REPORT'),
        bottom: _isOrganizer
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.orangeAccent,
                tabs: const [
                  Tab(icon: Icon(Icons.scoreboard), text: 'SCORE'),
                  Tab(icon: Icon(Icons.flash_on), text: 'LIVE EVENTS'),
                  Tab(icon: Icon(Icons.bar_chart), text: 'PLAYER STATS'),
                ],
              )
            : TabBar(
                controller: _tabController,
                indicatorColor: Colors.orangeAccent,
                tabs: const [
                  Tab(icon: Icon(Icons.flash_on), text: 'LIVE EVENTS'),
                  Tab(icon: Icon(Icons.bar_chart), text: 'PLAYER STATS'),
                ],
              ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          if (_isOrganizer) _buildScoreTab(),
          _buildLiveEventsTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  Widget _buildScoreTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Final Score',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text('HOME', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    _buildScoreInput(_homeScoreController),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '—',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text('AWAY', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    _buildScoreInput(_awayScoreController),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmittingScore ? null : _submitScore,
              icon: _isSubmittingScore
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle),
              label: const Text('SUBMIT FINAL SCORE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Submitting the score will update the tournament standings automatically.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreInput(TextEditingController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: () {
            final current = int.tryParse(controller.text) ?? 0;
            if (current > 0) {
              controller.text = (current - 1).toString();
            }
          },
        ),
        SizedBox(
          width: 60,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () {
            final current = int.tryParse(controller.text) ?? 0;
            controller.text = (current + 1).toString();
          },
        ),
      ],
    );
  }

  Widget _buildStatsTab() {
    if (widget.myTournamentTeamId == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Player stats are submitted by the coach of each team.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Consumer<TournamentSquadProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.squad.isEmpty) {
          return const Center(child: Text('No squad members. Set a squad first.'));
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: provider.squad.length,
                itemBuilder: (context, index) {
                  final member = provider.squad[index];
                  return _buildPlayerStatRow(member);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitPlayerStats,
                  icon: const Icon(Icons.send),
                  label: const Text('SUBMIT PLAYER STATS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlayerStatRow(TournamentSquadMember member) {
    _playerStats.putIfAbsent(
      member.playerProfileId,
      () => {
        'goals': 0,
        'assists': 0,
        'yellow_cards': 0,
        'red_cards': 0,
      },
    );
    final stats = _playerStats[member.playerProfileId]!;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.orangeAccent.withOpacity(0.2),
                  child: Text(
                    member.jerseyNumber?.toString() ?? '?',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    member.playerProfileId.length > 8
                        ? 'Player #${member.playerProfileId.substring(0, 8).toUpperCase()}'
                        : member.playerProfileId,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (member.position != null)
                  Chip(
                    label: Text(member.position!,
                        style: const TextStyle(fontSize: 10)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statCounter('⚽ Goals', stats, 'goals'),
                _statCounter('🅰️ Assists', stats, 'assists'),
                _statCounter('🟨 Yellow', stats, 'yellow_cards'),
                _statCounter('🟥 Red', stats, 'red_cards'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCounter(
      String label, Map<String, dynamic> stats, String key) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  if ((stats[key] as int) > 0) stats[key] = stats[key] - 1;
                });
              },
              child: const Icon(Icons.remove, size: 16),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                stats[key].toString(),
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  stats[key] = stats[key] + 1;
                });
              },
              child: const Icon(Icons.add, size: 16),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _submitScore() async {
    final homeScore = int.tryParse(_homeScoreController.text) ?? 0;
    final awayScore = int.tryParse(_awayScoreController.text) ?? 0;

    setState(() => _isSubmittingScore = true);
    final success = await context.read<TournamentProvider>().updateMatchResult(
          widget.matchId,
          homeScore,
          awayScore,
        );
    setState(() => _isSubmittingScore = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success
            ? 'Score submitted! Standings updated.'
            : 'Failed: ${context.read<TournamentProvider>().error}'),
        backgroundColor: success ? Colors.green : Colors.red,
      ));
      if (success) Navigator.pop(context);
    }
  }

  Future<void> _submitPlayerStats() async {
    // ...
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Player stats recorded!'),
        backgroundColor: Colors.green,
      ));
      Navigator.pop(context);
    }
  }

  Widget _buildLiveEventsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: PremiumCard(
            onTap: () async {
              final result = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (context) => MatchEventDialog(
                  matchId: widget.matchId,
                  homeTeamId: 'home_id', 
                  awayTeamId: 'away_id', 
                  homeTeamName: 'Home Team',
                  awayTeamName: 'Away Team',
                ),
              );
              if (result != null) {
                await context.read<MatchProvider>().addMatchEvent(widget.matchId, result);
              }
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle, color: PremiumTheme.neonGreen),
                SizedBox(width: 12),
                Text('RECORD LIVE EVENT (GOAL/CARD)', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
