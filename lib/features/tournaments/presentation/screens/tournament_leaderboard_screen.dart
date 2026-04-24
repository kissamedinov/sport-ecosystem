import 'package:flutter/material.dart';
import '../../../../core/api/stats_api_service.dart';
import '../../data/models/top_scorer.dart';
import '../widgets/leaderboard_item.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/presentation/widgets/premium_widgets.dart';

class TournamentLeaderboardScreen extends StatefulWidget {
  final String tournamentId;

  const TournamentLeaderboardScreen({super.key, required this.tournamentId});

  @override
  State<TournamentLeaderboardScreen> createState() => _TournamentLeaderboardScreenState();
}

class _TournamentLeaderboardScreenState extends State<TournamentLeaderboardScreen> {
  final StatsApiService _apiService = StatsApiService();
  late Future<List<TopScorer>> _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    _leaderboardFuture = _apiService.getTopScorers(widget.tournamentId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.deepNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('LEADERBOARD', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 14)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const PremiumHeader(title: 'Golden', subtitle: 'Boot Race'),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.military_tech, color: PremiumTheme.neonGreen, size: 32),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<TopScorer>>(
              future: _leaderboardFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen));
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: PremiumTheme.danger)));
                }
                final leaderboard = snapshot.data ?? [];
                if (leaderboard.isEmpty) {
                  return const Center(child: Text("No scorers recorded yet.", style: TextStyle(color: Colors.white38)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: leaderboard.length,
                  itemBuilder: (context, index) {
                    return LeaderboardItem(
                      scorer: leaderboard[index],
                      rank: index + 1,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
