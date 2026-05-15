import 'package:flutter/material.dart';
import '../../../../core/api/stats_api_service.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../data/models/player_stats.dart';
import '../../data/models/player_career_stats.dart';
import '../../data/models/match_history_item.dart';
import '../widgets/career_history_chart.dart';

class PlayerStatsScreen extends StatefulWidget {
  final String playerId;

  const PlayerStatsScreen({super.key, required this.playerId});

  @override
  _PlayerStatsScreenState createState() => _PlayerStatsScreenState();
}

class _PlayerStatsScreenState extends State<PlayerStatsScreen> {
  final StatsApiService _apiService = StatsApiService();
  late Future<PlayerStats> _statsFuture;
  late Future<PlayerCareerStats> _careerFuture;
  late Future<List<MatchHistoryItem>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _apiService.getPlayerStats(widget.playerId);
    _careerFuture = _apiService.getCareerStats(widget.playerId);
    _historyFuture = _apiService.getMatchHistory(widget.playerId);
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        title: const Text("CAREER INSIGHTS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<PlayerCareerStats>(
        future: _careerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: onSurface)));
          }
          final career = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMainDashboard(career),
                const SizedBox(height: 32),
                _buildSectionHeader("DETAILED STATISTICS"),
                const SizedBox(height: 16),
                _buildDetailedStatsGrid(career),
                const SizedBox(height: 32),
                _buildSectionHeader("PROGRESSION"),
                const SizedBox(height: 16),
                FutureBuilder<List<MatchHistoryItem>>(
                  future: _historyFuture,
                  builder: (context, historySnap) {
                    if (historySnap.hasData) {
                      return CareerHistoryChart(history: historySnap.data!);
                    }
                    return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                  },
                ),
                const SizedBox(height: 32),
                _buildSectionHeader("LATEST MATCHES"),
                const SizedBox(height: 16),
                _buildMatchHistoryList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 14, decoration: BoxDecoration(color: PremiumTheme.neonGreen, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMainDashboard(PlayerCareerStats career) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: PremiumTheme.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: PremiumTheme.neonShadow(color: PremiumTheme.neonGreen.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("OVERALL RATING", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(career.rating.toStringAsFixed(1), style: const TextStyle(color: Colors.black, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -2)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Text("${career.matchesPlayed}", style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w900)),
                    const Text("MATCHES", style: TextStyle(color: Colors.black54, fontSize: 8, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.black.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDashboardMetric("GOALS", "${career.goals}"),
              _buildDashboardMetric("ASSISTS", "${career.assists}"),
              _buildDashboardMetric("AWARDS", "${career.bestPlayerAwards}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardMetric(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildDetailedStatsGrid(PlayerCareerStats career) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.6,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatTile("Yellow Cards", "${career.yellowCards}", Icons.square, Colors.amber),
        _buildStatTile("Red Cards", "${career.redCards}", Icons.square, Colors.redAccent),
        _buildStatTile("Goal Ratio", (career.goals / (career.matchesPlayed > 0 ? career.matchesPlayed : 1)).toStringAsFixed(2), Icons.calculate_rounded, PremiumTheme.electricBlue),
        _buildStatTile("Clean Sheets", "0", Icons.shield_rounded, PremiumTheme.neonGreen),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(label, style: TextStyle(color: onSurface.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.bold)),
              Text(value, style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchHistoryList() {
    return FutureBuilder<List<MatchHistoryItem>>(
      future: _historyFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final history = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.length > 10 ? 10 : history.length,
          itemBuilder: (context, index) {
            final match = history[index];
            final onSurface = Theme.of(context).colorScheme.onSurface;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: onSurface.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: PremiumTheme.neonGreen.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Center(child: Icon(Icons.sports_soccer_rounded, color: PremiumTheme.neonGreen, size: 16)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(match.opponent, style: TextStyle(color: onSurface, fontWeight: FontWeight.w800, fontSize: 14)),
                        Text(match.tournamentName, style: TextStyle(color: onSurface.withValues(alpha: 0.4), fontSize: 11)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("${match.goals}G ${match.assists}A", style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.w900, fontSize: 13)),
                      if (match.isBestPlayer) const Icon(Icons.stars_rounded, color: Colors.amber, size: 14),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
