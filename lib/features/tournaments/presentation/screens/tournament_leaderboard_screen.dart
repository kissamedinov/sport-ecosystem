import 'package:flutter/material.dart';
import '../../../../core/api/stats_api_service.dart';
import '../../data/models/top_scorer.dart';
import '../widgets/leaderboard_item.dart';

class TournamentLeaderboardScreen extends StatefulWidget {
  final String tournamentId;

  const TournamentLeaderboardScreen({super.key, required this.tournamentId});

  @override
  _TournamentLeaderboardScreenState createState() => _TournamentLeaderboardScreenState();
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
      appBar: AppBar(
        title: const Text("Tournament Leaderboard"),
        backgroundColor: Colors.blue[900],
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[900]!, Colors.blue[700]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            _buildStatSummary(),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: FutureBuilder<List<TopScorer>>(
                  future: _leaderboardFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }
                    final leaderboard = snapshot.data ?? [];
                    if (leaderboard.isEmpty) {
                      return const Center(child: Text("No scorers recorded yet."));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 24, bottom: 24),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatSummary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text(
            "Top Scorers",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Icon(Icons.military_tech, color: Colors.amber, size: 40),
        ],
      ),
    );
  }
}
